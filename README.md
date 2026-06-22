**Nudge 2.0** 🚇
A smart, offline-first metro transit tracking app with a real-time data pipeline backend. Built with Flutter for the mobile experience and Python/AWS for the data engineering layer.
Current Status: Core mobile app functional (route selection, journey tracking, background GPS). Data engineering backend in active development.

**What's Working Now (Mobile App)**
<img width="1420" height="574" alt="image" src="https://github.com/user-attachments/assets/a50a2199-9565-4816-a6d0-042903bc3107" />

**Mobile Tech Stack**
Framework: Flutter (Dart)
State Management: provider
Geolocation: geolocator
Background Processing: flutter_foreground_task
Local Storage: sqflite (SQLite) — in progress

**What's Being Built Next (Data Engineering Backend)**
This is where the project transforms from an app into a full data engineering portfolio. The backend will ingest, process, and analyze transit data at scale.

Phase 1: Local Data Foundation (In Progress)
<img width="1314" height="412" alt="image" src="https://github.com/user-attachments/assets/04dbb5c4-884e-4db7-bd25-e3582cec0534" />

Phase 2: Cloud Ingestion (Upcoming)
<img width="1302" height="492" alt="image" src="https://github.com/user-attachments/assets/60958436-f3ae-4723-bdbd-07d87ad137b3" />

Phase 3: ETL Pipeline (Upcoming)
<img width="1210" height="414" alt="image" src="https://github.com/user-attachments/assets/0c747360-27ec-40d2-b74a-962a80d58430" />

Phase 4: ML & Analytics (Upcoming)
<img width="1438" height="408" alt="image" src="https://github.com/user-attachments/assets/d37c49f8-b740-45e9-a160-acba062a9b92" />

Phase 5: Privacy & Scale (Upcoming)
<img width="1336" height="336" alt="image" src="https://github.com/user-attachments/assets/95609eba-8270-4168-95d1-0daecd1e6423" />


🏛️ **System Architecture**
┌─────────────────────────────────────────────────────────────────────┐
│                         MOBILE APP (Flutter)                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Route UI    │  │  Background  │  │  Local DB    │              │
│  │  (Select     │  │  GPS Service │  │  (SQLite)    │              │
│  │   start/end) │  │  (5s interval)│  │  • stations  │              │
│  │              │  │              │  │  • queue     │              │
│  │  ✅ LIVE     │  │  ✅ LIVE     │  │  🔄 WIP      │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    │  HTTPS (when network available)
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA ENGINEERING BACKEND                     │
│                                                                      │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐              │
│  │ API Gateway │───►│ AWS Lambda  │───►│  S3 Raw     │              │
│  │  /sync/batch│    │  (Validate) │    │  Data Lake  │              │
│  └─────────────┘    └──────┬──────┘    └──────┬──────┘              │
│                            │                   │                    │
│                            ▼                   │                    │
│                     ┌─────────────┐            │                    │
│                     │ DynamoDB    │            │                    │
│                     │ (Sync State)│            │                    │
│                     └─────────────┘            │                    │
│                                                │                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  AIRFLOW + PYSPARK (Daily ETL)                               │   │
│  │  Extract -> Validate -> Transform -> Load -> Predict          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                │                    │
│  ┌─────────────────────────┐  ┌─────────────────────────┐           │
│  │  AUTH DB (Encrypted)    │  │  ANALYTICS DB           │           │
│  │  • users (PII)          │  │  • anonymous journeys     │           │
│  │  • tokens               │  │  • predictions          │           │
│  └─────────────────────────┘  └─────────────────────────┘           │
│                                                │                    │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  CONSUMPTION: Streamlit Dashboard + Grafana Monitoring      │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘


**Tech Stack (Full)**
-Mobile Layer
  Flutter (Dart) — Cross-platform UI
  geolocator — GPS tracking
  flutter_foreground_task — Background service
  sqflite — Local SQLite database
  provider — State management

-Data Engineering Layer
  Python — Core scripting language
  PostgreSQL — Relational database (stations, analytics, auth)
  AWS S3 — Data lake for raw/cleaned data
  AWS Lambda — Serverless event processing
  AWS API Gateway — REST API for mobile sync
  AWS DynamoDB — NoSQL cache (predictions, sync state)
  AWS IAM — Security & access control
  Apache Airflow — Pipeline orchestration
  PySpark — Distributed data processing
  Streamlit — Analytics dashboard
  Git/GitHub — Version control


**Android Setup (For Contributors)**
Add these permissions to android/app/src/main/AndroidManifest.xml:

<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />


🎯 **Why This Project?**
Most DE portfolios are "I analyzed Netflix data from Kaggle." This is different:
Real problem: Missing your metro stop because you're distracted
Real constraints: Underground = no network, GPS drift, battery limits
Real architecture: Streaming ingestion, batch ETL, ML predictions, privacy compliance
Real scale path: Designed to handle 100K+ users with the same stack
Interview pitch: "I built a transit app and then built the full data pipeline behind it — offline-first ingestion, Airflow-orchestrated ETL, heuristic ML for arrival predictions, and GDPR-compliant data separation."
🤝 **Contributing**
This is a personal learning project. If you're learning data engineering too, feel free to fork and build along. I'll document every phase as I go.





**"Built with Flutter. Powered by Python. Engineered for people who miss their stops."**
