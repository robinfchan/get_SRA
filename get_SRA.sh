#!/usr/bin/env bash

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

table=$1 # input file containing SRA accession numbers to download

exec 3>&1 4>&2
exec 1>get_SRA.log 2>&1

sra_list=$(awk -F "\"*,\"*" '{print $1}' $1)

for record in $sra_list
do
	if [ "$record" = "Run" ];
	then
		echo "Skipping header..."
	else
		echo "\nPrefetching $record"
		prefetch --max-size 100000000 --progress 2 $record
		echo "...\nPrefetch done, checking integrity of $record"
		vdb-validate $record
	fi
done

for record in $sra_list
do
	if [ "$record" = "Run" ];
	then
		echo ""
	else

		echo "...\nConverting $record to FASTQ"
		fastq-dump \
		--outdir fastq \
		--gzip \
		--skip-technical  \
		--readids \
		--read-filter pass \
		--dumpbase \
		--split-3 \
		--clip $record \
		$record
	fi
done
