#!/bin/bash
OUTPUT="csv/admin2.csv"
SOURCE_ADMIN="tsv/admin2Codes.txt"
SOURCE="tmp/admin2.csv"
ALTERNATES="tmp/Alternates.csv"
COUNTRIES="tmp/countries.csv"
DEBUG="csv/debug_admin2.csv"

echo "name_english;name_ascii;name_local;geoname_id;ISO_NATION;" > $OUTPUT
echo "name_english;name_ascii;name_local;geoname_id;ISO_NATION;" > $DEBUG
cat $SOURCE_ADMIN > $SOURCE
sed -i 's/\t/;/g' $SOURCE

while IFS= read -r ADMIN_LINE
do
    IFS=';' read -a ADMIN_LINE_ARRAY <<< $ADMIN_LINE
    ISO=${ADMIN_LINE_ARRAY[0]:0:2}
    name_english=${ADMIN_LINE_ARRAY[1]}
    name_ascii=${ADMIN_LINE_ARRAY[2]}
    name_local='NULL'
    geoname_id=${ADMIN_LINE_ARRAY[3]}

    # seleziono country di riferimento basandomi su ISO per avere la iso della lingua principale
    COUNTRY_STRING=$(grep -E "^$ISO" $COUNTRIES)
    IFS=';' read -a COUNTRY_STRING_ARRAY <<< $COUNTRY_STRING
    preferred_lang=${COUNTRY_STRING_ARRAY[15]:0:2}

    # seleziono gruppo di definizioni alternates basato solo su lingua primaria e geonameid
    ALTERNATES_STRING=$(grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;$" $ALTERNATES)
    IFS=$'\n'
    ALTERNATES_ARRAY=( $(grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;$" $ALTERNATES) )
    # valuto quante definizioni in lingua primaria ho per un solo geonameid
    # se trovo piu' definizioni
    if [[ ${#ALTERNATES_ARRAY[@]} > 1 ]]; then
        # seleziono tra le definizioni in lingua quelle con preferredName = 1
        PREF_ARRAY=( $(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;;.*;.*;.*;$" -) )
        PREF_ARRAY_STRING=$(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;;.*;.*;.*;$" -)      
        # seleziono se ci sono definizioni che hanno sia preferred=1 che shortname=1
        PREF_AND_SHORT_ARRAY=( $(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;1;.*;.*;.*;$" -) )
        PREF_AND_SHORT_ARRAY_STRING=$(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;1;.*;.*;.*;$" -)
        # seleziono definizione sono solo shortname=1
        SHORT_ARRAY=( $(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;;1;.*;.*;.*;$" -) )
        SHORT_ARRAY_STRING=$(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;;1;.*;.*;.*;$" -)

        # valuto quante definizioni preferred=1 in lingua primaria
        if [[ ${#PREF_ARRAY[@]} == 0 ]]; then
            # se non ho definizioni preferred
            # valuto la presenza di shortname=1
            if [[ ${#SHORT_ARRAY[@]} == 0 ]];then
                # se non ho definizioni shortname
                # o prendo la prima definizione alternate in lingua 
                IFS=";" read -a X <<< ${ALTERNATES_ARRAY[0]}
                name_local=${X[3]}
                # o il nome inglese
                # name_local=$name_english
            fi   
        elif [[ ${#PREF_ARRAY[@]} == 1 ]]; then
            # se una sola definizione e' preferred=1 allora ok
            IFS=";" read -a X <<< $PREF_ARRAY_STRING
            name_local=${X[3]}
        elif [[ ${#PREF_ARRAY[@]} > 1 ]]; then
            # se ho piu' di una definizione segnata come preferred=1
            # valuto eventuali definizioni che non siano sia preferred che shortname
            if [[ ${#PREF_AND_SHORT_ARRAY[@]} == 1 ]]; then
                # se una sola definizione e' sia preferred=1 che shortname=1 allora ok
                IFS=";" read -a X <<< $PREF_AND_SHORT_ARRAY_STRING
                name_local=${X[3]}
            elif [[ ${#PREF_AND_SHORT_ARRAY[@]} > 1 ]]; then
                # se piu' di una definizione risulta sia preferred che short
                # per ora prendo la prima arbitrariamente
                IFS=";" read -a X <<< ${PREF_AND_SHORT_ARRAY[0]}
                name_local=${X[3]}
            elif [[ ${#PREF_AND_SHORT_ARRAY[@]} == 0 ]]; then
                # se non ho neanche una definizione sia preferred che short
                # valuto eventuali definizioni solamente short
                if [[ ${#SHORT_ARRAY[@]} == 1 ]]; then
                    # se ho un solo shortname=1 allora ok
                    IFS=";" read -a X <<< $SHORT_ARRAY_STRING
                    name_local=${X[3]}
                elif [[ ${#SHORT_ARRAY[@]} > 1 ]]; then
                    # se piu' di una definizione risulta shortname
                    # per ora prendo la prima arbitrariamente
                    IFS=";" read -a X <<< ${SHORT_ARRAY[0]}
                    name_local=${X[3]}
                elif [[ ${#SHORT_ARRAY[@]} == 0 ]]; then
                    #  se non ho neanche uno short name
                    # qua o prendo la prima definizione alternate in lingua 
                    IFS=";" read -a X <<< ${ALTERNATES_ARRAY[0]}
                    name_local=${X[3]}
                    # o il nome inglese
                    # name_local=$name_english
                fi
            fi
        fi
    elif [[ ${#ALTERNATES_ARRAY[@]} == 1 ]]; then
        # se trovo una sola definizione alternate  allora ok
        IFS=";" read -a X <<< $ALTERNATES_STRING
        name_local=${X[3]}
    elif [[ ${#ALTERNATES_ARRAY[@]} == 0 ]];then
        # se non trovo nessuna definizione in alternate allora uso quella inglese
        name_local=$name_english
    fi

    # STAMPA CSV
    echo $name_english';'$name_ascii';'$name_local';'$geoname_id';'$ISO';' >> $OUTPUT
done < "$SOURCE"

# filtro definizioni con nameenglish == namelocal
grep -E "(.*);\1;.*;" $OUTPUT >> $DEBUG