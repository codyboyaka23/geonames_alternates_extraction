#!/bin/bash
OUTPUT="csv/countries_debug.csv"
SOURCE_COUNTRIES="tsv/countryInfo.txt"
SOURCE="tmp/countries.csv"
ALTERNATES="tmp/AlternatesForCountries.csv"

echo "iso_3166_a2;iso_3166_a3;iso_3166_n;name_english;name_local;telephone_prefix;postal_code_regex;date_format;geoname_id;MESSAGE;" > $OUTPUT

cat $SOURCE_COUNTRIES > $SOURCE
sed -i '1d' $SOURCE
sed -i 's/\t/;/g' $SOURCE

while IFS= read -r COUNTRY_LINE
do
    IFS=';' read -a COUNTRY_LINE_ARRAY <<< $COUNTRY_LINE
    
    preferred_lang=${COUNTRY_LINE_ARRAY[15]:0:2}
    iso_3166_a2=${COUNTRY_LINE_ARRAY[0]}
    iso_3166_a3=${COUNTRY_LINE_ARRAY[1]}
    iso_3166_n=${COUNTRY_LINE_ARRAY[2]}
    name_english=${COUNTRY_LINE_ARRAY[4]}
    name_local='NULL'
    telephone_prefix=${COUNTRY_LINE_ARRAY[12]}
    postal_code_regex==${COUNTRY_LINE_ARRAY[14]}
    date_format='NULL'
    geoname_id=${COUNTRY_LINE_ARRAY[16]}
    MESSAGE='NULL'

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
            if [[ ${#SHORT_ARRAY[@]} == 0 ]];then
                # se non ho definizioni shortname
                # o prendo la prima definizione alternate in lingua 
                IFS=";" read -a X <<< ${ALTERNATES_ARRAY[0]}
                name_local=${X[3]}
                MESSAGE='0 preferred 0 shortname tra gli alternates trovati'
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
                MESSAGE='>1 sia preferred che shortname tra gli alternates trovati'
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
                    MESSAGE='>1 shortname, non preferred tra gli alternates trovati'
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
        MESSAGE='0 alternates trovati'
    fi

    echo $iso_3166_a2';'$iso_3166_a3';'$iso_3166_n';'$name_english';'$name_local';'$telephone_prefix';'$postal_code_regex';'$date_format';'$geoname_id';'$MESSAGE';'>> $OUTPUT

done < "$SOURCE"
