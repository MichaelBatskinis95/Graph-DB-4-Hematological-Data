//Integrating Proteomics

//A: Data normalization and logFC calculation
match (n:Proteomics)
with  max(n.early_G6PD) as G_max,min(n.early_G6PD) as G_min, max(n.early_control) as C_max,min(n.early_control) as C_min
match (n:Proteomics)
//step1: Data normalization
with n, (n.early_G6PD - G_min)/(G_max - G_min) as normG,  (n.early_control - C_min)/(C_max - C_min) as normC
//step2: logFC calculation --> set it as node property for each protein 
set n.abs_early_logFC = abs(log(normG/normC))
union
match (n:Proteomics)
with  max(n.mid_G6PD) as G_max,min(n.mid_G6PD) as G_min, max(n.mid_control) as C_max,min(n.mid_control) as C_min
match (n:Proteomics)
with n, (n.mid_G6PD - G_min)/(G_max - G_min) as normG,  (n.mid_control - C_min)/(C_max - C_min) as normC
set n.abs_mid_logFC = abs(log(normG/normC))
union
match (n:Proteomics)
with  max(n.late_G6PD) as G_max,min(n.late_G6PD) as G_min, max(n.late_control) as C_max,min(n.late_control) as C_min
match (n:Proteomics)
with n, (n.late_G6PD - G_min)/(G_max - G_min) as normG,  (n.late_control - C_min)/(C_max - C_min) as normC
set n.abs_late_logFC = abs(log(normG/normC))
union
match (n:Proteomics)
with  max(n.early_G6PD) as G0_max,min(n.early_G6PD) as G0_min, max(n.late_G6PD) as G42_max,min(n.late_G6PD) as G42_min
match (n:Proteomics)
with n, (n.early_G6PD - G0_min)/(G0_max - G0_min) as normG0,  (n.late_G6PD - G42_min)/(G42_max - G42_min) as normG42
set n.abs_earlyVSlate_logFC = abs(log(normG0/normG42));

//B: Find statistically significant proteins at all storage stages (control VS G6PD)
match (n:Proteomics)
where gds.util.infinity()>=n.abs_early_logFC >=1 
and gds.util.infinity()>=n.abs_mid_logFC >=1 
and gds.util.infinity()>=n.abs_late_logFC >=1 
return n.Name as `Protein Name`, n.UniProtAC as `UniProt AC`;

//C: Find stat. sig. proteins (G6PD early VS G6PD late) <-- in progress (to be done: find correlations bewteen proteins)
match (n:Proteomics)
where gds.util.infinity()>=n.abs_earlyVSlate_logFC >=1 
return n.Name as `Protein Name`, n.UniProtAC as `UniProt AC`;

//D: Proteins' correlation network
match (n:Proteomics)
with n
match (m:Proteomics)
where n.Name <> m.Name and id(n)<id(m)
with n, m, gds.alpha.similarity.pearson([n.early_G6PD,n.mid_G6PD,n.late_G6PD],[m.early_G6PD,m.mid_G6PD,m.late_G6PD]) as similarity
where abs(similarity)>=0.99
merge (n)-[r:protein_correlations{similarity:similarity}]->(m)
set r.correlation_type = case when abs(similarity) > 0 then "positive" else "negative" end;

//E: Centralities
call gds.betweenness.stream(
{nodeQuery:'match (a:Proteomics) return distinct id(a) as id',
relationshipQuery:"match (n)-[r:protein_correlations]->(m) return id(n) as source, id(m) as target"}
)
yield nodeId, score
with score as BC, nodeId as ID
call gds.alpha.degree.stream(
{nodeQuery:'match (a:Proteomics) return distinct id(a) as id',
relationshipQuery:"match (n)-[r:protein_correlations]->(m) return id(n) as source, id(m) as target"}
)
yield nodeId, score
match (n)-[r:protein_correlations]->(m)
where id(n) = nodeId and ID = nodeId and BC > 0 
return distinct n.Name as Protein, BC as `Betweeness Centrality`, score as `Degree Centrality` order by BC desc;

//F:Find Clusters of Proteins
match (n)-[:protein_correlations]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match (n:Proteomics) return distinct id(n) as id',
  relationshipQuery:'match (p)-[:protein_correlations]-(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
return collect(n.Name) as name, size(collect(n.Name)) as `# of compounds`,  communityId order by `# of compounds` asc

