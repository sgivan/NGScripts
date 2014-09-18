#!/bin/bash
# copy this script from ~sgivan/projects/NGSscripts/bin
# developed for use with nucmer output

file=$1

echo "|Contig|ANT505|AUTQ|AUTS|BADV|NJ631|CAPN|"

for node in `grep '>' $file | sed 's/>//' | sed -r 's/_length.+//' | sort -g`
do
    printf '|%s' $node
    for dir in ANT505 AUTQ AUTS BADV NJ631 CAPN 
        do
            cov=`show-coords -L 1000 -c -l -q -T ${dir}/${dir}.delta | grep ${node}_ | datamash sum 11`
            printf '|%2.2f' $cov
        done
    printf "%s\n" '|'
done
echo
