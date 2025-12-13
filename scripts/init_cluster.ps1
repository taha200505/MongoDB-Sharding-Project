# Windows PowerShell Script to Initialize MongoDB Cluster
# FILE: scripts/init_cluster.ps1

Write-Host ">>> Waiting 15s for containers to start..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# ---------------------------------------------------------
# 1. Initialize Config Servers (Replica Set: rsConfig)
# ---------------------------------------------------------
Write-Host ">>> Initializing Config Servers..." -ForegroundColor Cyan
docker exec configserver1 mongosh --port 27019 --eval "rs.initiate({ _id: 'rsConfig', configsvr: true, members: [{ _id: 0, host: 'configserver1:27019' }, { _id: 1, host: 'configserver2:27019' }, { _id: 2, host: 'configserver3:27019' }] })"

# ---------------------------------------------------------
# 2. Initialize Shards (Replica Sets)
# ---------------------------------------------------------
Write-Host ">>> Initializing Shard 1 (Hospital A)..." -ForegroundColor Cyan
docker exec shardsvr1 mongosh --port 27018 --eval "rs.initiate({ _id: 'rsShard1', members: [{ _id: 0, host: 'shardsvr1:27018' }, { _id: 1, host: 'shardsvr2:27018' }] })"

Write-Host ">>> Initializing Shard 2 (Hospital B)..." -ForegroundColor Cyan
docker exec shardsvr3 mongosh --port 27018 --eval "rs.initiate({ _id: 'rsShard2', members: [{ _id: 0, host: 'shardsvr3:27018' }, { _id: 1, host: 'shardsvr4:27018' }] })"

Write-Host ">>> Initializing Shard 3 (Hospital C)..." -ForegroundColor Cyan
docker exec shardsvr5 mongosh --port 27018 --eval "rs.initiate({ _id: 'rsShard3', members: [{ _id: 0, host: 'shardsvr5:27018' }, { _id: 1, host: 'shardsvr6:27018' }] })"

Write-Host ">>> Waiting 15s for Replica Sets to stabilize..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# ---------------------------------------------------------
# 3. Configure Router (Shards, Zones, Indexes)
# ---------------------------------------------------------
Write-Host ">>> Configuring Cluster & Zones..." -ForegroundColor Cyan

$mongoCommands = @"
  // 1. Add Shards to the Cluster
  sh.addShard('rsShard1/shardsvr1:27018,shardsvr2:27018');
  sh.addShard('rsShard2/shardsvr3:27018,shardsvr4:27018');
  sh.addShard('rsShard3/shardsvr5:27018,shardsvr6:27018');

  // 2. Enable Sharding for the Database
  sh.enableSharding('medical_db');

  // 3. Create Indexes (Required before sharding)
  use medical_db;
  db.doctors.createIndex({ 'hospital_id': 1 });
  db.patients.createIndex({ 'hospital_id': 1 });
  db.consultations.createIndex({ 'hospital_id': 1 });

  // 4. Shard Collections
  sh.shardCollection('medical_db.doctors', { 'hospital_id': 1 });
  sh.shardCollection('medical_db.patients', { 'hospital_id': 1 });
  sh.shardCollection('medical_db.consultations', { 'hospital_id': 1 });

  // 5. Create Zones (Tags) for Data Locality
  sh.addShardTag('rsShard1', 'HOSP_A_ZONE');
  sh.addShardTag('rsShard2', 'HOSP_B_ZONE');
  sh.addShardTag('rsShard3', 'HOSP_C_ZONE');

  // 6. Map Data Ranges to Zones
  // Hospital A -> Shard 1
  sh.updateZoneKeyRange('medical_db.patients', { 'hospital_id': 'HOSP-A' }, { 'hospital_id': 'HOSP-B' }, 'HOSP_A_ZONE');
  sh.updateZoneKeyRange('medical_db.doctors', { 'hospital_id': 'HOSP-A' }, { 'hospital_id': 'HOSP-B' }, 'HOSP_A_ZONE');
  sh.updateZoneKeyRange('medical_db.consultations', { 'hospital_id': 'HOSP-A' }, { 'hospital_id': 'HOSP-B' }, 'HOSP_A_ZONE');

  // Hospital B -> Shard 2
  sh.updateZoneKeyRange('medical_db.patients', { 'hospital_id': 'HOSP-B' }, { 'hospital_id': 'HOSP-C' }, 'HOSP_B_ZONE');
  sh.updateZoneKeyRange('medical_db.doctors', { 'hospital_id': 'HOSP-B' }, { 'hospital_id': 'HOSP-C' }, 'HOSP_B_ZONE');
  sh.updateZoneKeyRange('medical_db.consultations', { 'hospital_id': 'HOSP-B' }, { 'hospital_id': 'HOSP-C' }, 'HOSP_B_ZONE');

  // Hospital C -> Shard 3
  sh.updateZoneKeyRange('medical_db.patients', { 'hospital_id': 'HOSP-C' }, { 'hospital_id': 'HOSP-D' }, 'HOSP_C_ZONE');
  sh.updateZoneKeyRange('medical_db.doctors', { 'hospital_id': 'HOSP-C' }, { 'hospital_id': 'HOSP-D' }, 'HOSP_C_ZONE');
  sh.updateZoneKeyRange('medical_db.consultations', { 'hospital_id': 'HOSP-C' }, { 'hospital_id': 'HOSP-D' }, 'HOSP_C_ZONE');
"@

# Execute commands on Mongos
$mongoCommands | docker exec -i mongos1 mongosh --port 27017

# ---------------------------------------------------------
# 4. Import Data
# ---------------------------------------------------------
Write-Host ">>> Importing Data..." -ForegroundColor Cyan

docker exec mongos1 mongoimport --db medical_db --collection hospitals --file /data/medicale/hospitals.json --jsonArray
docker exec mongos1 mongoimport --db medical_db --collection doctors --file /data/medicale/doctors.json --jsonArray
docker exec mongos1 mongoimport --db medical_db --collection patients --file /data/medicale/patients.json --jsonArray
docker exec mongos1 mongoimport --db medical_db --collection consultations --file /data/medicale/consultations.json --jsonArray

Write-Host ">>> DONE! System is live." -ForegroundColor Green