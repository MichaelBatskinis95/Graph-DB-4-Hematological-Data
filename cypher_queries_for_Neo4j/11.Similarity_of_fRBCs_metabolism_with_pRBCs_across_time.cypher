//Similarity of fRBCs' metabolism with pRBCs across time
//Cosine similarity was used as a metric.
//The higher the cosine similirity the more similar the systems, that we compare, are.
with ["D0","D7","D14","D21","D28","D35","D42"] as time
unwind range(1,size(time)-1) as i
match (p1:Donors)-[r1:RELATED_TO{timestamp:'D0'}]->(n)<-[r2:RELATED_TO{timestamp:time[i]}]-(p1)
with sum(r1.CON * r2.CON) AS DotProduct,
      sqrt(reduce(r1Dot = 0.0, a in collect(r1.CON) | r1Dot + a^2)) as r1Length,
      sqrt(reduce(r2Dot = 0.0, b IN COLLECT(r2.CON) | r2Dot + b^2)) AS r2Length,time[i] as timepoint, p1
with p1,collect( DotProduct / (r1Length * r2Length)) as CS
return p1.Name as Donor, CS[0] as fRBCvsD7,CS[1] as fRBCvsD14, CS[2] as fRBCvsD21,CS[3] as fRBCvsD28, CS[4] as fRBCvsD35, CS[5] as fRBCvsD42