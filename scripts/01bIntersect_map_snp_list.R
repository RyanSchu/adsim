##take the intersection of a genetic map and a vcf
##output the list of snps as well as a truncated genetic map

suppressWarnings(suppressMessages(library(dplyr)))
suppressWarnings(suppressMessages(library(data.table)))
suppressWarnings(suppressMessages(library(argparse)))

parser <- ArgumentParser()
parser$add_argument("--snps", help="snp list from vcf file")
parser$add_argument("--map", help="genetic map file")
parser$add_argument("--out", help="As in plink - out path and output prefix")
args <- parser$parse_args()

"%&%" = function(a,b) paste(a,b,sep="")

map<-fread(args$map, header = F)
snps<-fread(args$snps, header = F)
intersection<-inner_join(map,snps,by="V1")

fwrite(intersect, args$out %&% "_genetic_map_intersection.txt", col.names = F, row.names = F,quote = F,sep=' ')
fwrite(intersect$V1, args$out %&% "_snp_list_intersection.txt", col.names = F, row.names = F,quote = F,sep=' ')