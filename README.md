# EcoFlux# EcoFlux

Application de suivi de capteurs domestiques (température, humidité, pression) par logement et par pièce, avec authentification, tableaux de bord graphiques et un script d'ingestion/simulation de données.

Le projet se compose de deux parties :

- **`ecoflux/`** — application mobile/desktop [Flutter](https://flutter.dev), connectée à [Supabase](https://supabase.com) (auth, base de données, stockage).
- **`main.py`** — script Python en ligne de commande pour injecter de l'historique de relevés ou simuler des données de capteurs en temps réel dans Supabase.

## Fonctionnalités

- Authentification (connexion / inscription) via Supabase Auth
- Gestion multi-logements (appartement, maison, etc.) et de leurs pièces
- Ajout, renommage, suppression et réorganisation (drag & drop) des pièces
- Tableau de bord par pièce avec graphiques (température, humidité, pression) via `fl_chart`
- Gestion du profil utilisateur
- Simulation et injection de données de capteurs (historique ou temps réel) via `main.py`

## Structure du projet

```
EcoFlux/
├── ecoflux/                  # Application Flutter
│   ├── lib/
│   │   ├── login/            # Écrans de connexion / inscription
│   │   ├── page/             # Écrans principaux (logements, pièces, dashboard, compte)
│   │   ├── models/           # Modèles de données (Property, Room, SensorData)
│   │   ├── services/         # Accès aux données (Supabase)
│   │   └── main.dart         # Point d'entrée + routing
│   └── supabase/             # Scripts SQL (schéma, RLS)
└── main.py                   # CLI d'ingestion / simulation de données capteurs
```

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.0`)
- Python 3.9+
- Un projet [Supabase](https://supabase.com) avec les tables `properties`, `rooms` et `sensor_readings`

## Configuration

1. Copier `.env.example` vers `.env` à la racine et renseigner les variables :

   ```
   SUPABASE_URL=...
   SUPABASE_SERVICE_KEY=...
   ```

   > `SUPABASE_SERVICE_KEY` est la clé *service role* : elle ne doit jamais être commitée ni utilisée côté client.

2. Configurer les identifiants Supabase côté Flutter dans `ecoflux/lib/supabase_config.dart` (URL + clé publique `anon`).

## Application Flutter

```bash
cd ecoflux
flutter pub get
flutter run
```

## Script de simulation de données (`main.py`)

Installation des dépendances :

```bash
pip install supabase python-dotenv
```

Commandes disponibles :

```bash
python main.py rooms                            # Liste les logements et pièces
python main.py fill [--days 7] [--interval 30]   # Injecte l'historique (toutes les pièces)
python main.py live [--interval 30]              # Simulation temps réel (toutes les pièces)
python main.py import --room-id <uuid>           # Importe ecoflux/assets/data.csv pour une pièce
```

## Base de données

Le schéma des tables et leurs policies RLS sont versionnés dans `ecoflux/supabase/` (migrations Supabase CLI).
