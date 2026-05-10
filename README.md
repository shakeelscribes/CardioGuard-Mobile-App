<div align="center">

# 🫀 CardioGuard Mobile

**Next-Generation Cardiovascular Disease Prediction**

[![Flutter](https://img.shields.io/badge/Built_with-Flutter-%2302569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Language-Dart-%230175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-%233ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![FastAPI](https://img.shields.io/badge/AI_Engine-FastAPI-%23009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com/)

*Your heart's future, visualized today.*

</div>

---

## 🚀 Overview

**CardioGuard Mobile** is a state-of-the-art Flutter application engineered to provide real-time, AI-driven cardiovascular disease (CVD) risk assessments. Seamlessly synced with the CardioGuard Web Platform, it places cutting-edge predictive analytics directly in your pocket. 

Designed with a futuristic **Glassmorphism UI** and fluid micro-animations, CardioGuard transforms complex medical data into beautiful, actionable, and easy-to-understand insights.

## ✨ Futuristic Features

*   🧠 **AI-Powered Diagnostics:** Instantly evaluates 11 critical health metrics (including BMI, Blood Pressure, Glucose, and Cholesterol) using a high-accuracy machine learning model.
*   🔒 **Seamless & Secure Access:** Next-gen authentication powered by **Supabase**, featuring one-tap **Google OAuth** and secure email/password biometric-ready logins.
*   ⚡ **Real-Time Data Sync:** Your health data travels with you. Instantly syncs predictions, history, and profile changes across both the Web and Mobile platforms.
*   🎨 **Premium Aesthetic:** Built with a stunning dark-mode optimized interface, utilizing glassmorphism, dynamic gradients, and fluid `animate_do` transitions.
*   📈 **Smart Trend Tracking:** Interactive, touch-responsive risk trend charts that help you visualize your heart health trajectory over time.
*   🔥 **Gamified Health:** Built-in streak trackers and personalized daily "Tip of the Day" cards to keep you motivated and engaged with your cardiovascular health.

## 🛠️ Technology Stack

| Architecture Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | `Flutter` & `Dart` | Cross-platform UI/UX rendering |
| **Backend & Auth** | `Supabase` | PostgreSQL database, Auth, & Row Level Security |
| **AI Processing** | `FastAPI` (Python) | High-speed machine learning inference |
| **State & UI** | `animate_do`, `fl_chart` | State management, animations, and data visualization |

## ⚙️ Quick Start

To experience CardioGuard Mobile locally, follow these steps:

### Prerequisites
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or higher recommended)
*   Android Studio / Xcode for emulation
*   A configured Supabase Project & Google Cloud OAuth Client

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/CardioGuard-Mobile.git
cd CardioGuard-Mobile/flutter_app
```

**2. Install Dependencies**
```bash
flutter pub get
```

**3. Configure Environment**
Create a `.env` file or update `lib/services/supabase_service.dart` with your Supabase credentials and Web Client ID:
```dart
static const String url = 'YOUR_SUPABASE_URL';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
static const String webClientId = 'YOUR_GOOGLE_WEB_CLIENT_ID';
```

**4. Ignite the App**
```bash
flutter run
```

## 📱 App Architecture Highlights

```text
lib/
├── models/         # Strongly-typed Dart data structures
├── screens/        # Fluid, animated UI views (Home, Profile, Input, Result)
├── services/       # Supabase, API, and Authentication logic
├── utils/          # Theming engine, custom colors, and constants
└── widgets/        # Reusable glassmorphic cards and interactive elements
```

## 🛡️ Security & Privacy

CardioGuard takes medical data privacy seriously:
*   **Zero-Knowledge Auth:** Passwords are never exposed; handled entirely by Supabase GoTrue.
*   **Row Level Security (RLS):** Database policies ensure users can only ever access their own prediction history.
*   **Token-based OAuth:** Google Sign-In utilizes secure ID Tokens rather than raw credentials.

---
<div align="center">
  <p>Engineered for the future of health tech.</p>
  <p><b>Built by Team STR</b></p>
</div>
