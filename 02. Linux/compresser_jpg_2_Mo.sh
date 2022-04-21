#!/usr/bin/bash
for i in *.jpg;
  do name=`echo "$i" | cut -d'.' -f1`
  echo "$name"
  convert "$i" -define jpeg:extent=2mb "${name}_compressé_2mo.jpg"
done
