//Find Clusters of Bio-Converged Compounds
match (n)-[:bio_converged_correlations]-()
with distinct n
call gds.louvain.stream({
  nodeQuery:'match (n)-[:bio_converged_correlations]-() return distinct id(n) as id',
  relationshipQuery:'match (p)-[r:bio_converged_correlations]-(k) return id(p) as source, id(k) as target'})
yield nodeId, communityId
where id(n) = nodeId
return collect(n.Name) as name, size(collect(n.Name)) as `# of compounds`,  communityId order by `# of compounds` asc