--[[
	ROBA EL HUEVO  -  Script del SERVIDOR  (v4)
	Dónde va: ServerScriptService  (Insertar objeto > Script)
	Construye todo el mapa automáticamente al iniciar el juego.

	Novedades v3:
	  • Caminadora frente a cada granja: camina en ella para subir de nivel y ser más rápido.
	  • Los huevos eclosionan en gallinas (producen x2).
	  • Mutaciones: huevos de Lava (x2) y Arcoíris (x3).
	  • Zorro NPC que roba huevos: golpéalo con el bate para ahuyentarlo.
	  • Misiones diarias con premio.
	  • Mejoras de defensa: cierre más largo y cerca eléctrica.
	  • Tienda en la plaza (al final de la cinta) con mejoras y Game Passes.
	  • Tabla global de los jugadores más ricos.

	Novedades v4:
	  • La caminadora está al costado de la granja; el jugador corre fijo en el centro.
	  • La caminadora cambia de color y de diseño en cada nivel.
	  • Ampliar la granja (+6 nidos por ampliación) con dinero del juego o Robux.
	  • Escudos de 10 min, 30 min, 1 día y 2 días con dinero del juego o Robux.

	⚙️ Game Passes: créalos en create.roblox.com y pon sus IDs en CONFIG.PASES.
	⚙️ Productos (Robux, compra repetible): pon sus IDs en CONFIG.PRODUCTOS.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local BadgeService = game:GetService("BadgeService")

------------------------------------------------------------------
-- CONFIGURACIÓN
------------------------------------------------------------------
local CONFIG = {
	CENTRO = Vector3.new(0, 300, 0), -- el mapa se construye en el cielo para no chocar con tu escenario
	DINERO_INICIAL = 100,
	INTERVALO_HUEVOS = 7, -- segundos entre huevos en la cinta (en la hora dorada, la mitad)
	DURACION_CINTA = 40, -- segundos que tarda un huevo en cruzar la cinta
	FACTOR_CARGANDO = 0.7, -- el ladrón va al 70 % de su velocidad
	ESPERA_BLOQUEO = 20, -- tiempo tras el cierre antes de poder cerrar otra vez
	ESCUDO_ROBO = 30, -- protección automática después de que te roban
	ESCUDO_ENTRADA = 60, -- protección al entrar al juego
	VENTA_PORCENTAJE = 0.5,
	NIDOS_INICIALES = 4,
	-- nidos 1-12: granja normal; 13-18: ampliación 1; 19-24: ampliación 2
	PRECIOS_NIDO = {
		0, 0, 0, 0, 500, 2500, 10000, 40000, 150000, 500000, 1500000, 5000000,
		8000000, 12000000, 18000000, 25000000, 35000000, 50000000,
		70000000, 100000000, 140000000, 200000000, 280000000, 400000000,
	},
	-- Ampliar la granja con dinero del juego (con Robux es el producto "Ampliar")
	PRECIOS_AMPLIACION = { 250000, 2500000 },
	-- Escudos: nadie puede entrar a tu granja. El tiempo corre aunque no estés conectado.
	ESCUDOS = {
		Escudo10m = { nombre = "10 minutos", segundos = 600, precio = 5000 },
		Escudo30m = { nombre = "30 minutos", segundos = 1800, precio = 15000 },
		Escudo1d = { nombre = "1 día", segundos = 86400, precio = 400000 },
		Escudo2d = { nombre = "2 días", segundos = 172800, precio = 700000 },
	},
	RENACER_BASE = 1000000, -- costo = base * (renacimientos + 1)^2
	BONO_RENACER = 0.5, -- +50 % de ingresos por renacimiento
	HORA_DORADA_CADA = 300,
	HORA_DORADA_DURACION = 60,
	GUARDAR_CADA = 60,

	-- Eclosión
	ECLOSION_BASE = 90, -- segundos para Común
	ECLOSION_POR_RAREZA = 30, -- segundos extra por cada rareza
	BONO_GALLINA = 2,

	-- Zorro
	ZORRO_CADA = 360, -- segundos entre apariciones
	ZORRO_VIDA = 3,
	ZORRO_VELOCIDAD = 14,

	-- Mejoras de defensa (se compran en la tienda con dinero del juego)
	DURACIONES_CIERRE = { 60, 80, 100, 120, 150 }, -- nivel 1 = gratis
	PRECIOS_CIERRE = { 0, 20000, 100000, 500000, 2000000 },
	PROB_CERCA = { 0.25, 0.5, 0.75 }, -- probabilidad de electrocutar al ladrón al salir
	PRECIOS_CERCA = { 50000, 300000, 1500000 },

	-- Misiones
	PREMIO_MISION_SEGUNDOS = 150, -- premio = 150 s de tus ingresos
	PREMIO_MISION_MINIMO = 500,

	-- Game Passes: pon aquí los IDs que te da Roblox (0 = sin configurar)
	PASES = {
		Dinero2x = 0,
		BateDorado = 0,
		CaminadoraVIP = 0,
	},
	PASES_GRATIS_EN_STUDIO = true, -- en Studio tienes todos los pases para probar

	-- Productos de desarrollador (Robux, se compran las veces que quieras): pon aquí sus IDs
	PRODUCTOS = {
		Ampliar = 0,
		Escudo10m = 0,
		Escudo30m = 0,
		Escudo1d = 0,
		Escudo2d = 0,
	},

	-- Ganancias offline: porcentaje de tus ingresos mientras no estás (con un máximo de horas)
	OFFLINE_PORCENTAJE = 0.25,
	OFFLINE_MAX_HORAS = 8,

	-- Racha diaria: premio = segundos de tus ingresos según el día (el día 7 da un huevo Mítico)
	RACHA_SEGUNDOS = { 60, 120, 180, 300, 450, 600 },
	RACHA_MINIMO = 500, -- mínimo por día (se multiplica por el número de día)

	-- Huevo misterioso: precio y probabilidad de cada rareza (Común ... Dorado)
	PRECIO_MISTERIOSO = 8000,
	PESOS_MISTERIOSO = { 35, 25, 20, 12, 6, 1.7, 0.3 },

	-- Aliados (equipos de 2): bono de ingresos para los dos mientras estén aliados
	BONO_ALIADO = 0.1,

	-- Insignias (Badges): créalas en create.roblox.com y pon aquí sus IDs (0 = sin configurar)
	INSIGNIAS = {
		PrimerRobo = 0, -- roba tu primer huevo
		CaminadoraMaxima = 0, -- caminadora nivel 8
		Cazazorros = 0, -- ahuyenta 10 zorros
		PrimerRenacer = 0, -- renace por primera vez
		Racha7 = 0, -- entra 7 días seguidos
		HuevoDorado = 0, -- consigue un huevo Dorado
	},
}

local RAREZAS = {
	{ nombre = "Común", color = Color3.fromRGB(240, 235, 220), precio = 50, ingreso = 1, peso = 50 },
	{ nombre = "Poco común", color = Color3.fromRGB(110, 220, 110), precio = 250, ingreso = 4, peso = 25 },
	{ nombre = "Raro", color = Color3.fromRGB(80, 160, 255), precio = 1200, ingreso = 15, peso = 13 },
	{ nombre = "Épico", color = Color3.fromRGB(170, 90, 255), precio = 6000, ingreso = 60, peso = 7 },
	{ nombre = "Legendario", color = Color3.fromRGB(255, 150, 30), precio = 30000, ingreso = 250, peso = 3.5 },
	{ nombre = "Mítico", color = Color3.fromRGB(255, 80, 170), precio = 150000, ingreso = 1000, peso = 1.2 },
	{ nombre = "Dorado", color = Color3.fromRGB(255, 215, 0), precio = 750000, ingreso = 4500, peso = 0.3 },
}

local MUTACIONES = {
	{ nombre = "Lava", mult = 2, prob = 0.06, color = Color3.fromRGB(255, 90, 20) },
	{ nombre = "Arcoíris", mult = 3, prob = 0.03, color = Color3.fromRGB(255, 120, 255) },
}

-- niveles de la caminadora: pasos necesarios y velocidad que dan
-- color = banda, marco = estructura, detalle = postes, luces y arcos
local CAMINADORA = {
	{ pasos = 0, vel = 16, color = Color3.fromRGB(90, 90, 95), material = Enum.Material.Fabric, marco = Color3.fromRGB(150, 110, 70), detalle = Color3.fromRGB(200, 200, 205) },
	{ pasos = 500, vel = 18, color = Color3.fromRGB(130, 135, 145), material = Enum.Material.Metal, marco = Color3.fromRGB(70, 70, 80), detalle = Color3.fromRGB(225, 225, 235) },
	{ pasos = 1500, vel = 20, color = Color3.fromRGB(60, 130, 220), material = Enum.Material.Metal, marco = Color3.fromRGB(30, 50, 90), detalle = Color3.fromRGB(120, 200, 255) },
	{ pasos = 4000, vel = 22, color = Color3.fromRGB(60, 190, 90), material = Enum.Material.DiamondPlate, marco = Color3.fromRGB(25, 70, 35), detalle = Color3.fromRGB(140, 255, 140) },
	{ pasos = 10000, vel = 24, color = Color3.fromRGB(160, 80, 220), material = Enum.Material.DiamondPlate, marco = Color3.fromRGB(50, 25, 80), detalle = Color3.fromRGB(220, 150, 255) },
	{ pasos = 25000, vel = 27, color = Color3.fromRGB(255, 140, 30), material = Enum.Material.Neon, marco = Color3.fromRGB(60, 30, 10), detalle = Color3.fromRGB(255, 200, 80) },
	{ pasos = 50000, vel = 30, color = Color3.fromRGB(255, 60, 60), material = Enum.Material.Neon, marco = Color3.fromRGB(40, 10, 10), detalle = Color3.fromRGB(255, 120, 120) },
	{ pasos = 100000, vel = 34, color = Color3.fromRGB(255, 215, 0), material = Enum.Material.Neon, marco = Color3.fromRGB(30, 25, 10), detalle = Color3.fromRGB(255, 240, 150) },
}

local TIPOS_MISION = {
	{ id = "comprar", texto = "Compra %d huevos", min = 3, max = 8 },
	{ id = "robar", texto = "Roba %d huevos", min = 1, max = 3 },
	{ id = "atrapar", texto = "Detén %d ladrones", min = 1, max = 2 },
	{ id = "pasos", texto = "Camina %d pasos en tu caminadora", min = 300, max = 1000 },
	{ id = "eclosionar", texto = "Haz eclosionar %d huevos", min = 1, max = 3 },
	{ id = "zorro", texto = "Golpea al zorro %d veces", min = 2, max = 4 },
}

local COLORES_GRANERO = {
	Color3.fromRGB(190, 50, 45),
	Color3.fromRGB(60, 110, 190),
	Color3.fromRGB(215, 165, 40),
	Color3.fromRGB(70, 150, 80),
	Color3.fromRGB(140, 80, 180),
	Color3.fromRGB(215, 110, 50),
}

local MADERA = Color3.fromRGB(125, 88, 55)
local MADERA_OSCURA = Color3.fromRGB(85, 60, 40)
local PAJA = Color3.fromRGB(225, 195, 95)
local TIERRA = Color3.fromRGB(140, 100, 65)
local ELECTRICO = Color3.fromRGB(90, 220, 255)

------------------------------------------------------------------
-- EVENTOS Y UTILIDADES
------------------------------------------------------------------
local eventoNotificar = Instance.new("RemoteEvent")
eventoNotificar.Name = "Notificar"
eventoNotificar.Parent = ReplicatedStorage

local eventoMisiones = Instance.new("RemoteEvent")
eventoMisiones.Name = "Misiones"
eventoMisiones.Parent = ReplicatedStorage

local eventoRevelar = Instance.new("RemoteEvent")
eventoRevelar.Name = "Revelar"
eventoRevelar.Parent = ReplicatedStorage

-- texto puede ser nil (solo sonido); sonido es un nombre de la tabla SONIDOS del cliente
local function notificar(plr, texto, sonido)
	if plr and plr.Parent then
		eventoNotificar:FireClient(plr, texto, sonido)
	end
end

local function notificarTodos(texto, sonido)
	eventoNotificar:FireAllClients(texto, sonido)
end

local function formato(n)
	n = math.floor(n)
	if n >= 1e9 then
		return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

local function formatoTiempo(s)
	s = math.max(0, math.ceil(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

local function formatoDuracion(s)
	s = math.max(0, math.floor(s))
	if s >= 86400 then
		return string.format("%dd %dh", s // 86400, (s % 86400) // 3600)
	elseif s >= 3600 then
		return string.format("%dh %dm", s // 3600, (s % 3600) // 60)
	elseif s >= 60 then
		return string.format("%dm %ds", s // 60, s % 60)
	end
	return s .. "s"
end

local function stat(plr, nombre)
	local ls = plr:FindFirstChild("leaderstats")
	return ls and ls:FindFirstChild(nombre)
end

local function dinero(plr)
	return stat(plr, "Dinero")
end

local function darDinero(plr, cantidad)
	local d = dinero(plr)
	if d then
		d.Value += math.floor(cantidad)
	end
end

------------------------------------------------------------------
-- ESTADO
------------------------------------------------------------------
local estado = {} -- [jugador] = {pasos, cierre, cerca, pases, misiones, ultimoEnvio}
local bases = {} -- lista de granjas
local basesDe = {} -- [jugador] = granja
local cargando = {} -- [jugador] = {huevo, info, base, ranura, dueno, salio}
local datosCargados = {} -- [jugador] = true si el DataStore cargó bien
local horaDorada = false
local zorro = nil -- zorro activo
local enCaminadora = {} -- [jugador] = granja (corriendo en su caminadora)
local aliados = {} -- [jugador] = su aliado (siempre en las dos direcciones)
local invitaciones = {} -- [quien invita] = invitado

local comprarItem, golpearZorro, intentarRobar, aplicarNidos, entrarCaminadora, salirCaminadora -- se definen más abajo

local function tienePase(plr, nombre)
	local e = estado[plr]
	return e ~= nil and e.pases[nombre] == true
end

local function sonAliados(a, b)
	return a ~= nil and b ~= nil and aliados[a] == b
end

local function multiplicador(plr)
	local r = stat(plr, "Renacer")
	local m = 1 + (r and r.Value or 0) * CONFIG.BONO_RENACER
	if tienePase(plr, "Dinero2x") then
		m *= 2
	end
	if aliados[plr] then
		m *= 1 + CONFIG.BONO_ALIADO
	end
	return m
end

-- da una insignia una sola vez por sesión (Roblox ignora si ya la tiene)
local function darInsignia(plr, nombre)
	local id = CONFIG.INSIGNIAS[nombre]
	local e = estado[plr]
	if not id or id == 0 or not e or e.insignias[nombre] then
		return
	end
	e.insignias[nombre] = true
	task.spawn(function()
		pcall(function()
			BadgeService:AwardBadge(plr.UserId, id)
		end)
	end)
end

local function costoRenacer(plr)
	local r = stat(plr, "Renacer")
	return CONFIG.RENACER_BASE * ((r and r.Value or 0) + 1) ^ 2
end

local function nivelCaminadora(pasos)
	local n = 1
	for i, nv in ipairs(CAMINADORA) do
		if pasos >= nv.pasos then
			n = i
		end
	end
	return n
end

local function velocidadDe(plr)
	local e = estado[plr]
	return CAMINADORA[nivelCaminadora(e and e.pasos or 0)].vel
end

local function aplicarVelocidad(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		local v = velocidadDe(plr)
		hum.WalkSpeed = cargando[plr] and math.floor(v * CONFIG.FACTOR_CARGANDO) or v
	end
end

local function duracionCierre(plr)
	local e = estado[plr]
	return CONFIG.DURACIONES_CIERRE[e and e.cierre or 1]
end

-- ¿la granja está protegida? (cierre, escudo de entrada/robo o escudo comprado)
local function protegida(base)
	if os.clock() < base.bloqueadoHasta then
		return true
	end
	local e = base.dueno and estado[base.dueno]
	return e ~= nil and os.time() < (e.escudoHasta or 0)
end

------------------------------------------------------------------
-- MISIONES DIARIAS
------------------------------------------------------------------
local function diaActual()
	return math.floor(os.time() / 86400)
end

local function generarMisiones(e)
	local tipos = table.clone(TIPOS_MISION)
	local lista = {}
	for _ = 1, 3 do
		local t = table.remove(tipos, math.random(#tipos))
		local meta = math.random(t.min, t.max)
		if t.id == "pasos" then
			meta = math.floor(meta / 50) * 50
		end
		table.insert(lista, { id = t.id, texto = string.format(t.texto, meta), meta = meta, prog = 0, hecha = false })
	end
	e.misiones = { dia = diaActual(), lista = lista }
end

local function enviarMisiones(plr)
	local e = estado[plr]
	if e and e.misiones then
		e.ultimoEnvio = os.clock()
		eventoMisiones:FireClient(plr, e.misiones.lista)
	end
end
eventoMisiones.OnServerEvent:Connect(enviarMisiones) -- el cliente las pide al iniciar

local function revisarDia(plr)
	local e = estado[plr]
	if e and (not e.misiones or e.misiones.dia ~= diaActual()) then
		generarMisiones(e)
		enviarMisiones(plr)
		notificar(plr, "📋 ¡Nuevas misiones del día!")
	end
end

local function progresoMision(plr, id, n)
	local e = estado[plr]
	if not e or not e.misiones then
		return
	end
	revisarDia(plr)
	local cambio, completada = false, false
	for _, m in ipairs(e.misiones.lista) do
		if m.id == id and not m.hecha then
			m.prog = math.min(m.meta, m.prog + (n or 1))
			cambio = true
			if m.prog >= m.meta then
				m.hecha = true
				completada = true
				local premio = math.max(CONFIG.PREMIO_MISION_MINIMO, (plr:GetAttribute("IngresoSeg") or 0) * CONFIG.PREMIO_MISION_SEGUNDOS)
				darDinero(plr, premio)
				notificar(plr, "📋 ¡Misión completada! +$" .. formato(premio), "Mision")
			end
		end
	end
	-- los pasos cambian muy seguido: se envían como mucho 2 veces por segundo
	if cambio and (completada or id ~= "pasos" or os.clock() - (e.ultimoEnvio or 0) > 0.5) then
		enviarMisiones(plr)
	end
end

------------------------------------------------------------------
-- CONSTRUCCIÓN: AYUDANTES
------------------------------------------------------------------
local mapa = Instance.new("Folder")
mapa.Name = "RobaHuevosMapa"
mapa.Parent = workspace

local function crearParte(props, clase)
	local p = Instance.new(clase or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	if props.Parent ~= false then
		p.Parent = props.Parent or mapa
	end
	return p
end

-- pieza decorativa soldada a una pieza raíz (se mueve con ella)
local function pegar(raiz, props, offset, clase)
	props.Anchored = false
	props.CanCollide = false
	props.CanTouch = false
	props.Massless = true
	props.CFrame = raiz.CFrame * offset
	props.Parent = raiz
	local p = crearParte(props, clase)
	local w = Instance.new("WeldConstraint")
	w.Part0 = raiz
	w.Part1 = p
	w.Parent = p
	return p
end

local function crearCartel(adornee, texto, alto, offsetY, ancho)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(ancho or 220, alto or 50)
	bb.StudsOffset = Vector3.new(0, offsetY or 3, 0)
	bb.MaxDistance = 140
	bb.Adornee = adornee
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextScaled = true
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextStrokeTransparency = 0
	lbl.Text = texto
	lbl.Parent = bb
	bb.Parent = adornee
	return lbl
end

-- cilindro "acostado" en Roblox: el eje va en X, así que lo giramos para que quede vertical
local VERTICAL = CFrame.Angles(0, 0, math.rad(90))

local function arbol(pos, escala)
	escala = escala or 1
	crearParte({ Name = "Tronco", Size = Vector3.new(2, 8, 2) * escala, Position = pos + Vector3.new(0, 4 * escala, 0), Color = MADERA_OSCURA, Material = Enum.Material.Wood })
	crearParte({ Name = "Copa", Shape = Enum.PartType.Ball, Size = Vector3.new(10, 10, 10) * escala, Position = pos + Vector3.new(0, 10 * escala, 0), Color = Color3.fromRGB(70, 150, 60), Material = Enum.Material.Grass })
	crearParte({ Name = "Copa", Shape = Enum.PartType.Ball, Size = Vector3.new(7, 7, 7) * escala, Position = pos + Vector3.new(2 * escala, 13 * escala, 1 * escala), Color = Color3.fromRGB(85, 170, 70), Material = Enum.Material.Grass })
end

local function techoDosAguas(cf, ancho, fondo, alto, color, padre)
	-- cumbrera a lo largo de X local; cf = centro de la base del techo
	local mitad = fondo / 2
	crearParte({ Name = "Techo", Size = Vector3.new(ancho, alto, mitad), CFrame = cf * CFrame.new(0, alto / 2, -mitad / 2), Color = color, Material = Enum.Material.WoodPlanks, Parent = padre }, "WedgePart")
	crearParte({ Name = "Techo", Size = Vector3.new(ancho, alto, mitad), CFrame = cf * CFrame.new(0, alto / 2, mitad / 2) * CFrame.Angles(0, math.pi, 0), Color = color, Material = Enum.Material.WoodPlanks, Parent = padre }, "WedgePart")
end

local C = CONFIG.CENTRO
local SUELO_Y = C.Y + 1
local MEDIO = 23 -- media medida de la granja (cerca)

local function dentroDeBase(base, pos)
	local p = base.cf:PointToObjectSpace(pos)
	return math.abs(p.X) < MEDIO and p.Z > -MEDIO and p.Z < (base.fondo or MEDIO) and p.Y > -2 and p.Y < 15
end

-- 12 nidos en la granja normal + 6 por cada ampliación
local function maxNidos(base)
	return 12 + 6 * (base.ampliacion or 0)
end

local function ranuraLibre(base)
	for i, r in ipairs(base.ranuras) do
		if i <= base.nidos and not r.huevo then
			return i
		end
	end
	return nil
end

------------------------------------------------------------------
-- HUEVOS Y GALLINAS
--   info = { r = rareza, g = es gallina, m = mutación (0 = ninguna) }
------------------------------------------------------------------
local function valorMult(info)
	local m = 1
	if info.g then
		m *= CONFIG.BONO_GALLINA
	end
	if info.m and info.m > 0 then
		m *= MUTACIONES[info.m].mult
	end
	return m
end

local function ingresoDe(info)
	return RAREZAS[info.r].ingreso * valorMult(info)
end

local function precioDe(info)
	return RAREZAS[info.r].precio * valorMult(info)
end

local function nombreDe(info)
	local n = (info.g and "🐔 " or "🥚 ") .. RAREZAS[info.r].nombre
	if info.m and info.m > 0 then
		n ..= " (" .. MUTACIONES[info.m].nombre .. ")"
	end
	return n
end

local function tiempoEclosion(ri)
	return CONFIG.ECLOSION_BASE + (ri - 1) * CONFIG.ECLOSION_POR_RAREZA
end

local function crearGallina(color)
	local cuerpo = crearParte({ Name = "Gallina", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(), Color = color, Material = Enum.Material.SmoothPlastic, CanCollide = false, CanTouch = false, Parent = false })
	local claro = color:Lerp(Color3.new(1, 1, 1), 0.4)
	pegar(cuerpo, { Name = "Cabeza", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Color = claro, Material = Enum.Material.SmoothPlastic }, CFrame.new(0, 1.6, -1.2))
	pegar(cuerpo, { Name = "Pico", Size = Vector3.new(0.5, 0.4, 0.7), Color = Color3.fromRGB(255, 170, 30) }, CFrame.new(0, 1.5, -2.2))
	pegar(cuerpo, { Name = "Cresta", Size = Vector3.new(0.3, 0.7, 0.9), Color = Color3.fromRGB(220, 30, 30) }, CFrame.new(0, 2.6, -1.1))
	for _, x in ipairs({ -0.5, 0.5 }) do
		pegar(cuerpo, { Name = "Ojo", Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = Color3.new(0, 0, 0) }, CFrame.new(x, 1.8, -1.95))
		pegar(cuerpo, { Name = "Pata", Size = Vector3.new(0.3, 1, 0.3), Color = Color3.fromRGB(255, 170, 30) }, CFrame.new(x * 1.2, -1.6, 0))
		pegar(cuerpo, { Name = "Ala", Size = Vector3.new(0.4, 1.5, 2), Color = claro, Material = Enum.Material.SmoothPlastic }, CFrame.new(x * 3, 0.1, 0.2))
	end
	pegar(cuerpo, { Name = "Cola", Size = Vector3.new(0.4, 1.4, 1), Color = color }, CFrame.new(0, 1.2, 1.4) * CFrame.Angles(math.rad(30), 0, 0))
	return cuerpo
end

local function crearHuevo(info)
	local r = RAREZAS[info.r]
	local color = (info.m == 1) and MUTACIONES[1].color or r.color
	local h
	if info.g then
		h = crearGallina(color)
	else
		h = Instance.new("Part")
		h.Name = "Huevo"
		h.Size = Vector3.new(3, 4, 3)
		h.Color = color
		h.Material = (info.r >= 5 or (info.m or 0) > 0) and Enum.Material.Neon or Enum.Material.SmoothPlastic
		h.Anchored = true
		h.CanCollide = false
		h.CanTouch = false
		local malla = Instance.new("SpecialMesh")
		malla.MeshType = Enum.MeshType.Sphere
		malla.Parent = h
	end
	h:SetAttribute("Rareza", info.r)
	local lbl = crearCartel(h, nombreDe(info) .. "\n$" .. formato(ingresoDe(info)) .. "/s", 55, 3.5, 240)
	lbl.TextColor3 = r.color
	if info.r >= 4 then
		local brillo = Instance.new("Sparkles")
		brillo.SparkleColor = r.color
		brillo.Parent = h
	end
	if info.r >= 5 then
		local luz = Instance.new("PointLight")
		luz.Color = r.color
		luz.Range = 10
		luz.Parent = h
	end
	if info.m == 1 then
		local fuego = Instance.new("Fire")
		fuego.Size = 3
		fuego.Heat = 4
		fuego.Parent = h
	elseif info.m == 2 then
		CollectionService:AddTag(h, "Arcoiris") -- el cliente le cambia el color
	end
	return h, lbl
end

local function colocarHuevo(base, idx, info)
	local ranura = base.ranuras[idx]
	local h, lbl = crearHuevo(info)
	h.CFrame = info.g and ranura.cf * CFrame.new(0, 0.4, 0) or ranura.cf
	h:SetAttribute("DuenoId", base.dueno and base.dueno.UserId or 0)
	ranura.huevo = h
	ranura.info = info
	ranura.lbl = lbl
	ranura.eclosion = (not info.g) and (os.clock() + tiempoEclosion(info.r)) or nil

	local pRobar = Instance.new("ProximityPrompt")
	pRobar.Name = "PromptRobar"
	pRobar.ActionText = "Robar"
	pRobar.ObjectText = nombreDe(info)
	pRobar.HoldDuration = 1.2
	pRobar.MaxActivationDistance = 8
	pRobar.RequiresLineOfSight = false
	pRobar.Parent = h

	local pVender = Instance.new("ProximityPrompt")
	pVender.Name = "PromptVender"
	pVender.ActionText = "Vender $" .. formato(precioDe(info) * CONFIG.VENTA_PORCENTAJE)
	pVender.ObjectText = nombreDe(info)
	pVender.KeyboardKeyCode = Enum.KeyCode.F
	pVender.HoldDuration = 0.6
	pVender.MaxActivationDistance = 8
	pVender.RequiresLineOfSight = false
	pVender.Parent = h

	pRobar.Triggered:Connect(function(plr)
		intentarRobar(plr, base, idx, h)
	end)
	pVender.Triggered:Connect(function(plr)
		if plr ~= base.dueno or ranura.huevo ~= h then
			return
		end
		ranura.huevo = nil
		ranura.info = nil
		ranura.lbl = nil
		ranura.eclosion = nil
		h:Destroy()
		local ganancia = math.floor(precioDe(info) * CONFIG.VENTA_PORCENTAJE)
		darDinero(plr, ganancia)
		notificar(plr, "Vendiste " .. nombreDe(info) .. " por $" .. formato(ganancia))
	end)

	h.Parent = base.modelo
end

-- saca el huevo de su nido y lo deja listo para cargarlo (ladrón o zorro)
local function arrancarHuevo(ranura)
	local h, info = ranura.huevo, ranura.info
	ranura.huevo = nil
	ranura.info = nil
	ranura.lbl = nil
	ranura.eclosion = nil
	for _, hijo in ipairs(h:GetChildren()) do
		if hijo:IsA("ProximityPrompt") then
			hijo:Destroy()
		end
	end
	h.Anchored = false
	h.Massless = true
	return h, info
end

local function soldarA(parte, raiz, offset)
	parte.CFrame = raiz.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = raiz
	w.Part1 = parte
	w.Parent = parte
end

local function vaciarBase(base)
	for _, r in ipairs(base.ranuras) do
		if r.huevo then
			r.huevo:Destroy()
		end
		r.huevo = nil
		r.info = nil
		r.lbl = nil
		r.eclosion = nil
	end
end

-- devuelve un huevo a su dueño (si sigue en el juego y con la misma granja)
local function devolverHuevo(dueno, base, idxPreferido, info)
	if not (dueno and dueno.Parent and basesDe[dueno] == base) then
		return false
	end
	local idx = (idxPreferido and idxPreferido <= base.nidos and base.ranuras[idxPreferido].huevo == nil) and idxPreferido or ranuraLibre(base)
	if idx then
		colocarHuevo(base, idx, info)
	else
		darDinero(dueno, precioDe(info))
	end
	return true
end

------------------------------------------------------------------
-- NIDOS (desbloqueables)
------------------------------------------------------------------
local function desbloquearNido(plr, base, i)
	if plr ~= base.dueno or i ~= base.nidos + 1 or i > maxNidos(base) then
		return
	end
	local precio = CONFIG.PRECIOS_NIDO[i]
	local d = dinero(plr)
	if not d or d.Value < precio then
		notificar(plr, "Necesitas $" .. formato(precio) .. " para este nido")
		return
	end
	d.Value -= precio
	aplicarNidos(base, i)
	notificar(plr, "🪺 ¡Nuevo nido desbloqueado! (" .. i .. "/" .. maxNidos(base) .. ")")
end

function aplicarNidos(base, n)
	base.nidos = n
	local duenoId = base.dueno and base.dueno.UserId or 0
	local maximo = maxNidos(base)
	for i, r in ipairs(base.ranuras) do
		local nido = r.nido
		nido:SetAttribute("DuenoId", duenoId)
		local prompt = nido:FindFirstChild("PromptNido")
		local cartel = nido:FindFirstChild("CartelNido")
		nido.CanCollide = i <= maximo
		if i > maximo then
			-- nido de una ampliación que aún no se compra: invisible
			nido.Transparency = 1
			if prompt then
				prompt:Destroy()
			end
			if cartel then
				cartel:Destroy()
			end
		elseif i <= n then
			nido.Color = PAJA
			nido.Transparency = 0
			if prompt then
				prompt:Destroy()
			end
			if cartel then
				cartel:Destroy()
			end
		else
			nido.Color = Color3.fromRGB(90, 80, 70)
			nido.Transparency = 0.4
			if not cartel then
				cartel = crearCartel(nido, "", 40, 2.5, 160).Parent
				cartel.Name = "CartelNido"
			end
			local lbl = cartel:FindFirstChildOfClass("TextLabel")
			if i == n + 1 then
				lbl.Text = "🔒 $" .. formato(CONFIG.PRECIOS_NIDO[i])
				lbl.TextColor3 = Color3.fromRGB(255, 230, 120)
				if not prompt then
					prompt = Instance.new("ProximityPrompt")
					prompt.Name = "PromptNido"
					prompt.ActionText = "Desbloquear $" .. formato(CONFIG.PRECIOS_NIDO[i])
					prompt.ObjectText = "Nido"
					prompt.HoldDuration = 0.4
					prompt.MaxActivationDistance = 8
					prompt.RequiresLineOfSight = false
					prompt.Triggered:Connect(function(plr)
						desbloquearNido(plr, base, i)
					end)
					prompt.Parent = nido
				end
			else
				lbl.Text = "🔒"
				lbl.TextColor3 = Color3.new(1, 1, 1)
				if prompt then
					prompt:Destroy()
				end
			end
		end
	end
end

------------------------------------------------------------------
-- CERCA ELÉCTRICA Y CAMINADORA (aspecto según el dueño)
------------------------------------------------------------------
local function aplicarCerca(base)
	local e = base.dueno and estado[base.dueno]
	local electrica = e and e.cerca > 0
	for _, t in ipairs(base.travesanos) do
		t.Color = electrica and ELECTRICO or MADERA
		t.Material = electrica and Enum.Material.Neon or Enum.Material.Wood
	end
end

-- La caminadora se reconstruye en cada nivel: cambia de color y gana piezas nuevas
local function aplicarCaminadora(base)
	local e = base.dueno and estado[base.dueno]
	local n = nivelCaminadora(e and e.pasos or 0)
	local duenoId = base.dueno and base.dueno.UserId or 0
	if base.caminadora and base.nivelCaminadora == n then
		base.consola:SetAttribute("DuenoId", duenoId)
		return
	end
	if base.caminadora then
		base.caminadora:Destroy()
	end
	base.nivelCaminadora = n
	local nv = CAMINADORA[n]
	local m = Instance.new("Model")
	m.Name = "Caminadora"
	m.Parent = base.modelo
	base.caminadora = m
	local function pieza(props, offset, clase)
		props.CFrame = base.tcf * offset
		props.Parent = m
		return crearParte(props, clase)
	end
	local brillo = n >= 2 and Enum.Material.Neon or Enum.Material.Metal
	local acento = nv.detalle -- color del neón (cambia en cada nivel)
	local oscuro = nv.marco:Lerp(Color3.new(0, 0, 0), 0.55)
	local tenue = acento:Lerp(Color3.new(0, 0, 0), 0.5) -- neón más suave (no encandila)

	-- Diseño tipo "portal": cubierta oscura con bordes de neón, banda negra con flechas
	-- que se mueven, pantalla brillante al frente, pasamanos de neón y consola al costado.
	-- El corredor está en el centro y mira hacia la pantalla (z local negativo).

	-- cubierta, bordes y rodillos
	pieza({ Name = "Cubierta", Size = Vector3.new(6.6, 0.9, 14), Color = oscuro, Material = Enum.Material.SmoothPlastic }, CFrame.new(0, 0.45, 0))
	for _, x in ipairs({ -3.15, 3.15 }) do
		pieza({ Name = "Borde", Size = Vector3.new(0.5, 1, 14.2), Color = nv.marco, Material = Enum.Material.Metal }, CFrame.new(x, 0.55, 0))
		pieza({ Name = "LuzBorde", Size = Vector3.new(0.12, 0.2, 14.2), Color = tenue, Material = Enum.Material.Neon }, CFrame.new(x * 1.07, 0.8, 0))
	end
	for _, z in ipairs({ -7.1, 7.1 }) do
		pieza({ Name = "Rodillo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6.2, 1.1, 1.1), Color = nv.marco, Material = Enum.Material.Metal }, CFrame.new(0, 0.55, z))
	end
	pieza({ Name = "LuzTrasera", Size = Vector3.new(1.6, 0.35, 0.1), Color = tenue, Material = Enum.Material.Neon }, CFrame.new(2.1, 0.55, 7.68))

	-- banda negra con flechas de neón (el cliente las mueve hacia atrás)
	local banda = pieza({ Name = "Banda", Size = Vector3.new(5, 0.3, 12), Color = Color3.fromRGB(20, 22, 28), Material = Enum.Material.Fabric }, CFrame.new(0, 0.95, 0))
	banda:SetAttribute("Velocidad", nv.vel)
	for k = 0, 4 do
		local z0 = -5.5 + k * 2.2
		for _, lado in ipairs({ -1, 1 }) do
			local barra = pieza({ Name = "Franja", Size = Vector3.new(2.5, 0.05, 0.4), Color = tenue, Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CanTouch = false }, CFrame.new(lado, 1.12, z0))
			barra:SetAttribute("Z0", z0)
			barra:SetAttribute("X0", lado)
			barra:SetAttribute("Giro", -lado * 30) -- las dos barras forman una flecha ">"
			CollectionService:AddTag(barra, "FranjaCaminadora")
		end
	end

	-- pantalla-portal al frente
	pieza({ Name = "MarcoPantalla", Size = Vector3.new(6.2, 7.4, 0.6), Color = nv.marco, Material = Enum.Material.Metal }, CFrame.new(0, 4.6, -7.25))
	-- pantalla clara y sin brillo para que se lean las letras oscuras
	local pantalla = pieza({ Name = "Pantalla", Size = Vector3.new(5.2, 6.4, 0.2), Color = acento:Lerp(Color3.new(1, 1, 1), 0.45), Material = Enum.Material.SmoothPlastic }, CFrame.new(0, 4.6, -6.9))
	local chispas = Instance.new("ParticleEmitter")
	chispas.Color = ColorSequence.new(acento)
	chispas.LightEmission = 1
	chispas.Size = NumberSequence.new(0.25, 0)
	chispas.Lifetime = NumberRange.new(0.6, 1.2)
	chispas.Rate = 4 + n * 3
	chispas.Speed = NumberRange.new(1, 3)
	chispas.SpreadAngle = Vector2.new(180, 180)
	chispas.Parent = pantalla

	-- pasamanos de neón a los lados (de la pantalla hacia el corredor)
	for _, x in ipairs({ -2.95, 2.95 }) do
		pieza({ Name = "PostePasamanos", Size = Vector3.new(0.4, 3.4, 0.4), Color = nv.marco, Material = Enum.Material.Metal }, CFrame.new(x, 2.6, -4.8))
		pieza({ Name = "Pasamanos", Size = Vector3.new(0.45, 0.45, 5.2), Color = tenue, Material = brillo }, CFrame.new(x, 4.4, -4.4))
		pieza({ Name = "Codo", Size = Vector3.new(0.45, 0.45, 2.2), Color = tenue, Material = brillo }, CFrame.new(x, 3.95, -1.4) * CFrame.Angles(math.rad(25), 0, 0))
	end

	-- consola al costado derecho
	local consola = pieza({ Name = "Consola", Size = Vector3.new(1.2, 3, 2.2), Color = oscuro, Material = Enum.Material.SmoothPlastic }, CFrame.new(3.95, 2.4, -5.4))
	pieza({ Name = "Display", Size = Vector3.new(0.1, 1.6, 1.4), Color = tenue, Material = Enum.Material.Neon }, CFrame.new(4.57, 2.9, -5.4))
	pieza({ Name = "Boton", Shape = Enum.PartType.Ball, Size = Vector3.new(0.6, 0.6, 0.6), Color = tenue, Material = Enum.Material.Neon }, CFrame.new(4.57, 1.6, -5.4))

	-- extras que se ganan al subir de nivel
	if n >= 3 then -- luz bajo la caminadora
		pieza({ Name = "LuzPiso", Size = Vector3.new(7.6, 0.1, 15.4), Color = tenue, Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false }, CFrame.new(0, 0.05, 0))
	end
	if n >= 5 then -- alas de neón arriba de la pantalla
		for _, x in ipairs({ -1, 1 }) do
			pieza({ Name = "Ala", Size = Vector3.new(0.4, 2.4, 0.4), Color = tenue, Material = Enum.Material.Neon }, CFrame.new(x * 3.4, 8.6, -7.25) * CFrame.Angles(0, 0, math.rad(-x * 30)))
		end
	end
	if n >= 6 then -- la pantalla ilumina alrededor
		local luz = Instance.new("PointLight")
		luz.Color = acento
		luz.Range = 16
		luz.Brightness = 2
		luz.Parent = pantalla
	end
	if n >= 7 then -- halo alrededor del marco
		pieza({ Name = "Halo", Size = Vector3.new(7, 8.2, 0.3), Color = tenue, Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false }, CFrame.new(0, 4.6, -7.6))
	end
	if n >= 8 then -- corona dorada con fuego
		local corona = pieza({ Name = "Corona", Shape = Enum.PartType.Ball, Size = Vector3.new(1.8, 1.8, 1.8), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon }, CFrame.new(0, 9.4, -7.25))
		local fuego = Instance.new("Fire")
		fuego.Size = 3
		fuego.Color = Color3.fromRGB(255, 200, 50)
		fuego.SecondaryColor = Color3.fromRGB(255, 120, 0)
		fuego.Parent = corona
	end

	-- texto escrito en la pantalla (lo ve el corredor y quien viene de la granja)
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.CanvasSize = Vector2.new(260, 320)
	sg.Parent = pantalla
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(20, 25, 40) -- letras oscuras sobre la pantalla clara
	lbl.TextStrokeTransparency = 1
	lbl.Text = "🏃"
	lbl.Parent = sg

	base.consola = consola
	consola:SetAttribute("DuenoId", duenoId)
	base.textoCaminadora = lbl
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptCorrer"
	prompt.ActionText = "Correr"
	prompt.ObjectText = "Caminadora nivel " .. n
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	-- E en la consola: subirse o bajarse (funciona aunque falle el script del cliente)
	prompt.Triggered:Connect(function(plr)
		if enCaminadora[plr] == base then
			salirCaminadora(plr)
		else
			entrarCaminadora(plr, base)
		end
	end)
	prompt.Parent = consola
	base.promptCorrer = prompt
end

------------------------------------------------------------------
-- MAPA
------------------------------------------------------------------
crearParte({ Name = "Suelo", Size = Vector3.new(380, 2, 260), Position = C, Color = Color3.fromRGB(95, 165, 75), Material = Enum.Material.Grass })

-- paredes invisibles para no caerse del mapa
for _, d in ipairs({ { 190, 0, 1, 260 }, { -190, 0, 1, 260 }, { 0, 130, 380, 1 }, { 0, -130, 380, 1 } }) do
	crearParte({ Name = "Limite", Size = Vector3.new(d[3], 40, d[4]), Position = C + Vector3.new(d[1], 20, d[2]), Transparency = 1 })
end

-- árboles en los bordes
for x = -180, 180, 20 do
	for _, z in ipairs({ -122, 122 }) do
		arbol(Vector3.new(C.X + x + math.random(-4, 4), SUELO_Y, C.Z + z + math.random(-3, 3)), 0.8 + math.random() * 0.5)
	end
end
for z = -105, 105, 30 do
	for _, x in ipairs({ -183, 183 }) do
		local libre = (x > 0 and math.abs(z) > 65) or (x < 0 and math.abs(z) > 15)
		if libre then
			arbol(Vector3.new(C.X + x, SUELO_Y, C.Z + z + math.random(-4, 4)), 0.8 + math.random() * 0.5)
		end
	end
end

-- cinta de madera
crearParte({ Name = "Cinta", Size = Vector3.new(250, 0.6, 12), Position = Vector3.new(C.X, SUELO_Y + 0.3, C.Z), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.WoodPlanks })
for _, z in ipairs({ -6.5, 6.5 }) do
	crearParte({ Name = "Baranda", Size = Vector3.new(250, 0.5, 0.5), Position = Vector3.new(C.X, SUELO_Y + 2.2, C.Z + z), Color = Color3.fromRGB(245, 245, 240), Material = Enum.Material.Wood })
	for x = -124, 124, 8 do
		crearParte({ Name = "Poste", Size = Vector3.new(0.6, 2.4, 0.6), Position = Vector3.new(C.X + x, SUELO_Y + 1.2, C.Z + z), Color = Color3.fromRGB(245, 245, 240), Material = Enum.Material.Wood })
	end
end

-- gallinero (de donde salen los huevos)
do
	local cf = CFrame.new(C.X - 133, SUELO_Y, C.Z)
	crearParte({ Name = "Gallinero", Size = Vector3.new(10, 8, 14), CFrame = cf * CFrame.new(0, 4, 0), Color = Color3.fromRGB(240, 228, 205), Material = Enum.Material.WoodPlanks })
	techoDosAguas(cf * CFrame.new(0, 8, 0) * CFrame.Angles(0, math.rad(90), 0), 16, 12, 4, Color3.fromRGB(170, 60, 50))
	crearParte({ Name = "Puerta", Size = Vector3.new(0.3, 5, 6), CFrame = cf * CFrame.new(5.1, 2.5, 0), Color = MADERA_OSCURA, Material = Enum.Material.Wood })
	local marca = crearParte({ Name = "Marca", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 14, 0), Transparency = 1, CanCollide = false })
	crearCartel(marca, "🐔 GALLINERO 🐔", 60, 0, 260)
end

local carpetaCinta = Instance.new("Folder")
carpetaCinta.Name = "HuevosCinta"
carpetaCinta.Parent = mapa
local carpetaCargados = Instance.new("Folder")
carpetaCargados.Name = "HuevosCargados"
carpetaCargados.Parent = mapa

local function valla(cf, desde, hasta, modelo, travesanos)
	-- tramo recto de cerca entre dos puntos locales (con pared invisible para obligar a usar la puerta)
	local dir = hasta - desde
	local largo = dir.Magnitude
	local n = math.max(1, math.ceil(largo / 6))
	for k = 0, n do
		local p = desde + dir * (k / n)
		crearParte({ Name = "Poste", Size = Vector3.new(0.9, 5, 0.9), CFrame = cf * CFrame.new(p.X, 3.5, p.Z), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = modelo })
	end
	local medio = (desde + hasta) / 2
	local giro = CFrame.lookAt(Vector3.zero, dir)
	for _, alto in ipairs({ 2.6, 4.6 }) do
		local t = crearParte({ Name = "Travesano", Size = Vector3.new(0.3, 0.5, largo), CFrame = cf * CFrame.new(medio.X, alto, medio.Z) * giro, Color = MADERA, Material = Enum.Material.Wood, Parent = modelo })
		table.insert(travesanos, t)
	end
	crearParte({ Name = "Muro", Size = Vector3.new(1, 12, largo), CFrame = cf * CFrame.new(medio.X, 7, medio.Z) * giro, Transparency = 1, Parent = modelo })
end

-- orden en que se desbloquean los nidos
local POS_NIDOS = {
	{ -12, -6 }, { 12, -6 }, { -12, 1 }, { 12, 1 },
	{ -18, -6 }, { 18, -6 }, { -18, 1 }, { 18, 1 },
	{ -12, 8 }, { 12, 8 }, { -18, 8 }, { 18, 8 },
	-- ampliación 1 y 2 (detrás del granero)
	{ -17.5, 28 }, { -10.5, 28 }, { -3.5, 28 }, { 3.5, 28 }, { 10.5, 28 }, { 17.5, 28 },
	{ -17.5, 38 }, { -10.5, 38 }, { -3.5, 38 }, { 3.5, 38 }, { 10.5, 38 }, { 17.5, 38 },
}

-- fondo de la granja según el nivel de ampliación (0, 1, 2)
local FONDOS = { MEDIO, MEDIO + 10, MEDIO + 20 }

-- muestra u oculta un modelo guardando la transparencia y colisión originales
local function mostrar(modelo, visible)
	for _, p in ipairs(modelo:GetDescendants()) do
		if p:IsA("BasePart") then
			if p:GetAttribute("TransOrig") == nil then
				p:SetAttribute("TransOrig", p.Transparency)
				p:SetAttribute("ColOrig", p.CanCollide)
			end
			p.Transparency = visible and p:GetAttribute("TransOrig") or 1
			p.CanCollide = visible and p:GetAttribute("ColOrig") or false
			p.CanQuery = visible
		end
	end
end

local function aplicarAmpliacion(base, nivel)
	base.ampliacion = nivel
	base.fondo = FONDOS[nivel + 1]
	for n, anexo in pairs(base.anexos) do
		mostrar(anexo, n <= nivel)
	end
	for n, fondo in pairs(base.fondos) do
		mostrar(fondo, n == nivel)
	end
	aplicarNidos(base, math.min(base.nidos, maxNidos(base)))
end

-- Símbolo pintado en el piso: círculo de color suave con un ícono, sin brillo.
-- Devuelve una zona invisible (para detectar al jugador), el círculo y el ícono.
local function crearSimbolo(cf, modelo, nombre, tamano, icono, color)
	local pintura = crearParte({ Name = nombre .. "Pintura", Size = Vector3.new(tamano, 0.2, tamano), CFrame = cf, Transparency = 1, CanCollide = false, CanTouch = false, Parent = modelo })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Top
	sg.CanvasSize = Vector2.new(200, 200)
	sg.LightInfluence = 1 -- se ilumina como el resto del mapa (no brilla de noche)
	sg.Parent = pintura
	local circulo = Instance.new("Frame")
	circulo.Size = UDim2.fromScale(1, 1)
	circulo.BackgroundColor3 = color
	circulo.BackgroundTransparency = 0.2
	circulo.Parent = sg
	Instance.new("UICorner", circulo).CornerRadius = UDim.new(0.5, 0)
	local borde = Instance.new("UIStroke")
	borde.Color = Color3.fromRGB(250, 245, 230)
	borde.Thickness = 10
	borde.Parent = circulo
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.64, 0.64)
	lbl.Position = UDim2.fromScale(0.18, 0.18)
	lbl.BackgroundTransparency = 1
	lbl.TextScaled = true
	lbl.Font = Enum.Font.FredokaOne
	lbl.Text = icono
	lbl.Parent = circulo
	local zona = crearParte({ Name = nombre, Size = Vector3.new(tamano * 0.85, 3, tamano * 0.85), CFrame = cf * CFrame.new(0, 1.4, 0), Transparency = 1, CanCollide = false, Parent = modelo })
	return zona, circulo, lbl
end

local COLOR_CERRAR = Color3.fromRGB(165, 65, 55)
local COLOR_PROTEGIDA = Color3.fromRGB(60, 115, 185)
local COLOR_ESPERA = Color3.fromRGB(120, 115, 105)

local function ponerNombre(base, texto)
	for _, lbl in ipairs(base.carteles) do
		lbl.Text = texto
	end
end

local function estiloCierre(base, color, icono)
	base.circuloBloqueo.BackgroundColor3 = color
	base.iconoBloqueo.Text = icono
end

local function construirGranja(i, pos)
	-- la granja "mira" hacia la cinta: la puerta está en z local = -23
	local cf = CFrame.lookAt(pos, Vector3.new(pos.X, pos.Y, C.Z))
	local modelo = Instance.new("Model")
	modelo.Name = "Granja" .. i
	modelo.Parent = mapa
	local color = COLORES_GRANERO[i]

	local base = {
		indice = i,
		cf = cf,
		modelo = modelo,
		dueno = nil,
		ranuras = {},
		travesanos = {},
		anexos = {},
		fondos = {},
		ampliacion = 0,
		fondo = MEDIO,
		tcf = cf * CFrame.new(16, 0, -36), -- caminadora al frente de la granja, al lado del camino
		nidos = CONFIG.NIDOS_INICIALES,
		pendiente = 0,
		bloqueadoHasta = 0,
		listoBloqueo = 0,
		spawn = cf * CFrame.new(0, 4, -14),
	}

	-- suelo, camino interno y camino hacia la cinta
	crearParte({ Name = "Pasto", Size = Vector3.new(46, 1, 46), CFrame = cf * CFrame.new(0, 0.5, 0), Color = Color3.fromRGB(115, 185, 85), Material = Enum.Material.Grass, Parent = modelo })
	crearParte({ Name = "Camino", Size = Vector3.new(7, 0.2, 34), CFrame = cf * CFrame.new(0, 1.1, -6), Color = TIERRA, Material = Enum.Material.Ground, Parent = modelo })
	crearParte({ Name = "Sendero", Size = Vector3.new(7, 0.2, 36), CFrame = cf * CFrame.new(0, 0.1, -41), Color = TIERRA, Material = Enum.Material.Ground, Parent = modelo })

	-- cerca (el fondo cambia de lugar cuando la granja se amplía)
	valla(cf, Vector3.new(-MEDIO, 0, -MEDIO), Vector3.new(-MEDIO, 0, MEDIO), modelo, base.travesanos)
	for nivel = 0, #CONFIG.PRECIOS_AMPLIACION do
		local z = FONDOS[nivel + 1]
		if nivel > 0 then
			local zAntes = FONDOS[nivel]
			local anexo = Instance.new("Model")
			anexo.Name = "Ampliacion" .. nivel
			anexo.Parent = modelo
			crearParte({ Name = "Pasto", Size = Vector3.new(46, 1, z - zAntes), CFrame = cf * CFrame.new(0, 0.5, (z + zAntes) / 2), Color = Color3.fromRGB(115, 185, 85), Material = Enum.Material.Grass, Parent = anexo })
			valla(cf, Vector3.new(-MEDIO, 0, zAntes), Vector3.new(-MEDIO, 0, z), anexo, base.travesanos)
			valla(cf, Vector3.new(MEDIO, 0, zAntes), Vector3.new(MEDIO, 0, z), anexo, base.travesanos)
			base.anexos[nivel] = anexo
		end
		local fondo = Instance.new("Model")
		fondo.Name = "Fondo" .. nivel
		fondo.Parent = modelo
		valla(cf, Vector3.new(-MEDIO, 0, z), Vector3.new(MEDIO, 0, z), fondo, base.travesanos)
		base.fondos[nivel] = fondo
	end
	valla(cf, Vector3.new(MEDIO, 0, -MEDIO), Vector3.new(MEDIO, 0, MEDIO), modelo, base.travesanos)
	valla(cf, Vector3.new(-MEDIO, 0, -MEDIO), Vector3.new(-6.5, 0, -MEDIO), modelo, base.travesanos)
	valla(cf, Vector3.new(6.5, 0, -MEDIO), Vector3.new(MEDIO, 0, -MEDIO), modelo, base.travesanos)

	-- arco de entrada con el nombre del dueño
	for _, x in ipairs({ -6.5, 6.5 }) do
		crearParte({ Name = "PilarArco", Size = Vector3.new(1.6, 11, 1.6), CFrame = cf * CFrame.new(x, 6.5, -MEDIO), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = modelo })
	end
	crearParte({ Name = "VigaArco", Size = Vector3.new(16, 1.4, 1.8), CFrame = cf * CFrame.new(0, 12, -MEDIO), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = modelo })
	local letrero = crearParte({ Name = "Letrero", Size = Vector3.new(12, 3, 0.4), CFrame = cf * CFrame.new(0, 9.6, -MEDIO - 0.3), Color = color, Material = Enum.Material.WoodPlanks, Parent = modelo })
	-- el nombre queda escrito en el letrero (por fuera y por dentro), no flotando
	base.carteles = {}
	for _, cara in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = cara
		sg.CanvasSize = Vector2.new(400, 100)
		sg.LightInfluence = 1
		sg.Parent = letrero
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextScaled = true
		lbl.TextColor3 = Color3.fromRGB(255, 250, 235)
		lbl.TextStrokeTransparency = 0.4
		lbl.Text = "Granja libre"
		lbl.Parent = sg
		local margen = Instance.new("UIPadding")
		margen.PaddingLeft = UDim.new(0.05, 0)
		margen.PaddingRight = UDim.new(0.05, 0)
		margen.PaddingTop = UDim.new(0.12, 0)
		margen.PaddingBottom = UDim.new(0.12, 0)
		margen.Parent = lbl
		table.insert(base.carteles, lbl)
	end

	base.barrera = crearParte({
		Name = "Barrera",
		Size = Vector3.new(12, 9, 0.5),
		CFrame = cf * CFrame.new(0, 5.5, -MEDIO),
		Color = Color3.fromRGB(255, 60, 60),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		Parent = modelo,
	})

	-- granero
	crearParte({ Name = "Granero", Size = Vector3.new(20, 9, 10), CFrame = cf * CFrame.new(0, 5.5, 16), Color = color, Material = Enum.Material.WoodPlanks, Parent = modelo })
	techoDosAguas(cf * CFrame.new(0, 10, 16), 22, 11.5, 4.5, Color3.fromRGB(70, 60, 55), modelo)
	crearParte({ Name = "Puerta", Size = Vector3.new(7, 6.5, 0.3), CFrame = cf * CFrame.new(0, 4.25, 10.9), Color = MADERA_OSCURA, Material = Enum.Material.Wood, Parent = modelo })
	for _, ang in ipairs({ 42, -42 }) do
		crearParte({ Name = "CruzPuerta", Size = Vector3.new(9, 0.5, 0.2), CFrame = cf * CFrame.new(0, 4.25, 10.7) * CFrame.Angles(0, 0, math.rad(ang)), Color = Color3.new(1, 1, 1), Material = Enum.Material.Wood, Parent = modelo })
	end
	crearParte({ Name = "Ventana", Size = Vector3.new(3, 2, 0.3), CFrame = cf * CFrame.new(0, 8.6, 10.9), Color = Color3.new(1, 1, 1), Material = Enum.Material.Wood, Parent = modelo })

	-- silo
	crearParte({ Name = "Silo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(12, 5.5, 5.5), CFrame = cf * CFrame.new(17, 7, 17) * VERTICAL, Color = Color3.fromRGB(200, 200, 205), Material = Enum.Material.Metal, Parent = modelo })
	crearParte({ Name = "CupulaSilo", Shape = Enum.PartType.Ball, Size = Vector3.new(5.5, 5.5, 5.5), CFrame = cf * CFrame.new(17, 13, 17), Color = color, Material = Enum.Material.Metal, Parent = modelo })

	-- fardos de paja
	for _, p in ipairs({ { -17, 2.25, 15 }, { -17, 2.25, 18.6 }, { -17, 4.75, 16.8 }, { -20.5, 2.25, 15 } }) do
		crearParte({ Name = "Fardo", Size = Vector3.new(3, 2.5, 3.4), CFrame = cf * CFrame.new(p[1], p[2], p[3]), Color = PAJA, Material = Enum.Material.Fabric, Parent = modelo })
	end

	-- nidos
	for _, xz in ipairs(POS_NIDOS) do
		local x, z = xz[1], xz[2]
		local nido = crearParte({ Name = "Nido", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 5, 5), CFrame = cf * CFrame.new(x, 1.6, z) * VERTICAL, Color = PAJA, Material = Enum.Material.Fabric, Parent = modelo })
		table.insert(base.ranuras, { cf = cf * CFrame.new(x, 3.6, z), nido = nido })
	end

	-- círculo para recoger dinero
	base.padRecoger = crearSimbolo(cf * CFrame.new(-12, 1.15, -16), modelo, "Recoger", 7, "💰", Color3.fromRGB(75, 140, 70))
	base.textoRecoger = crearCartel(base.padRecoger, "", 50, 2)

	-- círculo para cerrar la granja
	base.padBloqueo, base.circuloBloqueo, base.iconoBloqueo = crearSimbolo(cf * CFrame.new(12, 1.15, -16), modelo, "Cerrar", 6, "🔒", COLOR_CERRAR)
	base.textoBloqueo = crearCartel(base.padBloqueo, "", 50, 2)

	base.padRecoger.Touched:Connect(function(hit)
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if plr and plr == base.dueno and base.pendiente >= 1 then
			local cantidad = math.floor(base.pendiente)
			darDinero(plr, cantidad)
			base.pendiente -= cantidad
			notificar(plr, "+$" .. formato(cantidad), "Recoger")
		end
	end)

	base.padBloqueo.Touched:Connect(function(hit)
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if plr and plr == base.dueno then
			local ahora = os.clock()
			if ahora >= base.bloqueadoHasta and ahora >= base.listoBloqueo then
				local dur = duracionCierre(plr)
				base.bloqueadoHasta = ahora + dur
				base.listoBloqueo = base.bloqueadoHasta + CONFIG.ESPERA_BLOQUEO
				notificar(plr, "🔒 ¡Granja cerrada por " .. dur .. " s!")
			end
		end
	end)

	aplicarAmpliacion(base, 0)
	aplicarCaminadora(base)
	table.insert(bases, base)
end

local indiceBase = 0
for _, x in ipairs({ -90, 0, 90 }) do
	for _, z in ipairs({ -65, 65 }) do
		indiceBase += 1
		construirGranja(indiceBase, Vector3.new(C.X + x, SUELO_Y, C.Z + z))
	end
end

------------------------------------------------------------------
-- ROBAR / ENTREGAR / DEVOLVER
------------------------------------------------------------------
local function soltarHuevo(plr, entregar)
	local c = cargando[plr]
	if not c then
		return
	end
	cargando[plr] = nil
	if c.huevo then
		c.huevo:Destroy()
	end
	local char = plr.Character
	local marca = char and char:FindFirstChild("MarcaLadron")
	if marca then
		marca:Destroy()
	end
	aplicarVelocidad(plr)

	if entregar then
		local miBase = basesDe[plr]
		local idx = miBase and ranuraLibre(miBase)
		if idx then
			colocarHuevo(miBase, idx, c.info)
		else
			darDinero(plr, precioDe(c.info))
		end
		notificar(plr, "🦹 ¡Robaste " .. nombreDe(c.info) .. "!", "Robo")
		progresoMision(plr, "robar", 1)
		darInsignia(plr, "PrimerRobo")
		if c.info.r == #RAREZAS then
			darInsignia(plr, "HuevoDorado")
		end
		if c.dueno and c.dueno.Parent and basesDe[c.dueno] == c.base then
			-- escudo automático para que no te roben varias veces seguidas
			c.base.bloqueadoHasta = math.max(c.base.bloqueadoHasta, os.clock() + CONFIG.ESCUDO_ROBO)
			notificar(c.dueno, plr.DisplayName .. " te robó " .. nombreDe(c.info) .. " 😡  Escudo activado " .. CONFIG.ESCUDO_ROBO .. " s")
		end
	else
		if devolverHuevo(c.dueno, c.base, c.ranura, c.info) then
			notificar(c.dueno, "¡Recuperaste " .. nombreDe(c.info) .. "!")
		end
		notificar(plr, "Perdiste el huevo robado.")
	end
end

function intentarRobar(plr, base, idx, h)
	local ranura = base.ranuras[idx]
	if plr == base.dueno or ranura.huevo ~= h then
		return
	end
	if enCaminadora[plr] then
		return
	end
	if sonAliados(plr, base.dueno) then
		notificar(plr, "No puedes robarle a tu aliado 🤝")
		return
	end
	if cargando[plr] then
		notificar(plr, "Ya llevas un huevo.")
		return
	end
	local miBase = basesDe[plr]
	if not miBase then
		return
	end
	if not ranuraLibre(miBase) then
		notificar(plr, "No tienes nidos libres. Vende un huevo (F) o desbloquea otro nido.")
		return
	end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end

	local huevo, info = arrancarHuevo(ranura)
	soldarA(huevo, hrp, CFrame.new(0, 4.5, 0))
	huevo.Parent = carpetaCargados

	-- el ladrón brilla en rojo y se ve a través de las paredes
	local marca = Instance.new("Highlight")
	marca.Name = "MarcaLadron"
	marca.FillColor = Color3.fromRGB(255, 40, 40)
	marca.FillTransparency = 0.6
	marca.OutlineColor = Color3.fromRGB(255, 255, 255)
	marca.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	marca.Parent = char

	cargando[plr] = { huevo = huevo, info = info, base = base, ranura = idx, dueno = base.dueno, salio = false }
	aplicarVelocidad(plr)
	notificar(plr, "¡Corre a tu granja!")
	notificar(base.dueno, "⚠️ ¡" .. plr.DisplayName .. " te está robando " .. nombreDe(info) .. "!", "Alarma")
	if aliados[base.dueno] then
		notificar(aliados[base.dueno], "⚠️ ¡" .. plr.DisplayName .. " le está robando a tu aliado!", "Alarma")
	end
end

local function descarga(plr)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Sit = true
	end
	if char then
		local rayo = Instance.new("Highlight")
		rayo.FillColor = ELECTRICO
		rayo.FillTransparency = 0.2
		rayo.Parent = char
		Debris:AddItem(rayo, 0.6)
	end
end

------------------------------------------------------------------
-- ZORRO NPC
------------------------------------------------------------------
local Y_ZORRO = SUELO_Y + 3.2

local function crearZorro(pos)
	local naranja = Color3.fromRGB(225, 115, 40)
	local raiz = crearParte({ Name = "Zorro", Size = Vector3.new(2.6, 2.4, 5), CFrame = CFrame.new(pos), Color = naranja, CanCollide = false, CanTouch = false, Parent = false })
	pegar(raiz, { Name = "Cabeza", Size = Vector3.new(2.2, 2.2, 2.2), Color = naranja }, CFrame.new(0, 0.8, -3.2))
	pegar(raiz, { Name = "Hocico", Size = Vector3.new(1, 0.9, 1.2), Color = Color3.fromRGB(250, 245, 235) }, CFrame.new(0, 0.4, -4.7))
	pegar(raiz, { Name = "Nariz", Shape = Enum.PartType.Ball, Size = Vector3.new(0.45, 0.45, 0.45), Color = Color3.new(0, 0, 0) }, CFrame.new(0, 0.6, -5.35))
	for _, x in ipairs({ -0.6, 0.6 }) do
		pegar(raiz, { Name = "Oreja", Size = Vector3.new(0.6, 1, 0.8), Color = naranja }, CFrame.new(x, 2.4, -3.1), "WedgePart")
		pegar(raiz, { Name = "Ojo", Shape = Enum.PartType.Ball, Size = Vector3.new(0.35, 0.35, 0.35), Color = Color3.new(0, 0, 0) }, CFrame.new(x * 0.9, 1.3, -4.3))
		for _, z in ipairs({ -1.6, 1.6 }) do
			pegar(raiz, { Name = "Pata", Size = Vector3.new(0.6, 1.6, 0.6), Color = Color3.fromRGB(60, 40, 30) }, CFrame.new(x * 1.3, -1.8, z))
		end
	end
	pegar(raiz, { Name = "Cola", Size = Vector3.new(1.2, 1.2, 3.5), Color = naranja }, CFrame.new(0, 0.9, 3.8) * CFrame.Angles(math.rad(25), 0, 0))
	pegar(raiz, { Name = "PuntaCola", Size = Vector3.new(1.3, 1.3, 1), Color = Color3.fromRGB(250, 245, 235) }, CFrame.new(0, 1.8, 5.6) * CFrame.Angles(math.rad(25), 0, 0))
	local cartel = crearCartel(raiz, "", 40, 4.5, 200)
	raiz.Parent = mapa
	return raiz, cartel
end

local function moverZorro(z, destino)
	destino = Vector3.new(destino.X, Y_ZORRO, destino.Z)
	while z.vivo do
		local pos = z.raiz.Position
		local diff = destino - pos
		local dist = diff.Magnitude
		if dist < 0.5 then
			return true
		end
		local vel = z.huevo and CONFIG.ZORRO_VELOCIDAD * 0.8 or CONFIG.ZORRO_VELOCIDAD
		local nueva = pos + diff.Unit * math.min(dist, vel * 0.05)
		z.raiz.CFrame = CFrame.lookAt(nueva, nueva + diff.Unit)
		task.wait(0.05)
	end
	return false
end

local function terminarZorro(z)
	z.vivo = false
	if zorro == z then
		zorro = nil
	end
	if z.huevo then
		z.huevo:Destroy()
		z.huevo = nil
	end
	if z.raiz then
		z.raiz:Destroy()
	end
end

function golpearZorro(plr, dano)
	local z = zorro
	if not z or not z.vivo then
		return
	end
	z.vida -= dano
	z.golpeadores[plr] = true
	progresoMision(plr, "zorro", 1)
	z.cartel.Text = "🦊 " .. string.rep("❤️", math.max(0, z.vida))
	z.raiz.Color = Color3.new(1, 1, 1)
	task.delay(0.12, function()
		if z.raiz.Parent then
			z.raiz.Color = Color3.fromRGB(225, 115, 40)
		end
	end)
	if z.vida <= 0 then
		if z.info then
			if devolverHuevo(z.dueno, z.base, nil, z.info) then
				notificar(z.dueno, "¡Recuperaste " .. nombreDe(z.info) .. "!")
			end
			z.info = nil
		end
		for p in pairs(z.golpeadores) do
			if p.Parent then
				local premio = math.max(500, (p:GetAttribute("IngresoSeg") or 0) * 60)
				darDinero(p, premio)
				notificar(p, "🦊 ¡Ahuyentaste al zorro! +$" .. formato(premio), "Mision")
				local ep = estado[p]
				if ep then
					ep.zorros += 1
					if ep.zorros >= 10 then
						darInsignia(p, "Cazazorros")
					end
				end
			end
		end
		notificarTodos("🦊 ¡El zorro huyó al bosque!")
		terminarZorro(z)
	end
end

local function lanzarZorro()
	if zorro then
		return
	end
	local candidatas = {}
	for _, b in ipairs(bases) do
		if b.dueno and not protegida(b) then
			for _, r in ipairs(b.ranuras) do
				if r.huevo then
					table.insert(candidatas, b)
					break
				end
			end
		end
	end
	if #candidatas == 0 then
		return
	end
	local base = candidatas[math.random(#candidatas)]
	local frente = base.cf * Vector3.new(0, 0, -48) -- entre la caminadora y la cinta
	local puerta = base.cf * Vector3.new(0, 0, -19)
	local lado = math.random(2) == 1 and 1 or -1
	local inicio = Vector3.new(C.X + 185 * lado, 0, frente.Z)

	local z = { vivo = true, vida = CONFIG.ZORRO_VIDA, base = base, dueno = base.dueno, golpeadores = {} }
	z.raiz, z.cartel = crearZorro(Vector3.new(inicio.X, Y_ZORRO, inicio.Z))
	z.cartel.Text = "🦊 " .. string.rep("❤️", z.vida)
	zorro = z
	notificarTodos("🦊 ¡Un zorro va hacia la granja de " .. base.dueno.DisplayName .. "! Golpéalo con el bate", "Zorro")

	task.spawn(function()
		local function huir()
			if moverZorro(z, inicio) then
				if z.info then
					notificar(z.dueno, "🦊 El zorro escapó con " .. nombreDe(z.info) .. "...")
				end
				terminarZorro(z)
			end
		end
		if not moverZorro(z, frente) then
			return
		end
		if protegida(base) or base.dueno ~= z.dueno then
			huir() -- la granja está protegida: se rinde
			return
		end
		if not moverZorro(z, puerta) then
			return
		end
		local opciones = {}
		for i, r in ipairs(base.ranuras) do
			if r.huevo then
				table.insert(opciones, i)
			end
		end
		if #opciones == 0 or base.dueno ~= z.dueno then
			huir()
			return
		end
		local ranura = base.ranuras[opciones[math.random(#opciones)]]
		if not moverZorro(z, ranura.cf.Position) then
			return
		end
		if ranura.huevo and base.dueno == z.dueno then
			local huevo, info = arrancarHuevo(ranura)
			soldarA(huevo, z.raiz, CFrame.new(0, 2.5, -3.5))
			huevo.Parent = carpetaCargados
			z.huevo, z.info = huevo, info
			notificar(z.dueno, "🦊 ¡El zorro tomó " .. nombreDe(info) .. "! ¡Atrápalo!")
		end
		if moverZorro(z, puerta) and moverZorro(z, frente) then
			huir()
		end
	end)
end

------------------------------------------------------------------
-- BATE
------------------------------------------------------------------
local function golpear(atacante, victima, direccion, fuerza)
	local char = victima.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end
	if cargando[victima] then
		soltarHuevo(victima, false)
		notificar(atacante, "¡Detuviste al ladrón!", "Mision")
		progresoMision(atacante, "atrapar", 1)
	end
	notificar(atacante, nil, "Golpe")
	notificar(victima, nil, "Golpe")
	hum.Sit = true
	local empuje = Instance.new("BodyVelocity")
	empuje.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	empuje.Velocity = direccion * fuerza + Vector3.new(0, 30, 0)
	empuje.Parent = hrp
	Debris:AddItem(empuje, 0.2)
end

local function darBate(plr)
	local mochila = plr:FindFirstChildOfClass("Backpack") or plr:WaitForChild("Backpack", 5)
	if not mochila then
		return
	end
	local dorado = tienePase(plr, "BateDorado")
	-- quitar bate viejo (por si acaba de comprar el dorado)
	for _, lugar in ipairs({ mochila, plr.Character }) do
		local viejo = lugar and lugar:FindFirstChild("Bate")
		if viejo then
			if viejo:GetAttribute("Dorado") == dorado then
				return
			end
			viejo:Destroy()
		end
	end

	local tool = Instance.new("Tool")
	tool.Name = "Bate"
	tool.ToolTip = dorado and "Bate dorado: más alcance y fuerza" or "Golpea a los ladrones y al zorro"
	tool.CanBeDropped = false
	tool:SetAttribute("Dorado", dorado)
	local mango = Instance.new("Part")
	mango.Name = "Handle"
	mango.Size = Vector3.new(0.6, 4, 0.6)
	mango.Color = dorado and Color3.fromRGB(255, 205, 40) or Color3.fromRGB(150, 100, 60)
	mango.Material = dorado and Enum.Material.Foil or Enum.Material.Wood
	mango.CanCollide = false
	mango.Massless = true
	mango.Parent = tool
	if dorado then
		local brillo = Instance.new("Sparkles")
		brillo.SparkleColor = Color3.fromRGB(255, 215, 0)
		brillo.Parent = mango
	end
	local gripNormal = tool.Grip
	local alcance = dorado and 12 or 8
	local fuerza = dorado and 85 or 55

	local ultimo = 0
	tool.Activated:Connect(function()
		if os.clock() - ultimo < 0.8 then
			return
		end
		ultimo = os.clock()
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return
		end
		tool.Grip = gripNormal * CFrame.Angles(math.rad(-80), 0, 0)
		task.delay(0.2, function()
			tool.Grip = gripNormal
		end)
		local frente = hrp.CFrame.LookVector
		for _, otro in ipairs(Players:GetPlayers()) do
			local h2 = otro ~= plr and otro.Character and otro.Character:FindFirstChild("HumanoidRootPart")
			if h2 then
				local diff = h2.Position - hrp.Position
				if diff.Magnitude < alcance and diff.Magnitude > 0.1 and frente:Dot(diff.Unit) > 0.2 then
					golpear(plr, otro, frente, fuerza)
				end
			end
		end
		if zorro and zorro.vivo then
			local diff = zorro.raiz.Position - hrp.Position
			if diff.Magnitude < alcance + 3 and frente:Dot(diff.Unit) > 0 then
				golpearZorro(plr, dorado and 2 or 1)
			end
		end
	end)
	tool.Parent = mochila
end

------------------------------------------------------------------
-- CAMINADORA: el jugador corre fijo en el centro de la banda
--   El servidor guarda quién está corriendo; el cliente lo mantiene en el centro
--   y lo hace correr en el lugar (ver RobaHuevos_Cliente).
------------------------------------------------------------------
local eventoSalirCaminadora = Instance.new("RemoteEvent")
eventoSalirCaminadora.Name = "SalirCaminadora"
eventoSalirCaminadora.Parent = ReplicatedStorage

local function centroCaminadora(base)
	return base.tcf * CFrame.new(0, 4.1, 0)
end

local ultimaBajada = {} -- [jugador] = os.clock() de cuando se bajó (para no volver a subirlo al instante)
local pistasCorrer = {} -- [jugador] = animación de correr (la reproduce el servidor)

-- animaciones de correr de Roblox, por si el personaje no trae la suya
local CORRER_R15 = "rbxassetid://913376220"
local CORRER_R6 = "rbxassetid://180426354"

-- El servidor reproduce la animación de correr: así se ve igual para todos
-- y no depende del script del cliente.
local function animarCorrer(plr, char, hum)
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local animate = char:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local propia = run and run:FindFirstChildOfClass("Animation")
	local anim = Instance.new("Animation")
	if propia and propia.AnimationId ~= "" then
		anim.AnimationId = propia.AnimationId
	else
		anim.AnimationId = hum.RigType == Enum.HumanoidRigType.R15 and CORRER_R15 or CORRER_R6
	end
	local ok, pista = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not pista then
		warn("[RobaHuevos] No se pudo cargar la animación de correr:", pista)
		return
	end
	pista.Priority = Enum.AnimationPriority.Action4 -- por encima de la animación de estar quieto
	pista.Looped = true
	pista:Play(0.2)
	pista:AdjustSpeed(math.max(1, velocidadDe(plr) / 16) * 1.1)
	pistasCorrer[plr] = pista
end

-- Se puede usar la caminadora propia o la de una granja libre.
-- El jugador queda anclado en el centro de la banda mientras corre.
function entrarCaminadora(plr, base)
	if (base.dueno ~= nil and base.dueno ~= plr) or cargando[plr] or enCaminadora[plr] then
		return
	end
	if os.clock() - (ultimaBajada[plr] or 0) < 1.5 then
		return
	end
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	hum.Sit = false
	enCaminadora[plr] = base
	char:PivotTo(centroCaminadora(base))
	hrp.Anchored = true
	animarCorrer(plr, char, hum)
	plr:SetAttribute("CentroCaminadora", centroCaminadora(base))
	if base.promptCorrer then
		base.promptCorrer.ActionText = "Bajarse"
	end
	notificar(plr, "🏃 ¡A correr! Para bajarte: Espacio, el botón rojo o E en la consola")
end

function salirCaminadora(plr, sinMover)
	local base = enCaminadora[plr]
	if not base then
		return
	end
	enCaminadora[plr] = nil
	ultimaBajada[plr] = os.clock()
	plr:SetAttribute("CentroCaminadora", nil)
	if base.promptCorrer then
		base.promptCorrer.ActionText = "Correr"
	end
	local pista = pistasCorrer[plr]
	if pista then
		pista:Stop(0.2)
		pistasCorrer[plr] = nil
	end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
	end
	if char and not sinMover then
		char:PivotTo(base.tcf * CFrame.new(-5.5, 4, 0))
	end
end

-- ¿el jugador está parado encima de la banda?
local function sobreLaBanda(base, pos)
	local p = base.tcf:PointToObjectSpace(pos)
	return math.abs(p.X) < 2.6 and math.abs(p.Z) < 6 and p.Y > 0 and p.Y < 7
end

eventoSalirCaminadora.OnServerEvent:Connect(function(plr)
	salirCaminadora(plr)
end)

------------------------------------------------------------------
-- TIENDA
------------------------------------------------------------------
local function actualizarAtributosTienda(plr)
	local e = estado[plr]
	if not e then
		return
	end
	plr:SetAttribute("NivelCierre", e.cierre)
	plr:SetAttribute("PrecioCierre", CONFIG.PRECIOS_CIERRE[e.cierre + 1] or -1)
	plr:SetAttribute("NivelCerca", e.cerca)
	plr:SetAttribute("PrecioCerca", CONFIG.PRECIOS_CERCA[e.cerca + 1] or -1)
	plr:SetAttribute("NivelAmpliar", e.ampliacion)
	plr:SetAttribute("PrecioAmpliar", CONFIG.PRECIOS_AMPLIACION[e.ampliacion + 1] or -1)
	plr:SetAttribute("EscudoHasta", e.escudoHasta)
	for nombre in pairs(CONFIG.PASES) do
		plr:SetAttribute("Pase_" .. nombre, e.pases[nombre] == true)
	end
end

local function aplicarPase(plr, nombre)
	if nombre == "BateDorado" then
		darBate(plr)
	elseif nombre == "CaminadoraVIP" then
		notificar(plr, "🏃 ¡Tu caminadora ahora cuenta pasos x2!")
	elseif nombre == "Dinero2x" then
		notificar(plr, "💰 ¡Ahora ganas el doble de dinero!")
	end
end

local function ampliarGranja(plr)
	local e = estado[plr]
	if not e or not CONFIG.PRECIOS_AMPLIACION[e.ampliacion + 1] then
		return false
	end
	e.ampliacion += 1
	local base = basesDe[plr]
	if base then
		aplicarAmpliacion(base, e.ampliacion)
		notificar(plr, "🏗️ ¡Granja ampliada! Ahora puedes tener hasta " .. maxNidos(base) .. " nidos")
	end
	actualizarAtributosTienda(plr)
	return true
end

local function darEscudo(plr, item)
	local e = estado[plr]
	local escudo = CONFIG.ESCUDOS[item]
	if not e or not escudo then
		return
	end
	-- si ya tenías escudo, el tiempo se suma
	e.escudoHasta = math.max(os.time(), e.escudoHasta or 0) + escudo.segundos
	notificar(plr, "🛡️ ¡Escudo de " .. escudo.nombre .. " activado! Nadie puede entrar a tu granja")
	actualizarAtributosTienda(plr)
end

-- compra con Robux (productos de desarrollador): se entrega en ProcessReceipt
local function comprarRobux(plr, item)
	local e = estado[plr]
	if not e then
		return
	end
	if item == "Ampliar" and not CONFIG.PRECIOS_AMPLIACION[e.ampliacion + 1] then
		notificar(plr, "Tu granja ya está al máximo.")
		return
	end
	local id = CONFIG.PRODUCTOS[item]
	if not id or id == 0 then
		notificar(plr, "Este producto aún no está configurado (pon su ID en CONFIG.PRODUCTOS).")
		return
	end
	MarketplaceService:PromptProductPurchase(plr, id)
end

function comprarItem(plr, item)
	local e = estado[plr]
	local d = dinero(plr)
	if not e or not d then
		return
	end
	if item == "Cierre" then
		local precio = CONFIG.PRECIOS_CIERRE[e.cierre + 1]
		if not precio then
			notificar(plr, "Tu cierre ya está al máximo.")
			return
		end
		if d.Value < precio then
			notificar(plr, "Necesitas $" .. formato(precio))
			return
		end
		d.Value -= precio
		e.cierre += 1
		notificar(plr, "🔒 ¡Cierre mejorado! Ahora dura " .. duracionCierre(plr) .. " s")
	elseif item == "Cerca" then
		local precio = CONFIG.PRECIOS_CERCA[e.cerca + 1]
		if not precio then
			notificar(plr, "Tu cerca ya está al máximo.")
			return
		end
		if d.Value < precio then
			notificar(plr, "Necesitas $" .. formato(precio))
			return
		end
		d.Value -= precio
		e.cerca += 1
		local base = basesDe[plr]
		if base then
			aplicarCerca(base)
		end
		notificar(plr, "⚡ ¡Cerca eléctrica nivel " .. e.cerca .. "! " .. math.floor(CONFIG.PROB_CERCA[e.cerca] * 100) .. " % de atrapar ladrones")
	elseif item == "Ampliar" then
		local precio = CONFIG.PRECIOS_AMPLIACION[e.ampliacion + 1]
		if not precio then
			notificar(plr, "Tu granja ya está al máximo.")
			return
		end
		if d.Value < precio then
			notificar(plr, "Necesitas $" .. formato(precio) .. " (o cómprala con Robux: tecla F)")
			return
		end
		d.Value -= precio
		ampliarGranja(plr)
	elseif item == "Misterioso" then
		local base = basesDe[plr]
		local idx = base and ranuraLibre(base)
		if not idx then
			notificar(plr, "No tienes nidos libres para el huevo misterioso.")
			return
		end
		if d.Value < CONFIG.PRECIO_MISTERIOSO then
			notificar(plr, "Necesitas $" .. formato(CONFIG.PRECIO_MISTERIOSO))
			return
		end
		d.Value -= CONFIG.PRECIO_MISTERIOSO
		-- sortear rareza con los pesos del huevo misterioso
		local total = 0
		for _, p in ipairs(CONFIG.PESOS_MISTERIOSO) do
			total += p
		end
		local x, ri = math.random() * total, 1
		for i, p in ipairs(CONFIG.PESOS_MISTERIOSO) do
			x -= p
			if x <= 0 then
				ri = i
				break
			end
		end
		local mutacion = 0
		if math.random() < MUTACIONES[2].prob then
			mutacion = 2
		elseif math.random() < MUTACIONES[1].prob then
			mutacion = 1
		end
		local info = { r = ri, g = false, m = mutacion }
		colocarHuevo(base, idx, info)
		eventoRevelar:FireClient(plr, ri, nombreDe(info))
		if ri >= 5 then
			task.delay(2.5, function()
				notificarTodos("🎁 ¡" .. plr.DisplayName .. " sacó " .. nombreDe(info) .. " del huevo misterioso!")
			end)
		end
		if ri == #RAREZAS then
			darInsignia(plr, "HuevoDorado")
		end
	elseif CONFIG.ESCUDOS[item] then
		local escudo = CONFIG.ESCUDOS[item]
		if d.Value < escudo.precio then
			notificar(plr, "Necesitas $" .. formato(escudo.precio) .. " (o cómpralo con Robux: tecla F)")
			return
		end
		d.Value -= escudo.precio
		darEscudo(plr, item)
	else
		local id = CONFIG.PASES[item]
		if tienePase(plr, item) then
			notificar(plr, "Ya tienes este pase ✅")
			return
		end
		if not id or id == 0 then
			notificar(plr, "Este pase aún no está configurado (pon su ID en CONFIG.PASES).")
			return
		end
		MarketplaceService:PromptGamePassPurchase(plr, id)
		return
	end
	actualizarAtributosTienda(plr)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(plr, id, comprado)
	local e = estado[plr]
	if not comprado or not e then
		return
	end
	for nombre, pid in pairs(CONFIG.PASES) do
		if pid == id then
			e.pases[nombre] = true
			actualizarAtributosTienda(plr)
			aplicarPase(plr, nombre)
		end
	end
end)

local function cargarPases(plr)
	local e = estado[plr]
	for nombre, id in pairs(CONFIG.PASES) do
		local tiene = false
		if CONFIG.PASES_GRATIS_EN_STUDIO and RunService:IsStudio() then
			tiene = true
		elseif id ~= 0 then
			local ok, res = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, id)
			end)
			tiene = ok and res == true
		end
		e.pases[nombre] = tiene
	end
end

------------------------------------------------------------------
-- PLAZA: TIENDA, RENACER Y TABLA GLOBAL (al final de la cinta)
------------------------------------------------------------------
local PX = C.X + 160
crearParte({ Name = "Plaza", Size = Vector3.new(60, 0.4, 120), Position = Vector3.new(PX, SUELO_Y + 0.2, C.Z), Color = Color3.fromRGB(205, 195, 175), Material = Enum.Material.Cobblestone })

-- edificio de la tienda
do
	local crema = Color3.fromRGB(245, 235, 210)
	crearParte({ Name = "MuroTienda", Size = Vector3.new(1, 14, 56), Position = Vector3.new(PX + 24, SUELO_Y + 7, C.Z), Color = crema, Material = Enum.Material.WoodPlanks })
	for _, z in ipairs({ -28, 28 }) do
		crearParte({ Name = "MuroTienda", Size = Vector3.new(16, 14, 1), Position = Vector3.new(PX + 16.5, SUELO_Y + 7, C.Z + z), Color = crema, Material = Enum.Material.WoodPlanks })
	end
	crearParte({ Name = "TechoTienda", Size = Vector3.new(18, 1, 58), Position = Vector3.new(PX + 16, SUELO_Y + 14.5, C.Z), Color = Color3.fromRGB(150, 45, 40), Material = Enum.Material.WoodPlanks })
	crearParte({ Name = "Mostrador", Size = Vector3.new(3, 3.5, 44), Position = Vector3.new(PX + 12, SUELO_Y + 1.75, C.Z), Color = MADERA, Material = Enum.Material.Wood })
	for k = 0, 10 do
		crearParte({
			Name = "Toldo",
			Size = Vector3.new(6, 0.4, 5),
			CFrame = CFrame.new(PX + 6, SUELO_Y + 12.5, C.Z - 25 + k * 5) * CFrame.Angles(0, 0, math.rad(20)),
			Color = (k % 2 == 0) and Color3.fromRGB(220, 50, 50) or Color3.new(1, 1, 1),
			Material = Enum.Material.Fabric,
		})
	end
	local marca = crearParte({ Name = "MarcaTienda", Size = Vector3.new(1, 1, 1), Position = Vector3.new(PX + 12, SUELO_Y + 19, C.Z), Transparency = 1, CanCollide = false })
	crearCartel(marca, "🛒 TIENDA 🛒", 80, 0, 320)
end

local function puesto(item, x, z, titulo, descripcion, color, forma, conRobux, textoDinero)
	local pos = Vector3.new(PX + x, SUELO_Y, C.Z + z)
	crearParte({ Name = "Puesto", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 4.5, 4.5), CFrame = CFrame.new(pos + Vector3.new(0, 1.9, 0)) * VERTICAL, Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.Marble })
	local icono = crearParte({ Name = "Icono", Shape = forma or Enum.PartType.Block, Size = Vector3.new(2.2, 2.2, 2.2), CFrame = CFrame.new(pos + Vector3.new(0, 5, 0)), Color = color, Material = Enum.Material.Neon, CanCollide = false })
	icono:SetAttribute("Item", item)
	CollectionService:AddTag(icono, "Girar")
	-- cartel medido en studs: se achica con la distancia y no se encima con los puestos vecinos
	local cartel = Instance.new("BillboardGui")
	cartel.Size = UDim2.fromScale(7, 2.6)
	cartel.StudsOffset = Vector3.new(0, 3.3, 0)
	cartel.MaxDistance = 60
	cartel.Adornee = icono
	cartel.Parent = icono
	for k, texto in ipairs({ titulo, descripcion }) do
		local lbl = Instance.new("TextLabel")
		lbl.Size = k == 1 and UDim2.fromScale(1, 0.58) or UDim2.fromScale(1, 0.38)
		lbl.Position = k == 1 and UDim2.fromScale(0, 0) or UDim2.fromScale(0, 0.62)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextScaled = true
		lbl.TextColor3 = k == 1 and Color3.new(1, 1, 1) or Color3.fromRGB(255, 235, 170)
		lbl.TextStrokeTransparency = 0.2
		lbl.Text = texto
		lbl.Parent = cartel
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptTienda"
	prompt.ActionText = textoDinero or "Comprar"
	prompt.ObjectText = titulo
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(plr)
		comprarItem(plr, item)
	end)
	prompt.Parent = icono
	if conRobux then
		-- segundo botón (tecla F) para comprar al instante con Robux
		local pRobux = Instance.new("ProximityPrompt")
		pRobux.Name = "PromptRobux"
		pRobux.ActionText = "Comprar con Robux ⚡"
		pRobux.ObjectText = titulo
		pRobux.KeyboardKeyCode = Enum.KeyCode.F
		pRobux.HoldDuration = 0.5
		pRobux.MaxActivationDistance = 10
		pRobux.RequiresLineOfSight = false
		pRobux.UIOffset = Vector2.new(0, 80)
		pRobux.Triggered:Connect(function(plr)
			comprarRobux(plr, item)
		end)
		pRobux.Parent = icono
	end
	return icono
end

-- La tienda es un cuadro (vista desde arriba):
--   fila pegada al edificio, una columna a cada lado y el huevo de renacer en el centro.
local FILA = 4 -- x de la fila pegada al edificio
local COLUMNA = { -6, -16, -26 } -- x de los puestos de cada columna
local LADO = 20 -- z de las columnas (izquierda = -LADO, derecha = +LADO)
local COLOR_ESCUDO = Color3.fromRGB(120, 200, 255)

local function puestoEscudo(item, x, z)
	local escudo = CONFIG.ESCUDOS[item]
	puesto(item, x, z, "🛡️ Escudo " .. escudo.nombre, "E: dinero  •  F: Robux", COLOR_ESCUDO, Enum.PartType.Ball, true, "Comprar $" .. formato(escudo.precio))
end

-- fila pegada al edificio
puesto("Dinero2x", FILA, -20, "💰 x2 Dinero", "Game Pass (Robux)", Color3.fromRGB(80, 230, 100), Enum.PartType.Ball)
puesto("BateDorado", FILA, -10, "🏏 Bate dorado", "Game Pass (Robux)", Color3.fromRGB(255, 205, 40), Enum.PartType.Cylinder)
local iconoMisterioso = puesto("Misterioso", FILA, 0, "🎁 Huevo misterioso", "¡Puede salir un Dorado!", Color3.fromRGB(200, 120, 255), Enum.PartType.Ball, false, "Abrir $" .. formato(CONFIG.PRECIO_MISTERIOSO))
CollectionService:AddTag(iconoMisterioso, "Arcoiris")
puesto("CaminadoraVIP", FILA, 10, "🏃 Caminadora VIP", "Game Pass (Robux)", Color3.fromRGB(170, 90, 255))
puesto("Ampliar", FILA, 20, "🏗️ Ampliar granja", "E: dinero  •  F: Robux", Color3.fromRGB(205, 150, 90), nil, true)

-- columna izquierda: defensa
puesto("Cierre", COLUMNA[1], -LADO, "🔒 Cierre largo", "Cierra tu granja más tiempo", Color3.fromRGB(170, 170, 180))
puesto("Cerca", COLUMNA[2], -LADO, "⚡ Cerca eléctrica", "Electrocuta ladrones", ELECTRICO)
puestoEscudo("Escudo10m", COLUMNA[3], -LADO)

-- columna derecha: escudos
puestoEscudo("Escudo30m", COLUMNA[1], LADO)
puestoEscudo("Escudo1d", COLUMNA[2], LADO)
puestoEscudo("Escudo2d", COLUMNA[3], LADO)

-- huevo dorado gigante para renacer (en el centro de la tienda)
local promptRenacer
do
	local pos = Vector3.new(PX - 11, SUELO_Y, C.Z)
	crearParte({ Name = "Plataforma", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 18, 18), CFrame = CFrame.new(pos + Vector3.new(0, 0.9, 0)) * VERTICAL, Color = Color3.fromRGB(235, 225, 200), Material = Enum.Material.Marble })
	crearParte({ Name = "Anillo", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 14, 14), CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) * VERTICAL, Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon })
	local huevo = crearParte({ Name = "HuevoGigante", Size = Vector3.new(7, 10, 7), CFrame = CFrame.new(pos + Vector3.new(0, 6.5, 0)), Color = Color3.fromRGB(255, 205, 40), Material = Enum.Material.Foil })
	local malla = Instance.new("SpecialMesh")
	malla.MeshType = Enum.MeshType.Sphere
	malla.Parent = huevo
	local luz = Instance.new("PointLight")
	luz.Color = Color3.fromRGB(255, 220, 100)
	luz.Range = 20
	luz.Brightness = 2
	luz.Parent = huevo
	crearCartel(huevo, "♻️ RENACER\n+50 % de ingresos para siempre", 80, 8, 300)
	promptRenacer = Instance.new("ProximityPrompt")
	promptRenacer.Name = "PromptRenacer"
	promptRenacer.ActionText = "Renacer"
	promptRenacer.ObjectText = "Huevo dorado"
	promptRenacer.HoldDuration = 2
	promptRenacer.MaxActivationDistance = 12
	promptRenacer.RequiresLineOfSight = false
	promptRenacer.Parent = huevo
end

-- tabla global de los más ricos
local filasTabla = {}
do
	local pos = Vector3.new(PX - 8, SUELO_Y + 9, C.Z + 44)
	local tabla = crearParte({ Name = "TablaGlobal", Size = Vector3.new(16, 13, 1), CFrame = CFrame.lookAt(pos, pos - Vector3.xAxis), Color = MADERA_OSCURA, Material = Enum.Material.Wood })
	for _, z in ipairs({ -6, 6 }) do
		crearParte({ Name = "PataTabla", Size = Vector3.new(1, 9, 1), Position = Vector3.new(pos.X + 0.6, SUELO_Y + 4.5, pos.Z + z), Color = MADERA_OSCURA, Material = Enum.Material.Wood })
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(640, 520)
	sg.Parent = tabla
	local fondo = Instance.new("Frame")
	fondo.Size = UDim2.fromScale(1, 1)
	fondo.BackgroundColor3 = Color3.fromRGB(40, 70, 45)
	fondo.Parent = sg
	local orden = Instance.new("UIListLayout")
	orden.Padding = UDim.new(0, 4)
	orden.Parent = fondo
	local function fila(texto, alto, color)
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, alto)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.FredokaOne
		lbl.TextScaled = true
		lbl.TextColor3 = color or Color3.new(1, 1, 1)
		lbl.Text = texto
		lbl.Parent = fondo
		return lbl
	end
	fila("🏆 LOS MÁS RICOS 🏆", 60, Color3.fromRGB(255, 215, 80))
	for i = 1, 10 do
		filasTabla[i] = fila(i == 1 and "Cargando..." or "", 40)
	end
end

local ricos
pcall(function()
	ricos = DataStoreService:GetOrderedDataStore("RobaHuevos_Ricos_v1")
end)
local nombresCache = {}

local function actualizarTabla()
	if not ricos then
		return
	end
	local ok, pagina = pcall(function()
		return ricos:GetSortedAsync(false, 10):GetCurrentPage()
	end)
	if not ok then
		filasTabla[1].Text = "Activa API Services para ver la tabla"
		return
	end
	for i = 1, 10 do
		local entrada = pagina[i]
		if entrada then
			local id = tonumber(entrada.key)
			local nombre = nombresCache[id]
			if not nombre then
				local ok2, n = pcall(function()
					return Players:GetNameFromUserIdAsync(id)
				end)
				nombre = ok2 and n or ("Jugador " .. entrada.key)
				nombresCache[id] = nombre
			end
			filasTabla[i].Text = i .. ". " .. nombre .. "  —  $" .. formato(entrada.value)
		else
			filasTabla[i].Text = ""
		end
	end
end

------------------------------------------------------------------
-- RENACER
------------------------------------------------------------------
promptRenacer.Triggered:Connect(function(plr)
	local base = basesDe[plr]
	local d = dinero(plr)
	local rv = stat(plr, "Renacer")
	if not base or not d or not rv then
		return
	end
	local costo = costoRenacer(plr)
	if d.Value < costo then
		notificar(plr, "Necesitas $" .. formato(costo) .. " para renacer")
		return
	end
	soltarHuevo(plr, false)
	vaciarBase(base)
	base.pendiente = 0
	aplicarNidos(base, CONFIG.NIDOS_INICIALES)
	d.Value = CONFIG.DINERO_INICIAL
	rv.Value += 1
	darInsignia(plr, "PrimerRenacer")
	plr:SetAttribute("CostoRenacer", costoRenacer(plr))
	notificarTodos("♻️ " .. plr.DisplayName .. " renació (x" .. multiplicador(plr) .. " de ingresos)")
end)

------------------------------------------------------------------
-- CINTA DE HUEVOS
------------------------------------------------------------------
local INICIO = Vector3.new(C.X - 124, SUELO_Y + 2.6, C.Z)
local FIN = Vector3.new(C.X + 124, SUELO_Y + 2.6, C.Z)

local function elegirRareza()
	local pesos, total = {}, 0
	for i, r in ipairs(RAREZAS) do
		local p = r.peso
		if horaDorada and i >= 4 then
			p *= 5
		end
		pesos[i] = p
		total += p
	end
	local x = math.random() * total
	for i, p in ipairs(pesos) do
		x -= p
		if x <= 0 then
			return i
		end
	end
	return 1
end

local function elegirMutacion()
	local x = math.random()
	for i = #MUTACIONES, 1, -1 do
		local prob = MUTACIONES[i].prob * (horaDorada and 2 or 1)
		if x < prob then
			return i
		end
		x -= prob
	end
	return 0
end

local function generarHuevoCinta()
	local info = { r = elegirRareza(), g = false, m = elegirMutacion() }
	local precio = precioDe(info)
	local h = crearHuevo(info)
	h.CFrame = CFrame.new(INICIO)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptComprar"
	prompt.ActionText = "Comprar $" .. formato(precio)
	prompt.ObjectText = nombreDe(info)
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = h
	h.Parent = carpetaCinta

	local tween = TweenService:Create(h, TweenInfo.new(CONFIG.DURACION_CINTA, Enum.EasingStyle.Linear), { CFrame = CFrame.new(FIN) })
	tween.Completed:Connect(function()
		if h.Parent then
			h:Destroy()
		end
	end)
	tween:Play()

	if info.r >= 5 or info.m > 0 then
		notificarTodos("✨ ¡Salió " .. nombreDe(info) .. " del gallinero! ✨")
	end

	local vendido = false
	prompt.Triggered:Connect(function(plr)
		if vendido then
			return
		end
		local miBase = basesDe[plr]
		if not miBase then
			return
		end
		local d = dinero(plr)
		if not d or d.Value < precio then
			notificar(plr, "Necesitas $" .. formato(precio))
			return
		end
		local idx = ranuraLibre(miBase)
		if not idx then
			notificar(plr, "No tienes nidos libres. Vende un huevo (F) o desbloquea otro nido.")
			return
		end
		vendido = true
		d.Value -= precio
		tween:Cancel()
		h:Destroy()
		colocarHuevo(miBase, idx, info)
		notificar(plr, "¡Compraste " .. nombreDe(info) .. "!", "Comprar")
		progresoMision(plr, "comprar", 1)
		if info.r == #RAREZAS then
			darInsignia(plr, "HuevoDorado")
		end
	end)
end

------------------------------------------------------------------
-- GUARDADO (DataStore)
------------------------------------------------------------------
local almacen
pcall(function()
	almacen = DataStoreService:GetDataStore("RobaHuevos_v1")
end)

local function cargarDatos(plr)
	if not almacen then
		return false, nil
	end
	local ok, datos = pcall(function()
		return almacen:GetAsync("p_" .. plr.UserId)
	end)
	if not ok then
		warn("[RobaHuevos] No se pudieron cargar datos (¿API Services desactivado?):", datos)
	end
	return ok, datos
end

local function guardarDatos(plr)
	if not almacen or not datosCargados[plr] then
		return
	end
	local d = dinero(plr)
	local rv = stat(plr, "Renacer")
	local e = estado[plr]
	if not d or not rv or not e then
		return
	end
	local base = basesDe[plr]
	local huevos = {}
	local total = d.Value
	local nidos = CONFIG.NIDOS_INICIALES
	local ingreso = 0
	if base then
		for _, r in ipairs(base.ranuras) do
			if r.info then
				table.insert(huevos, { r = r.info.r, g = r.info.g, m = r.info.m })
				ingreso += ingresoDe(r.info)
			end
		end
		ingreso *= multiplicador(plr)
		total += math.floor(base.pendiente)
		nidos = base.nidos
	end
	local ok, err = pcall(function()
		almacen:SetAsync("p_" .. plr.UserId, {
			dinero = total,
			huevos = huevos,
			nidos = nidos,
			renacimientos = rv.Value,
			pasos = e.pasos,
			cierre = e.cierre,
			cerca = e.cerca,
			ampliacion = e.ampliacion,
			escudoHasta = e.escudoHasta,
			misiones = e.misiones,
			ingresoSeg = ingreso, -- para las ganancias offline
			ultimaConexion = os.time(),
			racha = e.racha,
			ultimoDiaRacha = e.ultimoDiaRacha,
			zorros = e.zorros,
		})
	end)
	if not ok then
		warn("[RobaHuevos] Error al guardar:", err)
	end
	if ricos then
		pcall(function()
			ricos:SetAsync(tostring(plr.UserId), math.floor(total))
		end)
	end
end

------------------------------------------------------------------
-- ALIADOS (equipos de 2)
--   Pulsa G sobre otro jugador para invitarlo; si él pulsa G sobre ti, son aliados.
--   Los aliados no se pueden robar, entran a la granja del otro aunque esté cerrada,
--   pueden atrapar a quien le robe al otro y ganan +10 % de ingresos.
------------------------------------------------------------------
local function actualizarAliado(plr)
	local a = aliados[plr]
	plr:SetAttribute("AliadoId", a and a.UserId or 0)
	plr:SetAttribute("AliadoNombre", a and a.DisplayName or "")
end

local function romperAlianza(plr, aviso)
	local a = aliados[plr]
	if not a then
		return
	end
	aliados[plr] = nil
	aliados[a] = nil
	actualizarAliado(plr)
	if a.Parent then
		actualizarAliado(a)
		notificar(a, "🤝 " .. plr.DisplayName .. " " .. aviso)
	end
end

local function manejarAlianza(quien, objetivo)
	if quien == objetivo then
		return
	end
	if aliados[quien] == objetivo then
		romperAlianza(quien, "terminó la alianza contigo")
		notificar(quien, "Terminaste la alianza con " .. objetivo.DisplayName)
		return
	end
	if aliados[quien] or aliados[objetivo] then
		notificar(quien, "Cada jugador puede tener solo un aliado.")
		return
	end
	if invitaciones[objetivo] == quien then
		-- el otro ya me había invitado: se forma la alianza
		invitaciones[objetivo] = nil
		invitaciones[quien] = nil
		aliados[quien] = objetivo
		aliados[objetivo] = quien
		actualizarAliado(quien)
		actualizarAliado(objetivo)
		notificar(quien, "🤝 ¡Ahora eres aliado de " .. objetivo.DisplayName .. "! +10 % de ingresos", "Mision")
		notificar(objetivo, "🤝 ¡Ahora eres aliado de " .. quien.DisplayName .. "! +10 % de ingresos", "Mision")
	else
		invitaciones[quien] = objetivo
		notificar(quien, "Invitaste a " .. objetivo.DisplayName .. ". Debe pulsar G sobre tu personaje para aceptar.")
		notificar(objetivo, "🤝 " .. quien.DisplayName .. " quiere ser tu aliado. Pulsa G sobre su personaje para aceptar.")
	end
end

------------------------------------------------------------------
-- COMPRAS CON ROBUX (productos de desarrollador)
------------------------------------------------------------------
MarketplaceService.ProcessReceipt = function(recibo)
	local plr = Players:GetPlayerByUserId(recibo.PlayerId)
	-- si el jugador no está o sus datos aún no cargan, Roblox lo reintentará después
	if not plr or datosCargados[plr] == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	for item, id in pairs(CONFIG.PRODUCTOS) do
		if id ~= 0 and id == recibo.ProductId then
			if item == "Ampliar" then
				if not ampliarGranja(plr) then
					-- ya estaba al máximo: se le devuelve el valor en dinero del juego
					darDinero(plr, CONFIG.PRECIOS_AMPLIACION[#CONFIG.PRECIOS_AMPLIACION])
				end
			else
				darEscudo(plr, item)
			end
			guardarDatos(plr)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

------------------------------------------------------------------
-- JUGADORES
------------------------------------------------------------------
local function alAparecer(plr, char)
	local hum = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not hrp then
		return
	end
	aplicarVelocidad(plr)

	-- botón para formar alianza (tecla G); el cliente lo oculta en tu propio personaje
	local pAliado = Instance.new("ProximityPrompt")
	pAliado.Name = "PromptAliado"
	pAliado.ActionText = "Alianza 🤝"
	pAliado.ObjectText = plr.DisplayName
	pAliado.KeyboardKeyCode = Enum.KeyCode.G
	pAliado.HoldDuration = 0.8
	pAliado.MaxActivationDistance = 8
	pAliado.RequiresLineOfSight = false
	pAliado:SetAttribute("JugadorId", plr.UserId)
	pAliado.Triggered:Connect(function(otro)
		manejarAlianza(otro, plr)
	end)
	pAliado.Parent = hrp

	hum.Died:Connect(function()
		soltarHuevo(plr, false)
		salirCaminadora(plr, true)
	end)
	local base = basesDe[plr]
	if base then
		task.wait(0.1)
		char:PivotTo(base.spawn)
	end
	darBate(plr)
end

-- Racha diaria: se revisa al entrar y cuando cambia el día
local function revisarRacha(plr)
	local e = estado[plr]
	if not e then
		return
	end
	local hoy = diaActual()
	if e.ultimoDiaRacha == hoy then
		plr:SetAttribute("Racha", e.racha)
		return
	end
	e.racha = (e.ultimoDiaRacha == hoy - 1) and e.racha + 1 or 1
	e.ultimoDiaRacha = hoy
	plr:SetAttribute("Racha", e.racha)

	local base = basesDe[plr]
	local dia = (e.racha - 1) % 7 + 1
	if dia == 7 then
		local info = { r = 6, g = false, m = 0 } -- huevo Mítico
		local idx = base and ranuraLibre(base)
		if idx then
			colocarHuevo(base, idx, info)
		else
			darDinero(plr, precioDe(info))
		end
		notificar(plr, "🔥 ¡Racha de " .. e.racha .. " días! Premio: " .. nombreDe(info), "Mision")
	else
		local ingreso = 0
		if base then
			for _, r in ipairs(base.ranuras) do
				if r.info then
					ingreso += ingresoDe(r.info)
				end
			end
		end
		ingreso *= multiplicador(plr)
		local premio = math.max(CONFIG.RACHA_MINIMO * dia, math.floor(ingreso * CONFIG.RACHA_SEGUNDOS[dia]))
		darDinero(plr, premio)
		notificar(plr, "🔥 Racha de " .. e.racha .. " día(s): +$" .. formato(premio) .. "  (día 7: huevo Mítico)", "Mision")
	end
	if e.racha >= 7 then
		darInsignia(plr, "Racha7")
	end
end

local function alEntrar(plr)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local d = Instance.new("IntValue")
	d.Name = "Dinero"
	d.Value = CONFIG.DINERO_INICIAL
	d.Parent = ls
	local rv = Instance.new("IntValue")
	rv.Name = "Renacer"
	rv.Parent = ls
	ls.Parent = plr

	local e = {
		pasos = 0,
		cierre = 1,
		cerca = 0,
		ampliacion = 0,
		escudoHasta = 0,
		racha = 0,
		ultimoDiaRacha = 0,
		zorros = 0,
		insignias = {},
		pases = {},
		misiones = nil,
		ultimoEnvio = 0,
	}
	estado[plr] = e

	local base
	for _, b in ipairs(bases) do
		if not b.dueno then
			base = b
			break
		end
	end
	if base then
		base.dueno = plr
		base.pendiente = 0
		base.bloqueadoHasta = os.clock() + CONFIG.ESCUDO_ENTRADA
		base.listoBloqueo = 0
		basesDe[plr] = base
		ponerNombre(base, "Granja de " .. plr.DisplayName)
		aplicarNidos(base, CONFIG.NIDOS_INICIALES)
	else
		notificar(plr, "Todas las granjas están ocupadas.")
	end

	plr.CharacterAdded:Connect(function(char)
		e.conPersonaje = true
		alAparecer(plr, char)
	end)

	cargarPases(plr)
	local ok, datos = cargarDatos(plr)
	if not plr.Parent then
		return
	end
	datosCargados[plr] = ok
	if ok and type(datos) == "table" then
		d.Value = datos.dinero or CONFIG.DINERO_INICIAL
		rv.Value = datos.renacimientos or 0
		e.pasos = datos.pasos or 0
		e.cierre = math.clamp(datos.cierre or 1, 1, #CONFIG.DURACIONES_CIERRE)
		e.cerca = math.clamp(datos.cerca or 0, 0, #CONFIG.PROB_CERCA)
		e.misiones = datos.misiones
		e.ampliacion = math.clamp(datos.ampliacion or 0, 0, #CONFIG.PRECIOS_AMPLIACION)
		e.escudoHasta = datos.escudoHasta or 0
		e.racha = datos.racha or 0
		e.ultimoDiaRacha = datos.ultimoDiaRacha or 0
		e.zorros = datos.zorros or 0

		-- ganancias offline: un porcentaje de lo que ganabas, por el tiempo que no estuviste
		local fuera = math.min(os.time() - (datos.ultimaConexion or os.time()), CONFIG.OFFLINE_MAX_HORAS * 3600)
		local ganancia = math.floor((datos.ingresoSeg or 0) * fuera * CONFIG.OFFLINE_PORCENTAJE)
		if fuera > 60 and ganancia > 0 then
			d.Value += ganancia
			task.delay(3, function()
				notificar(plr, "💤 Mientras no estabas (" .. formatoDuracion(fuera) .. ") tu granja ganó $" .. formato(ganancia), "Recoger")
			end)
		end

		if base then
			aplicarAmpliacion(base, e.ampliacion)
			aplicarNidos(base, math.clamp(datos.nidos or CONFIG.NIDOS_INICIALES, CONFIG.NIDOS_INICIALES, maxNidos(base)))
			for _, h in ipairs(datos.huevos or {}) do
				local info = type(h) == "number" and { r = h, g = false, m = 0 } or { r = h.r, g = h.g == true, m = h.m or 0 }
				local idx = ranuraLibre(base)
				if idx and RAREZAS[info.r] then
					colocarHuevo(base, idx, info)
				end
			end
		end
	end

	if base then
		aplicarCerca(base)
		aplicarCaminadora(base)
	end
	revisarDia(plr)
	enviarMisiones(plr)
	revisarRacha(plr)
	actualizarAliado(plr)
	actualizarAtributosTienda(plr)
	plr:SetAttribute("CostoRenacer", costoRenacer(plr))
	if plr.Character and not e.conPersonaje then
		task.spawn(alAparecer, plr, plr.Character)
	elseif plr.Character then
		-- el personaje apareció antes de cargar los datos: aplicar velocidad y bate correctos
		aplicarVelocidad(plr)
		darBate(plr)
	end
	notificar(plr, "🛡️ Tu granja está protegida " .. CONFIG.ESCUDO_ENTRADA .. " s. ¡Compra tus primeros huevos!")
end

Players.PlayerAdded:Connect(alEntrar)
for _, plr in ipairs(Players:GetPlayers()) do
	task.spawn(alEntrar, plr)
end

Players.PlayerRemoving:Connect(function(plr)
	romperAlianza(plr, "salió del juego")
	invitaciones[plr] = nil
	for quien, invitado in pairs(invitaciones) do
		if invitado == plr then
			invitaciones[quien] = nil
		end
	end
	soltarHuevo(plr, false)
	guardarDatos(plr)
	local base = basesDe[plr]
	basesDe[plr] = nil
	if base then
		vaciarBase(base)
		base.dueno = nil
		base.pendiente = 0
		base.bloqueadoHasta = 0
		base.listoBloqueo = 0
		ponerNombre(base, "Granja libre")
		base.nidos = CONFIG.NIDOS_INICIALES
		aplicarAmpliacion(base, 0)
		aplicarCerca(base)
		aplicarCaminadora(base)
	end
	if zorro and zorro.golpeadores then
		zorro.golpeadores[plr] = nil
	end
	enCaminadora[plr] = nil
	ultimaBajada[plr] = nil
	pistasCorrer[plr] = nil
	datosCargados[plr] = nil
	estado[plr] = nil
end)

game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		guardarDatos(plr)
	end
end)

------------------------------------------------------------------
-- BUCLES
------------------------------------------------------------------
-- Cinta
task.spawn(function()
	while true do
		generarHuevoCinta()
		task.wait(horaDorada and CONFIG.INTERVALO_HUEVOS / 2 or CONFIG.INTERVALO_HUEVOS)
	end
end)

-- Hora dorada
task.spawn(function()
	while true do
		task.wait(CONFIG.HORA_DORADA_CADA)
		horaDorada = true
		ReplicatedStorage:SetAttribute("HoraDoradaFin", workspace:GetServerTimeNow() + CONFIG.HORA_DORADA_DURACION)
		notificarTodos("🌟 ¡HORA DORADA! Más huevos raros y mutaciones durante " .. CONFIG.HORA_DORADA_DURACION .. " s 🌟", "Nivel")
		task.wait(CONFIG.HORA_DORADA_DURACION)
		horaDorada = false
	end
end)

-- Zorro
task.spawn(function()
	while true do
		task.wait(CONFIG.ZORRO_CADA)
		lanzarZorro()
	end
end)

-- Ingresos y eclosión (cada segundo)
task.spawn(function()
	while true do
		task.wait(1)
		local ahora = os.clock()
		for _, base in ipairs(bases) do
			local dueno = base.dueno
			if dueno then
				local suma = 0
				for i, r in ipairs(base.ranuras) do
					if r.info then
						suma += ingresoDe(r.info)
						if not r.info.g and r.eclosion then
							if ahora >= r.eclosion then
								local nueva = { r = r.info.r, g = true, m = r.info.m }
								r.huevo:Destroy()
								r.huevo = nil
								colocarHuevo(base, i, nueva)
								notificar(dueno, "🐣 ¡Eclosionó! Ahora tienes " .. nombreDe(nueva), "Eclosion")
								progresoMision(dueno, "eclosionar", 1)
							elseif r.lbl then
								r.lbl.Text = nombreDe(r.info) .. "\n$" .. formato(ingresoDe(r.info)) .. "/s • 🐣 " .. formatoTiempo(r.eclosion - ahora)
							end
						end
					end
				end
				suma *= multiplicador(dueno)
				base.pendiente += suma
				dueno:SetAttribute("IngresoSeg", suma)
				base.textoRecoger.Text = "💰 Recoger $" .. formato(base.pendiente)
			else
				base.textoRecoger.Text = ""
			end
		end
	end
end)

-- Ladrones, cerca eléctrica, cierres y caminadoras (10 veces por segundo)
task.spawn(function()
	while true do
		task.wait(0.1)
		local ahora = os.clock()

		for plr, c in pairs(cargando) do
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hrp or not c.huevo.Parent then
				soltarHuevo(plr, false)
			else
				local miBase = basesDe[plr]
				-- el dueño o su aliado atrapan al ladrón si lo tocan
				local defensor = nil
				for _, p in ipairs({ c.dueno or false, c.dueno and aliados[c.dueno] or false }) do
					local h2 = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if h2 and (h2.Position - hrp.Position).Magnitude < 5 then
						defensor = p
					end
				end
				if miBase and dentroDeBase(miBase, hrp.Position) then
					soltarHuevo(plr, true)
				elseif defensor then
					notificar(defensor, "¡Atrapaste al ladrón!", "Golpe")
					progresoMision(defensor, "atrapar", 1)
					if defensor ~= c.dueno then
						notificar(c.dueno, "🤝 Tu aliado " .. defensor.DisplayName .. " atrapó al ladrón")
					end
					soltarHuevo(plr, false)
				elseif not c.salio and not dentroDeBase(c.base, hrp.Position) then
					-- al salir de la granja: la cerca eléctrica puede detenerlo
					c.salio = true
					local ed = c.dueno and estado[c.dueno]
					if ed and ed.cerca > 0 and basesDe[c.dueno] == c.base and math.random() < CONFIG.PROB_CERCA[ed.cerca] then
						descarga(plr)
						notificar(plr, "⚡ ¡La cerca eléctrica te dio una descarga!")
						notificar(c.dueno, "⚡ Tu cerca eléctrica detuvo a " .. plr.DisplayName)
						progresoMision(c.dueno, "atrapar", 1)
						soltarHuevo(plr, false)
					end
				end
			end
		end

		for _, base in ipairs(bases) do
			local dueno = base.dueno
			if dueno then
				-- cierre: expulsa a los intrusos
				if protegida(base) then
					for _, p in ipairs(Players:GetPlayers()) do
						local hrp = p ~= dueno and not sonAliados(p, dueno) and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
						if hrp and dentroDeBase(base, hrp.Position) then
							soltarHuevo(p, false)
							p.Character:PivotTo(base.cf * CFrame.new(0, 5, -32))
							notificar(p, "Esta granja está protegida.")
						end
					end
				end

			end
		end

		-- caminadora: cada jugador usa la suya (o la de una granja libre)
		for _, plr in ipairs(Players:GetPlayers()) do
			local e = estado[plr]
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local enUso = enCaminadora[plr]
			if not enUso then
				-- arranca sola al subirse a la banda
				if e and hrp and hum and hum.Health > 0 then
					for _, b in ipairs(bases) do
						if (b.dueno == plr or b.dueno == nil) and sobreLaBanda(b, hrp.Position) then
							entrarCaminadora(plr, b)
							break
						end
					end
				end
			elseif not e or not hrp or not hum or hum.Health <= 0 then
				salirCaminadora(plr, true)
			else
				-- contar pasos
				local nivelAntes = nivelCaminadora(e.pasos)
				local suma = tienePase(plr, "CaminadoraVIP") and 2 or 1
				e.pasos += suma
				progresoMision(plr, "pasos", suma)
				local nivel = nivelCaminadora(e.pasos)
				if nivel > nivelAntes then
					aplicarVelocidad(plr)
					local miBase = basesDe[plr]
					if miBase then
						aplicarCaminadora(miBase)
					end
					local pista = pistasCorrer[plr]
					if pista then
						pista:AdjustSpeed(math.max(1, velocidadDe(plr) / 16) * 1.1)
					end
					notificarTodos("⚡ " .. plr.DisplayName .. " subió su caminadora a nivel " .. nivel .. " (velocidad " .. CAMINADORA[nivel].vel .. ")", "Nivel")
					if nivel == #CAMINADORA then
						darInsignia(plr, "CaminadoraMaxima")
					end
				end
			end
		end
	end
end)

-- Carteles (cierre y caminadora)
task.spawn(function()
	while true do
		task.wait(0.25)
		local ahora = os.clock()
		for _, base in ipairs(bases) do
			local dueno = base.dueno
			if not dueno then
				base.textoBloqueo.Text = ""
				estiloCierre(base, COLOR_ESPERA, "🔒")
				base.barrera.Transparency = 1
				base.textoCaminadora.Text = "🏃 Caminadora"
			else
				local e = estado[dueno]
				local escudo = e and (e.escudoHasta or 0) - os.time() or 0
				if escudo > 0 then
					base.textoBloqueo.Text = "🛡️ Escudo " .. formatoDuracion(escudo)
					estiloCierre(base, COLOR_PROTEGIDA, "🛡️")
					base.barrera.Transparency = 0.3
				elseif ahora < base.bloqueadoHasta then
					base.textoBloqueo.Text = "🛡️ " .. math.ceil(base.bloqueadoHasta - ahora) .. " s"
					estiloCierre(base, COLOR_PROTEGIDA, "🛡️")
					base.barrera.Transparency = 0.3
				elseif ahora < base.listoBloqueo then
					base.textoBloqueo.Text = "Espera " .. math.ceil(base.listoBloqueo - ahora) .. " s"
					estiloCierre(base, COLOR_ESPERA, "⏳")
					base.barrera.Transparency = 1
				else
					base.textoBloqueo.Text = "🔒 Cerrar granja"
					estiloCierre(base, COLOR_CERRAR, "🔒")
					base.barrera.Transparency = 1
				end
				if e then
					local n = nivelCaminadora(e.pasos)
					local sig = CAMINADORA[n + 1]
					base.textoCaminadora.Text = "🏃 Nivel " .. n .. " • Velocidad " .. CAMINADORA[n].vel .. "\n"
						.. (sig and (formato(e.pasos) .. " / " .. formato(sig.pasos) .. " pasos") or "¡NIVEL MÁXIMO!")
				end
			end
		end
	end
end)

-- Autoguardado, cambio de día y tabla global
task.spawn(function()
	actualizarTabla()
	while true do
		task.wait(CONFIG.GUARDAR_CADA)
		for _, plr in ipairs(Players:GetPlayers()) do
			guardarDatos(plr)
			revisarDia(plr)
			revisarRacha(plr)
		end
		actualizarTabla()
	end
end)
