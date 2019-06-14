## takes input vcf and a list of samples - sample list are generated beforehand
## By default doesn't subset chr, but in general only 22 is necessary
## 

chrNumDefault=22
outPathDefault="./adsim"
numGenDefault=6
numSimDefault=20

while :
do
    case "$1" in
      --1000G) #1000 genomes vcf file to extract samples from. Required.
                vcfFile=True
                shift 1
                ;;
      --samples) #samples to generate admixture from. Required.
                samplesFile="$2"
                shift 2
                ;;
      --out | -o) #same as normal plink - Path to out files and the shared prefix
                outPath="$2"
                shift 2
                ;;
      --nsim | -n) #number of samples to simulate. default is 20.
                numSim="$2"
                shift 2
                ;;
      --chr | -c) #chrs you would like to subset to
                chrNum="$2"
                shift 2
                ;;
      --generations | --gen | -g) #number of generations to simulate default is 6
                numGen="$2"
                shift 2
                ;;
      --map | -m | --genetic-map) #genetic map file - format is rsid pos centimorgan-pos. REQUIRED.
                geneticMap="$2"
                shift 2
                ;;
      --help | -h) 
                echo "--1000G : vcf file to extract samples from. Typically 1000 genome file. REQUIRED."
                echo "--chr or -c : chr you would like to subset to. only supports one chr or all. Input number for chr or ALL for all. Default is 22."
                echo "--generations or --gen or -g : number of generations to simulate. Default is 6."
                echo "--out or -o : Use is as in plink - Path to out files and the shared prefix. Default is wWORKING_DIR/adsim"
                echo "--map or -m or --genetic-map : genetic map file - format is rsid pos centimorgan-pos. REQUIRED."
                echo "--nsim or -n : Number of samples to simulate. Default is 20.
                echo "--samples : samples to generate simulations from. A small subset will be used to simulate, while the rest will become refernces. REQUIRED."
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
  echo "VCF not set or DNE. Please input a valid VCF."
  echo "./simulate.sh --help or ./simulate.sh -h for option help"
  echo "Exiting"
  exit 1
fi
if [ -z "${samplesFile}" ] || [ ! -e "${samplesFile}" ]
then
  echo "Samples file not set or DNE. Please input a valid VCF."
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
echo "Subsetting input vcf to samples"
if [ "${chrNum:=chrNumDefault}" = "ALL" ]
then
  vcftools --vcf "${vcfFile}" --out "${outPath:=outPathDefault}"_sample_filtered --keep "${samplesFile}" --recode
else
  vcftools --vcf "${vcfFile}" --out "${outPath:=outPathDefault}"_sample_filtered --keep "${samplesFile}" --recode --chr "${chrNum}"
fi

echo "Extracting snps"
sed '/#/d' "${outPath}"_sample_filtered.recode.vcf | awk '{print $3}' > "${outPath}"_sample_filtered.snp.list
echo "Finding intersection with genetic map"
Rscript scripts/01bIntersect_map_snp_list.R --snps "${outPath}"_sample_filtered.snp.list --map "${geneticMap}" --out "${outPath}"
echo "Creating new vcf from subset"
vcftools --vcf "${outPath}"_sample_filtered.recode.vcf --recode --snps "${outPath}"_snp_list_intersection.txt --out  "${outPath}"_sample_filtered.intersection

echo "Beginning simulation"
if [ "${chrNum:=chrNumDefault}" = "ALL" ]
then
  python do-admixture-simulation.py \
  --input-vcf 1000G_80_20.recode.vcf \
  --sample-map ${samples} \
  --n-output "${numSim:=numSimDefault}" \
  --n-generations ${numGen:=numGenDefault}" \
  --genetic-map "${outPath}"_genetic_map_intersection.txt \
  --output-basename "${outPath}"
else
  python do-admixture-simulation.py \
  --input-vcf "${outPath}"_sample_filtered.intersection \
  --sample-map "${samples} \
  --n-output "${numSim:=numSimDefault}" \
  --n-generations ${numGen:=numGenDefault}" \
  --genetic-map "${outPath}"_genetic_map_intersection.txt \
  --chromosome "${chrNum}"
  --output-basename "${outPath}"
then

echo "Finished simulating. Please find outputs with the prefix ${outPath}*"
echo "Have a nice day :)"