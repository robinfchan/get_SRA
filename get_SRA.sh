#!/bin/bash

# Downloads SRA data and converts to FASTQ files. Pulls accession numbers 
# from SraRunTable.txt metadata or SRR_Acc_List.txt tables from SRA Run
# Selector.
#
# NOTE: assumes SRA Toolkit is installed and assigned to $PATH
# https://github.com/ncbi/sra-tools/wiki/02.-Installing-SRA-Toolkit
# 
# Also need to run vdb-config -i to set local repository directory
# otherwise SRA Toolkit will write to the root drive (probably should set
# to your own EBS volume since you can scale up storage if needed)
#
# A good explainer for fastq-dump settings can be found here:
# https://edwards.sdsu.edu/research/fastq-dump/

show_help() {
cat << EOF
Usage: ${0##*/} [-pvd] [-l INPUT_LIST] [-o OUTPUT_DIR]
	-h		display help and exit
	-l		SraRunTable.txt or SRR_Acc_List.txt from SRA Run Selector
			or any other CSV with NCBI accession numbers to download
			in the first column
	-o		output directory to write fastq dumps
	-p		prefetch SRA files; run "vdb-config -i" to set where they write
	-v		validate prefetched SRA data
	-d		fastq dump reads (prefetching is optional)
EOF
}

list="" ; dest=""; validate=0; prefetch=0; dump=0

# Parse options
OPTIND=1
while getopts hl:o:pvd opt; do
  case "$opt" in
	h) show_help; exit 0 ;;
    l) list=$OPTARG ;;
    o) dest=$OPTARG ;;
	p) prefetch=1 ;;
    v) validate=1 ;;
	d) dump=1 ;;
    *) echo "Invalid Option Specified!" >&2; exit 1 ;;
  esac
done
shift "$(($OPTIND-1))"

if [ -z $list ]; then
	echo "Must supply -l argument!" >&2; exit 1
fi

if [ -z $dest ] && [ $dump -gt 0 ]; then
	echo "Must supply -o argument!" >&2; exit 1
fi

# Logging
exec 3>&1 4>&2
exec 1>get_SRA.log 2>&1

# Pull accession numbers from table
sra_list=$(awk -F "\"*,\"*" '{print $1}' $list)

# Prefetch
if [ $prefetch -gt 0 ]; then
	for record in $sra_list;
	do
		if [ "$record" = "Run" ]; then
			echo "Skipping header..."
		else
			echo "\nPrefetching $record"
			prefetch --max-size 100000000 --progress 2 $record
		fi
	done
else
	echo "Skipping SRA file prefetching..."
fi

# Validation
if [ $validate -gt 0 ]; then
	for record in $sra_list; do
		if [ "$record" = "Run" ]; then
			echo "Skipping header..."
		else
			echo "...\nChecking integrity of $record"
			vdb-validate $record
		fi
	done
else
	echo "Skipping SRA file validation..."
fi

# Fastq dump
if [ $dump -gt 0 ]; then
	for record in $sra_list; do
		if [ "$record" = "Run" ]; then
			echo ""
		else
			if [ -n "$(find ${dest} -maxdepth 1 -name "${record}*" -print -quit)" ]; then
				echo "FASTQ file(s) for $record already exists, skipping..."
			else
				echo "...\nConverting $record to FASTQ"
				fastq-dump \
				--outdir $dest \
				--gzip \
				--skip-technical  \
				--readids \
				--read-filter pass \
				--dumpbase \
				--split-3 \
				--clip $record \
				$record
			fi
		fi
	done
else
	echo "Skipping FASTQ dump..."
fi

exit 0
