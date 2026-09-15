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

---

## 🚀 Propers Passos
*(S'aniran afegint a mesura que es defineixin noves tasques)*








