#PBS -S /bin/bash
#PBS -N nbarcid
#PBS -q batch
#PBS -l nodes=1:ppn=2:AMD
#PBS -l mem=40gb
#PBS -l walltime=48:00:00

#Set paths to inputs
#GITDIR is the directory of the github repo, this allows the script to point at other scripts
GITDIR=/home/lfa81121/hmmer/
#input peptides should be a file with each set of genomic peptide predictions to be searched listed one per line.
INPUTPEPTIDES=$GITDIR/inputpeps
#Set output directory
DIR=/scratch/lfa81121/nbarcid
#HMM of general motif
MOTIF=/scratch/lfa81121/hmmer/NB-ARC.hmm
#Name of motif, used for file naming purposes
MOT=NB-ARC
#This is the folder all the genomic peptide predictions are in
PEPDIR=/work/cemlab/reference_genomes

#Change working directory to output directory
cd $DIR

#Read inputpeps and run motif search pipeline for each entry
while read -r GENOME
  do
    #Grabs the peptide predictions for the current genome
    PEPSEQ=$PEPDIR/$GENOME
    #shortened name of peptide predictions, for file naming
    PEP=${GENOME:0:5}

    module load HMMER/3.2.1-foss-2018b

    #Uses the generic HMM file to search your protien sequences for matches
    hmmsearch -E .001 --tblout $DIR/"$PEP"_gennbs.tbl  $MOTIF $PEPSEQ

    #Makes a table file from the input sequence, with one line per sequence conaining both seqid and sequence
    #Note fasta2tbl is a script within the github reop
    $GITDIR/fasta2tbl $PEPSEQ > $DIR/"$PEP".seqtbl

    #Extract the peptide sequence names from hmmsearch output
    rm $DIR/"$PEP"_gennbs.seqtbl
    while read -r SEQID B
      do
        grep -wE $SEQID $DIR/"$PEP".seqtbl >> $DIR/"$PEP"_gennbs.seqtbl
      done < <(tail -n +4 $DIR/"$PEP"_gennbs.tbl | head -n -10)

    #Generate FASTA with peptide sequences for each hit
    #Note that tbl2fasta is a script in the github repo
    $GITDIR/tbl2fasta $DIR/"$PEP"_gennbs.seqtbl > $DIR/"$PEP"_gennbs.fa

    #Use muscle to make a multi sequence alignment from the fasta file
    module load MUSCLE/3.8.31-foss-2016b
    muscle -in $DIR/"$PEP"_gennbs.fa -out $DIR/"$PEP"_gennbs_msa.fa

    #Use FASTA file to generate species specific HMM file
    #Note we must re-load HMMER due to a version discrepency in software dependencies with MUSCLE
    module load HMMER/3.2.1-foss-2018b
    hmmbuild "$PEP"_"$MOT".hmm $DIR/"$PEP"_gennbs_msa.fa

    #Search protien sequences for more matches using species specific motif
    hmmsearch -E .001 --tblout $DIR/"$PEP"_specnbs.tbl  "$PEP"_"$MOT".hmm $PEPSEQ

    #Make a fasta file of the results for organism specific hits
        #Extract the peptide sequence names from hmmsearch output
        rm $DIR/"$PEP"_specnbs.seqtbl
        while read -r SEQID B
          do
            grep -wE $SEQID $DIR/"$PEP".seqtbl >> $DIR/"$PEP"_specnbs.seqtbl
          done < <(tail -n +4 $DIR/"$PEP"_specnbs.tbl | head -n -10)

        #Generate FASTA with peptide sequences for each hit
        #Note tbl2fasta is a script in the github repo
        tbl2fasta $DIR/"$PEP"_specnbs.seqtbl > $DIR/"$PEP"_specnbs.fa
  done < $INPUTPEPTIDES

#cat all species specific NBS and general NBS hits for each set of predicted peptides into a single file each for general nbs or species specific
cat $DIR/*specnbs.fa >combinedspecnbs.fa
cat $DIR/*gennbs.fa >combinedgennbs.fa

#Use muscle to generate multi seuqence alignment
module load MUSCLE/3.8.31-foss-2016b
muscle -in $DIR/combinedgennbs.fa -out $DIR/combinedgennbs_msa.fa
muscle -in $DIR/combinedspecnbs.fa -out $DIR/combinedspecnbs_msa.fa

#Use FASTA file to generate species specific HMM file
#Note we must re-load HMMER due to a version discrepency in software dependencies with MUSCLE
module load HMMER/3.2.1-foss-2018b
hmmbuild combinedgennbs_cuc.hmm $DIR/combinedgennbs_msa.fa
hmmbuild combinedspecnbs_cuc.hmm $DIR/combinedspecnbs_msa.fa

#use the above HMM files to search each set of peptides for hits with the two new motifs
while read -r GENOME
  do
    PEPSEQ=$PEPDIR/$GENOME
    PEP=${GENOME:0:5}
    #Search protien sequences for more matches using species specific motif
    hmmsearch -E .001 --tblout $DIR/"$PEP"_combinedgennbs.tbl  combinedgennbs_cuc.hmm $PEPSEQ

    #Make a fasta file of the results for organism specific hits
    #Extract the peptide sequence names from hmmsearch output
    rm $DIR/"$PEP"_combinedgennbs.seqtbl
    while read -r SEQID B
      do
        grep -wE $SEQID $DIR/"$PEP".seqtbl >> $DIR/"$PEP"_combinedgennbs.seqtbl
      done < <(tail -n +4 $DIR/"$PEP"_combinedgennbs.tbl | head -n -10)
    #Generate FASTA with peptide sequences for each hit
    #Note tbl2fasta is a script in the github repo
    tbl2fasta $DIR/"$PEP"_combinedgennbs.seqtbl > $DIR/"$PEP"_combinedgennbs.fa
  done < $INPUTPEPTIDES

while read -r GENOME
  do
    PEPSEQ=$PEPDIR/$GENOME
    PEP=${GENOME:0:5}
    #Search protien sequences for more matches using species specific motif
    hmmsearch -E .001 --tblout $DIR/"$PEP"_combinedspecnbs.tbl  combinedspecnbs_cuc.hmm $PEPSEQ

    #Make a fasta file of the results for organism specific hits
    #Extract the peptide sequence names from hmmsearch output
    rm $DIR/"$PEP"_combinedspecnbs.seqtbl
    while read -r SEQID B
      do
        grep -wE $SEQID $DIR/"$PEP".seqtbl >> $DIR/"$PEP"_combinedspecnbs.seqtbl
      done < <(tail -n +4 $DIR/"$PEP"_combinedspecnbs.tbl | head -n -10)
    #Generate FASTA with peptide sequences for each hit
    #Note tbl2fasta is a script in the github repo
    tbl2fasta $DIR/"$PEP"_combinedspecnbs.seqtbl > $DIR/"$PEP"_combinedspecnbs.fa
  done < $INPUTPEPTIDES
