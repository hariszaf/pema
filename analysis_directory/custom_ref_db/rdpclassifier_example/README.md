These two are example files for the case you need to train the RDPClassifier with your own reference database. 

In this case, we had a list of species known to be present at Amvrakikos gulf, Greece. 

We extracted all the relative sequences from Midori2 database to build the `taxonomy_file` and the `sequences_file` in the right format.


**You need to provide PEMA** with two such files having the **exact format** as the ones here. 

In any other case, PEMA will not be able to train the classiier with your reference database and it will return an error. 


You may find more about how to build these files and train the RDPClassifier over 
[here](https://hariszaf.github.io/pema_documentation/training_rdpclassifier/).
