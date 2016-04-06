#!/bin/bash

for file in `find data -iname *.json`;  do
  # jq -r ".items[] | [.identifier._value , .sponsorPrinted[], .created._value, .label._value, .numberOfSignatures, .status] | @csv" ${file}
  jq -r ".items[] | [.identifier._value] | @csv" ${file}
done
