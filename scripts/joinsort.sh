#!/usr/bin/env bash
##
##     @script.name [option] ARGUMENTS...
##
## Options:
##     -h, --help              All client scripts have this, it can be omitted.
##     --var=VALUE        index for variant column chr:pos:ref:alt. This or next four must be specified
##     --chr=VALUE        Columnn indexes
##     --pos=VALUE
##     --ref=VALUE
##     --alt=VALUE

export LCTYPE=C
export LANG=C
source "scripts/easyoptions.sh" || exit

inputfile=$1
liftedfile=$2

cols=$(zcat < "$inputfile" | head -n 1 | awk 'BEGIN{FS="\t"}{ print NF}')

if [[ ! -n "$var"  ]]
then
    if [[ ! -n "$chr"  ]] || [[ ! -n "$pos"  ]] || [[ ! -n "$ref"  ]]  || [[ ! -n "$alt"  ]]
    then
        echo "chr pos ref alt columns must be specified if var not given"
        exit 1
    fi
    cols=$((cols+1))
    echo "cols"$cols
    join -1 1 -2 3 -t$'\t' <(  zcat < "$inputfile" | awk -v chr=$chr -v pos=$pos -v ref=$ref -v alt=$alt ' BEGIN{OFS="\t"} NR==1{ print "#variant",$0 } NR>1{ print $chr":"$pos":"$ref":"$alt,$0 }' | sort -b -k 1,1 -t $'\t'  ) <( awk 'BEGIN{ OFS="\t"; print "achr38","apos38","#variant" }{ print $1,$2+1,$4}'  $liftedfile | sort -t$'\t' -b -k 3,3 ) > ekafile
    join -1 1 -2 3 -t$'\t' <(  zcat < "$inputfile" | awk -v chr=$chr -v pos=$pos -v ref=$ref -v alt=$alt ' BEGIN{OFS="\t"} NR==1{ print "#variant",$0 } NR>1{ print $chr":"$pos":"$ref":"$alt,$0 }' | sort -b -k 1,1 -t $'\t'  ) <( awk 'BEGIN{ OFS="\t"; print "achr38","apos38","#variant" }{ print $1,$2+1,$4}'  $liftedfile | sort -t$'\t' -b -k 3,3 ) \
| sort -t$'\t' -V -k $((cols+1)),$((cols+1))  -k $((cols+2)),$((cols+2)) | awk  'BEGIN{ FS="\t"; OFS="\t"} NR==1{ print $0,"REF","ALT"} NR>1{ split($1,a,":"); print $0,a[3],a[4] } '|  bgzip > $(basename $inputfile)".lifted.gz"
else
    join -1 1 -2 3 -t$'\t' <(  zcat < "$inputfile" | awk -v var=$var 'NR==1{ printf "#variant"; for(i=1;i<=NF; i++) if(i!=var) printf "\t"$i; printf "\n"; } NR>1{ printf $var; for(i=1;i<=NF; i++) if(i!=var) printf "\t"$i; printf "\n"; }' | sort -b -k 1,1 -t $'\t'  ) \
<( awk 'BEGIN{ OFS="\t"; print "achr38","apos38","#variant" }{ print $1,$2+1,$4}'  $liftedfile | sort -t$'\t' -b -k 3,3 ) \
| sort -t$'\t' -V -k $((cols+1)),$((cols+1))  -k $((cols+2)),$((cols+2)) | awk  'BEGIN{ FS="\t"; OFS="\t"} NR==1{ print $0,"REF","ALT"} NR>1{ split($1,a,":"); print $0,a[3],a[4] } '|  bgzip > $(basename $inputfile)".lifted.gz"
fi

tabix -s $((cols+1)) -b $((cols+2)) -e $((cols+2)) $(basename $inputfile)".lifted.gz"
