# 🤖 AGENTS.md - Context Tècnic i d'Arquitectura per a Llom

Aquest document serveix com a **guia de referència tècnica i d'arquitectura permanent per a agents d'IA i desenvolupadors** que treballin a la base de codi de **Llom**. Conté els patrons, models de dades, directrius de disseny, regles d'integritat i convencions que s'han de respectar estrictament.

---

## 📌 1. Visió General i Filosofia del Projecte

**Llom** és una aplicació multiplataforma (Web i Android) per a la gestió de biblioteques personals i familiars.
La seva filosofia fonamental és la **recreació visual de la prestatgeria física oberta**:
- L'usuari no busca només entre llistes de text o targetes genèriques; visualitza els mobles, baldes i lloms dels seus llibres tal com estan col·locats a casa seva.
- El disseny prioritza l'ergonomia mòbil moderna (**Bottom Modals**), l'accessibilitat per a perfils sènior (contrastos alts, tipografia nítida, mides tàctils generoses) i el treball col·laboratiu en família.

---

## 🎨 2. Directrius Visuals i de Disseny Inviolables

Quan implementis o modifiquis components d'UI, has de respectar aquests principis:

### 🪵 2.1. Prestatgeria Física Oberta (MAI Cards per a Baldes)
- **Prohibit utilitzar contenidors tipus `Card` o caixes blanques aïllades per a cada balda.**
- L'embolcall ha de ser net sobre el fons càlid de l'aplicació (`AppColors.canvas` = `#FDF8F6`).
- **Tauló físic de fusta**: Cada balda té sota els llibres una base horitzontal de fusta de **12px d'alçada**, color beix/fusta càlid **`#D9C5B2`**, amb vora suau `BorderRadius.circular(3)`, vora `Color(0xFFCBB5A1)` i ombra subtil inferior (`BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: Offset(0, 3))`).
- Els llibres reposen directament sobre aquesta base (alineats a `Alignment.bottomCenter`).
- **Capçalera neta de la balda**:
  - Títol: `Balda {index} · {Posició}` (on posició és `Superior`, `Intermèdia`, `Inferior` o `Única`), estil `18sp`, `FontWeight.w600`, color `AppColors.textMain`.
  - Subtítol: `{N} llibres` (o `1 llibre` / `0 llibres`), estil `14sp`, color `AppColors.textMuted`.
  - Botó ràpid: Botó circular amb icona de càmera (`Icons.camera_alt_outlined`) a la dreta per fotografiar la balda directament.
- **Llom fantasma per a baldes buides**:
  - Si `books.isEmpty`, el tauló de fusta roman visible.
  - Sobre el tauló es renderitza un llom fantasma (alçada 160px, amplada 46px, vora translúcida amb `AppColors.primary.withAlpha(130)`, icona `+` i text vertical `"Afegir llibre / foto"`).
  - En prémer-lo, obre directament el formulari d'afegir llibre sense trencar la il·lusió òptica del moble.

### 📕 2.2. Lloms Editorials Realistes (`BookSpineWidget`)
- **Proporcions**:
  - Alçada dinàmica harmonitzada entre **150px i 186px**.
  - Amplada proporcionada entre **41px i 48px** (mai blocs amples de 60px que semblin targetes).
  - Vores superiors arrodonides: `BorderRadius.vertical(top: Radius.circular(6))`.
- **Detalls editorials**:
  - Dues nervadures clàssiques gravades a la part superior (dues línies fines horitzontals).
  - Títol del llibre en vertical retolat de baix a dalt (`RotatedBox` amb `quarterTurns: 3`), centrat, 13sp, negreta, amb `TextOverflow.ellipsis`.
  - Peu del llom: **Número d'ordre net (`#1`, `#2`, `#3`)**, MAI l'ID de base de dades ni un timestamp.
- **Paleta de colors de llom**:
  - Alternança elegant entre terracota corporatiu (`AppColors.primary` / `0xFFE2725B`), blanc porcellana (`0xFFFFFFFF` amb vora subtil) i crema càlid (`0xFFF5EBE6`).

### 📱 2.3. Bottom Modals (Bottom Sheets) vs. AlertDialogs
- **Formularis i Detalls -> Bottom Sheet**:
  - L'alta de llibres, l'edició de llibres, la selecció d'accions i la visualització de detalls s'han de fer SEMPRE amb `showModalBottomSheet` (`isScrollControlled: true`, vores superiors arrodonides a 24px, nansa superior d'arrossegament i amortiment de teclat `viewInsets.bottom`).
- **Alertes Destructives -> AlertDialog centrat**:
  - Els diàlegs centrats es reserven exclusivament per a confirmacions crítiques de seguretat (eliminar llibre, eliminar estanteria, eliminar biblioteca, tancar sessió).

---

## 🗄️ 3. Model de Dades de Cloud Firestore

L'estructura a Firestore està jerarquitzada per biblioteques per permetre la multi-tenència segura:

### 3.1. `users/{userId}`
Perfil de l'usuari autenticat.
```typescript
{
  uid: string,                // ID d'usuari de Firebase Auth
  email: string,              // Adreça de correu
  displayName: string,        // Nom visible
  photoUrl: string?,          // URL d'avatar (opcional)
  activeLibraryId: string?,   // ID de la biblioteca actualment seleccionada
  createdAt: Timestamp        // Data de registre
}
```

### 3.2. `libraries/{libraryId}`
Col·lecció principal de biblioteques.
```typescript
{
  name: string,               // Nom de la biblioteca (ex: "Biblioteca Familiar")
  ownerId: string,            // UID del propietari
  inviteCode: string,         // Codi alfanumèric de 6 caràcters majúscules (ex: "LM7K92")
  members: {                  // Mapa de rols per UID
    [uid: string]: "owner" | "editor" | "viewer"
  },
  memberUids: string[],       // Llista d'UIDs de membres (per a consultes array-contains)
  createdAt: Timestamp        // Data de creació
}
```

### 3.3. `libraries/{libraryId}/bookcases/{bookcaseId}`
Subcol·lecció de mobles d'estanteria.
```typescript
{
  name: string,               // Nom del moble (ex: "Llibreria de Roure", "Balda Passadís")
  room: string,               // Habitació o estança (ex: "Saló", "Estudi")
  shelfCount: number,         // Nombre de baldes físiques (ex: 4)
  bookCount: number,          // Comptador desnormalitzat de llibres en aquest moble
  order: number,              // Ordre manual personalitzat (0, 1, 2...)
  createdAt: Timestamp        // Data de creació
}
```

### 3.4. `libraries/{libraryId}/books/{bookId}`
Subcol·lecció de llibres de la biblioteca.
```typescript
{
  title: string,              // Títol del llibre (obligatori)
  author: string,             // Autor / Autora (opcional)
  shelfCode: string,          // Codi de balda (ex: "{bookcaseId}-B2" o "E1-B2")
  bookcaseId: string?,        // ID del moble al qual pertany
  positionIndex: number,      // Posició o timestamp d'ordenació a la balda
  photoUrl: string?,          // Foto de portada o llom (opcional)
  notes: string?,             // Notes personals (opcional)
  createdAt: Timestamp        // Data d'alta
}
```

### 3.5. Regles d'Integritat i Transaccions
1. **Comptador `bookCount`**:
   - `addBook`: incrementa atòmicament `bookCount` del moble via `FieldValue.increment(1)`.
   - `deleteBook`: decrementa atòmicament `bookCount` via `FieldValue.increment(-1)`.
   - `updateBook`: si canvia de moble (`oldBookcaseId != newBookcaseId`), decrementa l'antic i incrementa el nou en un `WriteBatch`.
2. **Esborrat en cascada**:
   - En esborrar un moble (`deleteBookcase`), s'executa un batch per esborrar tots els documents a `libraries/{libraryId}/books` on `bookcaseId == bookcase.id` abans d'eliminar el document del moble.

---

## 🏛️ 4. Arquitectura de Capes i Gestió d'Estat

```text
       UI / Screens (Flutter Widgets)
                     │
                     ▼
      Providers (ChangeNotifier / StreamBuilder)
                     │
                     ▼
             Services Layer
       (Firestore / Auth / UpdateService)
                     │
                     ▼
     Cloud Firestore / Firebase Auth / Hosting
```

### 4.1. Serveis (`lib/services/`)
- **`AuthService`**: Gestió d'autenticació amb Google Sign-In i correu/contrasenya. Creació automàtica del perfil a `users/{uid}`.
- **`LibraryService`**: Creació de biblioteques amb codi alfanumèric aleatori (6 caràcters), unió per codi, canvi de biblioteca activa i salvaguardes d'eliminació.
- **`BookcaseService`**: CRUD de mobles d'estanteria, ordenació per camp `order`, consultes reactives en temps real via `snapshots()`, gestió atòmica de llibres (`addBook`, `updateBook`, `deleteBook`) i esborrat en cascada.
- **`UpdateService`**: Consulta a Firebase Hosting (`/version.json`), comparació semàntica de versions (`major.minor.patch+build`), descàrrega directa d'APK (`launchUrl`).

### 4.2. Proveïdors d'Estat (`lib/providers/`)
- **`LibraryProvider`**:
  - Manté l'usuari actual (`UserModel?`), la biblioteca activa (`LibraryModel?`) i el rol.
  - Propietats clau: `canEdit` (cert si el rol és `owner` o `editor`), `isOwner` (cert si és `owner`).
  - Mètodes: `loadUserAndLibrary`, `setActiveLibrary`, `leaveLibrary`, `clear`.
- **`SettingsProvider`**:
  - Control de l'escala de text accessible (`textScaleFactor`).

### 4.3. Enrutament (`AuthGate`)
- `AuthGate` escolta els canvis d'estat d'autenticació de Firebase.
- Si no hi ha sessió -> `AuthScreen`.
- Si hi ha sessió però no té biblioteca -> `NoLibraryScreen` o `SetupLibraryScreen`.
- Si hi ha sessió i biblioteca activa -> `HomeScreen`.

---

## 🔄 5. Sistema d'Actualitzacions OTA (Patró Centim)

El sistema permet actualitzacions ràpides sense dependre exclusivament de Google Play:
- **Hosting URL**: `https://llom-23d56.web.app`
- **Metadades**: `https://llom-23d56.web.app/version.json` (`{"version": "1.0.2+3", "apkUrl": "..."}`)
- **APK directe**: `https://llom-23d56.web.app/llom.apk`
- **Comportament per Plataforma**:
  - **Web (`kIsWeb`)**: Botó destacat a `ProfileScreen` per descarregar l'APK per a dispositius Android.
  - **Android (`!kIsWeb`)**:
    - Comprovació silenciosa en segon pla a `HomeScreen` (`_checkForSilentUpdate`). Mostra `SnackBar` flotant amb botó *«Actualitzar»*.
    - Opció de comprovació manual a `ProfileScreen` amb diàleg modal complet.
- **Visor de Release Notes**: Modal de lectura en Markdown que carrega `assets/release_notes.md`.

---

## 🤖 6. Regles i Bones Pràctiques per a Agents d'IA

Quan generis o modifiquis codi en aquest repositori, segueix rigorosament aquestes normes:

1. **Idioma**:
   - Tots els textos d'interfície, botons, diàlegs, alertes, missatges de `SnackBar`, comentaris de codi i documents han d'estar redactats en **català correcte**.
2. **Context de BuildContext a través d'Async Gaps**:
   - MAI utilitzis `context` després d'un `await` sense comprovar prèviament `if (mounted)` o `if (context.mounted)`.
   - Per a missatgers o navegadors, captura la referència abans de la crida asíncrona:
     ```dart
     final messenger = ScaffoldMessenger.of(context);
     final navigator = Navigator.of(context);
     await algunaOperacioAsincrona();
     if (mounted) {
       messenger.showSnackBar(...);
     }
     ```
3. **Plataforma Web vs. Natiu**:
   - MAI importis `dart:io` a fitxers compartits que es compilin a Web. Utilitza la bandera `kIsWeb` de `package:flutter/foundation.dart`.
4. **Validació de Tests i Linter**:
   - Abans de donar qualsevol tasca per completada, has d'executar:
     ```bash
     flutter test
     flutter analyze
     ```
   - **Tots els tests (actualment 77+) han de passar (100% success)** i `flutter analyze` ha de donar **zero errors i zero warnings**.
5. **Manteniment de `TASKS.md`**:
   - Cada tasca completada s'ha de documentar a [TASKS.md](file:///c:/git/llom/TASKS.md) amb el número correlatiu, el checklist de punts clau i el recompte de tests verificats.
6. **Manteniment de `release.ps1`**:
   - Per preparar releases, fes servir el script `.\release.ps1 -Version "X.Y.Z+B" -ReleaseNotes "..."` que manté sincronitzats `pubspec.yaml`, `assets/release_notes.md` i els tags de Git.
