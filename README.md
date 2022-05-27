# Graph-DB-4-Hematological-Data

A graph-based framework, based on graph database technologies, to facilitate storage, retrieval, and exploration for hematological and biological graph data.

## *Workflow*

<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/Workflow_HemData.jpg" width="1024" height = "256"/>

### 1. Data Collection & Preperation

**Final Dataset = Experimental Data + Computationally Verified Data**

<ins>Experimental Data</ins>

Data about the metabolic, proteomic & physiological profile of 6 G6PD deficient & 1 control donor were retrieved.

*Metabolic Data*

7 weekly samplings, 295 metabolites

For each metabolite the following information were collected:
- official name
- ID in Kegg Database
- metabolic pathway to which it belongs and
- abundances in both G6PD deficient and control donors

*Physiological Data*

7 weekly samplings, 83 physiological parameters

For each physiological parameter the following information were collected:
- official name
- abundances in both G6PD deficient and control donors

*Proteomic Profile*

3 weekly pooled samplings, 934 proteins

For each protein the following information were collected:
- official name
- related gene
- accession number (AC) in UniprotKB/Swissprot db
- abundances in both G6PD deficient and control donors

<ins>Computationally Verified Data</ins>

Data retrieved from the following databases were used for the qualitative enrichment of the Knowledge Graph:
- String: 241 protein interactions between G6PD and other related proteins
- STITCH: 453 protein-chemical or chemical-chemical interactions
- Ensembl: 39 records about diseases related to G6PD or proteins closely associated with it
- Human Protein Atlas (HPA): 27 additional diseases

<ins>Data Pre-processing and Curation</ins>

The following issues were fixed in this stage:
✅ missing values
✅ entries with insufficient information
✅ duplicate entries from different sources

<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/Exp_data_preprocessing.svg" width="400" height = "400"/>

### 2. Graph Databasefor Bio/Hematological Networks

#### 2.1 Query Requirements

#### 2.2 The Graph Data Model

#### 2.3 Bio/Hematological Data Analysis

#### 2.4 The final Knowledge Graph 

### 3. Data Exploration for Bio/Hematological Networks
