
# PEMA as Singularity image

Here are the ```Singularity``` files for building the corresponding Singularity containers of PEMA. 

## notes

The message "Extracting OCI image" indicates that Singularity is converting a Docker container into a Singularity image. 
OCI stands for Open Container Initiative, which is a set of industry standards for container runtimes and image formats.

The decision of where to set the export commands for the PATH variable depends on how you want your Singularity container to behave.

If you want the environment (including PATH) to be configured during the build process, affecting all subsequent runs of the container, then you should include it in the %post section. This ensures that the environment is set up during the container creation.

If you want to customize the environment dynamically each time you run the container (e.g., using different versions of Java or other tools), then you might prefer to include it in the %runscript section. This allows you to override or extend the environment when executing the container.

SIF stands for "Singularity Image Format." It is the file format used by Singularity to store container images. A Singularity image file has a .sif extension, and it contains the entire filesystem and metadata of a container. 


