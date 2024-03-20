#!/bin/bash


#help function
helpFunction()
{
	echo ""
   	echo "Usage: bash $0 -h hapmap.txt -p ped/map -f fam -v vcf -t <hap2ped/ped2hap/fam2hap/fam2vcf>"
   	echo -e "\t-h hapmap file"
	echo -e "\t-p ped/map file (no extention)"
	echo -e "\t-f fam file (no extention)"
	echo -e "\t-v vcf file (no extension)"
	echo -e "\t-t Convertion type [ hap2ped (or) ped2hap (or) fam2hap (or) fam2vcf]"
	exit 1
}

# inputs
while getopts "h:p:f:t:" option
do
case "${option}"
in
h) hapmap=${OPTARG};;
p) pedin=${OPTARG};;
f) famin=${OPTARG};;
v) vcf=${OPTARG};;
t) convtype=${OPTARG};;
esac
done

if [ -z $convtype ] 
then
	echo "Specify the convertion type"
	helpFunction
fi

if [ -z $hapmap ] || [ -z $pedin ] && [ -z $famin ]
then
	echo "one or many missing ifles"
	helpFunction
fi
		
if [ $convtype == "hap2ped" ]
then
	echo "hapmap --> ped/map"
	/home/niranjani/Softwares/tassel-5-standalone/run_pipeline.pl -fork1 -h $hapmap -export $pedin -exportType Plink
	awk '{$1=$2} {OFS=FS} {print}' $pedin".plk.ped" > tmp.ped
	mv tmp.ped $pedin".plk.ped"
fi

if [ $convtype == "ped2hap" ]
then
        echo "ped/map --> hapmap"
        SOFTWARES_QC/tassel-5-standalone/run_pipeline.pl -fork1 -plink -ped $pedin".ped" -map $pedin".map" -export $hapmap -exportType Hapmap
fi

if [ $convtype == "fam2hap" ]
then
	echo "fam --> ped/map --> hapmap"
	pedin=$famin

	/home/niranjani/Softwares/plink-1.07-x86_64/./plink --bfile $famin --recode --tab --noweb --allow-no-sex --out $pedin
	/home/niranjani/Softwares/tassel-5-standalone/run_pipeline.pl -fork1 -plink -ped $pedin".ped" -map $pedin".map" -export $hapmap -exportType Hapmap
fi




if [ $convtype == "fam2vcf" ]
then
	echo "fam --> vcf"
	/home/niranjani/Softwares/plink2 --bfile $famin --keep-allele-order --recode vcf --out $vcf
fi











