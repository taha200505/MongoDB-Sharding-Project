import json
import random
from datetime import datetime, timedelta
from faker import Faker
from tqdm import tqdm
import os

# -----------------------------
# CONFIG – REALISTIC SHARD-FRIENDLY SIZES
# -----------------------------
N_HOSPITALS = 3
N_DOCTORS = 5000
N_PATIENTS = 3_000_000        # 3M for testing
N_CONSULTATIONS = 20_000_000  # 20M for testing

OUTPUT_DIR = "./generated_data/"
fake = Faker()
os.makedirs(OUTPUT_DIR, exist_ok=True)

HOSPITAL_IDS = [i for i in range(1, N_HOSPITALS + 1)]  # numeric!

# -----------------------------
# NOTES GENERATOR
# -----------------------------
symptoms_list = [
    "fever", "cough", "headache", "fatigue", "nausea",
    "rash", "chest pain", "shortness of breath", "dizziness"
]

diagnoses_list = [
    "common cold", "flu", "hypertension", "diabetes",
    "allergy", "migraine", "bronchitis", "asthma"
]

treatments_list = [
    "Paracetamol", "Ibuprofen", "Antibiotics", "Rest",
    "Inhaler", "Antihistamines", "Lifestyle changes"
]

def generate_medical_note():
    return f"Patient has {random.choice(symptoms_list)}. Diagnosed with {random.choice(diagnoses_list)}. Treated using {random.choice(treatments_list)}."

# -----------------------------
# GENERATE HOSPITALS
# -----------------------------
def generate_hospitals():
    data = []
    for hid in HOSPITAL_IDS:
        data.append({
            "hospital_id": hid,
            "name": f"Hospital {hid}",
            "created_at": datetime.utcnow().isoformat()
        })
    with open(OUTPUT_DIR + "hospitals.json", "w") as f:
        json.dump(data, f, indent=2)
    print("[OK] hospitals.json created")

# -----------------------------
# DOCTORS (NUMERIC doctor_id)
# -----------------------------
def generate_doctors():
    data = []
    for i in tqdm(range(1, N_DOCTORS + 1), desc="Generating doctors"):
        data.append({
            "doctor_id": i,                          # numeric
            "name": fake.name(),
            "hospital_id": random.choice(HOSPITAL_IDS),
            "specialty": random.choice([
                "Cardiology", "Dermatology", "Neurology",
                "Pediatrics", "Surgery"
            ]),
            "created_at": datetime.utcnow().isoformat()
        })
    with open(OUTPUT_DIR + "doctors.json", "w") as f:
        json.dump(data, f, indent=2)
    print("[OK] doctors.json created")

# -----------------------------
# PATIENTS (NUMERIC patient_id)
# -----------------------------
def generate_patients():
    with open(OUTPUT_DIR + "patients.json", "w") as f:
        f.write("[\n")
        for i in tqdm(range(1, N_PATIENTS + 1), desc="Generating patients"):
            obj = {
                "patient_id": i,
                "name": fake.name(),
                "age": random.randint(0, 100),
                "hospital_id": random.choice(HOSPITAL_IDS),
                "created_at": datetime.utcnow().isoformat()
            }
            f.write(json.dumps(obj))
            if i < N_PATIENTS:
                f.write(",\n")
        f.write("\n]")
    print("[OK] patients.json created")

# -----------------------------
# CONSULTATIONS (MONOTONIC consultation_id)
# -----------------------------
def generate_consultations():
    with open(OUTPUT_DIR + "consultations.json", "w") as f:
        f.write("[\n")

        for cid in tqdm(range(1, N_CONSULTATIONS + 1), desc="Generating consultations"):
            obj = {
                "consultation_id": cid,                   # monotonic integer
                "hospital_id": random.choice(HOSPITAL_IDS),
                "patient_id": random.randint(1, N_PATIENTS),
                "doctor_id": random.randint(1, N_DOCTORS),
                "date": (datetime.utcnow() - timedelta(days=random.randint(0, 3650))).isoformat(),
                "notes": generate_medical_note(),
                "created_at": datetime.utcnow().isoformat()
            }

            f.write(json.dumps(obj))
            if cid < N_CONSULTATIONS:
                f.write(",\n")

        f.write("\n]")
    print("[OK] consultations.json created")

# -----------------------------
# MAIN
# -----------------------------
def main():
    generate_hospitals()
    generate_doctors()
    generate_patients()
    generate_consultations()
    print("\nALL FILES GENERATED SUCCESSFULLY ✔️")

if __name__ == "__main__":
    main()
