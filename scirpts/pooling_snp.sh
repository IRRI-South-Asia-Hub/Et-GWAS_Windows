#!/bin/bash

helpFunction()
{
	echo ""
   	echo "Usage: bash $0 -h hapmap.txt -p ped/map -f fam -v vcf -t <hap2ped/ped2hap/fam2hap/fam2vcf>"
   	echo -e "\t-h trait"
	exit 1
}

# inputs
while getopts "h:" option
do
case "${option}"
in
h) trait=${OPTARG};;
esac
done

#awk '{print $2}' $trait".hmp.txt" | awk -F "/" 'OFS="\t" {print $1,$2}' > $trait"_hmp_allele.txt"
awk 'OFS="\t" {print $3,$4}' $trait".afreq" > $trait"_hmp_allele.txt"
sed -i "1s/.*/Ref\tAlt/" $trait"_hmp_allele.txt"
