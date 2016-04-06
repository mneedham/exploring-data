#!/bin/bash

for file in `find data -iname *.json`;  do
  jq -r ".items[] | [.identifier._value] | @csv" ${file}
done


# ./to_csv.sh | xargs -I {} echo https://petition.parliament.uk/petitions/{}.json > data/petitions.csv
