INPUTDIR=$1
FILTEREDINPUTDIR=$2
BINDIR=$3
MIN_READ_LENGTH=$4
MAX_READ_LENGTH=$5

mkdir -p $FILTEREDINPUTDIR
OUTPUTDIR=$(dirname $(dirname $FILTEREDINPUTDIR))

for i in `ls $INPUTDIR/*.fastq`; do
    #echo 'Copying and unzipping ' $i
    echo 'Copying ' $i
    filename=`basename $i`
    cp $i $FILTEREDINPUTDIR
    #gunzip $FILTEREDINPUTDIR/$filename
done
    
javac $BINDIR/src/FilterReads.java
allfiles=`ls $FILTEREDINPUTDIR/*.fastq`
echo 'Filtering reads by length'
java -cp $BINDIR/src FilterReads $MIN_READ_LENGTH $MAX_READ_LENGTH $allfiles
    
# check read count
echo 'sample,read_count' > $OUTPUTDIR/summary.length_filter.csv

for i in $allfiles; do
	
	sample=$(basename $i)
	read_count=$(awk -v var1=$(wc -l < $i) -v var2=4 'BEGIN { print  ( var1 / var2 ) }' )
	echo $sample,$read_count>> $OUTPUTDIR/summary.length_filter.csv
    echo 'Zipping filtered reads: '$i
    gzip $i
    
done