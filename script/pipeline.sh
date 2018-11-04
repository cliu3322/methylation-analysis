#!/bin/bash

## rau quality control
## fastqc -o raw_qc /mnt/Bioinfo_Student/Ting_Gong/Methylation_pipeline/SRR097849_2.fastq

## Trim: This short script is for trim galore
output="/output/"
input="/input/"
adapter2=AGATCGGAAGAGC
trim_galore -a ${adapter2}  -q 20 --stringency 5 --paired --length 20 -o ${output} ${input}L002_001.R1.test.fastq ${input}L002_001.R2.test.fastq

## Align
bismark --genome /mnt/Bioinfo_Student/Ting_Gong/hg19 -1 NA12878v2-Bstag_ACTGAGCG_H3Y7GALXX_L002_001.R2_val_2.fq -2 NA12878v2-Bstag_ACTGAGCG_H3Y7GALXX_L002_001.R1_val_1.fq -B NYGC_NA12878_A -p 7
## Use samtools to look at alignment rate
samtools flagstat NYGC_NA12878_A_pe.bam

## Filter: Score duplicate sets based on the sum of base qualities using MarkDuplicates (not working)
picard CollectAlignmentSummaryMetrics INPUT=NYGC_NA12878_A_pe.bam OUTPUT=NYGC_NA12878_A.bam_alignment_metrics.txt REFERENCE_SEQUENCE=/mnt/Bioinfo_Student/Ting_Gong/hg19/genome.fa
picard -Xmx32G MarkDuplicates INPUT=NYGC_NA12878_A_pe.bam OUTPUT=NYGC_NA12878_A_markduplicates.bam METRICS_FILE=NYGC_NA12878_A_markduplicates_metrics.txt OPTICAL_DUPLICATE_PIXEL_DISTANCE=2500 CREATE_INDEX=true

## Extract primary reads
samtools view -F 260 NYGC_NA12878_A_markduplicates.bam -h > NYGC_NA12878_A_samtools.sam

## Add downsampling
samtools view -s 0.05 -h NYGC_NA12878_A_samtools.sam > NYGC_NA12878_A_samtools_5.sam
samtools view -s 0.1 -h NYGC_NA12878_A_samtools.sam > NYGC_NA12878_A_samtools_10.sam
samtools view -s 0.2 -h NYGC_NA12878_A_samtools.sam > NYGC_NA12878_A_samtools_20.sam
samtools view -s 0.3 -h NYGC_NA12878_A_samtools.sam > NYGC_NA12878_A_samtools_30.sam

## Methylation extractor (Bismark)
bismark_methylation_extractor -p --bedGraph NYGC_NA12878_A_samtools_5.sam
bismark_methylation_extractor -p --bedGraph NYGC_NA12878_A_samtools_10.sam
bismark_methylation_extractor -p --bedGraph NYGC_NA12878_A_samtools_20.sam
bismark_methylation_extractor -p --bedGraph NYGC_NA12878_A_samtools_30.sam

## Methylation extractor (MethylDackel)
MethylDackel extract genome.fa NYGC_NA12878_A_1_pe.deduplicated_5.bam
MethylDackel extract genome.fa NYGC_NA12878_A_1_pe.deduplicated_10.bam
MethylDackel extract genome.fa NYGC_NA12878_A_1_pe.deduplicated_20.bam
MethylDackel extract genome.fa NYGC_NA12878_A_1_pe.deduplicated_30.bam

## Annotation
cat NYGC_NA12878_A_samtools_5.bedGraph | awk '{print $1 "\t" $2 "\t" $3}' > NYGC_NA12878_A_samtools_5.bed
annotatePeaks.pl NYGC_NA12878_A_samtools_5.bed hg19 -annStats AnnotationStats.txt > Annotation.tsv
cat NYGC_NA12878_A_samtools_10.bedGraph | awk '{print $1 "\t" $2 "\t" $3}' > NYGC_NA12878_A_samtools_10.bed
annotatePeaks.pl NYGC_NA12878_A_samtools_10.bed hg19 -annStats AnnotationStats.txt > Annotation_10.tsv
cat NYGC_NA12878_A_samtools_20.bedGraph | awk '{print $1 "\t" $2 "\t" $3}' > NYGC_NA12878_A_samtools_20.bed
annotatePeaks.pl NYGC_NA12878_A_samtools_20.bed hg19 -annStats AnnotationStats.txt > Annotation_20.tsv
cat NYGC_NA12878_A_samtools_30.bedGraph | awk '{print $1 "\t" $2 "\t" $3}' > NYGC_NA12878_A_samtools_30.bed
annotatePeaks.pl NYGC_NA12878_A_samtools_30.bed hg19 -annStats AnnotationStats.txt > Annotation_30.tsv
## annotatePeaks.pl CpG_context_NYGC_NA12878_A_samtools_5.txt hg19 > peaks.txt

## Bam to bed file
bamToBed -i NYGC_NA12878_A_1_pe.deduplicated_unsort_5.bam > NYGC_NA12878_A_1_pe.deduplicated_unsort_5.bed

cat NYGC_NA12878_A_1_pe.deduplicated_unsort_5.bedGraph | awk '{print $1 "\t" $2 "\t" $3}' > NYGC_NA12878_A_1_pe.deduplicated_unsort_5.bed
annotatePeaks.pl NYGC_NA12878_A_1_pe.deduplicated_unsort_5.bed hg19 -annStats AnnotationStats.txt > Annotation_5.tsv

bwameth.py index genome.fa
bwameth.py --reference genome.fa NA12878v2-Bstag_ACTGAGCG_H3Y7GALXX_L002_001.R1_val_1.fq NA12878v2-Bstag_ACTGAGCG_H3Y7GALXX_L002_001.R2_val_2.fq -t 12 | samtools view -b - > NYGC_NA12878_A_1_bwameth.bam
