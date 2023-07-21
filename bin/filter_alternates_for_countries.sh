#!/bin/bash
OUTPUT="tmp/AlternatesForCountries.csv"
SOURCE_COUNTRIES="tsv/countryInfo.txt"
SOURCE="tmp/countries.csv"
ALTERNATES="tmp/Alternates.csv"
cat $SOURCE_COUNTRIES > $SOURCE
sed -i '1d' $SOURCE
sed -i 's/\t/;/g' $SOURCE
while IFS= read -r COUNTRY_LINE
do
    IFS=';' read -a COUNTRY_LINE_ARRAY <<< $COUNTRY_LINE
    preferred_lang=${COUNTRY_LINE_ARRAY[15]:0:2}
    geoname_id=${COUNTRY_LINE_ARRAY[16]}
    grep -E "^[0-9]+;$geoname_id;$preferred_lang;.*;$" $ALTERNATES >> $OUTPUT
done < "$SOURCE"