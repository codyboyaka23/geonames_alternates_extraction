#!/bin/bash
OUTPUT="tmp/AlternatesForAdmin2.csv"
SOURCE_ADMIN="tsv/admin2Codes.txt"
SOURCE="tmp/admin2.csv"
ALTERNATES="tmp/Alternates.csv"
COUNTRIES="tmp/countries.csv"
cat $SOURCE_ADMIN > $SOURCE
sed -i 's/\t/;/g' $SOURCE
while IFS= read -r ADMIN_LINE
do
    IFS=';' read -a ADMIN_LINE_ARRAY <<< $ADMIN_LINE
    ISO=${ADMIN_LINE_ARRAY[0]:0:2}
    geoname_id=${ADMIN_LINE_ARRAY[3]}
    IFS=';' read -a X <<< "$(grep -E "^$ISO" $COUNTRIES)"
    preferred_lang=${X[15]:0:2}
    grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;$" $ALTERNATES >> $OUTPUT
done < "$SOURCE"