#!/usr/bin/env python3
"""
EcoFlux — Simulation et ingestion de données capteurs

Commandes :
  python main.py rooms                            Liste les logements et pièces
  python main.py fill [--days 7] [--interval 30]  Injecte l'historique (toutes les pièces)
  python main.py live [--interval 30]             Simulation temps réel (toutes les pièces)
  python main.py import --room-id <uuid>          Importe assets/data.csv pour une pièce

Prérequis :
  pip install supabase python-dotenv
  Fichier .env avec SUPABASE_URL et SUPABASE_SERVICE_KEY
"""

import argparse
import csv
import math
import os
import random
import signal
import sys
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

load_dotenv()

SUPABASE_URL        = os.getenv("SUPABASE_URL")
SUPABASE_SERVICE_KEY = os.getenv("SUPABASE_SERVICE_KEY")
CSV_PATH            = Path(__file__).parent / "ecoflux" / "assets" / "data.csv"

# Profils de simulation par type de pièce (icône Flutter)
# temp_base : température moyenne (°C), temp_amp : amplitude jour/nuit
# humi_base : humidité moyenne (%), humi_amp : amplitude jour/nuit
ROOM_PROFILES = {
    "living":   {"temp_base": 21.0, "temp_amp": 3.0, "humi_base": 48.0, "humi_amp":  8.0},
    "bedroom":  {"temp_base": 19.0, "temp_amp": 4.5, "humi_base": 53.0, "humi_amp": 10.0},
    "kitchen":  {"temp_base": 22.5, "temp_amp": 5.0, "humi_base": 60.0, "humi_amp": 15.0},
    "bathroom": {"temp_base": 22.0, "temp_amp": 2.5, "humi_base": 72.0, "humi_amp": 20.0},
    "office":   {"temp_base": 20.5, "temp_amp": 2.0, "humi_base": 44.0, "humi_amp":  6.0},
    "garage":   {"temp_base": 14.0, "temp_amp": 9.0, "humi_base": 56.0, "humi_amp": 12.0},
    "garden":   {"temp_base": 13.0, "temp_amp":11.0, "humi_base": 65.0, "humi_amp": 20.0},
}
DEFAULT_PROFILE = {"temp_base": 20.0, "temp_amp": 4.0, "humi_base": 50.0, "humi_amp": 10.0}


def get_client():
    if not SUPABASE_URL or not SUPABASE_SERVICE_KEY:
        print("Fichier .env manquant ou incomplet.")
        print("Copie .env.example -> .env et remplis SUPABASE_URL + SUPABASE_SERVICE_KEY.")
        sys.exit(1)
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)


def generate_reading(room_id: str, profile: dict, at: datetime) -> dict:
    """Génère un relevé réaliste avec variation sinusoïdale jour/nuit + bruit gaussien."""
    hour = at.hour + at.minute / 60

    temp = profile["temp_base"] + profile["temp_amp"] * math.sin(math.pi * (hour - 6) / 12)
    humi = profile["humi_base"] - profile["humi_amp"] * math.sin(math.pi * (hour - 6) / 12)
    pres = 1013.0 + 2.0 * math.sin(math.pi * hour / 24)

    return {
        "room_id":     room_id,
        "temperature": round(temp + random.gauss(0, 0.3), 2),
        "humidity":    round(max(20.0, min(95.0, humi + random.gauss(0, 1.0))), 2),
        "pressure":    round(pres + random.gauss(0, 0.5), 2),
        "recorded_at": at.isoformat(),
    }


def fetch_rooms(client) -> list[dict]:
    """Récupère toutes les pièces avec le nom de leur logement."""
    props  = client.table("properties").select("id, name").order("position").execute().data
    rooms  = client.table("rooms").select("id, name, icon, property_id").order("position").execute().data
    prop_names = {p["id"]: p["name"] for p in props}
    for r in rooms:
        r["property_name"] = prop_names.get(r["property_id"], "?")
    return rooms


# ── Commande : rooms ──────────────────────────────────────────────────────────

def cmd_rooms(_args):
    client = get_client()
    props = client.table("properties").select("id, name, type").order("position").execute().data
    rooms = client.table("rooms").select("id, name, icon, property_id").order("position").execute().data

    rooms_by_prop = {}
    for r in rooms:
        rooms_by_prop.setdefault(r["property_id"], []).append(r)

    if not props:
        print("Aucun logement trouve. Cree-en un depuis l'app Flutter.")
        return

    for p in props:
        print(f"\n  {p['name']}  ({p['type']})")
        for r in rooms_by_prop.get(p["id"], []):
            print(f"    {r['icon']:<12} {r['name']:<20} {r['id']}")
    print()


# ── Commande : fill ───────────────────────────────────────────────────────────

def cmd_fill(args):
    client = get_client()
    rooms  = fetch_rooms(client)

    if not rooms:
        print("Aucune piece trouvee. Cree-en une depuis l'app Flutter.")
        return

    days         = args.days
    interval_min = args.interval
    now          = datetime.now(timezone.utc)
    start        = now - timedelta(days=days)

    timestamps = []
    ts = start
    while ts <= now:
        timestamps.append(ts)
        ts += timedelta(minutes=interval_min)

    total = len(rooms) * len(timestamps)
    print(f"\nGeneration de {len(timestamps)} releves x {len(rooms)} piece(s) = {total} insertions")
    print(f"  Periode   : {days} jour(s) en arriere")
    print(f"  Intervalle: {interval_min} min\n")

    inserted = 0
    for room in rooms:
        profile = ROOM_PROFILES.get(room["icon"], DEFAULT_PROFILE)
        rows = [generate_reading(room["id"], profile, t) for t in timestamps]

        for i in range(0, len(rows), 100):
            client.table("sensor_readings").insert(rows[i:i + 100]).execute()
        inserted += len(rows)
        print(f"  OK  {room['property_name']} / {room['name']} ({room['icon']}) — {len(rows)} releves")

    print(f"\n{inserted} releves inseres avec succes.")


# ── Commande : live ───────────────────────────────────────────────────────────

def cmd_live(args):
    client   = get_client()
    rooms    = fetch_rooms(client)
    interval = args.interval

    if not rooms:
        print("Aucune piece trouvee.")
        return

    print(f"\nSimulation temps reel — {len(rooms)} piece(s) | Intervalle : {interval}s | Ctrl+C pour arreter\n")

    def _stop(_sig, _frame):
        print("\nSimulation arretee.")
        sys.exit(0)

    signal.signal(signal.SIGINT, _stop)

    count = 0
    while True:
        now      = datetime.now(timezone.utc)
        readings = []

        for room in rooms:
            profile = ROOM_PROFILES.get(room["icon"], DEFAULT_PROFILE)
            readings.append(generate_reading(room["id"], profile, now))

        client.table("sensor_readings").insert(readings).execute()
        count += 1
        ts = now.isoformat()[:19].replace("T", " ")
        print(f"[{ts}] #{count:>4}")

        for r, room in zip(readings, rooms):
            label = f"{room['property_name']} / {room['name']}"
            print(f"  {label:<35}  {r['temperature']:>5.1f}C  {r['humidity']:>4.0f}%  {r['pressure']:>7.1f} hPa")

        print()
        time.sleep(interval)


# ── Commande : import (compatibilite) ────────────────────────────────────────

def cmd_import(args):
    if not CSV_PATH.exists():
        print(f"Fichier CSV introuvable : {CSV_PATH}")
        sys.exit(1)

    client = get_client()
    rows   = []

    with open(CSV_PATH, newline="") as f:
        for line in csv.DictReader(f):
            rows.append({
                "room_id":     args.room_id,
                "temperature": float(line["temperature_c"]),
                "humidity":    float(line["humidity_pct"]),
                "pressure":    float(line["pressure_hpa"]),
                "recorded_at": f"{line['timestamp'].strip()}T12:00:00+00:00",
            })

    print(f"Import de {len(rows)} releves pour la piece {args.room_id}...")
    for i in range(0, len(rows), 50):
        client.table("sensor_readings").insert(rows[i:i + 50]).execute()
        print(f"  {min(i + 50, len(rows))}/{len(rows)}")
    print("Import termine.")


# ── CLI ───────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="EcoFlux — donnees capteurs")
    sub    = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("rooms", help="Liste les logements et pieces")

    p_fill = sub.add_parser("fill", help="Injecte l'historique pour toutes les pieces")
    p_fill.add_argument("--days",     type=int, default=7,  metavar="N", help="Nombre de jours (defaut : 7)")
    p_fill.add_argument("--interval", type=int, default=30, metavar="MIN", help="Intervalle en minutes (defaut : 30)")

    p_live = sub.add_parser("live", help="Simulation temps reel sur toutes les pieces")
    p_live.add_argument("--interval", type=int, default=30, metavar="SEC", help="Intervalle en secondes (defaut : 30)")

    p_imp = sub.add_parser("import", help="Importe assets/data.csv pour une piece")
    p_imp.add_argument("--room-id", required=True, metavar="UUID")

    args = parser.parse_args()
    {"rooms": cmd_rooms, "fill": cmd_fill, "live": cmd_live, "import": cmd_import}[args.command](args)


if __name__ == "__main__":
    main()
