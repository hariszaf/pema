#!/usr/bin/env python

'''
Aim:    This script is required when user asks for a custom db to be used
        along with the CREST. 
        It converts a taxonomy in tab-delimited file containing the taxonomic hierarchical
        structure to RDP Classifier taxonomy training file
        For more about this task, you may check
        here: https://hariszaf.github.io/pema_documentation/training_crest_classifier/
        
        Approach: Each taxon is uniquely identified by the combination of its tax id and depth from 
                  the root rank, its attributes comprise: name, parent taxid, and level of depth from the root rank. 

Usage:  The script is invoked by the trainForCREST.sh 
        script of PEMA (see at /scripts).


Author: Benli Chai
'''

import sys, string
if not len(sys.argv) == 2:
	print "lineage2taxTrain.py taxonomyFile"
	sys.exit()

f = open(sys.argv[1], 'r').readlines()
header = f[0]
header = f[0].strip().split('\t')[1:]#header: list of ranks
hash = {}#taxon name-id map
ranks = {}#column number-rank map
lineages = []#list of unique lineages

hash = {"Root":0}#initiate root rank taxon id map
for i in range(len(header)):
	name = header[i]
	ranks[i] = name
root = ['0', 'Root', '-1', '0', 'rootrank']#root rank info
print string.join(root, '*')
ID = 0 #taxon id
for line in f[1:]:
	cols = line.strip().split('\t')[1:]
	for i in range(len(cols)):#iterate each column
		name = []
		for node in cols[:i + 1]:
			node = node.strip()
			if not node in ('-', ''):
				name.append(node)
		pName = string.join(name[:-1], ';')
		if not name in lineages:
			lineages.append(name)
		depth = len(name)
		name = string.join(name, ';')
		if name in hash.keys():#already seen this lineage
			continue
		try:
			rank = ranks[i]
		except KeyError:
			print cols
			sys.exit()
		if i == 0:
			pName = 'Root'
		pID = hash[pName]#parent taxid
		ID += 1
		hash[name] = ID #add name-id to the map
		out = ['%s'%ID, name.split(';')[-1], '%s'%pID, '%s'%depth, rank] 
		print string.join(out, '*')


# This script has not been developed by the PEMA team.
# You may find the original at: https://github.com/GLBRC-TeamMicrobiome/python_scripts 
