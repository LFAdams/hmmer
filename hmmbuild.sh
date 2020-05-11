#PBS -S /bin/bash
#PBS -N j_hmmer
#PBS -q batch
#PBS -l nodes=1:ppn=2:AMD
#PBS -l mem=40gb
#PBS -l walltime=480:00:00
DIR=/scratch/lfa81121/hmmer
GENOME=/work/cemlab/reference_genomes/97103_v2.fa
GN=97103_v2
MOTIF=/scratch/lfa81121/hmmer/NB-ARC.hmm
module load HMMER/3.1b2-foss-2016b
makehmmerdb $GENOME $DIR/97103_v2_hmmerdb
nhmmer -o $DIR/out --tblout $DIR/table $MOTIF $DIR/97103_v2_hmmerdb
