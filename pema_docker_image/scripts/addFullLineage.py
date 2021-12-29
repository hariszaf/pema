#!/usr/bin/python

'''
Aim:    This script is required when user asks for a custom db to be used
        along with the RDPClassifier. For more about this task, you may check
        here: https://hariszaf.github.io/pema_documentation/training_rdpclassifier/

Usage:  The script is invoked by the trainForRDPClassifier.sh 
        script of PEMA (see at /scripts).

Author: This script has not been developed by the PEMA team.
        You may find the original at: https://github.com/GLBRC-TeamMicrobiome/python_scripts
'''

import sys, string
if len(sys.argv) != 3:
	print 'addFullLineage.py taxonomyFile fastaFile'
	sys.exit()
f1 = open(sys.argv[1], 'r').readlines()
hash = {} #lineage map
for line in f1[1:]:
	line = line.strip()

	#convert to unicode to avoid trouble from non-unicode source file
	line = unicode(line, "UTF-8")#strip non-unicode non-breaking space
	line = line.strip(u"\u00A0")
	cols = line.strip().split('\t')
	lineage = ['Root']
	for node in cols[1:]:
		node = node.strip()
		if not (node == '-' or node == ''):
			lineage.append(node)
	ID = cols[0]

	lineage = string.join(lineage, ';').strip()
	hash[ID] = lineage


f2 = open(sys.argv[2], 'r').readlines()
for line in f2:
	line = line.strip()
	if line == '':
		continue

	#convert to unicode to avoid trouble from non-unicode source file
	line = unicode(line, "UTF-8")#strip non-unicode non-breaking space
	line = line.strip(u"\u00A0")
	if line[0] == '>':
		ID = line.strip().split()[0].replace('>', '')

		try:
			lineage = hash[ID]
		except KeyError:
			print ID, 'not in taxonomy file'
			sys.exit()
		print '>' + ID + '\t' + lineage
	else:
			print line.strip()

