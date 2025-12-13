# Distributed Medical Record System (MongoDB Sharded Cluster)

**Brief:** A production-like MongoDB sharded cluster designed to centralize hospital records while enforcing data locality, availability, and query performance using zone sharding.

## 1. Quick Summary

- **Sharding strategy:** Zone (tag-aware) sharding based on `hospital_id`.
- **Topology:** 11 containers — 2 mongos, 3 config servers (rsConfig), 3 shards (each a 2-node replica set).
- **Goals:** Data locality per hospital, single-shard targeted queries, high availability via replica sets.

## 2. Topology (Logical)

- **Routers (mongos):** `mongos1`, `mongos2`
- **Config Servers (rsConfig):** `configserver1`, `configserver2`, `configserver3`
- **Shards:**
  - rsShard1 (Nodes: `shardsvr1`, `shardsvr2`) — Hospital A (HOSP-A)
  - rsShard2 (Nodes: `shardsvr3`, `shardsvr4`) — Hospital B (HOSP-B)
  - rsShard3 (Nodes: `shardsvr5`, `shardsvr6`) — Hospital C (HOSP-C)

**Zone mapping:**

- HOSP-A → HOSP_A_ZONE → rsShard1
- HOSP-B → HOSP_B_ZONE → rsShard2
- HOSP-C → HOSP_C_ZONE → rsShard3

## 3. Why this shard key

`hospital_id` :

- **Drives locality:** All patient & staff records for a hospital live on a single shard.
- **Enables targeted queries (** `SINGLE_SHARD` **):** Optimizes the most common access patterns (viewing a hospital's own patients).
- **Minimizes latency:** Reduces cross-shard joins and distributed writes.

## 4. Collections & Schema (Concise)

| Collection    | Shard Key | Notes |
|---|---|---|
| patients    | `hospital_id` | Large, frequently queried; locality-critical. |
| doctors    | `hospital_id` | Local staff data. |
| consultations | `hospital_id` | Join-heavy; kept co-located with patients/doctors. |
| hospitals    | (unsharded) | Small metadata; stored on primary shard. |

## 5. Common Cluster Commands

These are executed via the `mongos` router.

- Enable sharding:

```javascript
sh.enableSharding("medical_db")
sh.shardCollection("medical_db.patients", { hospital_id: 1 })