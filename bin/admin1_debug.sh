#!/bin/bash
OUTPUT="csv/admin1_debug.csv"
SOURCE_ADMIN="tsv/admin1CodesASCII.txt"
SOURCE="tmp/admin1.csv"
ALTERNATES="tmp/AlternatesForAdmin1.csv"
COUNTRIES="tmp/countries.csv"

echo "country_iso_3166_a2;name_english;name_ascii;name_local;geoname_id;MESSAGE;" > $OUTPUT

cat $SOURCE_ADMIN > $SOURCE
sed -i 's/\t/;/g' $SOURCE

while IFS= read -r ADMIN_LINE
do
    IFS=';' read -a ADMIN_LINE_ARRAY <<< $ADMIN_LINE
    country_iso_3166_a2=${ADMIN_LINE_ARRAY[0]:0:2}
    name_english=${ADMIN_LINE_ARRAY[1]}
    name_ascii=${ADMIN_LINE_ARRAY[2]}
    name_local='NULL'
    geoname_id=${ADMIN_LINE_ARRAY[3]}
    MESSAGE="NULL"

    # seleziono country di riferimento basandomi su ISO per avere la iso della lingua principale
    COUNTRY_STRING=$(grep -E "^$country_iso_3166_a2" $COUNTRIES)
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
        PREF_ARRAY=( $(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;;.*$" -) )
        PREF_ARRAY_STRING=$(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;;.*$" -)      
        # seleziono se ci sono definizioni che hanno sia preferred=1 che shortname=1
        PREF_AND_SHORT_ARRAY=( $(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;1;.*$" -) )
        PREF_AND_SHORT_ARRAY_STRING=$(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;1;1;.*$" -)
        # seleziono definizione sono solo shortname=1
        SHORT_ARRAY=( $(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;;1;.*$" -) )
        SHORT_ARRAY_STRING=$(echo $ALTERNATES_STRING | grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;;1;.*$" -)

        # valuto quante definizioni preferred=1 in lingua primaria
        if [[ ${#PREF_ARRAY[@]} == 0 ]]; then
            # se non ho definizioni preferred
            # valuto la presenza di shortname=1
            # BOF blocco da ripetere
                if [[ ${#SHORT_ARRAY[@]} == 0 ]];then
                    # se non ho definizioni shortname
                    # o prendo la prima definizione alternate in lingua 
                    IFS=";" read -a X <<< ${ALTERNATES_ARRAY[0]}
                    name_local=${X[3]}
                    MESSAGE='0 preferred 0 shortname tra gli alternates trovati'
                    # o il nome inglese
                    # name_local=$name_english
                elif [[ ${#SHORT_ARRAY[@]} == 1 ]]; then
                    # se ho un solo shortname=1 allora ok
                    IFS=";" read -a X <<< $SHORT_ARRAY_STRING
                    name_local=${X[3]}
                elif [[ ${#SHORT_ARRAY[@]} > 1 ]]; then
                    # se piu' di una definizione risulta shortname
                    # per ora prendo la prima arbitrariamente
                    IFS=";" read -a X <<< ${SHORT_ARRAY[0]}
                    name_local=${X[3]}
                    MESSAGE='>1 shortname, 0 preferred tra gli alternates trovati'
                fi
            # EOF blocco da ripetere
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
                MESSAGE='>1 sia preferred che shortname tra gli alternates trovati'
            elif [[ ${#PREF_AND_SHORT_ARRAY[@]} == 0 ]]; then
                # se non ho neanche una definizione sia preferred che short
                # valuto eventuali definizioni solamente short
                # BOF blocco da ripetere
                    if [[ ${#SHORT_ARRAY[@]} == 0 ]];then
                        # se non ho definizioni shortname
                        # o prendo la prima definizione alternate in lingua 
                        IFS=";" read -a X <<< ${ALTERNATES_ARRAY[0]}
                        name_local=${X[3]}
                        MESSAGE='0 preferred 0 shortname tra gli alternates trovati'
                        # o il nome inglese
                        # name_local=$name_english
                    elif [[ ${#SHORT_ARRAY[@]} == 1 ]]; then
                        # se ho un solo shortname=1 allora ok
                        IFS=";" read -a X <<< $SHORT_ARRAY_STRING
                        name_local=${X[3]}
                    elif [[ ${#SHORT_ARRAY[@]} > 1 ]]; then
                        # se piu' di una definizione risulta shortname
                        # per ora prendo la prima arbitrariamente
                        IFS=";" read -a X <<< ${SHORT_ARRAY[0]}
                        name_local=${X[3]}
                        MESSAGE='>1 shortname, 0 preferred tra gli alternates trovati'
                    fi
                # EOF blocco da ripetere
            fi
        fi
    elif [[ ${#ALTERNATES_ARRAY[@]} == 1 ]]; then
        # se trovo una sola definizione alternate  allora ok
        IFS=";" read -a X <<< $ALTERNATES_STRING
        name_local=${X[3]}
    elif [[ ${#ALTERNATES_ARRAY[@]} == 0 ]];then
        # se non trovo nessuna definizione in alternate allora uso quella inglese
        name_local=$name_english
        MESSAGE='0 alternates trovati'
    fi

    # STAMPA CSV
    echo $country_iso_3166_a2';'$name_english';'$name_ascii';'$name_local';'$geoname_id';'$MESSAGE';' >> $OUTPUT
done < "$SOURCE"
