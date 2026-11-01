# 🥚 Roba el Huevo

Juego de Roblox estilo *tycoon* + robo: compra huevos que pasan por una cinta, ponlos en los nidos de tu granja para ganar dinero, y roba los huevos de las granjas de otros jugadores sin que te atrapen.

Todo el mapa (granjas, cinta, gallinero, plaza, tienda) **se construye por código** al iniciar el servidor, así que solo necesitas pegar dos scripts en Roblox Studio.

---

## 📁 Archivos

| Archivo | Tipo en Roblox | Dónde va |
|---|---|---|
| `RobaHuevos_Servidor.lua` | **Script** | `ServerScriptService` |
| `RobaHuevos_Cliente.lua` | **LocalScript** | `StarterPlayer > StarterPlayerScripts` |

---

## 🎮 Cómo se juega

1. **Compra** huevos en la cinta que sale del 🐔 Gallinero (mantén **E**).
2. Los huevos se colocan en los **nidos** de tu granja y generan dinero cada segundo.
3. Pisa el símbolo **💰** de tu granja para recoger el dinero.
4. **Roba** huevos de otras granjas (mantén **E** sobre un huevo ajeno) y llévalos a la tuya.
5. **Defiéndete**: toca al ladrón, golpéalo con el 🏏 bate o cierra tu granja pisando el símbolo **🔒**.
6. **Vende** tus huevos con **F** (50 % de su valor).

### Funciones

| Función | Descripción |
|---|---|
| 🪺 **Nidos** | Empiezas con 4 y puedes desbloquear hasta 12 (24 con ampliaciones). |
| 🏗️ **Ampliar granja** | 2 ampliaciones de +6 nidos detrás del granero. Con dinero del juego o al instante con Robux. |
| 🐣 **Eclosión** | Los huevos se convierten en gallinas con el tiempo y producen x2. |
| 🔥🌈 **Mutaciones** | Huevos de Lava (x2) y Arcoíris (x3). |
| 🏃 **Caminadora** | Al frente de cada granja, junto al camino. Súbete a la banda y arranca sola: corres en el centro con la animación de correr y una cámara de costado. Los pasos suben tu velocidad (8 niveles, de 16 a 34). Diseño tipo portal de neón que cambia de color y gana piezas en cada nivel. Bájate con Espacio o con el botón. |
| 🦊 **Zorro** | Cada 6 min intenta robar un huevo. Golpéalo 3 veces para ahuyentarlo y ganar premio. |
| 🌟 **Hora dorada** | Cada 5 min, durante 60 s, salen más huevos raros y mutaciones. |
| 📋 **Misiones diarias** | 3 misiones al día con premio en dinero. |
| 🛡️ **Escudos** | Gratis al entrar (60 s) y después de que te roban (30 s). En la tienda: 10 min, 30 min, 1 día y 2 días, con dinero del juego o Robux. El tiempo corre aunque no estés conectado. |
| ⚡ **Cerca eléctrica** | Mejora de tienda: puede electrocutar al ladrón cuando sale con tu huevo. |
| 🔒 **Cierre largo** | Mejora de tienda: tu granja queda cerrada más tiempo. |
| ♻️ **Renacer** | Reinicias tu progreso a cambio de +50 % de ingresos permanente. |
| 🏆 **Tabla global** | Los 10 jugadores más ricos de todos los servidores. |
| 💾 **Guardado** | El progreso se guarda automáticamente con DataStore. |
| 💤 **Ganancias offline** | Al volver recibes el 25 % de lo que ganabas, por el tiempo que no estuviste (máximo 8 h). |
| 🔥 **Racha diaria** | Premio por entrar días seguidos; el día 7 regala un huevo Mítico. |
| 🎁 **Huevo misterioso** | Cuesta $8K y puede salir cualquier rareza, hasta un Dorado, con ruleta animada. |
| 🔊 **Sonidos** | Efectos al comprar, robar, golpear, eclosionar y subir de nivel. Botón para silenciar. |
| 🏅 **Insignias** | Primer robo, caminadora al máximo, 10 zorros, primer renacer, racha de 7 días y huevo Dorado. |
| 🤝 **Aliados** | Pulsa **G** sobre otro jugador; si te responde con G, son aliados: no se roban, entran a la granja del otro, atrapan ladrones juntos y ganan +10 %. |
| 🛒 **Tienda** | Al final de la cinta: puestos en cuadro alrededor del huevo de renacer. |

### Rarezas

| Rareza | Precio | Ingreso/s |
|---|---|---|
| Común | $50 | 1 |
| Poco común | $250 | 4 |
| Raro | $1.2K | 15 |
| Épico | $6K | 60 |
| Legendario | $30K | 250 |
| Mítico | $150K | 1.000 |
| Dorado | $750K | 4.500 |

---

## 🛠️ Instalación en Roblox Studio

1. Abre tu lugar en **Roblox Studio**.
2. En el **Explorador**, clic derecho en `ServerScriptService` → **Insertar objeto → Script**. Borra el texto que trae y pega el contenido de `RobaHuevos_Servidor.lua`.
3. Clic derecho en `StarterPlayer > StarterPlayerScripts` → **Insertar objeto → LocalScript**. Pega el contenido de `RobaHuevos_Cliente.lua`.
4. Pulsa ▶ **Probar**. El mapa aparece flotando a 300 studs de altura para no chocar con tu escenario (puedes cambiarlo en `CONFIG.CENTRO`).
5. Para probar robos entre jugadores: pestaña **Prueba → Clientes y servidores → 2 jugadores → Iniciar**.

> En Studio tienes todos los Game Passes gratis para probar (`PASES_GRATIS_EN_STUDIO = true`).

---

## 🚀 Publicar el juego en Roblox

1. **Archivo → Publicar en Roblox**.
2. **Inicio → Configuración del juego**:
   - **Seguridad** → activa *Permitir acceso de Studio a servicios de API* (necesario para guardar datos y la tabla global).
   - **Lugares** → número máximo de jugadores: **6** (hay 6 granjas).
3. En [create.roblox.com](https://create.roblox.com) → tu experiencia → hazla **Pública**.

### Game Passes

1. En create.roblox.com → tu experiencia → **Monetización → Pases**, crea:
   - **x2 Dinero**
   - **Bate dorado**
   - **Caminadora VIP**
2. Copia el ID de cada pase en `CONFIG.PASES` del script del servidor:

```lua
PASES = {
	Dinero2x = 123456789,
	BateDorado = 234567890,
	CaminadoraVIP = 345678901,
},
```

### Productos de desarrollador (Robux, compra repetible)

La ampliación de granja y los escudos se pueden comprar con Robux varias veces, así que son **productos de desarrollador**, no Game Passes.

1. En create.roblox.com → tu experiencia → **Monetización → Productos de desarrollador**, crea:
   - **Ampliar granja**
   - **Escudo 10 minutos**, **Escudo 30 minutos**, **Escudo 1 día**, **Escudo 2 días**
2. Copia el ID de cada uno en `CONFIG.PRODUCTOS`:

```lua
PRODUCTOS = {
	Ampliar = 111111111,
	Escudo10m = 222222222,
	Escudo30m = 333333333,
	Escudo1d = 444444444,
	Escudo2d = 555555555,
},
```

> En Studio las compras con Robux son de prueba (no se cobra nada), así que puedes probarlas con los IDs reales.

### Insignias (Badges)

1. En create.roblox.com → tu experiencia → **Engagement → Insignias**, crea las que quieras.
2. Copia cada ID en `CONFIG.INSIGNIAS` del script del servidor (`PrimerRobo`, `CaminadoraMaxima`, `Cazazorros`, `PrimerRenacer`, `Racha7`, `HuevoDorado`). Las que queden en `0` simplemente no se entregan.

### Música

Los efectos de sonido ya funcionan (usan sonidos que vienen con Roblox). Para poner música de fondo:
1. En Studio abre la **Caja de herramientas → Audio**, elige una canción y pulsa **Insertar**.
2. Aparece un objeto **Sound** en `Workspace`. Cámbiale el nombre a `Musica` y arrástralo a `ReplicatedStorage`.
3. Listo: el juego la toca en bucle. El botón 🔊 la silencia.

También puedes pegar el ID directamente en `MUSICA_ID` (sección *Sonidos y música* de `RobaHuevos_Cliente.lua`):

```lua
local MUSICA_ID = "rbxassetid://1234567890"
```

---

## ⚙️ Configuración

Todo se ajusta en la tabla `CONFIG`, al principio de `RobaHuevos_Servidor.lua`:

| Opción | Qué controla |
|---|---|
| `CENTRO` | Dónde se construye el mapa |
| `DINERO_INICIAL` | Dinero al empezar |
| `INTERVALO_HUEVOS` / `DURACION_CINTA` | Ritmo de la cinta |
| `PRECIOS_NIDO` | Costo de cada nido |
| `PRECIOS_AMPLIACION` | Costo de cada ampliación de granja (dinero del juego) |
| `ESCUDOS` | Duración y precio de cada escudo (dinero del juego) |
| `ECLOSION_BASE` / `BONO_GALLINA` | Tiempo de eclosión y bono de las gallinas |
| `ZORRO_CADA` / `ZORRO_VIDA` | Frecuencia y vida del zorro |
| `DURACIONES_CIERRE` / `PRECIOS_CIERRE` | Mejora de cierre |
| `PROB_CERCA` / `PRECIOS_CERCA` | Mejora de cerca eléctrica |
| `RENACER_BASE` / `BONO_RENACER` | Costo y bono de renacer |
| `HORA_DORADA_CADA` / `HORA_DORADA_DURACION` | Evento de hora dorada |
| `OFFLINE_PORCENTAJE` / `OFFLINE_MAX_HORAS` | Ganancias mientras no estás |
| `RACHA_SEGUNDOS` / `RACHA_MINIMO` | Premios de la racha diaria |
| `PRECIO_MISTERIOSO` / `PESOS_MISTERIOSO` | Precio y probabilidades del huevo misterioso |
| `BONO_ALIADO` | Bono de ingresos por tener aliado |

Las rarezas están en `RAREZAS`, las mutaciones en `MUTACIONES` y los niveles de la caminadora en `CAMINADORA`.

> Si cambias `PREMIO_MISION_SEGUNDOS` o `PREMIO_MISION_MINIMO`, cámbialos también al principio de `RobaHuevos_Cliente.lua`.

---

## 📄 Licencia

Proyecto personal. Puedes usarlo y modificarlo libremente.
