#!/usr/bin/env python3
"""
EcoFlux — Script de données capteurs
Usage:
  python main.py rooms                        Liste tes pièces et leurs UUIDs
  python main.py import --room-id <uuid>      Importe ecoflux/assets/data.csv dans Supabase
  python main.py simulate --room-id <uuid>    Génère des relevés live (Ctrl+C pour arrêter)
  python main.py simulate --room-id <uuid> --interval 10  (intervalle en secondes, défaut 30)

Prérequis:
  pip install supabase python-dotenv
  Créer un fichier .env (voir .env.example) avec ta service role key Supabase
"""

import argparse
import csv
import math
import os
import random
import signal
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
CSV_PATH = Path(__file__).parent / "ecoflux" / "assets" / "data.csv"


def get_client():
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        print("❌ Fichier .env manquant ou incomplet. Copie .env.example → .env et remplis les valeurs.")
        sys.exit(1)
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


# ── Commande : rooms ──────────────────────────────────────────────────────────

def cmd_rooms(_args):
    client = get_client()
    rows = client.table("rooms").select("id, name, icon, created_at").order("created_at").execute()
    rooms = rows.data
    if not rooms:
        print("Aucune pièce trouvée. Crée-en une depuis l'app Flutter.")
        return
    print(f"\n{'Nom':<20} {'Icône':<12} {'UUID'}")
    print("-" * 70)
    for r in rooms:
        print(f"{r['name']:<20} {r['icon']:<12} {r['id']}")
    print()


# ── Commande : import ─────────────────────────────────────────────────────────

def cmd_import(args):
    if not CSV_PATH.exists():
        print(f"❌ Fichier CSV introuvable : {CSV_PATH}")
        sys.exit(1)

    client = get_client()
    rows = []

    with open(CSV_PATH, newline="") as f:
        reader = csv.DictReader(f)
        for line in reader:
            rows.append({
                "room_id":     args.room_id,
                "temperature": float(line["temperature_c"]),
                "humidity":    float(line["humidity_pct"]),
                "pressure":    float(line["pressure_hpa"]),
                "recorded_at": f"{line['timestamp'].strip()}T12:00:00+00:00",
            })

    print(f"📥 Import de {len(rows)} relevés pour la pièce {args.room_id}...")
    for i in range(0, len(rows), 50):
        batch = rows[i:i + 50]
        client.table("sensor_readings").insert(batch).execute()
        print(f"  ✓ {min(i + 50, len(rows))}/{len(rows)}")

    print("✅ Import terminé.")


# ── Commande : simulate ───────────────────────────────────────────────────────

def _generate_reading(room_id: str) -> dict:
    """Génère un relevé réaliste avec variation sinusoïdale + bruit."""
    now = datetime.now(timezone.utc)
    hour = now.hour + now.minute / 60

    temp_base = 20.0 + 4.0 * math.sin(math.pi * (hour - 6) / 12)
    humi_base = 60.0 - 8.0 * math.sin(math.pi * (hour - 6) / 12)
    pres_base = 1013.0 + 2.0 * math.sin(math.pi * hour / 24)

    return {
        "room_id":     room_id,
        "temperature": round(temp_base + random.gauss(0, 0.3), 2),
        "humidity":    round(max(20, min(95, humi_base + random.gauss(0, 1.0))), 2),
        "pressure":    round(pres_base + random.gauss(0, 0.5), 2),
        "recorded_at": now.isoformat(),
    }


def cmd_simulate(args):
    client = get_client()
    interval = args.interval
    print(f"🔄 Simulation démarrée pour la pièce {args.room_id}")
    print(f"   Intervalle : {interval}s | Ctrl+C pour arrêter\n")

    def _stop(_sig, _frame):
        print("\n⏹  Simulation arrêtée.")
        sys.exit(0)

    signal.signal(signal.SIGINT, _stop)

    count = 0
    while True:
        reading = _generate_reading(args.room_id)
        client.table("sensor_readings").insert(reading).execute()
        count += 1
        ts = reading["recorded_at"][:19].replace("T", " ")
        print(f"[{ts}] #{count:>4}  🌡 {reading['temperature']}°C  💧 {reading['humidity']}%  🔵 {reading['pressure']} hPa")
        time.sleep(interval)


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="EcoFlux — données capteurs")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("rooms", help="Liste les pièces et leurs UUIDs")

    p_import = sub.add_parser("import", help="Importe assets/data.csv dans Supabase")
    p_import.add_argument("--room-id", required=True, metavar="UUID")

    p_sim = sub.add_parser("simulate", help="Génère des relevés live")
    p_sim.add_argument("--room-id", required=True, metavar="UUID")
    p_sim.add_argument("--interval", type=int, default=30, metavar="SEC")

    args = parser.parse_args()
    {"rooms": cmd_rooms, "import": cmd_import, "simulate": cmd_simulate}[args.command](args)


if __name__ == "__main__":
    main()
