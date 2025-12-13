#!/bin/bash

# UPDATED for new container names: configserverX, shardsvrX, mongosX

echo ">>> Waiting for containers to start..."
sleep 15

# 1. Initialize Config Server Replica Set
echo ">>> Initializing Config Servers..."
docker exec configserver1 mongosh --port 27019 --eval '
  rs.initiate({
    _id: "rsConfig",
    configsvr: true,
    members: [
      { _id: 0, host: "configserver1:27019" },
      { _id: 1, host: "configserver2:27019" },
      { _id: 2, host: "configserver3:27019" }
    ]
  })
'

# 2. Initialize Shard 1 (Hospital A)
echo ">>> Initializing Shard 1 (Hospital A)..."
docker exec shardsvr1 mongosh --port 27018 --eval '
  rs.initiate({
    _id: "rsShard1",
    members: [
      { _id: 0, host: "shardsvr1:27018" },
      { _id: 1, host: "shardsvr2:27018" }
    ]
  })
'

# 3. Initialize Shard 2 (Hospital B)
echo ">>> Initializing Shard 2 (Hospital B)..."
docker exec shardsvr3 mongosh --port 27018 --eval '
  rs.initiate({
    _id: "rsShard2",
    members: [
      { _id: 0, host: "shardsvr3:27018" },
      { _id: 1, host: "shardsvr4:27018" }
    ]
  })
'

# 4. Initialize Shard 3 (Hospital C)
echo ">>> Initializing Shard 3 (Hospital C)..."
docker exec shardsvr5 mongosh --port 27018 --eval '
  rs.initiate({
    _id: "rsShard3",
    members: [
      { _id: 0, host: "shardsvr5:27018" },
      { _id: 1, host: "shardsvr6:27018" }
    ]
  })
'

echo ">>> Waiting for Replica Sets to stabilize..."
sleep 15

# 5. Add Shards to Router & Configure Zones
echo ">>> Adding Shards to Mongos and Configuring Zones..."
docker exec mongos1 mongosh --port 27017 --eval '
  // Add Shards
  sh.addShard("rsShard1/shardsvr1:27018,shardsvr2:27018");
  sh.addShard("rsShard2/shardsvr3:27018,shardsvr4:27018");
  sh.addShard("rsShard3/shardsvr5:27018,shardsvr6:27018");

  // Enable Sharding for DB
  sh.enableSharding("medical_db");

  // Create Indexes
  use medical_db;
  db.doctors.createIndex({ "hospital_id": 1 });
  db.patients.createIndex({ "hospital_id": 1 });
  db.consultations.createIndex({ "hospital_id": 1 });

  // Shard Collections
  sh.shardCollection("medical_db.doctors", { "hospital_id": 1 });
  sh.shardCollection("medical_db.patients", { "hospital_id": 1 });
  sh.shardCollection("medical_db.consultations", { "hospital_id": 1 });

  // --- ZONE SHARDING (Data Locality) ---
  // Assign Shards to Tags
  sh.addShardTag("rsShard1", "HOSP_A_ZONE");
  sh.addShardTag("rsShard2", "HOSP_B_ZONE");
  sh.addShardTag("rsShard3", "HOSP_C_ZONE");

  // Direct Data to Specific Shards based on ID
  // Hospital A Data -> Shard 1
  sh.updateZoneKeyRange("medical_db.patients", { "hospital_id": "HOSP-A" }, { "hospital_id": "HOSP-B" }, "HOSP_A_ZONE");
  sh.updateZoneKeyRange("medical_db.doctors", { "hospital_id": "HOSP-A" }, { "hospital_id": "HOSP-B" }, "HOSP_A_ZONE");
  sh.updateZoneKeyRange("medical_db.consultations", { "hospital_id": "HOSP-A" }, { "hospital_id": "HOSP-B" }, "HOSP_A_ZONE");

  // Hospital B Data -> Shard 2
  sh.updateZoneKeyRange("medical_db.patients", { "hospital_id": "HOSP-B" }, { "hospital_id": "HOSP-C" }, "HOSP_B_ZONE");
  sh.updateZoneKeyRange("medical_db.doctors", { "hospital_id": "HOSP-B" }, { "hospital_id": "HOSP-C" }, "HOSP_B_ZONE");
  sh.updateZoneKeyRange("medical_db.consultations", { "hospital_id": "HOSP-B" }, { "hospital_id": "HOSP-C" }, "HOSP_B_ZONE");
  
  // Hospital C Data -> Shard 3
  sh.updateZoneKeyRange("medical_db.patients", { "hospital_id": "HOSP-C" }, { "hospital_id": "HOSP-D" }, "HOSP_C_ZONE");
  sh.updateZoneKeyRange("medical_db.doctors", { "hospital_id": "HOSP-C" }, { "hospital_id": "HOSP-D" }, "HOSP_C_ZONE");
  sh.updateZoneKeyRange("medical_db.consultations", { "hospital_id": "HOSP-C" }, { "hospital_id": "HOSP-D" }, "HOSP_C_ZONE");
'

echo ">>> Cluster Initialized. Importing Data..."

# 6. Import Data
docker exec mongos1 mongoimport --db medical_db --collection hospitals --file /data/medicale/hospitals.json --jsonArray
docker exec mongos1 mongoimport --db medical_db --collection doctors --file /data/medicale/doctors.json --jsonArray
docker exec mongos1 mongoimport --db medical_db --collection patients --file /data/medicale/patients.json --jsonArray
docker exec mongos1 mongoimport --db medical_db --collection consultations --file /data/medicale/consultations.json --jsonArray

echo ">>> DONE! System is live."