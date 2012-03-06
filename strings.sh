#!/bin/bash

for file in Resources/Localizations/*.lproj/PhotoSubmitter.strings; do
  twine generate-string-file Resources/Localizations/strings.txt $file --tags=common --encoding utf-16
done
