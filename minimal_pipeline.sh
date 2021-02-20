#!/bin/bash

### Pipeline for processing Illumina reads ###

## Set up parameters

# Get run directory
if [ "$(uname -s)" = 'Linux' ]; then
    BINDIR=$(dirname "$(readlink -f "$0" || echo "$(echo "$0" | sed -e 's,\\,/,g')")")
else
    BINDIR=$(dirname "$(readlink "$0" || echo "$(echo "$0" | sed -e 's,\\,/,g')")")
fi

#------------------------------------------------------------------------------

usage()
{
cat << EOF
usage: $0 [options]

OPTIONS:
   -h      show this message
   -i      path to input folder containing FASTQs
   -o      path to folder where output 'results' folder will be placed
   -c      path to config file for this run

EOF
}

#------------------------------------------------------------------------------
# set default values here
CONFIG=/opt/nCovIllumina/config/illumina.txt

# parse input arguments
while getopts "hi:o:c:" OPTION
do
	case $OPTION in
		h) usage; exit 1 ;;
		i) INPUTDIR=$OPTARG ;;
		o) OUTPUTDIR=$OPTARG ;;
		c) CONFIG=$OPTARG ;;
		?) usage; exit ;;
	esac
done

# if necessary arguments are not present, display usage info and exit
if [[ ! -s "$BINDIR/bashrc" ]]; then
	echo "Error: BINDIR ($BINDIR) does not contain the expected bashrc file."
	usage
	exit 2
fi

# if necessary arguments are not present, display usage info and exit
if [[ -z "$OUTPUTDIR" ]]; then
	OUTPUTDIR="$INPUTDIR"
fi

#------------------------------------------------------------------------------

# Load parameters from config
source "$BINDIR/bashrc"

# Set up script parameters based on config setup
REFERENCE=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/*.reference.fasta
GENES=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/genes.gff3

# postfiltering parameters
GLOBALDIVERSITY=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/approx_global_diversity.tsv # observed global variants
KEYPOS=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/key_positions.txt # clade-definiting positions
CASEDEFS=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/variant_case_definitions.csv # types of variant annotations
AMPLICONS=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/amplicons.tsv # amplicons file
HOMOPOLYMERS=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/homopolymer_positions.txt # homopolymer positions

REF_GB=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/reference_seq.gb
PANGOLIN_DATA=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/pangoLEARN/pangoLEARN/data
NEXTSTRAIN_CLADES=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/clades.tsv
SNPEFF_CONFIG=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/snpEff/snpEff.config
META_CONF=$GENOMEDIR/$PATHOGENREF/$PRIMERVERSION/nextstrain/nextstrain_metadata_fields.yaml

# Setting RUN_NAME to basename of the OUTPUTDIR
RUN_NAME=$( basename ${OUTPUTDIR} )

mkdir -p "$OUTPUTDIR" && cd "$OUTPUTDIR"
source "$CONFIG"

#-------------------------------------------------------------------------------

# Calculate read counts from raw fastq files

echo sample,read_count > $OUTPUTDIR/summary.raw.csv

for i in $INPUTDIR/*;do
sample=$(basename $i)
read_count=$(awk -v var1=$(wc -l < $i) -v var2=4 'BEGIN { print  ( var1 / var2 ) }' )
echo $sample,$read_count>> $OUTPUTDIR/summary.raw.csv
done

#------------------------------------------------------------------------------

## Filter reads by length - need to test if ncov_
conda activate ncov_illumina

FILTEREDINPUTDIR=$OUTPUTDIR'/filteredreads'
if [[! -d "$FILTEREDINPUTDIR" ]]; then  
  $BINDIR/src/filterreads.sh $INPUTDIR $FILTEREDINPUTDIR $BINDIR $MIN_READ_LENGTH $MAX_READ_LENGTH  
else  
  echo READ FILTERING SKIPPED
fi

echo "---------------------------------"
echo "READ FILTERING COMPLETE"
echo "---------------------------------"

#------------------------------------------------------------------------------

## Run iVar pipeline
if [[ ! -d "$OUTPUTDIR/results" ]]; then
  mkdir "$OUTPUTDIR/results"
  cp "$CONFIG" "$OUTPUTDIR/results"
  echo 'Getting ivar config'
  javac $BINDIR/src/ParseIvarConfig.java
  extraargs=$(java -cp $BINDIR/src ParseIvarConfig $CONFIG)
  echo $extraargs
  echo 'Running ivar'
  $BINDIR/src/ivar.sh $FILTEREDINPUTDIR $extraargs
fi

echo "---------------------------------"
echo "IVAR PIPELINE COMPLETE"
echo "---------------------------------"

#------------------------------------------------------------------------------