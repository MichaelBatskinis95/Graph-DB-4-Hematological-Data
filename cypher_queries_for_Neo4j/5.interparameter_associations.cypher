//Interparameter associations

//Correlations between compounds and physiological parameters
MATCH (p)<-[r1:Physiology]-(n)-[r2:RELATED_TO]->(m)
WHERE NOT n.Name = 'C'
WITH p, m, r1.timestamp AS time1, r2.timestamp AS time2, gds.alpha.similarity.pearson(COLLECT(r1.value),COLLECT(r2.CON)) AS similarity
WHERE abs(similarity)>=0.80
MERGE (p)-[r:phys_compounds_correlations{time_pair:time1+"-"+time2,similarity:toFloat(similarity)}]-(m) 
SET r.correlation_type = CASE WHEN r.similarity > 0 THEN "positive" ELSE "negative" END;

//Converged Correlations between compounds and physiological parameters
//set as threshold the # of occurance of a correlation (threshold: 25% of the possible times of occurance)
MATCH (n)-[r:phys_compounds_correlations]->(m)
WITH n, m, COLLECT(r.similarity) AS values, count(r) AS rel_counts
WHERE rel_counts > 12 //25% of theoretically possible combinations
MERGE (n)-[r:converged_phys_compounds_correlations{times_of_occurance:rel_counts}]-(m)
SET m.correlation_type = CASE WHEN ALL(x IN values WHERE x>0) THEN "positive" END
SET m.correlation_type =CASE WHEN ALL(x IN values WHERE x<0) THEN "negative" END;

//Clusters of Converged Physiological Parameters and Compounds
match (n)-[:converged_phys_compounds_correlations]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match (n)-[:converged_phys_compounds_correlations]-() return distinct id(n) as id',
  relationshipQuery:'match (p)-[r:converged_phys_compounds_correlations]->(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
return collect(n.Name) as name, size(collect(n.Name)) as `# of components`,  communityId order by `# of components` asc;

//Correlations between compounds and proteins
match (m)-[:bio_converged_correlations]->()
with m
match (n:Proteomics)
with m,n, gds.alpha.similarity.pearson([m.early_mean,m.mid_mean,m.late_mean],[n.early_G6PD,n.mid_G6PD,n.late_G6PD]) as similarity
where abs(similarity) >= 0.85
merge (m)-[r:protein_compounds_correlations{similarity:similarity}]->(n)
set r.correlation_type = case when similarity > 0 then "positive" else "negative" end;

// Clusters of Proteins and Biologically Converged Compounds
match (n)-[:protein_compounds_correlations]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match ()-[:protein_compounds_correlations]-(n) return distinct id(n) as id',
  relationshipQuery:'match (p)-[r:protein_compounds_correlations]->(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
with collect(n.Name) as name, size(collect(n.Name)) as `# of components`,  communityId
where  `# of components` > 1
return name, `# of components`, communityId order by `# of components` asc;

//Συνδυαστική αναπαράσταση όλων
match path1 = ()-[r:bio_converged_correlations]-(m)-[r2:protein_compounds_correlations|converged_phys_compounds_correlations]-(p)
where  gds.util.infinity()> p.abs_earlyVSlate_logFC >=1 or labels(p) = ["Physiological_Parameters"] 
return path1