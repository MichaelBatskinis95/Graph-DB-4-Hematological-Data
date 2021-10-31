//Time Based Correlation Analysis
//Step 1: Calculate mean values for each storage stage (early, mid, late)
match (n)-[r:RELATED_TO]->(m)
where n.Name <> 'C' and r.timestamp in ['D0','D7']
with m,avg(r.CON) as mean
set m.early_mean = mean
union
match (n)-[r:RELATED_TO]->(m)
where n.Name <> 'C' and r.timestamp in ['D14','D21','D28']
with m,avg(r.CON) as mean
set m.mid_mean = mean
union
match (n)-[r:RELATED_TO]->(m)
where n.Name <> 'C' and r.timestamp in ['D35','D42']
with m,avg(r.CON) as mean
set m.late_mean = mean

//Step 2: Constructing the time based correlation networks
WITH ["D0","D7"] AS time
UNWIND range(0,size(time)-1) AS id
MATCH (p)<-[r2:RELATED_TO{timestamp:time[id]}]-(n)-[r1:RELATED_TO{timestamp:time[id]}]->(m)
WHERE id(p)<id(m) AND NOT n.Name = 'C'
WITH p,m,gds.alpha.similarity.pearson(COLLECT(r1.CON),COLLECT(r2.CON)) AS Similarity
WHERE abs(Similarity)>=0.85
MERGE (m)-[r:early_storage{similarity:Similarity}]-(p)
SET r.correlation_type = CASE WHEN r.Similarity > 0 THEN "positive" ELSE "negative" END
UNION
WITH ["D14","D21","D28"] AS time
UNWIND range(0,size(time)-1) AS id
MATCH (p)<-[r2:RELATED_TO{timestamp:time[id]}]-(n)-[r1:RELATED_TO{timestamp:time[id]}]->(m)
WHERE id(p)<id(m) AND NOT n.Name = 'C'
WITH p,m,gds.alpha.similarity.pearson(COLLECT(r1.CON),COLLECT(r2.CON)) AS Similarity
WHERE abs(Similarity)>=0.85
MERGE (m)-[r:mid_storage{similarity:Similarity}]-(p)
SET r.correlation_type = CASE WHEN r.Similarity > 0 THEN "positive" ELSE "negative" END
UNION
WITH ["D35","D42"] AS time
UNWIND range(0,size(time)-1) AS id
MATCH (p)<-[r2:RELATED_TO{timestamp:time[id]}]-(n)-[r1:RELATED_TO{timestamp:time[id]}]->(m)
WHERE id(p)<id(m) AND NOT n.Name = 'C'
WITH p,m,gds.alpha.similarity.pearson(COLLECT(r1.CON),COLLECT(r2.CON)) AS Similarity
WHERE abs(Similarity)>=0.85
MERGE (m)-[r:late_storage{similarity:Similarity}]-(p)
SET r.correlation_type = CASE WHEN r.Similarity > 0 THEN "positive" ELSE "negative" END;

//Step 3: % of Idenitiy of Correlation Networks
//Here we compare the correlation networks we created above in pairs, in order
//to identify the % of common relationships
match (n)-[r1:early_storage]-(m),
(n)-[r:mid_storage]-(m)
with collect(distinct [n.Name,m.Name]) as pair, type(r1) as type,count(distinct r) as `common pairs`
match (m1)-[r2:mid_storage]-(m2)
return type+" VS "+type(r2) as `compared timelines`,(toFLoat(`common pairs`)/count(distinct r2))*100 as `% network identity`
union
match (n)-[r1:early_storage]-(m),
(n)-[r:late_storage]-(m)
with collect(distinct [n.Name,m.Name]) as pair, type(r1) as type,count(distinct r) as `common pairs`
match (m1)-[r2:late_storage]-(m2)
return type+" VS "+type(r2) as `compared timelines`,(toFLoat(`common pairs`)/count(distinct r2))*100 as `% network identity`
union
match (n)-[r1:late_storage]-(m),
(n)-[r:mid_storage]-(m)
with collect(distinct [n.Name,m.Name]) as pair, type(r1) as type,count(distinct r) as `common pairs`
match (m1)-[r2:mid_storage]-(m2)
return type+" VS "+type(r2) as `compared timelines`,(toFLoat(`common pairs`)/count(distinct r2))*100 as `% network identity`;

//Step 4: Find Communitites/Cluster for each storage stage
//4.1 Early Storage
match (n)-[:early_storage]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match (n)-[:early_storage]-() return distinct id(n) as id',
  relationshipQuery:'match (p)-[r:early_storage]-(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
with collect(n.Name) as Community, size(collect(n.Name)) as `# of compounds`,  communityId 
where `# of compounds` > 2
return Community,`# of compounds` order by `# of compounds` desc;

//4.2 Mid Storage
match (n)-[:mid_storage]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match (n)-[:mid_storage]-() return distinct id(n) as id',
  relationshipQuery:'match (p)-[r:mid_storage]-(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
with collect(n.Name) as Community, size(collect(n.Name)) as `# of compounds`,  communityId 
where `# of compounds` > 2
return Community,`# of compounds` order by `# of compounds` desc;

//4.3 Late Storage
match (n)-[:late_storage]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match (n)-[:late_storage]-() return distinct id(n) as id',
  relationshipQuery:'match (p)-[r:late_storage]-(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
with collect(n.Name) as Community, size(collect(n.Name)) as `# of compounds`,  communityId 
where `# of compounds` > 2
return Community,`# of compounds` order by `# of compounds` desc