import json
import random
import os
from datetime import datetime, timedelta

# Setup
os.makedirs("medicale", exist_ok=True)
HOSPITALS = ["HOSP-A", "HOSP-B", "HOSP-C"]
SPECIALTIES = ["Cardiology", "Neurology", "General", "Pediatrics"]

# 1. Generate Hospitals
hospitals_data = [
    {"_id": "HOSP-A", "name": "Central Paris Hospital", "region": "Paris", "capacity": 500},
    {"_id": "HOSP-B", "name": "Lyon Medical Center", "region": "Lyon", "capacity": 300},
    {"_id": "HOSP-C", "name": "Marseille Health", "region": "Marseille", "capacity": 450}
]

# 2. Generate Doctors (1000 per hospital)
doctors_data = []
doctor_ids = []
for h_id in HOSPITALS:
    for i in range(1, 1001):
        d_id = f"DOC-{h_id}-{i:03d}"
        doctor_ids.append(d_id)
        doctors_data.append({
            "_id": d_id,
            "hospital_id": h_id,
            "name": f"Dr. {random.choice(['Smith', 'Dupont', 'House', 'Grey', 'Strange'])}",
            "specialty": random.choice(SPECIALTIES)
        })

# 3. Generate Patients (50 total, distributed)
patients_data = []
patient_ids = []
for i in range(1, 100000):
    h_id = random.choice(HOSPITALS)
    p_id = f"PAT-{i:04d}"
    patient_ids.append((p_id, h_id)) # Keep track of patient's hospital
    patients_data.append({
        "_id": p_id,
        "hospital_id": h_id,
        "name": f"Patient_{i}",
        "dob": (datetime.now() - timedelta(days=random.randint(5000, 30000))).strftime("%Y-%m-%d"),
        "blood_type": random.choice(["A+", "O+", "B-", "AB+"])
    })

# 4. Generate Consultations
consultations_data = []
for i in range(1, 120000):
    pat_id, pat_hosp = random.choice(patient_ids)
    # Pick a doctor from the SAME hospital as the patient (Logical consistency)
    valid_docs = [d for d in doctors_data if d['hospital_id'] == pat_hosp]
    doc = random.choice(valid_docs)
    
    consultations_data.append({
        "_id": f"CONS-{i:05d}",
        "hospital_id": pat_hosp, # CRITICAL FOR SHARDING
        "patient_id": pat_id,
        "doctor_id": doc['_id'],
        "date": (datetime.now() - timedelta(days=random.randint(0, 365))).isoformat(),
        "notes": "Routine checkup and vitals analysis."
    })

# Write Files
def write_json(filename, data):
    with open(f"medicale/{filename}", "w") as f:
        # Mongoimport expects 1 JSON object per line (JSONL) or a JSON Array
        # We will write a JSON Array for simplicity
        json.dump(data, f, indent=2)
    print(f"Generated {filename} with {len(data)} records.")

write_json("hospitals.json", hospitals_data)
write_json("doctors.json", doctors_data)
write_json("patients.json", patients_data)
write_json("consultations.json", consultations_data)