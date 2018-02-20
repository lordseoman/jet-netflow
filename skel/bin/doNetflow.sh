#!/bin/bash

do_extraction() {
    echo "Extracting nfv9_raw_${1}.tgz"
    tar -zxf archive/nfv9_raw_${1}.tgz
    echo "Shifting to incoming"
    for dir in {ExindaNewP,ExindaNewS,ExindaOldP,ExindaOldS}; do
        mv done/${dir}/*${1}* incoming/${dir}/
    done
    prepare $1
    echo "Cleaning up done/"
    rm done/*/*${1}*
}

prepare() {
    echo "Preparing ${1}"
    find incoming/ExindaNewP -name "nfcapd.${1}*" -exec sh -c 'export FNAME=`basename {}`; /usr/local/bin/nfdump -r $FNAME -M incoming/ExindaNewP:ExindaNewS -o"csv" -O tstart > /Usage/todo/$FNAME.csv' \;
    cp incoming/ExindaNewP/*.${1}*.csv /Usage/todo/
    for dir in {ExindaNewP,ExindaNewS,ExindaOldP,ExindaOldS}; do
        mv incoming/${dir}/*.${1}* done/${dir}/
    done
}
    
cron_prepare() {
    echo "Doing periodic prep."
    i=0
    FILES=$(ls incoming/ExindaNewP/nfcapd.20*)
    for fn in $FILES; do
        IFS=/ read -a fnarray <<< "$fn"
        FNAME=${fnarray[-1]}
        IFS=. read -a dtarray <<< "$FNAME"
        PART=${dtarray[-1]}
        cp incoming/ExindaNewP/*.${PART}.csv /Usage/todo/
        /usr/local/bin/nfdump -r ${FNAME} -M incoming/ExindaNewP:ExindaNewS -o"csv" -O tstart > /Usage/todo/${FNAME}.csv
        for dir in {ExindaNewP,ExindaNewS,ExindaOldP,ExindaOldS}; do
            mv incoming/${dir}/*${PART}* done/${dir}/
        done
        i=$((i+1))
    done
    mv /Usage/todo/*.csv /Usage/incoming_1/
    echo "  - done $i files."
}

# This is used on the secondary to shift files not prepared directly to done/ for archival.
do_shift() {
    echo "Shifting files to done/ for $1"
    for dir in {ExindaNewP,ExindaNewS,ExindaOldP,ExindaOldS}; do
        mv incoming/${dir}/*.${1}* done/${dir}/
    done
}

do_prepare() {
    NOWYMD=`date +"%Y%m%d"`
    NOWYM=`date +"%Y%m"`
    i=$1
    while [ "${NOWYM}$(printf "%02d" ${i})" -ne "${NOWYMD}" ]; do
        PART="${NOWYM}$(printf "%02d" ${i})"
        if [ -f "incoming/ExindaNewP/nfcapd.${PART}0000" ]; then
            prepare $PART
            archive $PART
        fi
        i=$((i+1))
    done
}

# Call with do_archive "YYYYMM" DAYSTART DAYEND
do_archive() {
    i=$2
    while (( $i <= $3 )); do
        PART="${1}$(printf "%02d" ${i})"
        archive $PART
        i=$((i+1))
    done
}

archive() {
    FILES=$(ls done/*/*${1}* | wc -l)
    if [ $FILES -eq 8064 -o "$2" = "force" ]; then
        if [ -f "archive/nfv9_raw_${1}.tgz" ]; then
            echo "Archive already exists: archive/nfv9_raw_${1}.tgz"
        else
            if [ $FILES -lt 8064 ]; then
                FNE="-incomplete"
            else
                FNE=""
            fi
            echo "Archiving done/*/*${1}*"
            tar -zcf archive/nfv9_raw_${1}${FNE}.tgz done/*/*${1}*
            rm done/*/*${1}*
        fi
    fi
}

do_forever() {
    NEXT=$(( 10#`date +"%j"` + 1 ))
    while ! [ -e /opt/Usage/hourly.bypass ]; do
        THIS=$(( 10#`date +"%j"` ))
        HOUR=`date +"%H"`
        if [ $THIS -eq $NEXT -a $HOUR -eq 2 ]; then
            echo "Doing daily archival."
            archive `date +"%Y%m%d" -d yesterday`
            cron_prepare
            NEXT=$(( 10#`date +"%j"` + 1 ))
        else
            cron_prepare
        fi
        START=$(( 10#`date +"%s"` % 300 ))
        WAITTIME=$(( 300 - $START + 20 ))
        echo "Sleeping for $WAITTIME seconds"
        sleep $WAITTIME
    done
}

DIR=`pwd`
cd /Netflow

case "$1" in
    prepare)
        do_prepare 1 
        ;;
    manual-prepare)
        prepare $2
        ;;
    archive)
        do_archive `date +"%Y%m"` 1 `date +"%d" -d yesterday`
        ;;
    manual-archive)
        archive $2 $3
        ;;
    run-archive)
        do_extraction $2
        ;;
    shift)
        do_shift `date +"%Y%m%d" -d yesterday`
        archive `date +"%Y%m%d" -d yesterday`
        ;;
    run-shift)
        do_shift $2
        archive $2
        ;;
    cron)
        cron_prepare
        ;;
    forever)
        do_forever
        ;;
    *)
        echo $"Usage: $0 {prepare|monthly}"
        exit 1
esac
    
cd ${DIR}

