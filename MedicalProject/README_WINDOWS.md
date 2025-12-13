# Windows Setup Guide — MongoDB Sharded Medical Cluster

This guide explains how to deploy the MongoDB sharded cluster on Windows using PowerShell and Docker Desktop.

## Prerequisites
- Docker Desktop (running, WSL2 backend recommended).
- Python 3.x (verify: `python --version`).
- PowerShell 5+ (Windows 10/11). Run PowerShell as Administrator when changing execution policy.
- Git (optional) to clone repository.

## Quick checklist
- Clone or open the project root (the folder that contains `docker-compose.yml` and `scripts/`).
- Confirm Docker Desktop is started and has enough resources (CPU/memory) for the containers.

---

## Step 1 — Generate synthetic data
From the project root (e.g., `C:\path\to\med_cluster`):

```powershell
cd C:\path\to\med_cluster
python scripts/generate_data.py
```

Success: you should see a new folder (e.g., `medicale`) containing several JSON files.

---

## Step 2 — Start containers
Start the MongoDB containers with Docker Compose:

```powershell
docker-compose up -d
```

Check status and logs:
```powershell
docker-compose ps
docker logs cfg1   # replace cfg1 with the container name if different
```

Wait 30–60 seconds for MongoDB processes to initialize before configuring the cluster.

---

## Step 3 — Initialize the cluster
Run the provided PowerShell initializer which links config servers, forms shard replica sets, adds shards to the router, configures zones, and imports the JSON files:

```powershell
.\scripts\init_cluster.ps1
```

If you get a script execution error (e.g. “running scripts is disabled on this system”), allow the script for the current session:

```powershell
Set-ExecutionPolicy Unrestricted -Scope Process
.\scripts\init_cluster.ps1
```

What the script does (summary):
- Initiates the Config Server Replica Set.
- Initiates each Shard Replica Set.
- Adds shards to the mongos router(s).
- Configures zones (e.g., map Hospital A → Shard 1).
- Imports JSON data into the `medical_db` database.

---

## Step 4 — Verify installation
Open a shell on the mongos router:

```powershell
docker exec -it router1 mongosh
```

Within `mongosh`:

```js
use medical_db
db.patients.getShardDistribution()
// or
sh.status()
rs.status()   // run inside a shard primary via mongo shell if needed
```

Sample test query (should target the shard for Hospital A):
```js
db.patients.find({ hospital_id: "HOSP-A" }).limit(1)
```

---

## Common troubleshooting
- Containers exit immediately:
    - Inspect logs: `docker logs <container-name>`
    - Ensure ports are free and Docker has sufficient resources.

- “Host not found” or network errors:
    - Make sure you run commands from the project root (where `docker-compose.yml` lives).
    - Ensure Docker Desktop uses the default network mode and WSL2 is enabled if applicable.

- PowerShell script blocked:
    - Use `Set-ExecutionPolicy Unrestricted -Scope Process` and rerun the script.

- Recreate everything from scratch:
```powershell
docker-compose down -v
docker-compose up -d
.\scripts\init_cluster.ps1
```
(The `-v` flag removes volumes, which deletes stored data.)

---

## Useful commands
- View containers: `docker-compose ps`
- Follow a container log: `docker logs -f <name>`
- Enter a container shell: `docker exec -it <name> powershell` or `bash`
- Check MongoDB process inside a container: `docker exec -it <mongo-container> mongosh --eval "db.serverStatus()"`

---

If any step fails, capture the container logs and the output of `sh.status()` / `rs.status()` and inspect the init script output for errors.