#PBS -S /bin/bash
#PBS -q batch
#PBS -N muscall
#PBS -l nodes=1:ppn=48:AMD
#PBS -l walltime=48:00:00
#PBS -l mem=16gb

cd /scratch/lfa81121/nbarcid
module load MUSCLE/3.8.31-foss-2016b


muscle -in atcucspecnbs.fa -out atcucspecnbs_msa.fa
