# QC y preprocesamiento de lecturas Illumina (SRR31155591)

Reproduce el preprocesamiento de *Pseudomonas aeruginosa* strain maqsudiensis (Rahaman et al., 2025, Microbiol Resour Announc 14(6):e01190-24, doi:10.1128/mra.01190-24). El paper recorta con Trimmomatic v0.39 (AVGQUAL 30); aqui se traduce a fastp.
Repositorio: https://github.com/Alvaritopalas/proyecto-qc

**Se usa un submuestreo de 300.000 pares** (seqkit sample, semilla 11), no los 637.121 originales.

## Que hace `run_qc.sh`
1. Descarga y submuestrea las lecturas si faltan en `data/raw/`.
2. FastQC + MultiQC sobre las lecturas crudas.
3. Recorte con fastp (`--average_qual 30 --detect_adapter_for_pe --length_required 50 --n_base_limit 5`).
4. FastQC + MultiQC sobre las lecturas recortadas.
5. Imprime la tabla antes/despues con `seqkit stats`.

## Como ejecutarlo (desde la raiz del repo, sin SLURM)
Copia y pega directamente en tu terminal de linux:
```bash
git clone https://github.com/Alvaritopalas/proyecto-qc.git && cd proyecto-qc
mamba env create -f environment.yml
conda activate qc_env
bash run_qc.sh            # o: bash run_qc.sh SRR31155591
```

## Que produce
- `results/multiqc/raw.html` y `trimmed.html`, `results/fastp.html` y `.json`, `results/stats_antes_despues.tsv`
- `logs/` con la salida de cada herramienta

Tiempo: aprox. 30 segundos (la descarga inicial agrega unos minutos si no hay lecturas en `data/raw/`).
