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
3. Pisa el **círculo verde** de tu granja para recoger el dinero.
4. **Roba** huevos de otras granjas (mantén **E** sobre un huevo ajeno) y llévalos a la tuya.
5. **Defiéndete**: toca al ladrón, golpéalo con el 🏏 bate o cierra tu granja con el **círculo rojo**.
6. **Vende** tus huevos con **F** (50 % de su valor).

### Funciones

| Función | Descripción |
|---|---|
| 🪺 **Nidos** | Empiezas con 4 y puedes desbloquear hasta 12. |
| 🐣 **Eclosión** | Los huevos se convierten en gallinas con el tiempo y producen x2. |
| 🔥🌈 **Mutaciones** | Huevos de Lava (x2) y Arcoíris (x3). |
| 🏃 **Caminadora** | Frente a cada granja. Caminar en ella sube tu velocidad (8 niveles, de 16 a 34). |
| 🦊 **Zorro** | Cada 6 min intenta robar un huevo. Golpéalo 3 veces para ahuyentarlo y ganar premio. |
| 🌟 **Hora dorada** | Cada 5 min, durante 60 s, salen más huevos raros y mutaciones. |
| 📋 **Misiones diarias** | 3 misiones al día con premio en dinero. |
| 🛡️ **Escudos** | Protección al entrar (60 s) y después de que te roban (30 s). |
| ⚡ **Cerca eléctrica** | Mejora de tienda: puede electrocutar al ladrón cuando sale con tu huevo. |
| 🔒 **Cierre largo** | Mejora de tienda: tu granja queda cerrada más tiempo. |
| ♻️ **Renacer** | Reinicias tu progreso a cambio de +50 % de ingresos permanente. |
| 🏆 **Tabla global** | Los 10 jugadores más ricos de todos los servidores. |
| 💾 **Guardado** | El progreso se guarda automáticamente con DataStore. |

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

---

## ⚙️ Configuración

Todo se ajusta en la tabla `CONFIG`, al principio de `RobaHuevos_Servidor.lua`:

| Opción | Qué controla |
|---|---|
| `CENTRO` | Dónde se construye el mapa |
| `DINERO_INICIAL` | Dinero al empezar |
| `INTERVALO_HUEVOS` / `DURACION_CINTA` | Ritmo de la cinta |
| `PRECIOS_NIDO` | Costo de cada nido |
| `ECLOSION_BASE` / `BONO_GALLINA` | Tiempo de eclosión y bono de las gallinas |
| `ZORRO_CADA` / `ZORRO_VIDA` | Frecuencia y vida del zorro |
| `DURACIONES_CIERRE` / `PRECIOS_CIERRE` | Mejora de cierre |
| `PROB_CERCA` / `PRECIOS_CERCA` | Mejora de cerca eléctrica |
| `RENACER_BASE` / `BONO_RENACER` | Costo y bono de renacer |
| `HORA_DORADA_CADA` / `HORA_DORADA_DURACION` | Evento de hora dorada |

Las rarezas están en `RAREZAS`, las mutaciones en `MUTACIONES` y los niveles de la caminadora en `CAMINADORA`.

> Si cambias `PREMIO_MISION_SEGUNDOS` o `PREMIO_MISION_MINIMO`, cámbialos también al principio de `RobaHuevos_Cliente.lua`.

---

## 📄 Licencia

Proyecto personal. Puedes usarlo y modificarlo libremente.
