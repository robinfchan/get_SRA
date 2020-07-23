# get_SRA

## A helpful little script to prefetch SRA data and convert over to FASTQ

Downloads SRA data and converts to FASTQ files. Pulls accession numbers 
from SraRunTable.txt metadata or SRR_Acc_List.txt tables from SRA Run
Selector.

**NOTE: assumes SRA Toolkit is installed and assigned to $PATH**: 
https://github.com/ncbi/sra-tools/wiki/02.-Installing-SRA-Toolkit
 
Also need to run *vdb-config -i* to set local repository directory
otherwise SRA Toolkit will write to the root drive (probably should set
to your own EBS volume since you can scale up storage if needed)

A good explainer for fastq-dump settings can be found here:
https://edwards.sdsu.edu/research/fastq-dump/


## Usage

get_SRA.sh -pvd -l /path/to/SraRunTable.txt -o /path/to/fastq/output/dir

	-h		display help and exit
	-l		SraRunTable.txt or SRR_Acc_List.txt from SRA Run Selector
			or any other CSV with NCBI accession numbers to download
			in the first column
	-o		output directory to write fastq dumps
	-p		prefetch SRA files; run "vdb-config -i" to set where they write
	-v		validate prefetched SRA data
	-d		fastq dump reads (prefetching is optional)
