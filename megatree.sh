#PBS -S /bin/bash
#PBS -N megatree
#PBS -q batch
#PBS -l nodes=1:ppn=8:AMD
#PBS -l mem=40gb
#PBS -l walltime=48:00:00

cd /scratch/lfa81121/nbarcid/

module load MEGA/7.0.26-1

megacc -a /home/lfa81121/hmmer/MLLaminotree8.mao -d atcucspecnbs_msa.fa -o /scratch/lfa81121/nbarcid/mega/
