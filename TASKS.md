# 📚 Llom - Registre de Tasques i Full de Ruta

> **Llom**: Biblioteca personal intel·ligent que, a partir de fotografies de les estanteries, classifica i cataloga tots els llibres d'una llibreria casolana.

---

## 📋 Estat de les Tasques

### ✅ Tasca 1: Sistema de disseny i esquelet base
- [x] Crear estructura de carpetes a `lib/`:
  - `lib/core/theme/`
  - `lib/core/constants/`
  - `lib/models/`
  - `lib/services/`
  - `lib/screens/`
  - `lib/widgets/`
- [x] Crear tokens de colors a `lib/core/theme/app_colors.dart`:
  - `canvas`: `#FDF8F6`
  - `surface`: `#FFFFFF`
  - `primary`: `#F2856D`
  - `primaryDark`: `#DE6D54`
  - `accent`: `#F8B4A6`
  - `textMain`: `#2C2220`
  - `textMuted`: `#7D6E6B`
- [x] Crear tema Material 3 a `lib/core/theme/app_theme.dart`:
  - Fons per defecte `AppColors.canvas`
  - `AppBarTheme` transparent/sense ombres amb títol `textMain`
  - `FloatingActionButtonThemeData` salmó vibrant (`primary`) i icona blanca
  - `CardTheme` arrodonit (16px) i fons `surface`
  - `InputDecorationTheme` amb vores `accent`, fons blanc i radi de 14px
- [x] Actualitzar `lib/main.dart`:
  - Inicialització asíncrona de Firebase (`firebase_options.dart`)
  - Integració del tema `AppTheme.lightTheme`

### ✅ Tasca 2: Models de dades per a Cloud Firestore
- [x] Crear `lib/models/shelf_model.dart`:
  - Camps: `id`, `code`, `photoUrl`, `bookCount` (default 0), `createdAt`
  - Mètodes: `toMap()`, `fromMap()`, `copyWith()`, `==`, `hashCode`, `toString()`
- [x] Crear `lib/models/book_model.dart`:
  - Camps: `id`, `title`, `author`, `shelfCode`, `positionIndex`, `photoUrl`, `notes`, `createdAt`
  - Mètodes: `toMap()`, `fromMap()`, `copyWith()`, `==`, `hashCode`, `toString()`
- [x] Suport resilient per a deserialització de dates Firestore (`Timestamp`, `DateTime`, `int`, `String`).

### ✅ Tasca 3: Pantalla d'inici adaptable (UI Sènior) i components de Moble / Balda
- [x] Model de moble `lib/models/shelf_unit_model.dart` (`ShelfUnit`):
  - Camps: `id`, `name`, `location`, `shelfCount`, `bookCount`, `icon`.
  - Mobles de la llar mockejats: Finestra, Porta, Passadís i Despatx.
- [x] Widget accessible de moble `lib/widgets/furniture_card.dart` (`FurnitureCard`):
  - Objectius tàctils generosos (alçada >= 110px, padding folgat, radi 20px).
  - Tipografia d'alta llegibilitat (títol a 21sp en negreta, metadades en 16sp).
  - Icona esquemàtica gran d'estanteria amb fons salmó suau i fletxa gran de navegació.
- [x] Actualització de `lib/widgets/book_card.dart`:
  - Format gran adaptat a accessibilitat sènior, amb indicador de llom, posició i badge de balda clar.
- [x] Pantalla d'inici `lib/screens/home_screen.dart`:
  - Barra de cerca superior prominent amb text «Escriu el títol o autor per trobar el llibre...» i botó per netejar.
  - Graella adaptable responsive mitjançant `LayoutBuilder`:
    - Mòbil (< 600px): 1 columna vertical.
    - Tauleta / Web (600px - 1100px): Graella de 2 columnes centrada.
    - Escriptori / Web ampla (> 1100px): Contenidor limitat a `maxWidth: 1000px`.
  - Navegació contextual:
    - Sense cerca activa: graella gran de mobles. En tocar-ne un, obre la vista de baldes (`ShelfListScreen`).
    - Amb cerca activa: oculta mobles i mostra resultats de llibres coincidents; en tocar un llibre, navega al moble ressaltant la balda i posició.
- [x] Pantalla de baldes de moble `lib/screens/shelf_list_screen.dart`:
  - Vista detallada de les baldes d'un moble seleccionat, selector per xips grans i llistat de llibres.
- [x] Floating Action Button salmó prominent per fotografiar baldes.

### ✅ Tasca 4: Lloms de llibre interactius (BookSpineWidget), baldes físiques (ShelfRowWidget) i ShelfDetailScreen
- [x] Component de llom físic `lib/widgets/book_spine_widget.dart` (`BookSpineWidget`):
  - Representació d'un llibre dret amb amplada fixa (58px) i alçada variable realista (185-210px).
  - Cantonades superiors arrodonides (6px), vora suau i ombra lateral per crear sensació de volum 3D.
  - Nervadures clàssiques dobles a dalt i a baix.
  - Paleta alternada de colors: blanc porcellana, salmó, rosa pàl·lid i sorra càlida.
  - Títol girat de baix a dalt (`RotatedBox(quarterTurns: 3)`) d'alta llegibilitat i posició física a la base.
  - Animació d'elevació vertical dinàmica en fer tap o hover.
  - Ressaltat salmó (`isHighlighted`) i atenuació (`isDimmed` / opacitat 0.28) per filtrat de cerca.
- [x] Component de balda física `lib/widgets/shelf_row_widget.dart` (`ShelfRowWidget`):
  - Capçalera clara amb nom de balda (ex: «Balda 1 · Superior»), recompte de llibres i botó de càmera.
  - Contenidor horitzontal de llibres (`ListView.builder` scroll horitzontal) ordenat per `positionIndex`.
  - Barra física de fusta clara (`#E2D6D2`) a la base amb cantons arrodonits i ombra inferior.
- [x] Pantalla d'estanteria `lib/screens/shelf_detail_screen.dart` (`ShelfDetailScreen`):
  - Llista vertical de totes les baldes de l'estanteria amb desplaçament horitzontal de lloms.
  - Cercador ràpid superior que ressalta els lloms coincidents i atenua la resta en temps real.
  - Modal tàctil (`BottomSheet`) en prémer qualsevol llom amb la informació completa del llibre i la seva posició exacta a la balda.
- [x] Connexió de la navegació des de `HomeScreen` cap a `ShelfDetailScreen`.

### ✅ Tasca 5: Carrusel interactiu Cover Flow de mobles (BookcaseCarousel i BookcaseCard)
- [x] Component de miniatura de moble `lib/widgets/bookcase_card.dart` (`BookcaseCard`):
  - Marc exterior estilitzat (8px, `AppColors.accent` suau) i fons blanc.
  - Baldes interiors reals segons `shelfCount` amb simulació realista de lloms de llibres i taula de fusta.
  - Etiqueta gran a la base amb el nom del moble i recompte de baldes/llibres.
  - Ombra càlida salmó (`BoxShadow`) quan el moble té el focus central.
- [x] Carrusel Cover Flow `lib/widgets/bookcase_carousel.dart` (`BookcaseCarousel`):
  - `PageView.builder` amb interpolació suau d'escala (1.0 centre, 0.85 lateral) i opacitat (1.0 centre, 0.55 lateral).
  - Proporció adaptativa: `viewportFraction: 0.78` en mòbil i `0.55` en tauleta/web per veure els mobles veïns.
  - Botons flotants circulars laterals (`<` i `>`) amb fons blanc i icona salmó per navegar tàctilment o per clic.
  - Interacció intel·ligent: tocar el moble central obre el detall (`ShelfDetailScreen`); tocar un lateral anima el carrusel per centrar-lo.
- [x] Integració a `lib/screens/home_screen.dart`:
  - El carrusel Cover Flow substitueix la graella estàtica quan no hi ha cerca activa.
  - En escriure a la cerca superior, el carrusel s'amaga i es mostren els llibres coincidents.

### ✅ Tasca 6: Cerca global agrupada per moble i navegació amb paràmetres de focus
- [x] Lògica de cerca global a `lib/screens/home_screen.dart`:
  - Filtratge per títol i autor sobre la col·lecció completa.
  - Agrupació dels resultats de cerca per moble d'origen (`ShelfUnit`).
  - Capçaleres clares i destacades per cada moble (ex: «Trobat a Estanteria 1 · Finestra (2 llibres)»).
  - Targetes de llibre que mostren títol gran, autor, format «Balda X» i posició «#X d'esquerra a dreta».
- [x] Navegació contextual amb paràmetres de focus:
  - Obertura de `ShelfDetailScreen` passant `bookcase`, `initialShelfId` i `highlightBookId`.
- [x] Efecte de ressaltat a `lib/screens/shelf_detail_screen.dart` i `BookSpineWidget`:
  - Desplaçament automàtic (`Scrollable.ensureVisible`) fins a la balda seleccionada.
  - Desplaçament horitzontal automàtic dins la balda per situar el llom al camp de visió.
  - Llom coincident acolorit en salmó (`AppColors.primary`), elevat permanentment 16px i amb fletxa indicadora superior assenyalant-lo.
  - Atenuació de la resta de lloms de la balda a opacitat 0.4 per focalitzar la mirada directament sobre el llibre trobat.
- [x] Centralització de dades a `lib/core/constants/mock_data.dart`.

### ✅ Tasca 7: Millora d'usabilitat i Navegació Intel·ligent (Smart Routing) a HomeScreen
- [x] Millores d'accessibilitat i targetes de resultats (`BookCard`):
  - Targeta 100% interactiva amb `InkWell` i efecte splash suau.
  - Botó d'acció explícit substituint el badge petit: «Anar a Balda X →» amb fons salmó suau i fletxa gran.
  - Capçalera de moble destacada amb icona circular generosa (48x48px) i ombra suau per ràpida identificació física.
- [x] Lògica de navegació intel·ligent (Smart Routing):
  - **Cas 1 (1 resultat únic)**: En prémer el resultat o prémer Intro al teclat (`onSubmitted`), salta directament a `ShelfDetailScreen` amb scroll a la balda i el llom destacat.
  - **Cas 2 (Múltiples resultats a la mateixa estanteria)**:
    - Botó gran destacat a la capçalera de resultats: «Veure tots els llibres destacats a [Moble] →».
    - En prémer el botó o Intro al teclat, obre `ShelfDetailScreen` amb `initialSearchQuery`, ressaltant tots els llibres de l'autor alhora.
    - Acció per obrir l'estanteria sencera directament des de la capçalera de grup.
  - **Cas 3 (Resultats repartits)**: Vista agrupada per mobles amb selecció individual o de moble.
- [x] Transició neta i reactiva: Neteja d'estat immediata amb la 'x' sense parpellejos, restaurant el carrusel Cover Flow i preservant el disseny responsive (màxim 1000px).

### ✅ Tasca 8: Capa d'autenticació amb Firebase Auth i models multibiblioteca
- [x] Model d'usuari `lib/models/user_model.dart` (`UserModel`):
  - Camps: `uid`, `email`, `displayName`, `activeLibraryId`, `createdAt`.
  - Mètodes: `toMap()`, `fromMap()`, `copyWith()`, `==`, `hashCode`, `toString()`.
  - Deserialització resilient per a `Timestamp`, `DateTime`, `String` i `int`.
- [x] Model de biblioteca `lib/models/library_model.dart` (`LibraryModel`):
  - Camps: `id`, `name`, `ownerId`, `inviteCode`, `members`, `createdAt`.
  - Enum `Role` (`owner`, `editor`, `viewer`, `none`) amb serialització i deserialització.
  - Mètode auxiliar `Role getUserRole(String uid)` amb suport de fallback per a `ownerId`.
  - Mètodes: `toMap()`, `fromMap()`, `copyWith()`, `==`, `hashCode`, `toString()`.
- [x] Servei d'autenticació `lib/services/auth_service.dart` (`AuthService`):
  - Instàncies de `FirebaseAuth` i `FirebaseFirestore` amb injecció per a tests.
  - `Stream<User?> get authStateChanges` i getter `currentUser`.
  - Gestió d'errors mitjançant `AuthException` amb traducció de codis d'error a missatges amigables en català (`email-already-in-use`, `weak-password`, `invalid-email`, `user-not-found`, `wrong-password`, etc.).
  - Mètodes asíncrons:
    - `Future<UserModel> registerWithEmail(...)`: Crea l'usuari a Firebase Auth, actualitza displayName si escau, desa el document a `users/{uid}` i retorna `UserModel`.
    - `Future<UserModel> signInWithEmail(...)`: Inicia sessió i recupera el document Firestore de `users/{uid}` (amb creació transparent de document base en cas de no existir).
    - `Future<void> signOut()`: Tanca la sessió a Firebase Auth.
    - `Future<UserModel?> getCurrentUserData()`: Obté les dades de l'usuari actual des de Firestore.
- [x] Suite de tests per a `UserModel`, `LibraryModel` i `AuthException` (`18 de 18 tests superats`).

### ✅ Tasca 9: Servei de Biblioteques (LibraryService) i gestió de membres
- [x] Actualització de `lib/models/library_model.dart`:
  - Afegit el camp `memberUids` (`List<String>`) per a consultes Firestore indexades amb `.where('memberUids', arrayContains: uid)`.
  - Actualitzats `toMap()`, `fromMap()`, `copyWith()`, `==`, `hashCode`, `toString()` amb retrocompatibilitat i fallback automàtic des de `members`.
- [x] Implementació de `lib/services/library_service.dart` (`LibraryService`):
  - Instància de `FirebaseFirestore` amb avaluació mandrosa (*lazy evaluation*) per evitar inicialitzacions primerenques en tests unitaris.
  - Generador alfanumèric de codis d'invitació de 6 caràcters en majúscules (ex: `LM7K92`).
  - Gestió d'errors amb missatges amigables en català mitjançant `LibraryException`.
  - Mètodes principals atòmics (`WriteBatch`):
    - `Future<LibraryModel> createLibrary(...)`: Crea la biblioteca amb `ownerId`, `members: {ownerUid: "owner"}`, `memberUids: [ownerUid]`, actualitza `users/$ownerUid.activeLibraryId` de forma atòmica i retorna la instància.
    - `Future<LibraryModel> joinLibraryByCode(...)`: Cerca per codi en majúscules netejat, afegeix l'usuari a `members` amb el rol assignat i a `memberUids` via `FieldValue.arrayUnion`, fixa `activeLibraryId` i retorna la biblioteca.
    - `Stream<List<LibraryModel>> getUserLibraries(...)`: Escolta en temps real les biblioteques de l'usuari ordenades per `createdAt` descendent.
    - `Future<void> updateMemberRole(...)`: Verifica que el sol·licitant sigui `owner` abans d'assignar rol `editor` o `viewer` a un altre membre.
    - `Future<void> removeMember(...)`: Permet expulsar un membre si el sol·licitant és `owner` o sortida voluntària, netejant `members`, `memberUids` i restablint `activeLibraryId` si escau.
    - `Future<String> regenerateInviteCode(...)`: Regenera un nou codi d'invitació d'accés exclusiu per al propietari.
- [x] Suite de tests ampliada a [test/library_service_test.dart](file:///c:/git/llom/test/library_service_test.dart) i [test/models_test.dart](file:///c:/git/llom/test/models_test.dart) (**24 de 24 tests superats**).

### ✅ Tasca 10: Gestor d'estat de biblioteca activa (LibraryProvider) i persistència local
- [x] Afegides dependències a `pubspec.yaml`:
  - `shared_preferences: ^2.3.2` (persistència de la biblioteca activa entre reinicis).
  - `provider: ^6.1.2` (gestió d'estat reactiva a l'arbre de widgets).
- [x] Implementació de `lib/providers/library_provider.dart` (`LibraryProvider`):
  - Propietats d'estat: `currentUser`, `activeLibrary`, `userLibraries`, `isLoading`, `errorMessage`.
  - Getters per a rols i accessibilitat sènior:
    - `hasActiveLibrary`: Indica si hi ha una biblioteca seleccionada.
    - `currentRole`: Retorna el rol actual (`owner`, `editor` o `viewer`).
    - `isOwner`: Comprova si l'usuari és el propietari.
    - `canEdit`: Comprova permisos d'edició (`owner` o `editor`).
    - `isViewerOnly`: Mode sènior / consulta estricta (`viewer`).
  - Mètodes principals:
    - `Future<void> initialize(UserModel user)`: Carrega biblioteques en temps real, recupera `active_library_id` de `SharedPreferences` (o `user.activeLibraryId`), amb selecció automàtica de la primera biblioteca com a fallback resilient.
    - `Future<void> switchLibrary(LibraryModel library)`: Canvia la biblioteca activa, persisteix l'ID a `SharedPreferences` i actualitza `users/$uid.activeLibraryId` en segon pla.
    - `Future<bool> createAndSelectLibrary(String name)`: Crea una biblioteca a través de `LibraryService` i la selecciona com a activa immediatament.
    - `Future<bool> joinAndSelectLibrary(String inviteCode)`: S'uneix per codi d'invitació i la fixa com a biblioteca activa.
- [x] Connexió global a `lib/main.dart`:
  - `LlomApp` integrat amb `MultiProvider` i `ChangeNotifierProvider<LibraryProvider>` disponible a tot l'arbre de widgets.
- [x] Suite de tests ampliada a [test/library_provider_test.dart](file:///c:/git/llom/test/library_provider_test.dart) (**27 de 27 tests superats**).

### ✅ Tasca 11: Pantalla d'autenticació accessible (AuthScreen) i passarel·la de sessió (AuthGate)
- [x] Passarel·la de sessió `lib/screens/auth_gate.dart` (`AuthGate`):
  - `StreamBuilder<User?>` escoltant `AuthService.authStateChanges` en temps real.
  - Sense sessió activa: Mostra `AuthScreen`.
  - Amb sessió activa:
    - Recupera el perfil `UserModel` i crida `LibraryProvider.initialize(user)`.
    - Mostra indicador de càrrega càlid circular amb `AppColors.primary` durant la sincronització.
    - Si l'usuari té biblioteca activa (`hasActiveLibrary`), navega a `HomeScreen`.
    - Si no en té cap, obre `SetupLibraryScreen` per crear o unir-se a una biblioteca.
- [x] Pantalla d'autenticació adaptable `lib/screens/auth_screen.dart` (`AuthScreen`):
  - Disseny responsive per a gent gran: centrat a `maxWidth: 460px` en tauleta/web i marges de 24px en mòbil, fons blanc i cantonades de 24px.
  - Capçalera càlida: Monograma circular salmó, títol gran de 28sp «Benvingut a Llom» i subtítol «El catàleg visual dels teus llibres a casa».
  - Commutador de pestanyes grans entre «Entrar» i «Crear compte».
  - Camps de formulari accessibles: text de 18sp, padding còmode, camp nom en registre, correu amb teclat dedicat i contrasenya amb botó d'ull gran per mostrar/ocultar.
  - Validacions en català i contenidor destacat per a missatges d'error (`AuthException`).
  - Botó d'acció salmó prominent de 56px d'alçada amb text de 18sp i indicador de progrés circular blanc.
- [x] Flux de biblioteca inicial `lib/screens/setup_library_screen.dart` (`SetupLibraryScreen`):
  - Permet a l'usuari nou sense biblioteques crear-ne una o unir-se mitjançant codi d'invitació.
- [x] Connexió a `lib/main.dart`:
  - `LlomApp` configura `home: home ?? const AuthGate()` mantenint la capacitat de sobreescriptura en proves de widgets.
- [x] Suite de tests ampliada a [test/auth_screen_test.dart](file:///c:/git/llom/test/auth_screen_test.dart) (**31 de 31 tests superats**).

### ✅ Tasca 12: Interfície multibiblioteca, diàlegs d'acció i adaptació de rols
- [x] Pantalla d'acollida sense biblioteca `lib/screens/no_library_screen.dart` (`NoLibraryScreen`):
  - Es mostra automàticament des d'`AuthGate` quan l'usuari autenticat no té cap biblioteca activa.
  - Disseny net i centrat (`maxWidth: 500px`): icona gran de biblioteca en badge salmó, títol gran de 24sp «Encara no tens cap biblioteca» i subtítol explicatiu.
  - Botó 1 salmó prominent «Crear una biblioteca nova» i Botó 2 «Unir-me amb codi d'invitació».
- [x] Diàlegs d'acció modals `lib/widgets/library_dialogs.dart`:
  - `showCreateLibraryDialog`: Input gran per al nom, validació, crida a `LibraryProvider.createAndSelectLibrary` i confirmació per SnackBar.
  - `showJoinLibraryDialog`: Input alfanumèric en majúscules de 6 caràcters (`letterSpacing: 4`), crida a `LibraryProvider.joinAndSelectLibrary` i missatge d'error en banner vermell si no és vàlid.
  - `showShareLibraryDialog`: Targeta destacada amb tipografia monoespaiada de 32sp i fons suau (`AppColors.accent`), botó per copiar al porta-retalls (`Clipboard.setData`), i llistat de membres i rols (per al propietari).
- [x] Selector de biblioteca a `HomeScreen`:
  - Capçalera dinàmica amb el nom de la biblioteca activa (ex: «Biblioteca Cal Jeroni ▾») acompanyada del badge de llibres.
  - En prémer-lo, desplega un `ModalBottomSheet` arrodonit (28px) amb la llista de biblioteques de l'usuari (marcant l'activa amb un check per canviar de forma immediata).
  - Accés a «Compartir codi d'invitació» (visible només per a propietaris o editors).
  - Accions ràpides: «Crear nova biblioteca», «Unir-me amb codi» i «Tancar sessió».
- [x] Adaptació estricta per al rol sènior / consulta (`isViewerOnly` / `!canEdit`):
  - A `HomeScreen` i `ShelfDetailScreen`, quan `canEdit == false`:
    - S'amaga completament el `FloatingActionButton` («Afegir balda / Foto»).
    - S'amaguen les icones de càmera a la dreta de cada balda física a `ShelfRowWidget`.
- [x] Suite de tests ampliada a [test/library_ui_test.dart](file:///c:/git/llom/test/library_ui_test.dart) (**39 de 39 tests superats**).

### ✅ Tasca 13: Autenticació amb Google (Google Sign-In) Web & Mòbil
- [x] Dependència i configuració:
  - Afegit paquet `google_sign_in: ^6.2.2` a `pubspec.yaml` i resoltes dependències compatibles.
- [x] Servei d'autenticació a `lib/services/auth_service.dart`:
  - Mètode `Future<UserModel> signInWithGoogle()` amb suport per injecció de `GoogleSignIn` per a proves unitàries.
  - Ramificació multiplataforma:
    - En Web (`kIsWeb`): Ús directe de `signInWithPopup(GoogleAuthProvider())`.
    - En Mòbil/Android: Flux coordinat amb `GoogleSignIn().signIn()` i `GoogleAuthProvider.credential(idToken, accessToken)`.
  - Persistència i recuperació a Cloud Firestore:
    - Comprovació de document existent a `users/{user.uid}`.
    - Nou registre: Creació de document amb camps `{uid, email, displayName, activeLibraryId: null, createdAt}`.
    - Sessió recurrent: Recuperació del `UserModel` existent respectant el seu `activeLibraryId`.
  - Gestió d'errors i cancel·lacions:
    - Retorn net i silenciós davant cancel·lacions d'usuari (`code: 'cancelled'`, finestra emergent tancada) sense alarmes visuals falses.
    - Mapeig de codis d'error de Firebase Auth a missatges amigables en català.
- [x] Disseny i accessibilitat a `lib/screens/auth_screen.dart`:
  - Separador subtil amb línies horitzontals i text «o bé» en `AppColors.textMuted`.
  - Botó accessible gran de 56px d'alçada: fons blanc (`AppColors.surface`), vora suau (`AppColors.accent`) i tipografia en negreta (17sp, `AppColors.textMain`) «Continua amb Google».
  - Monograma oficial vectorial de 4 colors de Google (`GoogleLogoWidget` a `lib/widgets/google_logo_widget.dart`) sense dependències d'actius externs.
  - Estat de càrrega independent amb `CircularProgressIndicator` salmó (`AppColors.primary`) mentre s'efectua la connexió amb Google.
  - Bloqueig coordinat d'entrades (`_isLoading || _isGoogleLoading`) per prevenir peticions duplicades.
- [x] Suite de tests ampliada a [test/auth_screen_test.dart](file:///c:/git/llom/test/auth_screen_test.dart) (**42 de 42 tests superats**).

### ✅ Tasca 14: Resolució del bucle d'inicialització a AuthGate i optimització de Firestore
- [x] Correcció de la consulta de biblioteques a `lib/services/library_service.dart`:
  - Eliminada la restricció `.orderBy('createdAt', descending: true)` combinada amb `arrayContains: uid` a la consulta de Firestore, que fallava per manca d'índex compost (`cloud_firestore/failed-precondition`).
  - L'ordenació per data de creació es realitza ara en memòria a Dart (`libraries.sort(...)`), funcionant de manera immediata i sense requerir cap índex compost a Firebase Console.
- [x] Correcció del cicle de vida d'estat a `lib/screens/auth_gate.dart`:
  - Quan un usuari inicia sessió (`_initializedUid != user.uid`), es mostra directament l'estat de càrrega (`Carregant les teves biblioteques...`), evitant que es renderitzi `NoLibraryScreen` durant un fotograma abans d'iniciar la càrrega.
  - La marca d'inicialització `_initializedUid = user.uid` s'estableix sempre dins un bloc `finally`, evitant que qualsevol excepció provoqui crides repetitives i un bucle infinit entre la pantalla de càrrega i «Encara no tens cap biblioteca».
- [x] Suite de tests ampliada a [test/auth_gate_test.dart](file:///c:/git/llom/test/auth_gate_test.dart) (**45 de 45 tests superats**).

---

## 🚀 Propers Passos
*(S'aniran afegint a mesura que es defineixin noves tasques)*





