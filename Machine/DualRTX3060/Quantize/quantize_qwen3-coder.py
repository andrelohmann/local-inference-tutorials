# Dateiname: quantize_qwen3-coder.py

import os
from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer
from llmcompressor import oneshot
from llmcompressor.modifiers.awq import AWQModifier

# --- 1. Konfiguration ---
MODEL_ID = "Qwen/Qwen3-Coder-30B-A3B-Instruct"
SAVE_DIR = "Qwen3-Coder-30B-AWQ-final"  # Speicherort für das Ergebnis
DATASET_ID = "HuggingFaceH4/CodeAlpaca_20K"
NUM_CALIBRATION_SAMPLES = 256
MAX_SEQUENCE_LENGTH = 1024

# --- 2. Lade das Modell und den Tokenizer ---
print(f"Lade Modell: {MODEL_ID} mit CPU-Offloading...")
model = AutoModelForCausalLM.from_pretrained(
    MODEL_ID,
    torch_dtype="auto",
    device_map="auto", # CPU-Offloading aktivieren
    trust_remote_code=True
)
tokenizer = AutoTokenizer.from_pretrained(MODEL_ID, trust_remote_code=True)
print("Modell erfolgreich geladen.")

# --- 3. Lade und verarbeite den Kalibrierungsdatensatz ---
print(f"Lade und verarbeite Kalibrierungsdatensatz: {DATASET_ID}...")
ds = load_dataset(DATASET_ID, split=f"train[:{NUM_CALIBRATION_SAMPLES}]")
ds = ds.shuffle(seed=42)

def tokenize_function(examples):
    tokenized_batch = tokenizer(
        examples["prompt"],
        padding=False,
        truncation=True,
        max_length=MAX_SEQUENCE_LENGTH,
        add_special_tokens=False,
    )
    return tokenized_batch

tokenized_dataset = ds.map(
    tokenize_function,
    batched=True,
    remove_columns=[col for col in ds.column_names]
)
print("Kalibrierungsdatensatz vorbereitet.")

# --- 4. Definiere das Quantisierungs-"Rezept" ---
recipe = [
    AWQModifier(
        ignore=["lm_head"],
        scheme="W4A16",
        targets=["Linear"],
    ),
]
print("Quantisierungs-Rezept erstellt.")

# --- 5. Führe die Quantisierung durch UND SPEICHERE DAS ERGEBNIS ---
print("Starte 'oneshot'-Quantisierungs- und Speicherprozess...")
oneshot(
    model=model,
    dataset=tokenized_dataset,
    recipe=recipe,
    max_seq_length=MAX_SEQUENCE_LENGTH,
    num_calibration_samples=NUM_CALIBRATION_SAMPLES,
    output_dir=SAVE_DIR  # DER ENTSCHEIDENDE PARAMETER, DER ALLES LÖST
)
# Der Tokenizer muss separat gespeichert werden.
tokenizer.save_pretrained(SAVE_DIR)

print(f"\n\nQuantisierung und Speichern erfolgreich abgeschlossen!")
print(f"Das finale, quantisierte Modell befindet sich in: ./{SAVE_DIR}")