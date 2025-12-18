#!/bin/bash

echo "Sharding database and collections..."

# Enable sharding on the database
docker exec mongos mongosh --port 27017 --eval '
sh.enableSharding("medical");
print("✓ Sharding enabled on medical database");
'

# Shard patients collection
docker exec mongos mongosh --port 27017 --eval '
db = db.getSiblingDB("medical");
db.patients.createIndex({ patient_id: "hashed" });
sh.shardCollection("medical.patients", { patient_id: "hashed" });
print("✓ patients collection sharded using patient_id (hashed)");
'

# Shard hospitals collection
docker exec mongos mongosh --port 27017 --eval '
db = db.getSiblingDB("medical");
db.hospitals.createIndex({ hospital_id: "hashed" });
sh.shardCollection("medical.hospitals", { hospital_id: "hashed" });
print("✓ hospitals collection sharded using hospital_id (hashed)");
'

# Shard doctors collection
docker exec mongos mongosh --port 27017 --eval '
db = db.getSiblingDB("medical");
db.doctors.createIndex({ doctor_id: "hashed" });
sh.shardCollection("medical.doctors", { doctor_id: "hashed" });
print("✓ doctors collection sharded using doctor_id (hashed)");
'

# Shard consultations collection
docker exec mongos mongosh --port 27017 --eval '
db = db.getSiblingDB("medical");
db.consultations.createIndex({ consultation_id: "hashed" });
sh.shardCollection("medical.consultations", { consultation_id: "hashed" });
print("✓ consultations collection sharded using consultation_id (hashed)");
'

echo ""
echo "======================================"
echo "✔✔✔ All collections successfully sharded!"
echo "======================================"
