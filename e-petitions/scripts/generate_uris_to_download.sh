#!/bin/bash

for file in `find data -iname page-*.json`;  do
  jq -r ".items[] | [.identifier._value] | @csv" ${file}
done | xargs -I {} echo https://petition.parliament.uk/petitions/{}.json > data/petitions.csv
