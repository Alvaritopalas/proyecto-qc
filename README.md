# QC y preprocesamiento de lecturas Illumina (SRR31155591)

Reproduce el preprocesamiento de las lecturas de *Pseudomonas aeruginosa* strain maqsudiensis
(Rahaman et al., 2025, Microbiol Resour Announc 14(6):e01190-24, doi:10.1128/mra.01190-24).
El paper recorta con Trimmomatic v0.39 (AVGQUAL 30); aqui se traduce a fastp.

**El analisis se hace sobre un submuestreo de 300.000 pares de lecturas** (seqkit sample, semilla 11),
no sobre los 637.121 pares originales.

## Que hace `run_qc.sh`
1. Si faltan las lecturas submuestreadas, las descarga del SRA y las submuestrea.
2. FastQC + MultiQC sobre las lecturas crudas.
3. Recorte con fastp (`--average_qual 30 --detect_adapter_for_pe --length_required 50 --n_base_limit 5`).
4. FastQC + MultiQC sobre las lecturas recortadas.
5. Imprime la tabla antes/despues con `seqkit stats`.

## Como ejecutarlo
```bash
mamba env create -f environment.yml
conda activate qc_env
bash run_qc.sh            # o: bash run_qc.sh SRR31155591
```
Ejecutar desde la raiz del repositorio, directamente en la terminal (sin SLURM).

## Que produce
- `results/multiqc/raw.html` y `results/multiqc/trimmed.html` (reportes MultiQC)
- `results/fastp.html` y `results/fastp.json`
- `results/stats_antes_despues.tsv` (tabla antes/despues)
- `logs/` con la salida de cada herramienta

Tiempo: aprox. 30 segundos (la descarga inicial agrega unos minutos si no hay lecturas en `data/raw/`).
