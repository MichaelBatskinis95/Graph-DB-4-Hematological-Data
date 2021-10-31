//Define donors' nodes
LOAD CSV WITH HEADERS FROM
"file:///C:/Users/mbats/OneDrive/Desktop/metabolomic_data.csv" AS row
UNWIND keys(row) AS head
WITH  DISTINCT(head) AS heads ORDER BY toUpper(head) ASC
WHERE heads =~ 'G.*' OR heads =~ 'C_.*'
WITH apoc.text.replace(heads,'_D[0-9]*','') as names
WITH DISTINCT names
MERGE (n:Donors{Name:names});

//Define compounds' nodes and connect them to their donors
LOAD CSV WITH HEADERS FROM
"file:///C:/Users/mbats/OneDrive/Desktop/metabolomic_data.txt" AS record
CALL apoc.create.node([record.Pathway],{Name: record.compound, pvalue:toFloat(record.pvalue)}) YIELD node
WITH record,node
MATCH (n:Donors)
WITH record,node,n, ["D0","D7","D14","D21","D28","D35","D42"] AS timestamps
UNWIND range(0,size(timestamps)-1) AS id
MERGE(n)-[:RELATED_TO{CON:toFloat(record[n.Name+"_"+timestamps[id]]),timestamp:timestamps[id]}]->(node);

//Load Refined Dataset of Physiological Data
LOAD CSV WITH HEADERS FROM
"file:///C:/Users/mbats/OneDrive/Desktop/physiological_data_refined.txt" AS lines
UNWIND keys(lines) AS parms
WITH apoc.text.replace(parms,'_D[0-9]*','') AS names, lines
WITH distinct(names), lines
MERGE (p:Physiological_Parameters{Name:names})
WITH distinct(names), lines, p, ["D0","D7","D14","D21","D28","D35","D42"] AS timestamps ORDER BY names ASC
UNWIND range(0,size(timestamps)-1) AS id
WITH p, timestamps[id] AS time, collect(lines[names+"_"+timestamps[id]]) AS values
WHERE size(values) > 0
MATCH (n:Donors)
WITH collect(distinct n.Name) AS source, time, p, values
UNWIND range(0,size(values)-1) as vector
MATCH (m:Donors)
WHERE m.Name =~ source[vector]
MERGE (m)-[:Physiology{timestamp:time,value:toFloat(values[vector])}]->(p);

//Load Physiological Data of Control 
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/physiological_data_control.txt" AS data
WITH data, ["D0","D7","D14","D21","D28","D35","D42"] AS timestamps
MATCH (n:Physiological_Parameters), (m:Donors{Name:'C'})
UNWIND range(0,size(timestamps)-1) AS id
WITH m, n, timestamps[id] AS time, data[n.Name+"_"+timestamps[id]] AS value
WHERE value IS NOT NULL
MERGE (m)-[r:Physiology{timestamp:time,value:value}]->(n);

//Pass abbreveations for each physiological parameter
LOAD CSV FROM
"file:///C:/Users/mbats/OneDrive/Desktop/physiological_abbreviations.txt" AS data
WITH data
MATCH (n:Physiological_Parameters)
WHERE n.Name = data[0]
SET n.Full_Name =  data[1];

//Load Proteomics & Vesicular Data
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/proteomics_data.txt" AS data
WITH data
WHERE NOT ALL(x IN [data.Gpool_D2, data.Gpool_D42, data.Gpool_D21, data.C_D2, data.C_D42, data.C_D21, data.Ves_C_D42, data.Ves_G_D42] WHERE toFloat(x) <= 10.0)
MERGE (n:Proteomics{Name:data.`Identified Proteins (934)`, UniProtID:data.`Accession Number`, MolecularWeight:data.`Molecular Weight`, early_control:toFloat(data.C_D2), early_G6PD:toFloat(data.Gpool_D2), mid_control:toFloat(data.C_D21), mid_G6PD:toFloat(data.Gpool_D21), late_control:toFloat(data.C_D42), late_G6PD:toFloat(data.Gpool_D42),Ves_C_D42:toFloat(data.Ves_C_D42),Ves_G_D42:toFloat(data.Ves_G_D42)})
WITH n,apoc.text.regexGroups(n.Name, 'GN=[A-Z]*')[0][0] AS name
SET n.Gene = apoc.text.replace(name, 'GN=','');

//Load data from STITCH db
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/stitch_interactions.csv" AS data
WITH apoc.coll.union(collect([data.node1,data.node1_id]),collect([data.node2,data.node2_id])) AS list_of_names
UNWIND range(0,size(list_of_names)-1) AS i
match (m)
WHERE (labels(m) IN [["Proteomics"],["Physiology"],["G6PD"]] AND m.Name contains apoc.text.capitalize(list_of_names[i][0])) OR (NOT labels(m) IN [["Proteomics"],["Physiology"],["G6PD"]] AND m.Name = list_of_names[i][0])
SET m.molecule_type = 
CASE 
WHEN
list_of_names[i][1] CONTAINS 'ENSP' THEN 'Protein' 
WHEN
list_of_names[i][1] CONTAINS 'CID' THEN 'Chemical'
END
WITH list_of_names, COLLECT(list_of_names[i]) AS names
WITH apoc.coll.subtract(list_of_names, names) AS external_sources
UNWIND range(0,size(external_sources)-1) AS j
MERGE(k:Stitch_data{Name:external_sources[j][0], molecule_type: 
CASE WHEN external_sources[j][1] CONTAINS 'ENSP' THEN 'Protein' 
ELSE 'Chemical' END});
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/stitch_interactions.csv" as data
WITH data
MATCH (n)
MATCH (m)
WHERE (NOT labels(n) IN [['Donors'],['Physiological_Parameters']] AND NOT labels(m) IN [['Donors'],['Physiological_Parameters']]) AND (apoc.text.capitalize(n.Name) CONTAINS apoc.text.capitalize(data.node1) AND apoc.text.capitalize(m.Name) CONTAINS apoc.text.capitalize(data.node2)) AND (n) <> (m)
MERGE (n)-[r:interaction{source: "STITCH", textmining_score:toFloat(data.textmining_score), coexpression:toFloat(data.coexpression_score),neighbourhood_score:toFloat(data.neighbourhood_score),database_score:toFloat(data.database_score),combined_score:toFloat(data.combined_score)}]->(m)
WITH n, r, m
CALL apoc.refactor.setType(r, CASE 
WHEN n.molecule_type = 'Protein' and m.molecule_type = 'Protein' then 'PPI' 
WHEN n.molecule_type = 'Chemical' AND m.molecule_type = 'Chemical' THEN 'Chemical_Chemical_Interaction' 
WHEN (n.molecule_type = 'Chemical' AND m.molecule_type = 'Protein') OR (m.molecule_type = 'Chemical' and n.molecule_type = 'Protein') THEN
'Protein_Chemical_Interaction'
END) 
YIELD INPUT, OUTPUT
WHERE type(r) = 'interaction'
DELETE r

//Load data from Ensembl db (38 relationships - 6 existing proteins + 4 new proteins
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/Ensembl_interactions.csv" AS data
WITH data
MERGE (n:Ensembl_data{UniProtID:data.UniprotID})-[r:phenotype]-(m:Disease{Name:data.disease,source:data.source})
WITH n, r, m
MATCH (p)
WHERE (p:Proteomics or p:G6PD) AND p.UniProtID = n.UniProtID
DELETE n, r
MERGE (p)-[:phenotype]->(m);

//Load data from HPA db (26 relationships)
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/HPA_interactions.csv" AS data
WITH data
MERGE (m:Disease{Name:data.diseases,source:"HPA"})
WITH  data,m
MATCH (p)
WHERE p.UniProtID = data.UniProtID and m.Name = data.diseases
MERGE (p)-[:phenotype]->(m);


//Load data from String db
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/string_interactions.csv" AS data
WITH data
MATCH (n)
WHERE labels(n) IN [["Proteomics"],["Stitch_data"],["G6PD"]] AND n.Gene = data.node1 or n.Gene = data.node2
WITH apoc.coll.union(COLLECT(DISTINCT data.node1), COLLECT(DISTINCT data.node2)) AS listOFnames, COLLECT(DISTINCT n.Gene) AS common_names
WITH apoc.coll.subtract(listOFnames, common_names) AS string_data
UNWIND range(0,size(string_data)-1) as j
MERGE (m:String_data{Gene:string_data[j],molecule_type:"Protein"})
WITH m
LOAD CSV WITH HEADERS FROM 
"file:///C:/Users/mbats/OneDrive/Desktop/string_interactions.csv" as data
MATCH (n:String_data)
WHERE m.Gene = data.node1 AND n.Gene = data.node2
MERGE (m)-[:PPI{source:"String", database_score:data.database_score, textmining_score:data.textmining_score, coexpression_score:data.coexpression_score, neighbourhood_score:data.neighbourhood_score, combined_score:data.combined_score}]->(n)

