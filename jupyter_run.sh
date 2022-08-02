#!/bin/bash
#SBATCH --job-name=jupyter
#SBATCH --output=jupyter_run.log
#SBATCH --ntasks=1
#SBATCH --mem=32gb
#SBATCH --cpus-per-task=8
#SBATCH --partition=jupyter
#SBATCH --gres=gpu:1

echo "DATE:$(date)"
echo "HOST:$(hostname)"
echo "WORK_DIR:$(pwd)"

conda activate /mnt/work/python/dkottke/pytorch
srun jupyter lab --port=$1
