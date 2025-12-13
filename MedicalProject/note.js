// Add Shard 1 (Hospital A)
sh.addShard("rsShard1/shardsvr1:27018,shardsvr2:27018")

// Add Shard 2 (Hospital B)
sh.addShard("rsShard2/shardsvr3:27018,shardsvr4:27018")

// Add Shard 3 (Hospital C)
sh.addShard("rsShard3/shardsvr5:27018,shardsvr6:27018")



// Enable sharding for the database
sh.enableSharding("medical_db")

// Define the Shard Key
sh.shardCollection("medical_db.patients", { "hospital_id": 1 })
sh.shardCollection("medical_db.doctors", { "hospital_id": 1 })
sh.shardCollection("medical_db.consultations", { "hospital_id": 1 })

// Create Zones (Data Locality)
sh.addShardTag("rsShard1", "HOSP_A_ZONE")
sh.addShardTag("rsShard2", "HOSP_B_ZONE")
sh.addShardTag("rsShard3", "HOSP_C_ZONE")

// Map Hospital IDs to Zones
sh.updateZoneKeyRange("medical_db.patients", { "hospital_id": "HOSP-A" }, { "hospital_id": "HOSP-B" }, "HOSP_A_ZONE")
sh.updateZoneKeyRange("medical_db.patients", { "hospital_id": "HOSP-B" }, { "hospital_id": "HOSP-C" }, "HOSP_B_ZONE")
sh.updateZoneKeyRange("medical_db.patients", { "hospital_id": "HOSP-C" }, { "hospital_id": "HOSP-D" }, "HOSP_C_ZONE")