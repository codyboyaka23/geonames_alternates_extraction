#!/bin/bash
ALTERNATES="tmp/Alternates.csv"
SOURCE_ALTERNATES="tsv/alternateNamesV2.txt"

wget http://download.geonames.org/export/dump/alternateNamesV2.zip .
unzip alternateNamesV2.zip
mv alternateNamesV2/alternateNamesV2.txt $SOURCE_ALTERNATES
rm -fr alternateNamesV2
rm alternateNamesV2.zip
cat $SOURCE_ALTERNATES > $ALTERNATES
sed -i 's/\t/;/g' $ALTERNATES