#!/bin/bash

file=$1

dirs=`ls -C *.delta | sed -r 's/\/\w+.delta//g' | sed 's/  / /g'`
header=`echo $dirs | sed 's/ /|/g'`

# output of show-coords command
#NUCMER
#
#    [S1]     [E1]  |     [S2]     [E2]  |  [LEN 1]  [LEN 2]  |  [% IDY]  | [TAGS]
#    =====================================================================================
#    44534992 44537141  |    14112    16283  |     2150     2172  |    91.32  | Chr01        jcf7180018103480
#    47638838 47660237  |    29421     8014  |    21400    21408  |    99.64  | Chr01        jcf7180018103492
#    47660355 47667991  |     7637        1  |     7637     7637  |    99.93  | Chr01        jcf7180018103492
#    48972783 48974157  |    35413    34042  |     1375     1372  |    99.06  | Chr01        jcf7180018103497
#    48974294 48993688  |    34042    14705  |    19395    19338  |    99.36  | Chr01        jcf7180018103497

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
            cov=`show-coords -H -L 1000 -c -l -q -T ${dir}/${dir}.delta | grep ${node}_ | datamash sum 11`
#           "datamash sum 11" sums column 11
            printf '|%2.2f' $cov
        done
    printf "%s\n" '|'
done
echo
