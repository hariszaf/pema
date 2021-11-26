#!/bin/bash

# Aim  : not so sure what was that about
# Usage: PROBABLY NOT NEEDED

merged_read=${1}

sample=${merged_read::-16}


sed  -i "s/ERR101/$sample/g" $merged_read 
