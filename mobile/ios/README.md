# Talleres Club Abierto para iPhone

Base iOS de la versión funcional 1.9. El contenido inicial corresponde al commit
`26233b5408d1b00a046a51e2611cbaa2fa826e70`, utilizado por la compilación Android 1.9.
Cada nueva compilación toma el contenido del commit que ejecuta el workflow;
no descarga una web diferente durante el arranque.

## Contenido y alcance

Se utiliza el mismo constructor móvil que Android. Sus verificaciones comprueban
los 24 archivos de la plataforma, los tres accesos, cuatro categorías por panel,
los seis países de Scouting, Comunidad Formativa, Estructura Institucional y el
fondo. Después se compara cada archivo dentro de la aplicación iOS compilada.

Capacitor 8.5.1 queda fijado con un lock independiente. Los archivos fuente web,
los datos, las autorizaciones y la compilación Android no se modifican.

El router nativo resuelve las cuatro rutas de Comunidad Formativa terminadas en
`/` hacia su `index.html`. Es necesario porque el router SPA de Capacitor devuelve
la portada para rutas sin extensión. Las personalizaciones nativas se conservan
en `native/` y se aplican de manera idempotente al proyecto generado; no se borra
un proyecto iOS existente al sincronizar.

## Compilar

Requisitos: macOS, Xcode 26 o superior y Node 22 o superior. iOS mínimo: 15.

```bash
cd mobile/ios
npm ci --ignore-scripts
npm run generate
npm run open
```

El workflow `iPhone - compilacion inicial sin firma` compila y abre un simulador,
genera un archivo para dispositivo sin firmar y exporta el proyecto Xcode.
**Ningún artefacto de esta etapa es un IPA distribuible ni una publicación.**

La captura del inicio sólo acredita que la pantalla se abre; no certifica login
ni operaciones autenticadas. Los logs, hashes y `source-build.json` acompañan cada
ejecución.

El icono de pruebas reutiliza el PNG válido de Android de 192 px, extraído de
`f406829e778eb27de8021964214b819899d836b0`, sin rediseño. Se escala a 1024 px
para Xcode. Antes de preparar la ficha final conviene recuperar un original de
alta resolución válido: el archivo `resources/app-icon-master.png` de esa base
no se pudo decodificar correctamente. La portada conserva el logo web original.

## Pendientes para TestFlight y App Store

1. Elegir el titular real y activar Apple Developer Program (tarifa base oficial:
   USD 99/año). Individual muestra el nombre legal de la persona; Organization
   muestra la razón social y requiere entidad jurídica y D-U-N-S. La cuenta y
   correo deben ser los elegidos para Club Abierto, sin asumir la titularidad
   institucional de Talleres ni vincular el negocio logístico.
2. Registrar el Bundle ID `com.talleresclubabierto.app` si está disponible para el
   equipo elegido; configurar Team ID, certificados y aprovisionamiento.
3. Probar en iPhone: contraseña y sesión, controles de rol, navegación y teclado,
   OTP y rutas familiares, Scouting, selección de PDF/planillas y enlaces externos.
   Confirmar CORS para `capacitor://localhost` en las APIs empleadas.
4. Resolver Passkeys con el RP ID real, `webcredentials`, Team ID y AASA. El
   Historial Administrativo exige ese control: no se desactiva para publicar.
5. Completar ficha, capturas, privacidad, acceso de revisión con datos de prueba
   y descripción precisa de la relación institucional. Revisar la experiencia
   funcional según la regla 4.2 de Apple. La compilación no garantiza aprobación.
6. Firmar y subir la versión a TestFlight; tras las pruebas, enviar a App Review.

Referencias: [Apple Developer](https://developer.apple.com/programs/enroll/),
[revisión de Apple](https://developer.apple.com/app-store/review/guidelines/),
[Capacitor iOS](https://capacitorjs.com/docs/ios),
[Swift Package Manager](https://capacitorjs.com/docs/ios/spm).

