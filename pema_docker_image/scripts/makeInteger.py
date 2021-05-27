#!/usr/bin/python3


input_file = open('allTab.tsv', 'r') 
output_file = open('allTab_temp.tsv', 'w')

counter = 0 
for line in input_file:

   if counter == 0:
      counter += 1

      output_file.write(line)
      continue

   else: 
      counter += 1
      line = line.split('\t')

      output_file.write(line[0])

      for line in line[1:]:
         line = int(line)
         output_file.write('\t%d' % line)

      output_file.write('\n')







