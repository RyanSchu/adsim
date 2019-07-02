#!/bin/bash

## takes in outputs of simulation and a list of snps
## takes in the ref.bcf.gz as well as the query.vcf file
## makes internal calls to plink and vcftools
## as pruning is sensitive to sample size and the outputs of simulations can be quite small (defult 20) it is often best to prune snps within a larger reference group and subset the simulated data as such


outPathDefault="./adsim_from_list"

while :
do
    case "$1" in
      --vcf) #simulated vcf file to be pruned. Required.
                vcfFile=$2
                shift 2
                ;;
      --out | -o) #same as normal plink - Path to out files and the shared prefix
                outPath="$2"
                shift 2
                ;;
      --bcf) #simulated bcf file to be pruned. Required.
                bcfFile="$2"
                shift 2
                ;;
      --snplist | --snps | -s) #list of snps to subset
                snpList="$2"
                shift 2
                ;;
      --map | -m | --genetic-map) #genetic map file - filtered map file is preferred. REQUIRED.
                geneticMap="$2"
                shift 2
                ;;
      --help | -h) 
                echo "--vcf : vcf file to extract samples from. Typically 1000 genome file. REQUIRED."
                echo "--out or -o : Use is as in plink - Path to out files and the shared prefix. Default is WORKING_DIR/adsim_pruned"
                echo "--map or -m or --genetic-map : genetic map file - format is rsid pos centimorgan-pos. REQUIRED."
                echo "--snplist | --snps | -s : list of snps to subset"
                exit 0
                ;;
      -*) #unknown
                echo "Error: Unknown option: $1" >&2
                echo "./simulate.sh --help or ./simulate.sh -h for option help"
                exit 1
                ;;
      *)  # No more options
                shift
                break
                ;;
     esac
done
if [ -z "${vcfFile}" ] || [ ! -e "${vcfFile}" ]
then
  echo "Query VCF not set or DNE. Please input a valid VCF."
  echo "./simulate.sh --help or ./simulate.sh -h for option help"
  echo "Exiting"
  exit 1
fi
if [ -z "${bcfFile}" ] || [ ! -e "${bcfFile}" ]
then
  echo "Reference BCF not set or DNE. Please input a valid BCF."
  echo "./simulate.sh --help or ./simulate.sh -h for option help"
  echo "Exiting"
  exit 1
fi
if [ -z "${snpList}" ] || [ ! -e "${snpList}" ]
then
  echo "snpList not set or DNE. Please input a valid BCF."
  echo "./simulate.sh --help or ./simulate.sh -h for option help"
  echo "Exiting"
  exit 1
fi
if [ -z "${geneticMap}" ] || [ ! -e "${geneticMap}" ]
then
  echo "Genetic map file not set or DNE. Please input a valid map."
  echo "./simulate.sh --help or ./simulate.sh -h for option help"
  echo "Exiting"
  exit 1
fi
sed -i -e "5 s/VAR/ALT/g" "${vcfFile}"
echo "making new genetic map"
Rscript scripts/01bIntersect_map_snp_list.R --snps "${snpList}" --map "${geneticMap}" --out "${outPath:=$outPathDefault}"_from_list
echo "making new query vcf"
vcftools --vcf "${vcfFile}" --snps "${snpList}" --recode --out "${outPath}"_from_list
echo "making new reference bcf"
vcftools --bcf "${bcfFile}" --snps "${snpList}" --out "${outPath}"_from_list --recode-bcf
tabix  "${outPath}"_from_list.recode.bcf


