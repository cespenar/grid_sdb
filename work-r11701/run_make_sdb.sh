#!/bin/bash
#PBS -l walltime=24:00:00
#PBS -l select=1:ncpus=8:mem=16384MB
#PBS -l software=MESA
#PBS -o out.txt
#PBS -e err.txt
#PBS -m e
#PBS -M sample_email@sample_email.com

export OMP_NUM_THREADS=8
cd $PBS_O_WORKDIR

export MESASDK_ROOT=/home/jomesa/mesasdk
source $MESASDK_ROOT/bin/mesasdk_init.sh
export MESA_DIR=/home/jomesa/mesa-r11701

export MESA_OP_MONO_DATA_PATH=~/OP4STARS_1.3/mono
export MESA_OP_MONO_DATA_CACHE_FILENAME=~/OP4STARS_1.3/mono/op_mono_cache.bin

export GYRE_DIR=/home/jomesa/gyre-5.2

export TMPDIR=/lustre/scratch/jomesa/tmp

ruby -w make_sdb.rb > output.txt
