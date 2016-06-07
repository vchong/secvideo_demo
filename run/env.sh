#!/bin/bash

export PATH=/home/victor.chong/work/FVP_Base_AEMv8A-AEMv8A/models/Linux64_GCC-4.1
export ARMLMD_LICENSE_FILE="8224@127.0.0.1"
echo $ARMLMD_LICENSE_FILE

#if no work, run directly fr cmd prompt, in foregnd
#ssh -L 8224:localhost:8224 -L 18224:localhost:18224 -N victor.chong@flexlm.linaro.org &
