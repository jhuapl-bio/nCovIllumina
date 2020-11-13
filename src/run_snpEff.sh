#!/bin/bash

#Run directory
RUN=$1

#Get the code directory
BINDIR=$2

DIR="${RUN}/results"   

OUTDIR=$DIR

CONFIG="${BINDIR}/reference/snpEff.config"
DBNAME="ncov"

SCRIPT_DIR="${BINDIR}/src"
for vcf in $DIR/*.allcallers_combined.vcf; do
    ${SCRIPT_DIR}/annotate_variants.sh ${vcf} ${CONFIG} ${DBNAME} ${OUTDIR}
    echo "SnpEff completed on run ${DIR}"
done

echo "Making final reports on run ${DIR}"
cat ${OUTDIR}/*_ann_report.txt  | awk '$4 != "N" { print $0}'  | awk '!seen[$0]++' > ${OUTDIR}/final_snpEff_report.txt
cat ${OUTDIR}/*_ann_report.txt  | awk '!seen[$0]++' | awk 'NR == 1  || $4 == "N" { print $0}'  > ${OUTDIR}/snpEff_report_with_Ns.txt
echo "DONE"