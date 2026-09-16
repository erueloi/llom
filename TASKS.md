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

### ✅ Tasca 15: Configuració i desplegament de regles de seguretat de Cloud Firestore
- [x] Fitxer de regles de seguretat [firestore.rules](file:///c:/git/llom/firestore.rules):
  - Definició de permisos de lectura i escriptura per a usuaris autenticats (`request.auth != null`) a les col·leccions `users`, `libraries`, `shelves` i `books`.
- [x] Configuració de projecte a [firebase.json](file:///c:/git/llom/firebase.json) i [.firebaserc](file:///c:/git/llom/.firebaserc):
  - Vinculat al projecte Firebase `llom-23d56`.
- [x] Desplegament complet amb Firebase CLI:
  - Executat `firebase deploy --only firestore:rules --project llom-23d56` amb èxit, permetent la creació i escriptura de biblioteques i usuaris a Firestore.

### ✅ Tasca 16: Gestió d'esborrat/sortida de biblioteques amb salvaguardes i sincronització d'estanteries a Firestore
- [x] Regles de Firestore a [firestore.rules](file:///c:/git/llom/firestore.rules):
  - Afegit suport per a subcol·leccions de biblioteques (`libraries/{libraryId}/{document=**}`).
  - Desplegat a Firebase amb `firebase deploy --only firestore:rules --project llom-23d56`.
- [x] Model d'estanteria a [lib/models/bookcase_model.dart](file:///c:/git/llom/lib/models/bookcase_model.dart):
  - Camps: `id`, `name`, `room`, `shelfCount`, `bookCount`, `createdAt`.
  - Mètodes: `toMap()`, `fromMap()`, `copyWith()` i `toShelfUnit()` per a compatibilitat nativa amb els widgets de carrusel existents.
- [x] Servei d'estanteries a [lib/services/bookcase_service.dart](file:///c:/git/llom/lib/services/bookcase_service.dart):
  - Stream en temps real `getBookcases(libraryId)` sota `libraries/{libraryId}/bookcases`.
  - Mètodes `addBookcase(libraryId, bookcase)` i `deleteBookcase(libraryId, bookcaseId)`.
  - Resilient davant entorns de test sense Firebase inicialitzat.
- [x] Gestió d'esborrat i sortida a [lib/services/library_service.dart](file:///c:/git/llom/lib/services/library_service.dart) i [lib/providers/library_provider.dart](file:///c:/git/llom/lib/providers/library_provider.dart):
  - `leaveLibrary({required String libraryId, required String uid})`: elimina l'usuari de `members` i `memberUids`, i canvia automàticament a una altra biblioteca o `NoLibraryScreen`.
  - `deleteLibrary({required String libraryId, required String ownerUid})`: comprova que sigui l'amo, esborra el document a Firestore i reassigna la biblioteca activa.
- [x] Diàlegs amb salvaguarda a [lib/widgets/library_dialogs.dart](file:///c:/git/llom/lib/widgets/library_dialogs.dart):
  - Diàleg de sortida amigable: `showLeaveLibraryDialog`.
  - Diàleg de seguretat crítica: `showDeleteLibraryDialog` amb advertiment vermell ("Aquesta acció no es pot desfer"), avís d'esborrat de mobles i llibres, i camp de text on cal escriure exactament el nom de la biblioteca per desbloquejar el botó vermell «Eliminar definitivament».
  - Diàleg de creació d'estanteries: `showAddBookcaseDialog` amb selector d'habitació (`Menjador`, `Estudi`, `Dormitori`, etc.) i nombre de baldes (1-8).
- [x] Connexió a la pantalla principal [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart):
  - Opcions vermelles contextuals al menú desplegable de canvi de biblioteca (Sortir si membre, Eliminar si amo).
  - Connexió amb `_bookcaseService.getBookcases(activeLibrary.id)`:
    - Si la biblioteca està buida: Disseny d'acollida net amb botó «Afegir la primera estanteria».
    - Si té estanteries: Visualització dinàmica en format Cover Flow 3D (`BookcaseCarousel`).
    - Compatibilitat amb tests de widgets independents mitjançant fallback.
- [x] Suite de tests unitària i de widgets:
  - [test/bookcase_test.dart](file:///c:/git/llom/test/bookcase_test.dart): Proves del model i serialització de `BookcaseModel`.
  - [test/library_safeguard_test.dart](file:///c:/git/llom/test/library_safeguard_test.dart): Proves de salvaguardes del diàleg d'esborrat i sortida.
  - **50 de 50 tests superats** a `flutter test` i 0 advertències a `flutter analyze`.

### ✅ Tasca 17: Pantalla de Perfil d'Usuari ('ProfileScreen') i Preferències d'Accessibilitat
- [x] Model d'usuari a [lib/models/user_model.dart](file:///c:/git/llom/lib/models/user_model.dart):
  - Afegit camp opcional `photoUrl` a `UserModel`, amb persistència a `toMap()`, `fromMap()` i `copyWith()`.
- [x] Servei d'autenticació i passarel·les:
  - Propagació de `user.photoURL` a [lib/services/auth_service.dart](file:///c:/git/llom/lib/services/auth_service.dart) (a `signInWithGoogle`, registre i recuperació d'usuari) i [lib/screens/auth_gate.dart](file:///c:/git/llom/lib/screens/auth_gate.dart).
- [x] Estat de biblioteques i sessió a [lib/providers/library_provider.dart](file:///c:/git/llom/lib/providers/library_provider.dart):
  - Afegit mètode `clear()` per cancel·lar subscripcions i netejar l'estat local de biblioteques en tancar sessió.
- [x] Preferències d'accessibilitat globals (UI Sènior):
  - Creat [lib/providers/settings_provider.dart](file:///c:/git/llom/lib/providers/settings_provider.dart) amb persistència a `SharedPreferences` (`extra_large_text`).
  - Integrat a [lib/main.dart](file:///c:/git/llom/lib/main.dart) amb escalat tipogràfic global via `MediaQuery.copyWith(textScaler: TextScaler.linear(isExtraLargeText ? 1.25 : 1.0))`.
- [x] Diàleg compartit de biblioteques a [lib/widgets/library_dialogs.dart](file:///c:/git/llom/lib/widgets/library_dialogs.dart):
  - Funció `showLibrarySelectorSheet(context)` reutilitzable tant des de la capçalera de `HomeScreen` com des del botó de gestió de compte a `ProfileScreen`.
- [x] Pantalla de Perfil a [lib/screens/profile_screen.dart](file:///c:/git/llom/lib/screens/profile_screen.dart):
  - Disseny responsive centrat (`maxWidth: 550px`, fons `AppColors.canvas`).
  - Capçalera d'usuari: Avatar gran (80px) amb imatge de Google o inicial amb fons `AppColors.accent`, nom complet (24sp negreta), correu i badge arrodonit amb el rol a la biblioteca activa (`👑 Propietari/a`, `✏️ Editor/a`, `👁️ Lector/a`).
  - Secció d'accessibilitat: Targeta blanca amb `SwitchListTile` per al mode de text extra gran i informació de la versió de l'aplicació (`1.0.0 (v1)`).
  - Accions de compte: Botó d'acció gran per canviar de biblioteca activa i botó d'estil suau per tancar sessió amb diàleg ràpid de confirmació i retorn a `AuthGate`.
- [x] Accés des de la capçalera de [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart):
  - Afegit `CircleAvatar` tàctil a `AppBar.actions` que mostra la foto o inicial de l'usuari i obre `ProfileScreen`.
- [x] Suite de tests unitària i de widgets:
  - Proves de `UserModel` amb `photoUrl` a [test/models_test.dart](file:///c:/git/llom/test/models_test.dart).
  - Proves integrals a [test/profile_screen_test.dart](file:///c:/git/llom/test/profile_screen_test.dart) per a la renderització d'informació, commutador de text gran, versió, diàleg de tancament de sessió i navegació des de `HomeScreen`.
  - **55 de 55 tests superats (100% èxit)** i 0 advertències a `flutter analyze`.

### ✅ Tasca 18: Correccions d'avatar d'usuari, comptador dinàmic de llibres i estil de botó destructiu
- [x] Avatar amb inicial de reserva robusta a [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart) i [lib/screens/profile_screen.dart](file:///c:/git/llom/lib/screens/profile_screen.dart):
  - Utilització de `foregroundImage` i `onForegroundImageError` al `CircleAvatar` per gestionar tant `user.photoUrl == null` com errors de descàrrega de xarxa.
  - Renderització de la inicial del nom en majúscules en to salmó fosc (`AppColors.primaryDark`), `FontWeight.bold`:
    - Capçalera (`HomeScreen`): mida 22sp.
    - Perfil (`ProfileScreen`): mida 36sp.
- [x] Comptador dinàmic de llibres a [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart):
  - Eliminat el valor estàtic mockejat «379 llibres».
  - Connectat a Firestore mitjançant `_bookcaseService.getBookcases(activeLibrary.id)`, sumant el nombre real de llibres (`bookCount`) de totes les estanteries.
  - S'amaga automàticament el badge (`SizedBox.shrink()`) si la biblioteca no té mobles o llibres (`totalBooks == 0`).
  - Fallback resilient per a entorns de proves unitàries independents.
- [x] Estil visual destructiu al diàleg d'eliminació de biblioteca a [lib/widgets/library_dialogs.dart](file:///c:/git/llom/lib/widgets/library_dialogs.dart):
  - Quan el text no coincideix amb el nom de la biblioteca: botó desactivat amb fons gris suau (`Colors.grey.shade200`) i text atenuat (`Colors.grey.shade500`).
  - Quan el text coincideix exactament: botó actiu destacat amb fons vermell destructiu (`Colors.red.shade600`) i text blanc en negreta.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/library_safeguard_test.dart](file:///c:/git/llom/test/library_safeguard_test.dart) verificant la commutació de color de fons del botó destructiu.
  - Actualitzat [test/profile_screen_test.dart](file:///c:/git/llom/test/profile_screen_test.dart) comprovant els estils de tipografia de l'avatar (22sp i 36sp bold) i el comportament reactiu del badge de llibres (ocult amb 0 llibres, visible amb llibres).
  - **56 de 56 tests superats (100% èxit)** i 0 advertències a `flutter analyze`.

### ✅ Tasca 19: Identitat de Marca, Icones Web/Android i Pantalla d'Inici (SplashScreen)
- [x] Registre d'assets i dependències a [pubspec.yaml](file:///c:/git/llom/pubspec.yaml):
  - Afegit el directori `assets/images/` a la secció `flutter.assets`.
  - Afegit `package_info_plus: ^8.1.0` a `dependencies` per a lectura dinàmica de versió i compilació.
  - Afegit `flutter_launcher_icons: ^0.13.1` a `dev_dependencies`.
  - Configurat el bloc `flutter_launcher_icons` per generar icones d'Android i Web (amb fons `#FDF8F6` i color de tema `#F2856D`).
- [x] Assets d'imatge de marca:
  - Generat [assets/images/logo.png](file:///c:/git/llom/assets/images/logo.png) a partir de `logo_llom.png`.
  - Actualitzat [web/favicon.png](file:///c:/git/llom/web/favicon.png) amb la icona de marca.
  - Executat `dart run flutter_launcher_icons` generant les icones adaptatives per a Android i Web.
- [x] Nova Pantalla d'Inici accessible a [lib/screens/splash_screen.dart](file:///c:/git/llom/lib/screens/splash_screen.dart):
  - Fons net `AppColors.canvas` (`#FDF8F6`).
  - Contingut vertical centrat:
    - Logo centrat (`Image.asset("assets/images/logo.png")`, amplada 170px amb fallback resilient d'icona).
    - Espaiador vertical (24px) i títol de la marca "Llom" (32sp, negreta, letterSpacing -0.5).
    - Lema editorial: "Per no perdre cap llibre." (20sp, `AppColors.textMain`, semi-bold, estil editorial càlid).
    - Indicador de càrrega discret (`CircularProgressIndicator` salmó amb opacitat).
  - Part inferior (`SafeArea`):
    - Versió dinàmica obtinguda mitjançant `PackageInfo` (ex: "v1.0.0 (1)"), 13sp, color `AppColors.textMuted`.
- [x] Flux de navegació d'arrencada:
  - Execució en paral·lel de càrregues prèvies (`PackageInfo`, `SharedPreferences.getInstance()`) i un temps mínim visible de seguretat (~1.7s) per evitar parpellejos bruscos.
  - Transició suau amb `PageRouteBuilder` (`FadeTransition`) cap a `AuthGate`.
  - Actualitzat [lib/main.dart](file:///c:/git/llom/lib/main.dart) definint `home: home ?? const SplashScreen()`.
- [x] Suite de tests unitària i de widgets:
  - Creat [test/splash_screen_test.dart](file:///c:/git/llom/test/splash_screen_test.dart) verificant la renderització d'elements de marca, lema, indicador i transició suau.
  - **58 de 58 tests superats (100% èxit)** a `flutter test` i 0 advertències a `flutter analyze`.

### ✅ Tasca 20: Signatura d'Android per a Release i Protecció de Claus
- [x] Protecció de claus a [.gitignore](file:///c:/git/llom/.gitignore) i [android/.gitignore](file:///c:/git/llom/android/.gitignore):
  - Afegides les regles per excloure `*.jks`, `*.keystore` i `**/android/key.properties` de qualsevol commit al control de versions.
- [x] Configuració de Gradle Kotlin DSL a [android/app/build.gradle.kts](file:///c:/git/llom/android/app/build.gradle.kts):
  - Càrrega de propietats des de `key.properties` (`rootProject.file("key.properties")`) mitjançant `Properties()` i `FileInputStream`.
  - Creació de la configuració de signatura `signingConfigs.create("release")` associant `keyAlias`, `keyPassword`, `storeFile` i `storePassword`.
  - Assignació a `buildTypes.release` de `signingConfigs.release` (amb fallback a `debug` si no existeix `key.properties` en entorn local), `isMinifyEnabled = false` i `isShrinkResources = false`.
- [x] Verificació de build i qualitat:
  - Executat `.\gradlew.bat app:tasks --dry-run` (`BUILD SUCCESSFUL`).
  - **58 de 58 tests superats (100% èxit)** a `flutter test` i 0 advertències a `flutter analyze`.

### ✅ Tasca 21: Visor de Release Notes Accessible i Integració a ProfileScreen
- [x] Dependència i assets a [pubspec.yaml](file:///c:/git/llom/pubspec.yaml):
  - Afegit `flutter_markdown: ^0.7.5` a `dependencies`.
  - Declarat `assets/release_notes.md` sota `flutter.assets`.
  - Creat [assets/release_notes.md](file:///c:/git/llom/assets/release_notes.md) inicial amb les novetats de la versió.
- [x] Modal inferior accessible a [lib/widgets/release_notes_dialog.dart](file:///c:/git/llom/lib/widgets/release_notes_dialog.dart):
  - Mètode `showReleaseNotesModal(BuildContext context)` amb `showModalBottomSheet` arrodonit (24px), alçada adaptable fins al 80% i fons `AppColors.canvas`.
  - Capçalera amb icona corporativa salmó (`Icons.auto_awesome_rounded`), títol «Novetats de la versió» i botó de tancar gran.
  - Carregador asíncron via `rootBundle.loadString("assets/release_notes.md")` amb missatge amigable si no hi ha contingut.
  - Renderització Markdown amb `MarkdownStyleSheet` adaptat a la paleta de colors i tipografia accessible de Llom.
- [x] Integració a [lib/screens/profile_screen.dart](file:///c:/git/llom/lib/screens/profile_screen.dart):
  - Fila de versió convertida en `InkWell` tàctil amb subtítol «Què hi ha de nou? Toca per veure notes», badge de versió i fletxa `chevron_right_rounded` salmó per obrir el modal.
- [x] Suite de tests unitària i de widgets:
  - Creat [test/release_notes_test.dart](file:///c:/git/llom/test/release_notes_test.dart) comprovant l'obertura, renderització i tancament del modal, així com la integració tàctil des de `ProfileScreen`.
  - **60 de 60 tests superats (100% èxit)** a `flutter test` i 0 advertències a `flutter analyze`.

### ✅ Tasca 22: Sistema de Comprovació d'Actualitzacions i Descàrrega d'APK (Patró Centim)
- [x] Dependències a [pubspec.yaml](file:///c:/git/llom/pubspec.yaml):
  - Afegit `http: ^1.3.0` i `url_launcher: ^6.3.1` (amb `package_info_plus` ja configurat).
- [x] Servei d'actualitzacions a [lib/services/update_service.dart](file:///c:/git/llom/lib/services/update_service.dart):
  - URL base de metadades remotes: `https://llom-23d56.web.app/version.json`.
  - Mètode `checkUpdate()`: Consulta `version.json` amb capçaleres `Cache-Control: no-cache` i `Pragma: no-cache`. Llegeix la versió local mitjançant `PackageInfo.fromPlatform()`. Compara versions semàntiques (`major.minor.patch` + build number) i retorna `UpdateInfo(hasUpdate, currentVersion, latestVersion, apkUrl)` o `null` si hi ha un error de xarxa o servidor.
  - Mètode `downloadApk(url)`: Obre l'enllaç mitjançant `launchUrl` en mode `LaunchMode.externalApplication`.
  - Comparador semàntic robust `isNewerVersion(remote, local)` tolerant a sufixos `+build`.
- [x] Integració a [lib/screens/profile_screen.dart](file:///c:/git/llom/lib/screens/profile_screen.dart):
  - En Web (`kIsWeb`): Botó destacat a «Gestió de Compte»: «Descarregar APK per a Android / Tauleta» que apunta a `https://llom-23d56.web.app/llom.apk`.
  - A Android (`!kIsWeb`): Opció «Comprovar actualitzacions» a la targeta de versió del sistema. Mostra feedback de comprovació i, si hi ha nova versió, un `AlertDialog` («Nova versió disponible (vX.X.X)», «Descarregar i instal·lar», «Més tard»), o un `SnackBar` discret si ja està al dia («Ja tens la darrera versió instal·lada.»).
- [x] Comprovació silenciosa a [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart):
  - A Android (`!kIsWeb`): Comprovació silenciosa en segon pla en iniciar l'aplicació (`addPostFrameCallback`). Si es detecta una versió més recent, mostra un `SnackBar` flotant amb l'acció «Actualitzar».
- [x] Suite de tests unitària i de widgets:
  - Creat [test/update_service_test.dart](file:///c:/git/llom/test/update_service_test.dart) comprovant comparacions de versió semàntica i respostes HTTP (200, 404, 500).
  - Creat [test/profile_update_test.dart](file:///c:/git/llom/test/profile_update_test.dart) verificant els diàlegs i alertes a `ProfileScreen`.
  - Creat [test/home_update_test.dart](file:///c:/git/llom/test/home_update_test.dart) verificant la comprovació silenciosa i el botó «Actualitzar» a `HomeScreen`.
  - **68 de 68 tests superats (100% èxit)** a `flutter test` i 0 advertències a `flutter analyze`.

### ✅ Tasca 23: Refactorització del flux d'estanteries, BookshelfDetailScreen i Alta Manual de Llibres
- [x] Models de dades:
  - Actualitzat [lib/models/bookcase_model.dart](file:///c:/git/llom/lib/models/bookcase_model.dart) afegint el camp `order` per a l'ordenació personalitzada dels mobles.
  - Actualitzat [lib/models/book_model.dart](file:///c:/git/llom/lib/models/book_model.dart) afegint el camp `bookcaseId` per a consultes directes i esborrats en cascada.
- [x] Serveis de Firestore a [lib/services/bookcase_service.dart](file:///c:/git/llom/lib/services/bookcase_service.dart):
  - Ordenació automàtica de mobles per `order` i `createdAt`.
  - Mètode `updateBookcaseName` per canviar el nom del moble.
  - Mètode `deleteBookcase` amb esborrat en cascada de tots els llibres associats a `libraries/{libraryId}/books`.
  - Mètodes de gestió de llibres `getBooksForBookcase`, `addBook` (amb increment de `bookCount`) i `deleteBook` (amb decrement).
- [x] Diàlegs i gestió de mobles a [lib/widgets/library_dialogs.dart](file:///c:/git/llom/lib/widgets/library_dialogs.dart):
  - `showEditBookcaseNameDialog`: Diàleg modal per canviar el nom del moble.
  - `showDeleteBookcaseDialog`: Diàleg de confirmació de seguretat destructor abans d'eliminar el moble i els seus llibres.
- [x] Modal d'alta manual a [lib/widgets/add_manual_book_dialog.dart](file:///c:/git/llom/lib/widgets/add_manual_book_dialog.dart):
  - `showAddManualBookDialog` amb formulari accessible (Títol obligatori, Autor opcional, Selector Dropdown de baldes 1..N i botó prominent «Desar llibre»).
- [x] Interfície i navegació:
  - Actualitzat [lib/widgets/bookcase_card.dart](file:///c:/git/llom/lib/widgets/bookcase_card.dart) afegint menú contextual d'opcions (`PopupMenuButton`) amb «Editar nom» i «Eliminar estanteria».
  - Actualitzat [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart):
    - FAB inferior modificat a **«Afegir estanteria»** (icona `+`) obrint `showAddBookcaseDialog`.
    - Tap a la targeta d'estanteria que navega a la nova pantalla `BookshelfDetailScreen`.
  - Nova pantalla [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart):
    - Llistat vertical de baldes en gran amb recomptes i llibres en temps real (`StreamBuilder`).
    - FAB principal amb menú desplegable per a **«Fotografiar balda»** i **«Afegir llibre manualment»**.
- [x] Suite de tests unitària i de widgets:
  - Creat [test/add_manual_book_dialog_test.dart](file:///c:/git/llom/test/add_manual_book_dialog_test.dart).
  - Creat [test/bookshelf_detail_screen_test.dart](file:///c:/git/llom/test/bookshelf_detail_screen_test.dart).
  - Creat [test/home_screen_actions_test.dart](file:///c:/git/llom/test/home_screen_actions_test.dart).
  - Actualitzats [test/bookcase_test.dart](file:///c:/git/llom/test/bookcase_test.dart) i [test/library_ui_test.dart](file:///c:/git/llom/test/library_ui_test.dart).
  - **74 de 74 tests superats (100% èxit)** a `flutter test` i 0 incidències a `flutter analyze`.

### ✅ Tasca 24: Edició / Eliminació de Llibres i Migració a Bottom Modals (Bottom Sheets)
- [x] Servei de dades a [lib/services/bookcase_service.dart](file:///c:/git/llom/lib/services/bookcase_service.dart):
  - Afegit mètode `updateBook(String libraryId, BookModel book, {String? oldBookcaseId})` per actualitzar títol, autor, balda i ajustar atòmicament els comptadors de `bookCount` si canvia d'estanteria.
  - Verificat el mètode `deleteBook(String libraryId, String bookId, String bookcaseId)` amb decrement atòmic de comptador.
- [x] Formulari en Bottom Modal moderna a [lib/widgets/add_manual_book_dialog.dart](file:///c:/git/llom/lib/widgets/add_manual_book_dialog.dart):
  - Migrat de diàleg modal centrat (`AlertDialog`) a Bottom Sheet (`showModalBottomSheet` / `AddEditBookBottomSheet`).
  - Nansa d'arrossegament (*drag handle*), cantonades superiors arrodonides (24px) i adaptabilitat dinàmica al teclat (`viewInsets.bottom`).
  - Suport per a mode alta («Afegir llibre») i mode edició («Editar llibre»), amb pre-emplenat automàtic de dades del llibre existent (`title`, `author`, selector de balda).
  - Mètodes accessibles `showBookFormBottomSheet`, `showAddManualBookDialog` (retrocompatible) i `showEditBookBottomSheet`.
- [x] Accions a la pantalla de detall a [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart):
  - En prémer un llom de llibre (`BookSpineWidget`), s'obre la Bottom Sheet de detall amb nansa, capçalera, autor, xip de balda i moble.
  - Botó d'**«Editar»** (`edit_book_button`): Obre immediatament la Bottom Sheet d'edició amb les dades carregades.
  - Botó d'**«Eliminar»** (`delete_book_button`): Mostra confirmació de seguretat destructiva (`AlertDialog`) i esborra el llibre amb feedback (`SnackBar`).
- [x] Suite de tests unitària i de widgets:
  - Creat [test/book_edit_delete_test.dart](file:///c:/git/llom/test/book_edit_delete_test.dart) cobrint la càrrega de dades pre-emplenades, desat de canvis a Firestore, obertura de modal i flux d'eliminació amb confirmació.
  - **77 de 77 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 25: Recuperació del Disseny Visual de Prestatgeria Física Oberta (sense Cards)
- [x] Eliminació de contenidors tipus targeta a [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart):
  - Suprimit l'embolcall de `Container` amb fons blanc, ombres i marcs aïllats per balda. La pantalla ara transmet la sensació d'un moble d'estanteria contínua de fusta obert.
- [x] Capçalera neta per balda:
  - Títol: `Balda {index} · {Posició}` (`Superior`, `Intermèdia`, `Inferior` o `Única`), en 18sp semibold i `AppColors.textMain`.
  - Subtítol: `{N} llibres` (o `1 llibre` / `0 llibres`), en 14sp i `AppColors.textMuted`.
  - Acció directa a la dreta: Botó circular amb icona de càmera (`Icons.camera_alt_outlined`) per fotografiar la balda directament.
- [x] Tauló físic de fusta:
  - Base física horitzontal de fusta (`#D9C5B2`) de 12px sota els llibres amb vora suau i ombra subtil a la part inferior.
  - Els llibres reposen directament sobre el tauló alineats a la part inferior.
- [x] Perfeccionament de [lib/widgets/book_spine_widget.dart](file:///c:/git/llom/lib/widgets/book_spine_widget.dart):
  - Alçada generosa proporcionada (entre 150px i 186px segons el llibre).
  - Amplada proporcionada (entre 41px i 48px).
  - Vores superiors lleugerament arrodonides (`BorderRadius.vertical(top: Radius.circular(6))`).
  - Dues nervadures clàssiques gravades a la part superior.
  - Títol en vertical llegible (`RotatedBox` `quarterTurns: 3`), centrat i estilitzat.
  - Peu del llom: número d'ordre net (`#1`, `#2`, ...), mai IDs interns ni timestamps.
  - Paleta editorial harmonitzada: terracota (`AppColors.primary`), blanc porcellana (`#FFFFFF` amb vora subtil) i crema càlid (`#F5EBE6`).
- [x] Estat buit de la balda («Llom fantasma»):
  - Quan una balda no té llibres, el tauló de fusta es manté sempre visible.
  - Sobre el tauló es renderitza un llom fantasma estilitzat (alçada 160px, vora translúcida, icona `+` i text vertical *"Afegir llibre / foto"*), que convida a catalogar sense trencar la il·lusió òptica del moble.
- [x] Verificació i tests:
  - Actualitzat [test/bookshelf_detail_screen_test.dart](file:///c:/git/llom/test/bookshelf_detail_screen_test.dart) cobrint la nova capçalera, recomptes i llom fantasma.
  - **77 de 77 tests superats (100% èxit)** a `flutter test` i **0 incidències** a `flutter analyze`.

### ✅ Tasca 26: Actualització integral del README.md i creació d'AGENTS.md / ARCHITECTURE.md
- [x] Actualització exhaustiva de [README.md](file:///c:/git/llom/README.md):
  - Descripció del concepte de prestatgeria oberta física (sense contenidors Card).
  - Especificació dels lloms editorials realistes (`BookSpineWidget`).
  - Documentació dels Bottom Modals per a formularis i detalls de llibres.
  - Multi-tenència i gestió col·laborativa de biblioteques amb codis d'invitació de 6 caràcters.
  - Sistema d'actualitzacions OTA i descàrrega d'APK directa a la Web (Patró Centim).
  - Estructura de carpetes, instruccions de desenvolupament local i comanda de releases automatitzada (`release.ps1`).
- [x] Creació de la guia tècnica permanent per a IA a [AGENTS.md](file:///c:/git/llom/AGENTS.md):
  - Filosofia del projecte i directrius visuals inviolables (tauló `#D9C5B2` de 12px, proporcions de llom 41-48px x 150-186px, ordre `#1`, `#2` al peu, llom fantasma).
  - Esquema detallat de col·leccions Firestore (`users`, `libraries`, `bookcases`, `books`).
  - Regles d'integritat: transaccions atòmiques de `bookCount` i esborrat en cascada.
  - Arquitectura de capes (UI, Providers, Services, Backend).
  - Regles d'or per a agents: idioma català, protecció de `BuildContext` a través d'async gaps, prevenció de dependències de plataforma web (`dart:io`), obligació de 100% èxit en tests i zero advertències a `flutter analyze`.
- [x] Creació de [docs/ARCHITECTURE.md](file:///c:/git/llom/docs/ARCHITECTURE.md) com a resum d'arquitectura i pont d'enllaç ràpid cap a `AGENTS.md`.
- [x] Verificació:
  - **77 de 77 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 27: Connexió del Cercador a Cloud Firestore i Navegació Real a BookshelfDetailScreen
- [x] Servei de dades a [lib/services/bookcase_service.dart](file:///c:/git/llom/lib/services/bookcase_service.dart):
  - Afegit mètode reactiu `getAllBooks(String libraryId)` per escoltar tots els llibres de la biblioteca sencera en temps real (`Stream<List<BookModel>>`).
- [x] Cercador reactiu a [lib/screens/home_screen.dart](file:///c:/git/llom/lib/screens/home_screen.dart):
  - Connectat el cercador als llibres reals de Firestore quan hi ha una biblioteca activa (`activeLibrary.id.isNotEmpty`).
  - Si la biblioteca té 0 llibres a Firestore, mostra l'estat net: *"No s'ha trobat cap llibre. Encara no hi ha cap llibre catalogat en aquesta biblioteca."* (sense carregar cap dada mockejada).
  - Quan hi ha llibres, s'agrupen per les estanteries reals de Firestore (`BookcaseModel`) amb el nom i estança del moble.
  - Navegació directa a [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart) passant el moble real i el llibre seleccionat (`highlightBookId`).
  - Conservat el fallback net de mock per a entorns de prova sense sessió activa (retrocompatibilitat amb `widget_test.dart`).
- [x] Millores a [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart):
  - Suport per a `highlightBookId` i `initialSearchQuery`.
  - Afegida la barra de cerca interna dins del moble («Cerca un llibre en aquesta estanteria...»).
  - Ressaltat visual del llom amb fons destacat i fletxa taronja descendent (`arrow_downward_rounded`) gràcies a `BookSpineWidget` (`isHighlighted: true`, `isDimmed: true`).
- [x] Suite de tests unitària i de widgets:
  - Creat [test/home_search_firebase_test.dart](file:///c:/git/llom/test/home_search_firebase_test.dart) cobrint la cerca en biblioteques buides (0 llibres), cerca real amb navegació a `BookshelfDetailScreen`, i cerca interna a la pantalla del moble.
  - **80 de 80 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 28: Captura i Detecció Visual de Baldes amb Gemini Flash, Revisió Interactiva i Firebase Storage
- [x] Dependències i permisos del projecte:
  - Afegit SDK oficial de Gemini `google_generative_ai: ^0.4.6` a [pubspec.yaml](file:///c:/git/llom/pubspec.yaml).
  - Afegit permís de càmera `<uses-permission android:name="android.permission.CAMERA"/>` a [android/app/src/main/AndroidManifest.xml](file:///c:/git/llom/android/app/src/main/AndroidManifest.xml).
  - Creat [storage.rules](file:///c:/git/llom/storage.rules) i vinculat a [firebase.json](file:///c:/git/llom/firebase.json) permetent lectura/escriptura a usuaris autenticats sota `libraries/{libraryId}/{allPaths=**}`.
- [x] Models de dades:
  - Creat [lib/models/detected_book_spine.dart](file:///c:/git/llom/lib/models/detected_book_spine.dart) (`DetectedBookSpine`) amb coordenades normalitzades (0-1000) `box_2d` (`[ymin, xmin, ymax, xmax]`), serialització resilient (`fromMap`, `toMap`, `copyWith`) i mètode de conversió a `BookModel`.
  - Actualitzat [lib/models/book_model.dart](file:///c:/git/llom/lib/models/book_model.dart) amb el camp opcional `box` (`List<int>?`) mantenint retrocompatibilitat.
- [x] Servei de Visió amb Gemini Flash ([lib/services/shelf_vision_service.dart](file:///c:/git/llom/lib/services/shelf_vision_service.dart)):
  - Model `gemini-1.5-flash` amb mode de resposta JSON forçat (`responseMimeType: 'application/json'`).
  - Prompt del sistema d'alta precisió per segmentar i catalogar cada llom d'esquerra a dreta amb `box_2d`, `label` i `author`.
  - Gestió segura de `GEMINI_API_KEY`: font primària `const String.fromEnvironment("GEMINI_API_KEY")`, fallback a `SharedPreferences`, i modal Bottom Sheet net per demanar la clau i desar-la localment si és absent.
  - Ordenació automàtica dels lloms d'esquerra a dreta segons la coordenada `xmin`.
- [x] Servei de persistència a Firebase ([lib/services/bookcase_service.dart](file:///c:/git/llom/lib/services/bookcase_service.dart)):
  - Mètode `saveCatalogedShelf`: puja la imatge a `libraries/{libraryId}/shelves/{bookcaseId}_shelf_{shelfIndex}.jpg` a Firebase Storage, desa tots els llibres en batch a Cloud Firestore i incrementa atòmicament el camp `bookCount` del moble.
- [x] Pantalla de Revisió Interactiva ([lib/screens/shelf_review_screen.dart](file:///c:/git/llom/lib/screens/shelf_review_screen.dart)):
  - Visor d'imatge interactiu amb zoom i panoràmica (`InteractiveViewer`).
  - Renderitzat de caixes delimitadores translúcides amb etiqueta flotant per a cada llibre.
  - Modal Bottom Sheet per editar títol i autor o eliminar falsos positius.
  - Botó ràpid per afegir lloms manualment no detectats (`btn_add_spine_manual`).
  - Botó d'acció inferior per confirmar i desar la balda («Desar balda (N llibres)»).
- [x] Integració a [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart):
  - Optimització de captura a `ImagePicker`: `maxWidth: 2048`, `maxHeight: 2048`, `imageQuality: 85`.
  - Selector de balda des del FAB d'afegir contingut («Fotografiar balda») i botó directe a la capçalera de cada balda.
  - Diàleg de càrrega modal («Processant els llibres amb el far...») durant l'anàlisi de Gemini i navegació directa a `ShelfReviewScreen`.
- [x] Suite de tests unitària i de widgets:
  - Creat [test/shelf_vision_service_test.dart](file:///c:/git/llom/test/shelf_vision_service_test.dart) (7 tests).
  - Creat [test/shelf_review_screen_test.dart](file:///c:/git/llom/test/shelf_review_screen_test.dart) (5 tests).
  - Actualitzat [test/bookshelf_detail_screen_test.dart](file:///c:/git/llom/test/bookshelf_detail_screen_test.dart) (4 tests).
  - **94 de 94 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 29: Configuració d'Entorn Segur per a GEMINI_API_KEY, CI/CD i Gestió Local
- [x] Protecció de secrets a Git [.gitignore](file:///c:/git/llom/.gitignore):
  - Afegit `.vscode/`, `*.env` i `*.env.json` per evitar qualsevol pujada accidental de claus o configuracions locals al repositori remot.
  - Verificat amb `git status` que [.vscode/launch.json](file:///c:/git/llom/.vscode/launch.json) no queda marcat ni seguit pel control de versions.
- [x] Configuració de depuració local a [.vscode/launch.json](file:///c:/git/llom/.vscode/launch.json):
  - Creat perfil d'arrencada «Llom (Debug)» per a Flutter amb pas de clau per argument `--dart-define GEMINI_API_KEY=...`.
- [x] Actualització del flux de CI/CD a [.github/workflows/deploy.yml](file:///c:/git/llom/.github/workflows/deploy.yml):
  - Pas «Build APK (Release per a tauleta/mòbil)»: afegit `--dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}`.
  - Pas «Build Web (Release)»: afegit `--dart-define=GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}`.
- [x] Gestió i depuració de clau a la interfície de l'aplicació:
  - Comprovació automàtica a l'obertura de l'aplicació (`AuthGate` -> `HomeScreen`) que demana la clau en una Bottom Sheet neta si no està configurada a l'entorn ni al dispositiu.
  - Afegida opció a [lib/screens/profile_screen.dart](file:///c:/git/llom/lib/screens/profile_screen.dart) (`profile_gemini_key_tile`) per visualitzar l'estat («Configurada al dispositiu», «Injectada per entorn», «Sense configurar»), modificar-la o eliminar-la en qualsevol moment.
- [x] Verificació de qualitat:
  - Actualitzats [test/profile_screen_test.dart](file:///c:/git/llom/test/profile_screen_test.dart) i [test/release_notes_test.dart](file:///c:/git/llom/test/release_notes_test.dart).
  - **95 de 95 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 30: Actualització de Models de Gemini Flash i Gestió de Quotes/Facturació
- [x] Resolució del model retirat `gemini-1.5-flash` a [lib/services/shelf_vision_service.dart](file:///c:/git/llom/lib/services/shelf_vision_service.dart):
  - Google ha descatalogat `models/gemini-1.5-flash` a l'API v1beta retornant error 404 (Not Found).
  - Migrat el servei a una llista resilient de models candidats: `gemini-flash-latest`, `gemini-3.6-flash`, `gemini-3.5-flash` i `gemini-2.5-flash`.
  - Prova automàtica del següent model candidat en cas de 404 de l'API.
- [x] Diagnosi i gestió de crèdits/facturació (Error 429 `RESOURCE_EXHAUSTED`):
  - Identificada la resposta de Google: *"Your prepayment credits are depleted. Please go to AI Studio..."*.
  - Creat `GeminiVisionException` per capturar i formatar de manera clara els errors de quota (429), clau incorrecta (403) i models no disponibles (404).
- [x] Experiència d'usuari a [lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart):
  - Afegida l'acció interactiva «Canviar clau» directament a la SnackBar d'error per obrir el selector de clau sense haver de sortir de la pantalla.
- [x] Verificació de qualitat:
  - Actualitzat [test/shelf_vision_service_test.dart](file:///c:/git/llom/test/shelf_vision_service_test.dart).
  - **97 de 97 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 31: Desplaçament Horitzontal amb Ratolí a Web/Desktop i Detall Enriquit amb Google Books
- [x] Desplaçament horitzontal amb ratolí i trackpad:
  - Definit `AppScrollBehavior` a [lib/main.dart](file:///c:/git/llom/lib/main.dart) que hereta de `MaterialScrollBehavior` amb `dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad}`.
  - Assignat `scrollBehavior: const AppScrollBehavior()` al `MaterialApp` principal, permetent arrossegar i navegar pels lloms de les baldes amb ratolí sense necessitat de pantalla tàctil.
- [x] Model de dades de llibre ampliat a [lib/models/book_model.dart](file:///c:/git/llom/lib/models/book_model.dart):
  - Afegits els camps d'enriquiment `synopsis` (String?), `coverUrl` (String?), `pageCount` (int?), `publishedYear` (int?) i `infoUrl` (String?).
  - Actualitzats els mètodes de serialització (`toMap`, `fromMap`), mètode immutable `copyWith`, i operadors d'igualtat i `hashCode`.
- [x] Servei d'enriquiment amb Google Books ([lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart)):
  - Consulta l'API pública de Google Books (`https://www.googleapis.com/books/v1/volumes?q=intitle:{title}+inauthor:{author}&maxResults=1`).
  - Neteja automàtica d'etiquetes HTML de la descripció (`cleanHtml`).
  - Normalització de les URLs de portades a HTTPS (`http://` -> `https://`).
  - Extracció resilient de l'any de publicació a partir de cadenes de data (`YYYY-MM-DD` o `YYYY`).
  - Sistema de memòria cau en memòria (`_cache`) per evitar peticions duplicades o innecessàries.
  - Mètode `enrichAndPersistBook` per desar automàticament les dades enriquides al document del llibre a Cloud Firestore.
- [x] Nova Bottom Sheet moderna de detall del llibre ([lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart)):
  - Capçalera amb coberta oficial d'alta qualitat i fallback al llom estilitzat realista de Llom si no té portada.
  - Títol de llibre prominent amb tipografia nítida i autor.
  - Fila de xips informatius de localització física (moble, balda, nombre de pàgines i any de publicació).
  - Secció de sinopsi desplegable amb efecte de shimmer/esquelet durant la càrrega des de l'API de Google Books.
  - Botó d'acció primari destacat «Localitzar a la balda»:
    - Obre un visor interactiu (`_BookShelfVisualLocatorDialog`) amb la foto de la balda (`InteractiveViewer`) ressaltant el rectangle del llibre amb coordenades normalitzades 0-1000 i una bafarada informativa amb el títol.
  - Fila d'accions secundàries:
    - Botó d'enllaç extern a Google Books (`url_launcher`).
    - Botó d'editar llibre (`canEdit: true`).
    - Botó d'eliminar llibre amb confirmació destructiva (`AlertDialog`).
- [x] Integració a la pantalla de detall d'estanteria ([lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart)):
  - Substituït el modal anterior per la invocació unificada `showBookDetailBottomSheet`.
  - Injecció opcional del servei d'enriquiment per facilitar tests i desacoblament.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/models_test.dart](file:///c:/git/llom/test/models_test.dart) verificant la serialització dels nous camps.
  - Creat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) (5 tests complets per a HTML, HTTPS, anys, APIs i Firestore).
  - Creat [test/book_detail_bottom_sheet_test.dart](file:///c:/git/llom/test/book_detail_bottom_sheet_test.dart) (7 tests per a UI, sinopsi, localitzador visual, permisos i scroll behavior).
  - **109 de 109 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 32: Cerca Resilient a Google Books, Format de URLs a Storage i Gestió de CORS a Web
- [x] Resiliència a la cerca de Google Books ([lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart)):
  - Creat `cleanSearchTerm` per netejar caràcters de puntuació extres (comes, cometes, guions, dos punts, etc.) abans d'enviar la consulta.
  - Implementat mecanisme resilient de doble intent:
    * **Intent 1 (precís)**: Cerca amb títol i autor nets entre cometes (`intitle:"${cleanTitle}"+inauthor:"${cleanAuthor}"`).
    * **Intent 2 (tolerant)**: Fallback automàtic si el primer intent retorna `totalItems == 0` fent cerca oberta (`q=${Uri.encodeComponent("$cleanTitle $cleanAuthor")}`).
  - Enllaç de fallback per a `infoUrl`: Si l'API no retorna `infoLink` directe o és nul, assigna automàticament `https://books.google.com/books?q=${Uri.encodeComponent("$cleanTitle $cleanAuthor")}` en lloc de cerques genèriques.
- [x] Persistència de la imatge a Firebase Storage ([lib/services/bookcase_service.dart](file:///c:/git/llom/lib/services/bookcase_service.dart)):
  - Assegurat que `saveCatalogedShelf` espera l'execució de `uploadTask`, obté el `downloadUrl` públic complet (`final snapshot = await uploadTask; final downloadUrl = await snapshot.ref.getDownloadURL();`) i l'assigna al camp `photoUrl` de cada llibre creat a Firestore.
- [x] Gestió robusta d'imatges a Flutter Web i depuració de CORS ([lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart) i [lib/screens/shelf_review_screen.dart](file:///c:/git/llom/lib/screens/shelf_review_screen.dart)):
  - Afegits `loadingBuilder` amb indicadors centrats i `errorBuilder` detallats tant a la portada com a la fotografia de la balda (`InteractiveViewer`) i a `ShelfReviewScreen`.
  - Mostra missatges clars de diagnòstic de xarxa i instruccions sobre regles CORS de Firebase Storage quan s'executa en entorn Web (`kIsWeb`).
  - Suport de `photoUrl` a `ShelfReviewScreen` quan `imageBytes` és buit.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) (11 tests complets cobrint neteja de comes en títols com "Lejos, más lejos", fallback Intent 2 i fallback infoUrl).
  - Actualitzat [test/shelf_review_screen_test.dart](file:///c:/git/llom/test/shelf_review_screen_test.dart) verificant la renderització amb `photoUrl`.
  - **114 de 114 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 33: Resolució de l'Error 429 a Google Books, Autenticació amb API Key i Fallback a Open Library
- [x] Autenticació i control de quota a [lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart):
  - Resolució de la clau d'entorn `GEMINI_API_KEY` (o configurada localment via `ShelfVisionService.getEffectiveApiKey()`).
  - Addició automàtica del paràmetre `key` a les consultes de l'API de Google Books quan la clau està disponible (`maxResults: 3`, `printType: 'books'`).
  - Detecció d'HTTP 429 (`Too Many Requests`): si Google Books retorna codi 429, s'eviten més intents immediats contra el servei i es passa directament al servei de suport (Open Library).
- [x] Integració de Fallback amb Open Library ([lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart)):
  - Mètode `fetchFromOpenLibrary(String title, String author)`:
    * Consulta resilient a `https://openlibrary.org/search.json?title={title}&author={author}&limit=1`.
    * Extracció de portada en qualitat mitjana (`cover_i` -> `https://covers.openlibrary.org/b/id/{id}-M.jpg`).
    * Extracció d'any de primera publicació (`first_publish_year`) i nombre de pàgines (`number_of_pages_median`).
    * Consulta de sinopsi a l'endpoint d'obra d'Open Library (`/works/{key}.json`) o assignació d'`infoUrl` directe (`https://openlibrary.org{doc['key']}`).
  - Timeout segur de 4 segons a totes les consultes HTTP i 2 segons a la persistència de Firestore per evitar bloquejos.
- [x] Prevenció de crides repetides a la interfície ([lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart)):
  - Disparament de la consulta d'enriquiment una sola vegada a `initState` (o en canviar l'ID del llibre a `didUpdateWidget`) mitjançant `_enrichmentFuture` i control de flag `_isLoadingEnrichment`.
  - Si el llibre ja compta amb dades guardades (`book.synopsis != null` o `book.coverUrl != null`), s'omet la consulta a la xarxa.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) (15 tests, incloent injecció d'API key, gestió de 429, extracció d'Open Library i salt de xarxa).
  - Actualitzat [test/book_detail_bottom_sheet_test.dart](file:///c:/git/llom/test/book_detail_bottom_sheet_test.dart) (verificant que llibres amb sinopsi/portada ometen consultes i llibres sense dades les disparen).
  - Actualitzat [test/book_edit_delete_test.dart](file:///c:/git/llom/test/book_edit_delete_test.dart) assegurant aïllament de xarxa.
  - **120 de 120 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 34: Optimització de l'Enriquiment Prioritzant Open Library i Botó d'Enllaç Dinàmic
- [x] Ajust de [lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart):
  - Priorització d'Open Library (`fetchFromOpenLibrary`) com a primera opció ràpida per a portades, sinopsis i metadades.
  - Si Open Library troba el llibre (portada o sinopsi), assigna el seu `infoUrl` (`https://openlibrary.org/works/...`) i finalitza sense consultar serveis externs bloquejats.
  - Eliminació del paràmetre `key: apiKey` a les consultes de Google Books API per evitar errors HTTP 401 (la clau de Gemini no disposa d'abast OAuth per a Google Books).
  - Gestió d'errors HTTP 401 i 429 a Google Books per evitar bucles innecessaris de reintents.
  - Assegurada la persistència a Cloud Firestore de `coverUrl`, `synopsis`, `publishedYear`, `infoUrl` i `pageCount`.
- [x] Botó d'enllaç dinàmic a [lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart):
  - Adaptació dinàmica del botó d'enllaç extern segons l'adreça `infoUrl`:
    * Si conté `openlibrary.org`: text **"Open Library"** amb icona `Icons.local_library_outlined`.
    * Si conté `books.google`: text **"Google Books"** amb icona `Icons.menu_book_rounded`.
    * En qualsevol altre cas: text **"Fitxa del llibre"** amb icona `Icons.open_in_new_rounded`.
  - Manteniment de la clau `const Key('google_books_button')` per a compatibilitat retroactiva amb la suite de proves.
  - Obertura resilient de l'URL amb `url_launcher` (`launchUrl(..., mode: LaunchMode.externalApplication)`).
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) (16 tests verificant la priorització d'Open Library, l'omissió de Google Books si Open Library té èxit, i l'absència del paràmetre `key` a les consultes).
  - Actualitzat [test/book_detail_bottom_sheet_test.dart](file:///c:/git/llom/test/book_detail_bottom_sheet_test.dart) (10 tests verificant l'etiqueta i icona dinàmica per a Open Library, Google Books i fitxes genèriques).
  - **124 de 124 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 35: Integració de GOOGLE_BOOKS_API_KEY (format AIzaSy), Suport Robust d'Open Library i CI/CD
- [x] Lògica d'enriquiment a [lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart):
  - Lectura de la variable d'entorn `const String.fromEnvironment('GOOGLE_BOOKS_API_KEY')` o paràmetre al constructor `googleBooksApiKey`.
  - Validació de seguretat de format: només s'injecta el paràmetre `key` a Google Books si comença per `AIzaSy...` (`hasValidGoogleBooksApiKey == true`), mai amb claus d'AI Studio (`AQ.`) ni buides.
  - Nou flux de consulta:
    * **Pas 1**: Consulta primer Google Books API amb la clau. Si respon 200 amb dades vàlides (portada o sinopsi), finalitza i desa a memòria cau (i a Firestore mitjançant `enrichAndPersistBook`).
    * **Pas 2**: Si Google Books retorna 401, 429, 0 resultats o no disposa de portada/sinopsi, executa automàticament `fetchFromOpenLibrary` com a suport transparent i resilient.
- [x] Botó d'enllaç dinàmic a [lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart):
  - Adaptació prioritzada de text i icona segons la URL:
    * Si conté `books.google`: text **"Google Books"** amb icona `Icons.menu_book_rounded`.
    * Si conté `openlibrary.org`: text **"Open Library"** amb icona `Icons.local_library_outlined`.
    * Cas general: text **"Fitxa del llibre"** amb icona `Icons.open_in_new_rounded`.
- [x] Actualització del Workflow de GitHub Actions ([.github/workflows/deploy.yml](file:///c:/git/llom/.github/workflows/deploy.yml)):
  - Afegit `--dart-define=GOOGLE_BOOKS_API_KEY=${{ secrets.GOOGLE_BOOKS_API_KEY }}` tant a la comanda `flutter build apk` com a `flutter build web`.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) (18 tests cobrint clau `AIzaSy`, rebuig de clau `AQ.`, priorització de Google Books quan té dades i fallback automàtic a Open Library en 401/429/0).
  - Verificat [test/book_detail_bottom_sheet_test.dart](file:///c:/git/llom/test/book_detail_bottom_sheet_test.dart) (10 tests amb botons dinàmics i visualitzadors).
  - **126 de 126 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 36: Refinament de Càrrega de Portada i Sinopsi (Cerca Híbrida i Màxim de 3 Intents)
- [x] Model de Dades ([lib/models/book_model.dart](file:///c:/git/llom/lib/models/book_model.dart)):
  - Afegit camp `enrichmentAttempts: int` (per defecte 0) amb serialització a Firestore (`toMap` i `fromMap`) i suport a `copyWith`, `==` i `hashCode`.
- [x] Cerca Híbrida i Complementària ([lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart)):
  - A `fetchEnrichmentData`:
    * Si Google Books retorna tant portada com sinopsi, es dóna per complet i es retorna de seguida.
    * Si a Google Books li falta algun dels dos camps (o falla amb 401/429/0), es consulta automàticament Open Library i es fusionen les dades (ex: sinopsi de Google Books + portada d'Open Library).
  - A `enrichAndPersistBook`:
    * Comprovació estricta de completesa: només s'omet la cerca si el llibre disposa **tant** de sinopsi com de portada (`hasSynopsis && hasCover`).
    * Límit màxim de 3 intents: si `enrichmentAttempts >= 3`, no es tornen a consultar les APIs i es deixa estar.
    * Increment automàtic del comptador `enrichmentAttempts` i persistència a Cloud Firestore conjuntament amb les noves metadades recuperades.
- [x] Interfície d'Usuari ([lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart)):
  - En obrir el detall, si falta la portada o la sinopsi i s'han fet menys de 3 intents (`enrichmentAttempts < 3`), s'activa el servei d'enriquiment en segon pla per recuperar el camp mancant.
  - Si el llibre està complet o ja s'han assolit els 3 intents, no es fan peticions innecessàries a la xarxa.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/models_test.dart](file:///c:/git/llom/test/models_test.dart) verificant la serialització d'`enrichmentAttempts`.
  - Actualitzat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) (21 tests, incloent cerca híbrida Google Books + Open Library, cerca quan només hi ha un camp i salt quan s'arriba a 3 intents).
  - Actualitzat [test/book_detail_bottom_sheet_test.dart](file:///c:/git/llom/test/book_detail_bottom_sheet_test.dart) (12 tests verificant el disparament per camp mancant i l'omissió en llibres complets o amb 3 intents).
  - **131 de 131 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 37: Visualitzador de Fotografia Completa de Balda a BookshelfDetailScreen
- [x] Detecció de Fotografia de Balda ([lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart)):
  - Extracció de la URL de la fotografia de la balda (`shelfPhotoUrl`) a partir dels llibres de la balda que tinguin el camp `photoUrl` vàlid i no buit.
- [x] Botó d'Acció al Capçal de Balda ([lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart)):
  - Si la balda compta amb una fotografia associada (`shelfPhotoUrl != null`), es mostra un botó circular `IconButton.filledTonal` al costat del botó de la càmera amb clau `Key('shelf_photo_button_$shelfNumber')`, icona `Icons.photo_library_outlined` i tooltip `Veure fotografia de la balda $shelfNumber`.
- [x] Diàleg Modal del Visor de Fotografia de Balda ([lib/screens/bookshelf_detail_screen.dart](file:///c:/git/llom/lib/screens/bookshelf_detail_screen.dart)):
  - Mètode `_showShelfPhotoViewer` amb disseny coherent de targeta modal:
    * Capçalera amb títol de balda (`Balda N · Superior/Intermèdia/Inferior/Única`), nom del moble i botó de tancar (`close_shelf_photo_dialog`).
    * Visor de la imatge completa amb `InteractiveViewer` (zoom i desplaçament suau fins a 4x).
    * Gestió d'estats de càrrega (`CircularProgressIndicator`) i d'error amb missatges adaptats per a Web (`kIsWeb`) i mòbil.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/bookshelf_detail_screen_test.dart](file:///c:/git/llom/test/bookshelf_detail_screen_test.dart) (5 tests, incloent comprovació de presència del botó de foto només si hi ha `photoUrl`, obertura del diàleg amb `InteractiveViewer` i tancament correcte).
  - **132 de 132 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

### ✅ Tasca 38: Suport CORS Transparent per a Portades de Google Books a Flutter Web
- [x] Resolució de Restriccions CORS a Web ([lib/services/book_enrichment_service.dart](file:///c:/git/llom/lib/services/book_enrichment_service.dart)):
  - Creat el mètode `BookEnrichmentService.getSafeDisplayCoverUrl(String? url, {bool? isWebOverride})`:
    * A Flutter Web (`kIsWeb`), els servidors d'imatges de Google Books (`books.google.com` o `googleusercontent.com`) no inclouen capçaleres CORS (`Access-Control-Allow-Origin: *`), fet que provoca que el navegador bloquegi la petició amb `statusCode: 0` en renderitzar a CanvasKit.
    * Per solucionar-ho transparentment a la Web, l'URL es canalitza a través del proxy CDN d'imatges d'alt rendiment `images.weserv.nl` amb Cloudflare, que afegeix capçaleres CORS completes i memòria cau.
    * A Android, iOS i escriptori (`!kIsWeb`), es manté la URL directa original sense passar per cap proxy.
    * Les imatges d'Open Library (`covers.openlibrary.org`) i de Firebase Storage no es modifiquen, ja que suporten CORS de forma nativa.
- [x] Renderització de la Portada ([lib/widgets/book_detail_bottom_sheet.dart](file:///c:/git/llom/lib/widgets/book_detail_bottom_sheet.dart)):
  - A `_buildCoverThumbnail`, s'utilitza `BookEnrichmentService.getSafeDisplayCoverUrl(_currentBook.coverUrl)` per carregar la portada de manera segura i immediata, tant per a nous llibres com per a llibres ja existents a Cloud Firestore.
- [x] Suite de tests unitària i de widgets:
  - Actualitzat [test/book_enrichment_service_test.dart](file:///c:/git/llom/test/book_enrichment_service_test.dart) amb proves unitàries exhaustives per a `getSafeDisplayCoverUrl` (simulació Web amb proxy, simulació mòbil directa, prevenció de doble proxy i comprovació d'Open Library).
  - **133 de 133 tests superats (100% èxit)** a `flutter test` i **0 advertències** a `flutter analyze`.

---

## 🚀 Propers Passos
*(S'aniran afegint a mesura que es defineixin noves tasques)*





