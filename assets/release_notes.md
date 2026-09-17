# Release Notes

## v1.2.0+5
- Reordenació interactiva de llibres a la balda (Drag & Drop) amb persistència atòmica a Cloud Firestore.
- Eina de dibuix i marcatge manual de caixes sobre la fotografia de la balda per afegir llibres no detectats.
- Mode d'edició retroactiva de baldes reutilitzant la foto existent a Firebase Storage per revisar, afegir o suprimir llibres.
- Mòdul centralitzat de notificacions AppFeedback (Top Floating Pill) per a Android i Web.
- Dibuix realista de baldes buides vs plenes i detalls artesanals (planteta de terracota i llibre inclinat) al carrusel d'estanteries.
- Cerca millorada: preservació del text en obrir resultats i deselecció en buidar el cercador.
- Gestió àgil de baldes buides, buidat de prestatges i autocompletat d'autor amb vareta màgica.
- Suite de tests ampliada a 166 tests (100% èxit) i 0 advertències a flutter analyze.
## v1.1.0+4
- Desplaçament horitzontal fluid amb ratolí, trackpad i pantalla tàctil a les baldes (Web i Desktop).
- Nou visor de fotografia completa de la balda amb zoom interactiu de fins a 4x (InteractiveViewer).
- Enriquiment intel·ligent de llibres amb cerca híbrida: combinació de Google Books API i Open Library per a sinopsi, portada, pàgines i any.
- Resolució del bloqueig de CORS a Flutter Web per a portades de Google Books mitjançant canalització segura.
- Botó d'enllaç extern dinàmic a la fitxa del llibre (Google Books / Open Library).
- Cerca resilient de llibres tolerant a signes de puntuació i límit de 3 intents per optimitzar xarxa i quotes.
- Suite de tests ampliada a 133 tests (100% èxit) i zero advertències d'anàlisi.
## v1.0.2+3
- Nova pantalla de detall de mobles d'estanteria (BookshelfDetailScreen) en temps real.
- Edició i eliminació completa de llibres amb confirmació de seguretat i ajust atòmic de comptadors.
- Migració dels formularis i accions de llibres al patró modern de Bottom Modals (Bottom Sheets).
- Recuperació del disseny visual de prestatgeria física oberta (sense targetes / Cards) amb taulons de fusta càlids (#D9C5B2).
- Lloms editorials estilitzats (BookSpineWidget) amb nervadures gravades, número d'ordre net i paleta harmonitzada.
- Llom fantasma interactiu per convidar a catalogar a les baldes buides sense trencar la il·lusió òptica del moble.
## v1.0.1+2
- Sistema de descàrrega directa de l'APK per a Android des de la versió Web.
- Comprovació automàtica i manual de noves versions amb avís de descàrrega.
- Detecció silenciosa d'actualitzacions en segon pla a la pantalla d'inici.
- Visor interactiu de notes de la versió (Release Notes) des del perfil.
## v1.0.0
Primera release de Llom amb identificació de baldes, disseny accessible i desplegament automatitzat.
## v1.0.0+1
- Nova pantalla d'inici SplashScreen amb la identitat corporativa de Llom i transició suau.
- Integració de les noves icones de marca per a Android i Web.
- Catàleg intel·ligent d'estanteries i baldes sincronitzades amb Cloud Firestore.
- Autenticació accessible amb Google Sign-In i correu/contrasenya.
- Gestió multi-biblioteca amb rols (Propietari, Editor, Lector) i codis d'invitació.
- Disseny adaptat a accessibilitat sènior amb mode de text extra gran.





