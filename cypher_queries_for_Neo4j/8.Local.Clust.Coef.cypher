// Local Clustering Coefficient scores
match (n)-[r1:compound_similarity]->(m)
with collect(distinct r1.timestamp) as timepoints
unwind range(0,size(timepoints)-1) as time
call gds.localClusteringCoefficient.stream(
{nodeQuery:'match (a) where none(label in labels(a) where label in ["Donors","G6PD","Proteomics","Physiological_Parameters"]) return distinct id(a) as id',
relationshipQuery:"match (n)-[r:compound_similarity{timestamp: $time}]->(m) return id(n) as source, id(m) as target",
parameters:{time:timepoints[time]}
})
yield nodeId, localClusteringCoefficient
match (n)-[r:compound_similarity{timestamp:timepoints[time]}]->(m)
where id(n) = nodeId
with distinct n AS Compound, collect (distinct m.Name) as Neighbours, localClusteringCoefficient as LCC
with Compound, collect(distinct LCC) as all_LCC_Scores, collect(size(Neighbours)) as `# of neigbours/timepoint`
//filter out compounds that have inf lcc values and does not satisfy the repeatability criterion
where size(all_LCC_Scores) = 7 and none(score in all_LCC_Scores where score = gds.util.infinity()) 
return Compound.Name as Compound,labels(Compound)[0] as Pathway, all_LCC_Scores[0] as LCC_D0, all_LCC_Scores[1] as LCC_D7, 
all_LCC_Scores[2] as LCC_D14,all_LCC_Scores[3] as LCC_D21,all_LCC_Scores[4] as LCC_D28,
all_LCC_Scores[5] as LCC_D35,all_LCC_Scores[6] as LCC_D42 order by Compound asc