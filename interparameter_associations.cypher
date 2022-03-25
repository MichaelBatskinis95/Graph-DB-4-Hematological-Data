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

//Correlations between compounds and proteins
match (m)-[:bio_converged_correlations]->()
with m
match (n:Proteomics)
with m,n, gds.alpha.similarity.pearson([m.early_mean,m.mid_mean,m.late_mean],[n.early_G6PD,n.mid_G6PD,n.late_G6PD]) as similarity
where abs(similarity) >= 0.85
merge (m)-[r:protein_compounds_correlations{similarity:similarity}]->(n)
set r.correlation_type = case when similarity > 0 then "positive" else "negative" end;
