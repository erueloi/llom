# 🏛️ Llom - Arquitectura del Sistema

Per a la documentació tècnica completa, esquema de dades de Cloud Firestore, directrius de disseny per a components visuals, patrons de serveis i instruccions per a agents d'IA, consulta el document mestre a l'arrel:

👉 **[AGENTS.md](../AGENTS.md)**

---

## Resum Ràpid d'Arquitectura

- **Framework**: Flutter 3 (Dart >=3.10.7)
- **Backend & Cloud**: Cloud Firestore, Firebase Authentication, Firebase Hosting
- **Gestió d'Estat**: Provider (`LibraryProvider`, `SettingsProvider`) + Firestore Streams (`StreamBuilder`)
- **UI / UX**: Prestatgeria física oberta amb taulons de fusta (`#D9C5B2`), lloms editorials (`BookSpineWidget`), formularis en Bottom Modals (`AddEditBookBottomSheet`)
- **Plataformes**: Web (`https://llom-23d56.web.app`) i Android (APK directe i OTA)
- **CI / CD**: GitHub Actions (`.github/workflows/deploy.yml`) i `release.ps1`
