#!/bin/bash

for dir
do
    echo $dir
    cd $dir
    mkdir -p fastqc-raw fastqc-clean
    
    bsub -J ${dir}raw fastqc --outdir fastqc-raw --adapters ../adapter.txt --noextract --format fastq set1_00.fq 
    bsub -J ${dir}clean fastqc --outdir fastqc-clean --adapters ../adapter.txt --noextract --format fastq set1.fq 

    cd ..
done


