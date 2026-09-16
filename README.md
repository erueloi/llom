# 📚 Llom - Gestor Visual de Biblioteques Personals

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth%20%7C%20Hosting-FFCA28?logo=firebase)](https://firebase.google.com)
[![Version](https://img.shields.io/badge/Version-1.0.2%2B3-E2725B)](pubspec.yaml)
[![Tests](https://img.shields.io/badge/Tests-77%2F77%20passing-success)](test/)
[![License](https://img.shields.io/badge/License-Proprietary-lightgrey)](#)

**Llom** és una aplicació multiplataforma (Web i Android) dissenyada per catalogar, organitzar i gaudir de biblioteques personals i familiars. A diferència dels gestors de llibres abstractes o basats en llistes planes, **Llom recrea visualment la disposició física dels teus mobles i baldes**, permetent identificar els llibres pel seu llom com si fossis davant de la teva prestatgeria.

---

## ✨ Característiques Principals

### 🪵 1. Disseny de Prestatgeria Física Oberta
- **Sense targetes aïllades (*No Cards*)**: L'aplicació transmet la continuïtat d'un moble obert de fusta, no una llista de targetes genèriques de configuració.
- **Taulons físics de fusta (`#D9C5B2`)**: Base de suport horitzontal amb ombra subtil sobre la qual reposen els llibres.
- **Capçaleres netes amb posició**: Cada balda indica el seu ordre i posició física (`Balda 1 · Superior`, `Balda 2 · Intermèdia`, `Balda 3 · Inferior`), el nombre de llibres catalogats i un botó circular directe per fotografiar-la.
- **Llom fantasma per a baldes buides**: Si una balda no conté llibres, mostra una silueta estilitzada de llom amb vora translúcida i text vertical convidant a catalogar sense trencar la il·lusió del moble.

### 📕 2. Lloms Editorials Realistes (`BookSpineWidget`)
- **Proporcions visuals equilibrades**: Alçades realistes (150px - 186px) i amplades proporcionades (41px - 48px).
- **Detalls d'enquadernació clàssica**: Dues nervadures fines gravades a la part superior del llom.
- **Títol vertical llegible**: Retolat en vertical centrat amb rotació de 90° (`RotatedBox`), mida optimitzada i tall amb el·lipsi per a títols llargs.
- **Peu amb ordre net**: Mostra l'ordre físic correlatiu (`#1`, `#2`, `#3`), sense IDs interns ni hashes de base de dades.
- **Paleta de colors harmonitzada**: Alternança elegant entre terracota corporatiu (`AppColors.primary`), blanc porcellana amb vora fina i to crema càlid (`#F5EBE6`).

### 📱 3. Bottom Modals Modernes i Ergonòmiques
- **Formularis adaptables**: Tota la interacció d'alta, edició i detall de llibres es realitza mitjançant **Modal Bottom Sheets** modernes (`AddEditBookBottomSheet`).
- **Thumb-friendly & Teclat fluid**: S'ajusten de forma natural a la zona inferior de la pantalla i s'eleven fluidament per sobre del teclat virtual (`viewInsets.bottom`).
- **Nansa d'arrossegament (*Drag Handle*)**: Permet tancar lliscant cap avall (*swipe down to dismiss*).
- **Accions completes de llibre**: Des del detall del llibre es pot consultar la balda, editar dades (títol, autor, balda de destí) o eliminar-lo amb confirmació de seguretat destructiva.

### 👥 4. Gestió Col·laborativa de Biblioteques
- **Codis d'invitació únics**: Comparteix la biblioteca familiar mitjançant un codi alfanumèric de 6 caràcters (`LM7K92`).
- **Sistema de Rols**: Control granular d'accés (`owner`, `editor`, `viewer`).
- **Multi-biblioteca**: Canvia fàcilment entre diferents biblioteques des del perfil d'usuari.
- **Salvaguardes de seguretat**: Per eliminar una biblioteca o moble, es requereix confirmació explícita per evitar pèrdues accidentals.

### 🔄 5. Actualitzacions OTA i Descàrrega d'APK (Patró Centim)
- **Descàrrega d'APK des de la Web**: En entorns Web (`kIsWeb`), la pantalla de perfil ofereix un botó destacat per descarregar l'APK per a tauletes o mòbils Android.
- **Comprovació d'actualitzacions en segon pla**: A Android (`!kIsWeb`), l'app comprova silenciosament si hi ha una versió més recent a Firebase Hosting (`https://llom-23d56.web.app/version.json`) i avisa mitjançant un `SnackBar` flotant amb l'acció *«Actualitzar»*.
- **Comprovació manual i Release Notes**: Des de la pantalla de perfil es pot forçar la comprovació d'actualitzacions i consultar l'historial de novetats en Markdown (`assets/release_notes.md`).

### ♿ 6. Accessibilitat Sènior
- Paleta d'alt contrast i tons càlids relaxants (`AppColors.canvas`, `AppColors.primaryDark`).
- Suport complet per a escalat de text dinàmic (`textScaler`).
- Etiquetes semàntiques (`Semantics`) per a lectors de pantalla a cada llom i acció.

---

## 🏗️ Arquitectura i Estructura del Projecte

El projecte segueix una arquitectura per capes modular, desacoblada i orientada a dominis:

```text
llom/
├── assets/                  # Fitxers estàtics (release_notes.md, imatges)
├── lib/
│   ├── core/
│   │   ├── constants/       # Dades de prova (MockData) i valors immutables
│   │   └── theme/           # Paleta de colors (AppColors) i AppTheme
│   ├── models/              # Models immutables (BookModel, BookcaseModel, LibraryModel, UserModel)
│   ├── providers/           # Gestió d'estat (LibraryProvider, SettingsProvider)
│   ├── screens/             # Pantalles completes de flux (AuthGate, HomeScreen, BookshelfDetailScreen, ProfileScreen...)
│   ├── services/            # Lògica de dades i APIs (AuthService, LibraryService, BookcaseService, UpdateService)
│   ├── widgets/             # Components d'UI reutilitzables (BookSpineWidget, AddEditBookBottomSheet...)
│   ├── firebase_options.dart# Configuració generada per FlutterFire
│   └── main.dart            # Punt d'entrada de l'aplicació
├── test/                    # Suite de 77+ tests unitaris i de widgets
├── .github/workflows/       # CI/CD amb GitHub Actions (deploy.yml)
├── firestore.rules          # Regles de seguretat de Cloud Firestore
├── firebase.json            # Configuració del hosting i serveis Firebase
├── pubspec.yaml             # Dependències del projecte i versió
└── release.ps1              # Script d'automatització de versions i llançaments
```

---

## 🚀 Com Començar

### Prerequisits
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versió `>=3.10.7`)
- [Dart SDK](https://dart.dev)
- Compte de Firebase amb Firestore i Firebase Authentication configurats.

### Instal·lació i Execució Local

1. **Clonar el repositori**:
   ```bash
   git clone https://github.com/erueloi/llom.git
   cd llom
   ```

2. **Instal·lar dependències**:
   ```bash
   flutter pub get
   ```

3. **Executar en mode desenvolupament**:
   ```bash
   # Executar a Chrome / Web
   flutter run -d chrome

   # Executar a dispositiu Android o emulador
   flutter run -d android
   ```

---

## 🧪 Qualitat del Codi i Tests

El projecte compta amb una exhaustiva suite de proves unitàries i de components per garantir zero regressions:

```bash
# Executar tots els tests (77+ tests)
flutter test

# Verificar estil i linter
flutter analyze
```

---

## 📦 Sistema de Releases i Desplegament

Llom utilitza un sistema de llançament automatitzat inspirat en el flux de *Centim*:

1. **Llançar una nova versió**:
   Executa el script de PowerShell a l'arrel del projecte:
   ```powershell
   .\release.ps1 -Version "1.0.2+3" -ReleaseNotes "- Resum dels canvis i millores..."
   ```

2. **Què fa el script automàticament**:
   - Actualitza la clau `version:` a `pubspec.yaml`.
   - Prependrà la nova versió i notes a `assets/release_notes.md`.
   - Crea un commit de Git i un tag annotat `vX.X.X+X`.
   - Puja els canvis a GitHub (`git push origin --tags`).

3. **CI/CD Automàtic (`.github/workflows/deploy.yml`)**:
   - En rebre el tag `v*`, compila automàticament:
     - L'**APK Android** (`app-release.apk`).
     - La versió **Web Release**.
   - Genera el fitxer `version.json` amb la URL de l'APK.
   - Desplega les regles de Firestore i la web a **Firebase Hosting** (`https://llom-23d56.web.app`).

---

## 📄 Documentació Tècnica per a Agents i Desenvolupadors

Per a detalls a fons sobre el model de dades de Firestore, transaccions, esborrats en cascada, directrius de disseny i especificacions d'arquitectura, consulta:
- 👉 **[AGENTS.md](file:///c:/git/llom/AGENTS.md)**: Guia tècnica d'arquitectura i context continu per a agents d'IA.
- 👉 **[docs/ARCHITECTURE.md](file:///c:/git/llom/docs/ARCHITECTURE.md)**: Resum d'arquitectura del sistema.

