#!/bin/bash


directory=${1}
directoryPath=$(pwd)
cd $directory

# decompress the initial raw data that the sequencer returned
for file in ./*
do
	gunzip "$file"
done


# convert them in the ENA format
for sample in ./*
do

	sampleName=${sample#*/}
	sampleId=${sampleName%%_*}
	 

	if [ ${sample: -7}=="1.fastq" ]
	then
		
		sed "s/^@M0.*/@$sampleId\./g" $sampleName > "half_${sampleId}_1.fastq"	
		awk 'BEGIN{b = 1; c = 1} {if (NR % 4 == 1) {print $0 b++ " "c++"/1"} else print $0}' half_"${sampleId}"\_1.fastq  > $directoryPath/ena_"${sampleId}"\_1.fastq 
		
	fi
	
	if [ ${sample: -7}=="2.fastq" ]
	then
		
		sed "s/^@M0.*/@$sampleId\./g" $sampleName > "half_${sampleId}_2.fastq"
		awk 'BEGIN{b = 1; c = 1} {if (NR % 4 == 1) {print $0 b++ " "c++"/2"} else print $0}' half_"${sampleId}"\_2.fastq  > $directoryPath/ena_"${sampleId}"\_2.fastq
		
	fi
done



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
