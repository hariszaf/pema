Here is an example of an `analysis_directory`, the input for PEMA implementation.

The only **mandatory** directories and files are the `mydata` directory along with the `.fastq.gz` files included there 
and the `parameters.tsv` file.

Please, remove the README.md file that you will find on the `mydata` directory. Raw data files must be included there **only**.

Everything else on this directory is **optional**, depending on the parameters set you will choose.



You only need this directory, in case you need to use your own reference database.

If that is the case, **you need to keep the name of this directory exactly as it is**, i.e ```custom_ref_db```.


In case of 16/18S and ITS you need to train the CREST algorithm with your custom reference database. 
You may see the relative steps [here](https://hariszaf.github.io/pema_documentation/training_crest_classifier/).

Likewise, for the case of the COI marker gene, you need to train the RDPClassifier and you may see how 
[here](https://hariszaf.github.io/pema_documentation/training_rdpclassifier/).



These two are example files for the case you need to train the RDPClassifier with your own reference database. 

In this case, we had a list of species known to be present at Amvrakikos gulf, Greece. 

We extracted all the relative sequences from Midori2 database to build the `taxonomy_file` and the `sequences_file` in the right format.


**You need to provide PEMA** with two such files having the **exact format** as the ones here. 

In any other case, PEMA will not be able to train the classiier with your reference database and it will return an error. 


You may find more about how to build these files and train the RDPClassifier over 
[here](https://hariszaf.github.io/pema_documentation/training_rdpclassifier/).




