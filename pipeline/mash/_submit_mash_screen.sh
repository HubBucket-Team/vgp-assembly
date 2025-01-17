#!/bin/bash

if [ -z $1 ]; then
	echo "Usage: ./_submit_mash_screen.sh <genome>"
	echo "Requires: input.fofn"
	exit -1
fi

if [ ! -e input.fofn ]; then
	echo "Requires: input.fofn"
	exit -1
fi

LEN=`wc -l input.fofn | awk '{print $1}'`

genome=$1

mkdir -p logs

partition=quick
cpus=16
mem=24g
name=$genome.screen
script=$VGP_PIPELINE/mash/screen.sh
args=""
walltime=240
path=`pwd`
log=logs/$name.%A_%a.log

echo "\
sbatch -J $name -a 1-$LEN --partition=$partition --cpus-per-task=$cpus -D $path --mem=$mem --time=$walltime --error=$log --output=$log $script $args"
sbatch -J $name -a 1-$LEN --partition=$partition --cpus-per-task=$cpus -D $path --mem=$mem --time=$walltime --error=$log --output=$log $script $args > screen_jid

