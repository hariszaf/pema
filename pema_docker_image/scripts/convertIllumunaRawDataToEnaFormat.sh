#!/bin/bash

# This is a script that converts Illumina raw data file to the ENA format.
# All sample files that are going to be used in PEM., they need to be in the ENA format.
#
# This script will accomplish this task as long as your paired end raw data files have the following suffixes:
#
# forward read:   "_R1_001.fastq.gz"
# reverese reads: "_R2_001.fastq.gz"
#
# The rest of the name is irrelevant. 



# Keep the directory of the initial data in a variable
directory=${1}

# set the directoryPath the proper way no matter how the path was given by the user
if [ ${directory:1} == "/" ]
then
	directoryPath=$directory
else
	cd $directory
	directoryPath=$(pwd)
fi


if [ ${directoryPath: -1} == "/" ]
then
	directoryPath=${directoryPath::-1}
fi

cd $directoryPath

# decompress the initial raw data that the sequencer returned
for file in ./*
do
	gunzip "$file"
done

# convert them in the ENA format
let counter=-1
let giveName=0

for sample in ./*
do
    ((counter+=1))
    echo counter = $counter
	
    let test=$counter%2
    echo test = $test

    if [ "$test" -eq "0" ]
    then
        ((giveName+=1))
    fi

    echo giveName = $giveName

	sampleName=${sample##*/} 
	sampleId=${sampleName%%_*}
	newName=$(printf "ERR%07d" $giveName)
    
	sample="${sample:2}"
	
	if [[ $sample == *"_R1_001.fastq"* ]]
	then
		
		echo sample_1 is: $sample
		
		sed "s/^@M0.*/@$newName\./g ; s/^@ERR.*/@$newName\./g ; s/^@SRR.*/@$newName\./g" $sample > $directoryPath/"half_${sampleName}_R1_001.fastq"
		awk 'BEGIN{b = 1; c = 1} {if (NR % 4 == 1) {print $0 b++ " "c++"/1"} else print $0}' half_"${sampleName}"\_R1_001.fastq  > $directoryPath/ena_"${newName}"\_1.fastq 
	fi
	
	if [[ $sample == *"_R2_001.fastq"* ]]
	then

		echo sample_2 is: $sample

		sed "s/^@M0.*/@$newName\./g ; s/^@ERR.*/@$newName\./g ; s/^@SRR.*/@$newName\./g" $sample > $directoryPath/"half_${newName}_R2_001.fastq"
		awk 'BEGIN{b = 1; c = 1} {if (NR % 4 == 1) {print $0 b++ " "c++"/2"} else print $0}' half_"${newName}"\_R2_001.fastq  > $directoryPath/ena_"${newName}"\_2.fastq

	fi

	echo -e $sampleId"\t"$newName >> transformations.txt


done


cat transformations.txt | sort | uniq > transformations_sort.txt
rm transformations.txt ; mv transformations_sort.txt mapping_files_for_PEMA.tsv
sed -i '1s/^/initial_label_from_sequencer\t\ena_format_label\n\n/' mapping_files_for_PEMA.tsv


# remove some temp files created and move the converted files to a new folder
rm half_*
mkdir rawDataInEnaFormat
mv ena_* rawDataInEnaFormat
cd rawDataInEnaFormat

# give the initial samples names to the converted files and compress them
for filename in ./*; do mv "./$filename" "./$(echo "$filename" | sed -e 's/ena_//g')";  done
gzip *

# compress the initial files
cd $directoryPath
gzip *.fastq


# Move initial data files out of the mydata directory
mkdir initial_data
mv *.fastq.gz initial_data
mv initial_data ..
mv mapping_files_for_PEMA.tsv ..
mv rawDataInEnaFormat/* .
rm -r rawDataInEnaFormat/





