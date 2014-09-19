#!/bin/bash

file=$1

dirs=`ls -C */*.delta | sed -r 's/\/\w+.delta//g' | sed 's/  / /g'`
header=`echo $dirs | sed 's/ /|/g'`

#echo "dirs: $dirs"
#echo "header: |$header|"
#exit

#echo "|Contig|JJNZ|AUTP|JEMJ|AUTQ|"
echo "|Contig|$header|"

for node in `grep '>' $file | sed 's/>//' | sed -r 's/_length.+//' | sort -g`
do
    printf '|%s' $node
    #for dir in JJNZ AUTP JEMJ AUTQ
    for dir in $dirs
        do
            cov=`show-coords -L 1000 -c -l -q -T ${dir}/${dir}.delta | grep ${node}_ | datamash sum 11`
            printf '|%2.2f' $cov
        done
    printf "%s\n" '|'
done
echo
