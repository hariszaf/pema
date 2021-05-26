#!/usr/bin/env Rscript

## SECTION 0 

## Please let Phyloseq know which Silva version you chose.
## ATTENTION! Really important variable to fill!
## Move to SECTION 3 in order to set your phyloseq analysis. Please DO NOT change anything in SECTION 1.
## In SECTION 2 there are some statistics that are the same for each and every  analysis.
## However, you are free to change anything you want to in SECTION 2 as well.

## In addition, take really good care of your metadata file. This needs to be called "metadata.csv"! 
## If it is not called like this, the phyloseq will fail. 

args<-commandArgs(TRUE)
markerGene = args[1]
silvaVersion = args[2]

#------------------------------------------------------------------------------------------------------------------

##  SECTION 1

# ATTENTION! Do NOT change the following lines!! 
# That is what needs to stay as it is for PEMA to execute this phyloseq script! 
# Move into the next section in order to set the analysis the way you want to! 

# setting the envrinoment where phyloseq is going to run

# set_working_dir = paste("/home1/haris/metabar_pipeline/PEMA/",analysis_name,"/phyloseq-output", sep="")
# setwd(set_working_dir)

# for the calculation of diversity indices, the bioenv and the permanova
library(vegan) 
# for the actual analysis
library(phyloseq) 
# to import the tree
library(ape) 
# for the beautiful plots
library(ggplot2) 
#to create the taxonomy table and play around with the tables
library(dplyr)
library(tidyr) 
#to create beautiful colour palettes for your plots
library(RColorBrewer)
# Define a default theme for ggplot graphics
theme_set(theme_bw()) 



#import the OTU table (or else biotic data)
biotic <- read.csv("finalTable.tsv", sep = "\t", header=TRUE, row.names = 1) 

#import the tree of the OTUs
testTree <- "OTUs_tree.tre"
pointer <- "no"
if (file.exists(testTree)) {
	tree <- read.tree("OTUs_tree.tre")
	pointer <- "yes"
}


#Create taxonomy table from the Classification column of the biotic data

if (markerGene == 'gene_16S' || markerGene == 'gene_18S') {
	if (silvaVersion == 'silva_132') {
	  # Silva 132
	  taxonomy <- select(biotic, Classification)
	  colnames <- c("Root", "Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")
	  taxonomy <- separate(taxonomy, Classification, colnames, sep = ";", remove = TRUE,
						   convert = FALSE, extra = "warn", fill = "warn")
	  getPalette = colorRampPalette(brewer.pal(8, "Set2"))
	  
	} else if (silvaVersion == 'silva_128') {
	  # Silva 128
	  taxonomy <- select(biotic, Classification)
	  colnames <- c("Root", "Domain", "Superkingdom", "Superphylum", "Phylum", "Class", "Order", "Family", "Genus", "Species")
	  taxonomy <- separate(taxonomy, Classification, colnames, sep = ";", remove = TRUE,
							   convert = FALSE, extra = "warn", fill = "warn")
	  getPalette = colorRampPalette(brewer.pal(10, "Set2"))
	}	
	
} else if (markerGene == 'gene_ITS') {
    # UNITE database
	taxonomy <- select(biotic, Classification)
	colnames <- c("Root", "Superkingdom", "Subgroup", "Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
	taxonomy <- separate(taxonomy, Classification, colnames, sep = ";", remove = TRUE,
						 convert = FALSE, extra = "warn", fill = "warn")
	getPalette = colorRampPalette(brewer.pal(10, "Set2"))
	
} else if (markerGene == 'gene_COI') {
	# MIDORI database
	taxonomy <- select(biotic, Classification)
	colnames <- c("Superkingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")
	taxonomy <- separate(taxonomy, Classification, colnames, sep = ";", remove = TRUE,
						 convert = FALSE, extra = "warn", fill = "warn")
	getPalette = colorRampPalette(brewer.pal(7, "Set2"))
}
	
#convert the taxonomy data from data frame to matrix
taxonomy_matrix <- as.matrix(taxonomy)
# get index of NA values in the taxonomy 
y <- which(is.na(taxonomy)==TRUE)   
# replace all NA values with "Unknown"
taxonomy_matrix[y] <- "Unknown"       

# prepare the object for the phyloseq object
TAX = tax_table(taxonomy_matrix)

#remove Classification column from biotic data
biotic <- select(biotic, -Classification)
#convert the biotic data from data frame to matrix
biotic_matrix <- as.matrix(biotic)

#import the metadata of the samples, if any
metadata <- read.csv("metadata.csv", header=TRUE, row.names = 1) 

# prepare the objects for the phyloseq object
OTU = otu_table(biotic_matrix, taxa_are_rows = TRUE)
META = sample_data(metadata)

if ( pointer == 'yes') {
	TREE = phy_tree(tree)
	# combine them all to create the phyloseq object
	physeq = phyloseq(OTU, TAX, META, TREE)
} else {
	physeq = phyloseq(OTU, TAX, META)
}	

print("this is where the nice part begins!")


#------------------------------------------------------------------------------------------------------------------

##  SECTION 2

# In this section you can change the code however you want to, in order to get the analysis needed.
# You can remove any part you want or you can add anything. 
# You are also free to make any changes you want to in the commands that have been included. 
# These commands are only an attempt as a "traditional" analysis in microbial community studies. 

#tranpose biotic data for the calculation of diversity indices
biotic_transposed <- t(biotic)
# Number of individuals
RelativeAbundance <- rowSums(biotic_transposed) 
# Number of OTUs
NumberOfOTUs <- rowSums(biotic_transposed > 0)  
# Shannon index
Shannon <- diversity(biotic_transposed, base=2) 
# Simpson's index
Simpson <- diversity(biotic_transposed, "simpson") 
# Pielou's index
Pielou <- Shannon/log(NumberOfOTUs) 
# Margalef's index
Margalef <- (NumberOfOTUs-1)/log(RelativeAbundance) 
#Chao1 and ACE indices
MoreIndices <- estimateR(biotic_transposed)
MoreIndices <- t(MoreIndices)
# join them together
div_indices <- data.frame(RelativeAbundance, NumberOfOTUs, Shannon, Simpson, Pielou, Margalef)
div_indices <- cbind.data.frame(div_indices, Chao1=as.factor(MoreIndices[,2]), ACE=as.factor(MoreIndices[,4]))
# save the results in an output file
write.csv(div_indices,"div_indices.csv",quote=F)


#------------------------------------------------------------------------------------------------------------------


##  SECTION 3


# create a bar plot, for the taxon rank you like, e.g Phylum 
# this bar chart is created with the default colour palette of phyloseq
barchart <- plot_bar(physeq, fill = "Phylum")
pdf("barchart.pdf", width = 12)
print(barchart)
dev.off()

# ATTENTION!
# in the below commands, we chose the "Habitat" variable from our metadata file as an example.
# in addition, we chose "Phylum" as an example.
# you need to set those parameters (metadata variables and taxon level) in order to address your data and your needs.

# create a bar plot for the 100 most abundant taxa, for the Phylum rank per e.g Habitat (info included in the metadata)
top100 <- names(sort(taxa_sums(physeq), decreasing=TRUE))[1:100]
physeq.top100 <- transform_sample_counts(physeq, function(OTU) OTU/sum(OTU))
physeq.top100 <- prune_taxa(top100, physeq.top100)
#here you can change the taxonomic rank and the grouping of samples
barchart100 <- plot_bar(physeq.top100, fill="Phylum") + facet_wrap(~Habitat, scales="free_x")
pdf("barchart100.pdf")
print(barchart100)
dev.off()

# create a bar plot for all the taxa, for the Phylum rank per e.g. Habitat and Location (info included in the metadata)
# this bar chart is created with the default colour palette of phyloseq
barchart_habitat <- plot_bar(physeq, "Location", fill="Phylum") + facet_wrap(~Habitat, scales="free_x")
pdf("barchart_habitat.pdf", width =12)
print(barchart_habitat)
dev.off()

#get the data frame from the phyloseq object
pd <- psmelt(physeq)


#now let's do the bar plot again, but with custom chosen colours
#Count how many Phyla are there in your samples
HowManyPhyla <- length(unique(unlist(pd[,c("Phylum")])))
#OR
HowManyPhyla <- length(levels(as.factor(pd$Phylum)))

# Build a colour palette with number of colours as many as 
# the Phyla in your samples by interpolating the palette "Set2".
# "Set2" is one of the colorblind friendly palettes
# Another example of a colorblind friendly palette is "Dark2"
# If you want, by running the command display.brewer.all(colorblindFriendly = TRUE)
# you can see all the colorblind friendly palettes of the RColorBrewer package.
## Now the "getPalette" variable, we set it in the if statement of the marker gene.
#getPalette = colorRampPalette(brewer.pal(9, "Set2"))

PhylaPalette = getPalette(HowManyPhyla)


#and do the actual plotting
barchart_palette <- ggplot(pd, aes(x = Location, y = Abundance, factor(Phylum), fill = factor(Phylum))) +
  geom_bar(stat = "identity") +
  facet_wrap(~Habitat, scales = "free_x") +
  scale_fill_manual(values = PhylaPalette) +
  labs(fill = "Phylum") +
  guides(fill=guide_legend(ncol=2))
pdf("barchart_palette.pdf", width = 12)
print(barchart_palette)
dev.off()





if ( pointer == 'yes') {

	# plot the OTU tree with colour coding by e.g. Habitat (info included in the metadata) 
	tree1 <- plot_tree(physeq, color="Habitat", label.tips="taxa_names", ladderize="left", justify = "left", size = "Abundance", plot.margin=0.3)
	pdf("tree1.pdf")
	print(tree1)
	dev.off()
	
	tree2 <- plot_tree(physeq, color="Habitat", label.tips="taxa_names", ladderize="left", plot.margin=0.3)
	pdf("tree2.pdf")
	print(tree2)
	dev.off()
	
	tree3 <- plot_tree(physeq, color="Habitat", ladderize="left", plot.margin=0.3)
	pdf("tree3.pdf")
	print(tree3)
	dev.off()
}



# create a heatmap, for the Phylum rank 
heatmap <- plot_heatmap(physeq, taxa.label="Phylum")
pdf("heatmap.pdf")
print(heatmap)
dev.off()

# plot the diversity indices with colour coding by e.g. Location (info included in the metadata) 
richness <- plot_richness(physeq, measures=c("Shannon", "Simpson", "Chao1"), color="Location")
pdf("richness.pdf", width = 12)
print(richness)
dev.off()

# create the nmds plot colour coded by e.g. Location (info included in the metadata) 
ord.nmds.bray <- ordinate(physeq, method="NMDS", distance="bray")
p1 <- plot_ordination(physeq, ord.nmds.bray, color="Location", title="Bray NMDS")
pdf("p1.pdf")
print(p1)
dev.off()

# Split the previous nmds plot per e.g. Habitat (info included in the metadata) 
p2 <- p1 + facet_wrap(~Habitat, 3)
pdf("p2.pdf")
print(p2)
dev.off()

# Create an nmds plot per Phylum
p3 <- plot_ordination(physeq, ord.nmds.bray, type="taxa", color="Phylum", title="Bray NMDS")
pdf("p3.pdf", width =12)
print(p3)
dev.off()

# Split an nmds plot per Phylum
p4 <- p3 + facet_wrap(~Phylum, 3)
pdf("p4.pdf", width = 20)
print(p4)
dev.off()

#Run PERMANOVA to check for significance based on the Habitat factor (info included in the metadata) 
OTU.adonis.Habitat <- adonis(biotic_transposed ~ metadata$Habitat, data=metadata, permutations = 999, distance = "bray")
OTU.adonis.Habitat

#Run PERMANOVA to check for significance based on the combination (+) of Location & Habitat factors
OTU.adonis <- adonis(biotic_transposed ~ metadata$Location+metadata$Habitat,data=metadata,permutations = 999,distance = "bray") 
#summary(OTU.adonis)
OTU.adonis

# Create a bar plot only for the Proteobacteria
physeq.proteobacteria = subset_taxa(physeq, Phylum=="Proteobacteria")
proteo1 <- plot_bar(physeq.proteobacteria, title = "Proteobacteria per sample")
proteo2 <- plot_bar(physeq.proteobacteria, "Class", "Abundance", "Habitat", title = "Proteobacteria per class, colour by Habitat")
proteo3 <- plot_bar(physeq.proteobacteria, "Habitat", title = "Proteobacteria per Habitat")
proteo4 <- plot_bar(physeq.proteobacteria, "Class", title = "Proteobacteria per class")
proteo5 <- plot_bar(physeq.proteobacteria, "Class", "Abundance", "Class", facet_grid="Habitat~.", title = "Proteobacteria per Class, per Habitat")
pdf("proteo1.pdf")
print(proteo1)
dev.off()

pdf("proteo2.pdf")
print(proteo2)
dev.off()

pdf("proteo3.pdf")
print(proteo3)
dev.off()

pdf("proteo4.pdf")
print(proteo4)
dev.off()

pdf("proteo5.pdf", width = 12)
print(proteo5)
dev.off()

#BIO-ENV
# select the columns of the metadata file that contain numeric data
metadata_without_factors <- select_if(metadata, is.numeric)
# run the bioenv test
bioenv <- bioenv(biotic_transposed, metadata_without_factors) 
# display the results
summary(bioenv)


## Thank you for your patience! :) 



















































###############################        PREVIOUS VERSION

###  SECTION 3
#
## create a bar plot, for the taxon rank you like, e.g Phylum 
## this bar chart is created with the default colour palette of phyloseq
#barchart <- plot_bar(physeq, fill = "Phylum")
## in case you think about using ggsave, keep in mind that it has to be exactly after the plot you want to save. 
##ggsave(filename = "barchart.png", scale = 1, dpi = 100, width = 6)
#pdf("barchart.pdf", width = 12)
#print(barchart)
#dev.off()
#
## ATTENTION!
## in the below commands, we chose the "Habitat" variable from our metadata file as an example.
## in addition, we chose "Phylum" as an example.
## you need to set those parameters (metadata variables and taxon level) in order to address your data and your needs.
#
## create a bar plot for the 100 most abundant taxa, for the Phylum rank per e.g Habitat (info included in the metadata)
#top100 <- names(sort(taxa_sums(physeq), decreasing=TRUE))[1:100]
#physeq.top100 <- transform_sample_counts(physeq, function(OTU) OTU/sum(OTU))
#physeq.top100 <- prune_taxa(top100, physeq.top100)
##here you can change the taxonomic rank and the grouping of samples
#barchart100 <- plot_bar(physeq.top100, fill="Phylum") + facet_wrap(~Habitat, scales="free_x")
##ggsave(filename = "barchart100.png", scale = 1, dpi = 300)
#pdf("barchart100.pdf")
#print(barchart100)
#dev.off()
#
## create a bar plot for all the taxa, for the Phylum rank per e.g. Habitat and Location (info included in the metadata)
## this bar chart is created with the default colour palette of phyloseq
#barchart_habitat <- plot_bar(physeq, "Location", fill="Phylum") + facet_wrap(~Habitat, scales="free_x")
##ggsave(filename = "barchart_habitat.png", scale = 1, dpi = 300, width = 12)
#pdf("barchart_habitat.pdf", width = 12)
#print(barchart_habitat)
#dev.off()
#
#
##get the data frame from the phyloseq object
#pd <- psmelt(physeq)
#
##now let's do the bar plot again, but with custom chosen colours
##Count how many Phyla are there in your samples
#HowManyPhyla <- length(unique(unlist(pd[,c("Phylum")])))
##OR
#HowManyPhyla <- length(levels(as.factor(pd$Phylum)))
#
#
## Build a colour palette with number of colours as many as 
## the Phyla in your samples by interpolating the palette "Set2".
## "Set2" is one of the colorblind friendly palettes
## Another example of a colorblind friendly palette is "Dark2"
## If you want, by running the command display.brewer.all(colorblindFriendly = TRUE)
## you can see all the colorblind friendly palettes of the RColorBrewer package.
#
#
### Now the "getPalette" variable, we set it in the if statement of the marker gene.
##getPalette = colorRampPalette(brewer.pal(9, "Set2"))
#PhylaPalette = getPalette(HowManyPhyla)
#
##and do the actual plotting
#barchart_palette <- ggplot(pd, aes(x = Location, y = Abundance, factor(Phylum), fill = factor(Phylum))) +
#  geom_bar(stat = "identity") +
#  facet_wrap(~Biome, scales = "free_x") +
#  scale_fill_manual(values = PhylaPalette) +
#  guides(fill=guide_legend(ncol=2))
##ggsave(filename = "barchart_palette.png", scale = 1, dpi = 300, width = 12)
#pdf("barchart_palette.pdf", width = 12)
#print(barchart_palette)
#dev.off()
#
## here are some plots only for the case that a tree exists.
#if ( pointer == 'yes') {
#	# plot the OTU tree with colour coding by e.g. Habitat (info included in the metadata)
#	tree1 <- plot_tree(physeq, color="Habitat", label.tips="taxa_names", ladderize="left", justify = "left", size = "Abundance", plot.margin=0.3)
#	#ggsave(filename = "tree1.png", scale = 1, dpi = 300)
#	pdf("tree1.pdf")
#	print(tree1)
#	dev.off()
#	
#	tree2 <- plot_tree(physeq, color="Habitat", label.tips="taxa_names", ladderize="left", plot.margin=0.3)
#	#ggsave(filename = "tree2.png", scale = 1, dpi = 300)
#	pdf("tree2.pdf")
#	print(tree2)
#	dev.off()
#	
#	tree3 <- plot_tree(physeq, color="Habitat", ladderize="left", plot.margin=0.3)
#	#ggsave(filename = "tree3.png", scale = 1, dpi = 300)
#	pdf("tree3.pdf")
#	print(tree3)
#	dev.off()
#}
#
#
#	
## create a heatmap, for the Phylum rank 
#heatmap <- plot_heatmap(physeq, taxa.label="Phylum")
##ggsave(filename = "heatmap.png", scale = 1, dpi = 300)
#pdf("heatmap.pdf")
#print(heatmap)
#dev.off()
#
## plot the diversity indices with colour coding by e.g. Location (info included in the metadata) 
#richness <- plot_richness(physeq, measures=c("Shannon", "Simpson", "Chao1"), color="Location")
##ggsave(filename = "richness.png", scale = 1, dpi = 300, width = 12)
#pdf("richness.pdf", width = 12)
#print(richness)
#dev.off()
#
## create the nmds plot colour coded by e.g. Location (info included in the metadata) 
#ord.nmds.bray <- ordinate(physeq, method="NMDS", distance="bray")
#p1 <- plot_ordination(physeq, ord.nmds.bray, color="Location", title="Bray NMDS")
##ggsave(filename = "p1.png", scale = 1, dpi = 300)
#pdf("p1.pdf")
#print(p1)
#dev.off()
#
## Split the previous nmds plot per e.g. Habitat (info included in the metadata) 
#p2 <- p1 + facet_wrap(~Habitat, 3)
##ggsave(filename = "p2.png", scale = 1, dpi = 300)
#pdf("p2.pdf")
#print(p2)
#dev.off()
#
## Create an nmds plot per Phylum
#p3 <- plot_ordination(physeq, ord.nmds.bray, type="taxa", color="Phylum", title="Bray NMDS")
##ggsave(filename = "p3.png", scale = 1, dpi = 300, width = 12)
#pdf("p3.pdf", width = 12)
#print(p3)
#dev.off()
#
## Split an nmds plot per Phylum
#p4 <- p3 + facet_wrap(~Phylum, 3)
##ggsave(filename = "p4.png", scale = 1, dpi = 300, width = 20)
#pdf("p4.pdf", width = 20)
#print(p4)
#dev.off()
#
##Run PERMANOVA to check for significance based on the Habitat factor (info included in the metadata) 
#OTU.adonis.Habitat <- adonis(biotic_transposed ~ metadata$Habitat, data=metadata, permutations = 999, distance = "bray")
#OTU.adonis.Habitat
#
##Run PERMANOVA to check for significance based on the combination (+) of Location & Habitat factors
#OTU.adonis <- adonis(biotic_transposed ~ metadata$Location+metadata$Habitat,data=metadata,permutations = 999,distance = "bray") 
##summary(OTU.adonis)
#OTU.adonis
#
## Create a bar plot only for the Proteobacteria
#physeq.proteobacteria = subset_taxa(physeq, Phylum=="Proteobacteria")
#proteo1 <- plot_bar(physeq.proteobacteria, title = "Proteobacteria per sample")
##ggsave(filename = "proteo1.png", scale = 1, dpi = 300)
#pdf("proteo1.pdf")
#print(proteo1)
#dev.off()
#
#proteo2 <- plot_bar(physeq.proteobacteria, "Class", "Abundance", "Habitat", title = "Proteobacteria per class, colour by Habitat")
##ggsave(filename = "proteo2.png", scale = 1, dpi = 300)
#pdf("proteo2.pdf")
#print(proteo2)
#dev.off()
#
#proteo3 <- plot_bar(physeq.proteobacteria, "Habitat", title = "Proteobacteria per Habitat")
##ggsave(filename = "proteo3.png", scale = 1, dpi = 300)
#pdf("proteo3.pdf")
#print(proteo3)
#dev.off()
#
#proteo4 <- plot_bar(physeq.proteobacteria, "Class", title = "Proteobacteria per class")
##ggsave(filename = "proteo4.png", scale = 1, dpi = 300)
#pdf("proteo4.pdf")
#print(proteo4)
#dev.off()
#
#proteo5 <- plot_bar(physeq.proteobacteria, "Class", "Abundance", "Class", facet_grid="Habitat~.", title = "Proteobacteria per Class, per Habitat")
##ggsave(filename = "proteo5.png", scale = 1, dpi = 300, width = 12)
#pdf("proteo5.pdf", width = 12)
#print(proteo5)
#dev.off()
#
##BIO-ENV
## select the columns of the metadata file that contain numeric data
#metadata_without_factors <- select_if(metadata, is.numeric)
## run the bioenv test
#bioenv <- bioenv(biotic_transposed, metadata_without_factors) 
## display the results
#summary(bioenv)
#
### Thank you for your patience! :) 
#
#
