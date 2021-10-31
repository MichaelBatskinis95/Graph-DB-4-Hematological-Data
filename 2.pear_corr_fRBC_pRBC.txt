//Calculate Pearson's R between fRBCs and the different sampling periods. Extract more significant ones
CREATE (n:G6PD{Name:"G6PD",Gene:'G6PD,UniProtID:'P11413'});
MATCH (n:Donors)
WHERE n.Name <> 'C' //Does not include control donor
WITH COLLECT(n.Name) AS samples, ["D7","D14","D21","D28","D35","D42"] AS timestamps
UNWIND range(0,size(samples)) AS id
UNWIND range(0,size(timestamps)) as time
MATCH (n:Donors{Name:samples[id]})-[r:RELATED_TO{timestamp:"D0"}]->(m),
(n2:Donors{Name:samples[id]})-[r2:RELATED_TO{timestamp:timestamps[time]}]->(m)
WHERE n.Name <> 'C' AND n2.Name <> 'C'
WITH m, r2.timestamp AS pair, gds.alpha.similarity.pearson(COLLECT(r.CON), COLLECT(r2.CON)) AS similarity
WITH m, COLLECT(similarity) AS allPearsons
WITH m,[R IN allPearsons WHERE abs(R)>=0.80] AS true_values
MATCH (n:G6PD)
WHERE size(true_values)>=4
MERGE (m)-[r:associated_with]->(n)
