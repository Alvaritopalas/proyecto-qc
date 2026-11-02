#!/bin/bash
# QC y preprocesamiento de lecturas Illumina paired-end (fastp)
# Uso (desde la raiz del repositorio, con qc_env activado):
#   bash run_qc.sh [ACCESO_SRR]
set -euo pipefail

SRR=${1:-SRR31155591}

# Verificar que el entorno conda esta activado
for tool in fastqc multiqc fastp seqkit; do
  command -v "$tool" > /dev/null || { echo "Falta '$tool'. Ejecuta: conda activate qc_env"; exit 1; }
done

echo "Iniciando QC y preprocesamiento para ${SRR}..."

mkdir -p data/raw data/trimmed results/fastqc_raw results/fastqc_trimmed results/multiqc logs

# 0. Si no existen las lecturas submuestreadas, descargarlas y submuestrear
if [ ! -s "data/raw/${SRR}_1_sub.fastq.gz" ] || [ ! -s "data/raw/${SRR}_2_sub.fastq.gz" ]; then
  echo "0. Lecturas submuestreadas no encontradas: descargando ${SRR} (300.000 pares, semilla 11)..."
  prefetch "${SRR}" -O data/raw > logs/prefetch.log 2>&1
  fasterq-dump --split-files --threads 4 "data/raw/${SRR}/${SRR}.sra" -O data/raw > logs/fasterq_dump.log 2>&1
  for read in 1 2; do
    seqkit sample -s 11 -n 300000 "data/raw/${SRR}_${read}.fastq" \
      -o "data/raw/${SRR}_${read}_sub.fastq.gz" > "logs/seqkit_sample_${read}.log" 2>&1
    rm -f "data/raw/${SRR}_${read}.fastq"
  done
fi

echo "1. Ejecutando FastQC crudo..."
for read in 1 2; do
  fastqc --outdir results/fastqc_raw/ "data/raw/${SRR}_${read}_sub.fastq.gz" > "logs/fastqc_raw_${read}.log" 2>&1
done
multiqc -f results/fastqc_raw/ -o results/multiqc/ -n raw > logs/multiqc_raw.log 2>&1

echo "2. Ejecutando fastp (trimming)..."
fastp -i "data/raw/${SRR}_1_sub.fastq.gz" -I "data/raw/${SRR}_2_sub.fastq.gz" \
  -o "data/trimmed/${SRR}_1_trim.fastq.gz" -O "data/trimmed/${SRR}_2_trim.fastq.gz" \
  --average_qual 30 --detect_adapter_for_pe --length_required 50 --n_base_limit 5 \
  --html results/fastp.html --json results/fastp.json > logs/fastp.log 2>&1

echo "3. Ejecutando FastQC post-recorte..."
for read in 1 2; do
  fastqc --outdir results/fastqc_trimmed/ "data/trimmed/${SRR}_${read}_trim.fastq.gz" > "logs/fastqc_trim_${read}.log" 2>&1
done
multiqc -f results/fastqc_trimmed/ -o results/multiqc/ -n trimmed > logs/multiqc_trim.log 2>&1

echo "4. Tabla de comparacion (antes / despues):"
seqkit stats -a -T \
  "data/raw/${SRR}_1_sub.fastq.gz" "data/raw/${SRR}_2_sub.fastq.gz" \
  "data/trimmed/${SRR}_1_trim.fastq.gz" "data/trimmed/${SRR}_2_trim.fastq.gz" \
  > results/stats_antes_despues.tsv 2> logs/seqkit_stats.log
seqkit stats -a \
  "data/raw/${SRR}_1_sub.fastq.gz" "data/raw/${SRR}_2_sub.fastq.gz" \
  "data/trimmed/${SRR}_1_trim.fastq.gz" "data/trimmed/${SRR}_2_trim.fastq.gz"

echo "Proceso completado. Reportes en results/multiqc/ (raw.html y trimmed.html)."
