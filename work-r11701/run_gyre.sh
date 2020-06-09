#!/bin/bash
#PBS -l walltime=12:00:00
#PBS -l select=1:ncpus=16:mem=16384MB
#PBS -l software=GYRE
#PBS -o out_gyre.txt
#PBS -e err_gyre.txt
#PBS -m e
#PBS -M sample_email@sample_email.com

export OMP_NUM_THREADS=16
cd $PBS_O_WORKDIR

module load python/3.6.2-gcc6.2.0

export MESASDK_ROOT=/home/jomesa/mesasdk
source $MESASDK_ROOT/bin/mesasdk_init.sh
export MESA_DIR=/home/jomesa/mesa-r11701

export GYRE_DIR=/home/jomesa/gyre-5.2

export TMPDIR=/lustre/scratch/jomesa/tmp

python3 run_gyre.py -w . -i gyre.in -p "custom_He*.GYRE" > output_gyre.txt
