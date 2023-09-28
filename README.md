# Graph-DB-4-Hematological-Data

A graph-based framework, based on graph database technologies, to facilitate storage, retrieval, and exploration for hematological and biological graph data.

## *Workflow*

<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/Workflow_HemData.jpg" width="1024" height = "240"/>

**<ins>Important Note</ins>**</br>
<p align="justify">Pre-processing of physiological data (for more info see phys_data_preprocess.ipynb), along with the extraction of computationally verified data (External_sources.ipynb) were performed in Python. </p>


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
- *String*: 241 protein interactions between G6PD and other related proteins
- *STITCH*: 453 protein-chemical or chemical-chemical interactions
- *Ensembl*: 39 records about diseases related to G6PD or proteins closely associated with it
- *Human Protein Atlas (HPA)*: 27 additional diseases

<ins>Data Pre-processing and Curation</ins>

The following issues were fixed in this stage:</br>
✅ missing values </br>
✅ entries with insufficient information</br>
✅ duplicate entries from different sources</br>

<p align="middle">
<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/Exp_data_preprocessing.svg" width="400" height = "400"/><img src="https://github.com/MichaelBatskinis95/Figures/blob/main/data_curation.svg" width="400" height = "400"/>
</p>

### 2. Graph Database for Bio/Hematological Networks

<p align="justify">The construction of the knowledge graph, that highlights the associations between different bio/hematological parameters related to the G6PD enzyme, which is the key component of the biological issue that was investigated, was conducted in Neo4j graph database. </p>

#### 2.1 Query Requirements

<p align="justify">The first step towards the construction of the bio/hematological data networks was to determine user requirements. Those requirements will drive the construction of a knowledge graph that could explain interactions or, better yet, reveal potential associations between different parameters. </p>

<ins> First Group of Requirements: Biologically Converged Parameters </ins>

- <p align="justify">Spectating inter- and intra- parameter associations in all possible combinations &rarr; Gives insight about interactions between one or more different data types </p>
- <p align="justify">Determination of crucial parameters &rarr; Utilizing Centrality algorithms to gain insight about the most popular nodes of the – case study – system (hub nodes) </p>
- <p align="justify">Identification of converged metabolites based on the storage timeline of RBCs &rarr; Can be achieved by dividing the seven samplings into three – storage based – groups (early, mid, and late storage) and then performing correlation analysis (e.g using Pearson's Similarity algorithm) to identify the most converged components.</p></br>
<p align="middle">
<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/time_based_workflow.jpg" width="800" height = "400"/>
</p>

<ins> Second Group of Requirements: Data Visualization and Subnetworks Representation </ins>

- <p align="justify">Graph representation based on specific properties of the case study system &rarr; Utilizing filtering tools to gain insight about specific components</p>
- Detection of communities &rarr; Can be achieved by perfoming community detection analysis (e.g. using Louvain method)
- Focusing on clusters/subnetworks &rarr; Refers to the subsequent analysis after the detection of communities.

<ins> Third Group of Requirements: Comparative Analysis of Donors’ Metabolic Profile </ins>

- <p align="justify">Comparing donors’ metabolic profile in pairs &rarr; Answering to this question could highlight either the homogeneity or heterogeneity of the system, since all donors were tested under the same conditions (Can be achieved by applying pairwise comparison of donors' metabolic profile.</p>

<p align="middle">
<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/pairwise%20comparison.jpg" width="600" height = "400"/>
</p>

- <p align="justify">Investigating the impact of storage to RBCs’ metabolic profile &rarr; The purpose of this query is to gain insight about the effect of storage to RBCs’ vitality and functionality. Comparing the in vivo system of each donor (D0) with the in vitro system (D7 – D42) could reveal the critical storage period at which the functionality of RBCs starts to disrupt.</p>
<p align="middle">
<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/impact%20of%20storage%20on%20RBCs%20of%20G6PD-%20donors.jpg" width="600" height = "400"/>
</p>

#### 2.2 The Graph Data Model

<p align="justify">In total, the Bio/Hematological Data Network consists of <b>933 nodes</b>, divided in 9 general groups and <b>87,790 relationships</b>, arranged in 15 distinct types. The proposed graph data model consists of the following node types: compounds divided in 33 different subgroups depending on the metabolic pathway the belong to, physiological parameters, proteomics, donor, stitch data, string data, Ensembl, disease and G6PD. Below an infographic representation of the graph data model, that shows which node types interact with nodes types, is shown: </p>

<p align="middle">
<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/Infographic_Representation_GraphDB.jpg" width="500" height = "450"/>
</p>

#### 2.3 Bio/Hematological Data Analysis

<p align = "justify">After importing all necessary data to the network, statistical analysis using graph-related algorithms, to filter the most statistically significant parameters of the network, took place.  The process that was followed 1) started with finding a suitable approach to explore the data that were available, 2) followed by setting a proper threshold, so that the outcome would be accurate enough and 3) concluded with filtering out biologically converged intra- and inter- parameter relationships.</p>

**<ins>Approach</ins>**

Two algorithms were applied during the statistical analysis: <b>Pearson Similarity algorithm</b> and <b>Cosine Similarity algorithm</b>.

*Pearson Similarity Algorithm*

Applied for the characterization of significant intra- and inter- parameters associations between different datasets, such as:
- Compound Similarities
- Metabolites associated with G6PD
- Physiological Parameter – Compound Similarities
- Protein Similarities
- Protein – Compounds Similarities

$$ Pearson's  Similarity(A,B) = {cov(A,B) \over {σ_{A} \times σ_{Β}}} = {{\sum_{i=1}^n (A_{i}-\overline A)(B_{i}-\overline B)} \over {\sum_{i=1}^n (A_{i}-\overline A)^2(B_{i}-\overline B)^2}} $$

*Cosine Similarity Algorithm*

Used for:
- Comparison of donors’ metabolic profile
- Effect of time in G6PD- donor’s RBCs

$$ Cosine Similarity(A,B) = {A\bullet B \over {\lVert \mathbf{A} \rVert \times \lVert \mathbf{B} \rVert}} = {{\sum_{i=1}^n A_{i} \times B_{i}} \over \sqrt\sum_{i=1}^n A_{i}^2 \times \sqrt\sum_{i=1}^n B_{i}^2}$$

**<ins>Setting the Threshold</ins>**

After properly estimating Pearson Similarity scores, the filtering of the most significant intra- and inter- parameter correlations took place.  To o achieve that, a threshold was set, so that statistically significant associations will be distinguished.  The value of the threshold varied in each case, depending on the size of the case study dataset or the number of samplings.

**<ins>Filtering biologically converged correlations</ins>**

#### 2.4 The final Knowledge Graph 

<p align="justify">By assembling the outcome of what was described in Sections 2.1, 2.2 and 2.3 the final knowledge graph can be generated. We could describe the bio/hematological data network as a network of two layers. The first layer consists of the pre-processed experimental data along with all correlations that were mentioned in Section 2.3, while the second layer includes external data sources (nodes, relationships, and properties) that enrich the length and depth of the knowledge graph by adding more detailed information regarding proteins and metabolites related – directly or indirectly – to G6PD. </p>

<p align="middle">
<img src="https://github.com/MichaelBatskinis95/Figures/blob/main/final_knowledge_graph.jpg" width="800" height = "450"/>
</p>

### 3. Data Exploration for Bio/Hematological Networks

<p align"justify"> To facilitate data exploration on bio/hematological data, we adopted the GraphXR tool. which provides effective visualization capabilities especially for users without an IT background. Using GraphXR we applied several graph-related techniques to highlight significant inter- and intra- parameter associations, identify crucial components and discover communities that are formed within different subgraphs. </p>

#### 3.1 Investigating Intra- and Inter- Parameter Associations

<p align="justify"> Since the bio/hematological data network was set up to investigate homologous and heterologous correlations between different components and to answer to a set of questions related to this biological issue, a first approach regarding the exploration analysis could be to spectate specific relationships of the graph at will, depending on the question we want to answer. That said, a representative case could be to collect and, subsequently, display all G6PD-related metabolites along with compounds that are highly correlated with. To do so, we need to select to display only relationship types regarding: </p> 
a) G6PD-related components (relationship type: associated with) and 

b) biologically converged metabolites (relationship type: bio converged compounds)
