//Compute Pearson's Similarity among compounds at each timepoint and merge compounds with abs(similarity) >= 0.85
MATCH (n)-[r1:RELATED_TO]->(m)
WITH COLLECT(DISTINCT r1.timestamp) as timepoints
UNWIND range(0,size(timepoints)-1) as time
MATCH (n:Donors)-[r:RELATED_TO{timestamp:timepoints[time]}]->(m1),
(n)-[r2:RELATED_TO{timestamp:timepoints[time]}]->(m2)
WHERE m1 <> m2 AND n.Name <> 'C'
WITH m1,m2,r2.timestamp AS timepoint, gds.alpha.similarity.pearson(collect(r.CON),collect(r2.CON)) as Similarity
WHERE abs(Similarity) >=0.85
MERGE (m1)-[r3:compound_similarity{similarity:Similarity, timestamp:timepoint}]-(m2)
SET r3.correlation_type = CASE WHEN r3.similarity > 0 THEN "positive" else "negative" END

///Filter out bio_converged_compounds (meaning compounds with similar variances across time)

MATCH (m1)-[r:compound_similarity]-(m2)
WITH DISTINCT m1,m2,[R IN COLLECT(r.similarity) WHERE abs(R)>=0.85] AS true_values 
WHERE size(true_values)>=4 AND id(m1)<id(m2)
MERGE (m1)-[r:bio_converged_correlations{correlation_values:true_values}]->(m2)
SET r.correlation_type = CASE WHEN ALL(x IN r.correlation_values WHERE x < 0) THEN "negative" END
SET r.correlation_type = CASE WHEN ALL(x IN r.correlation_values WHERE x > 0) THEN "positive" END;

//Get compounds' atlas
MATCH path1 = (m)-[r2:associated_with]->(k:G6PD)
OPTIONAL MATCH path2 = (n)-[r:bio_converged_correlations]->(m)
RETURN path1, path2;

//Compounds related to G6PD plus their 1st neighbors
MATCH path1 = (m)-[r2:associated_with]->(k:G6PD)
OPTIONAL MATCH path2 = (n)-[r:bio_converged_correlations]->(m)
RETURN m.Name as Compound, collect(n.Name) as `1st neighbors`, size(collect(n.Name)) as `# of neighbors` order by `# of neighbors` desc