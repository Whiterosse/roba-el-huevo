--[[
	ROBA EL HUEVO  -  Script del CLIENTE  (v4)
	Dónde va: StarterPlayer > StarterPlayerScripts  (Insertar objeto > LocalScript)
	Muestra dinero, ingresos, escudo, renacer, hora dorada, misiones y avisos.
	Ajusta los botones de la tienda, anima los huevos arcoíris y la banda de la caminadora,
	y mantiene al jugador corriendo en el centro de su caminadora.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")

local jugador = Players.LocalPlayer

-- deben coincidir con CONFIG del servidor
local PREMIO_MISION_SEGUNDOS = 150
local PREMIO_MISION_MINIMO = 500

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

------------------------------------------------------------------
-- Prompts según quién es el dueño + textos de la tienda
------------------------------------------------------------------
local SOLO_DUENO = { PromptVender = true, PromptNido = true, PromptCorrer = true }
local SOLO_OTROS = { PromptRobar = true }
local promptsTienda = {}

-- mejoras con precio según tu nivel (el servidor manda "Precio<Item>", -1 = máximo)
local MEJORAS = { Cierre = "Mejorar", Cerca = "Mejorar", Ampliar = "Ampliar" }
local PASES = { Dinero2x = true, BateDorado = true, CaminadoraVIP = true }

local function actualizarTienda(p)
	local item = p.Parent and p.Parent:GetAttribute("Item")
	if MEJORAS[item] then
		local precio = jugador:GetAttribute("Precio" .. item) or 0
		local maximo = precio < 0
		p.Enabled = not maximo
		if p.Name == "PromptTienda" then
			p.ActionText = maximo and "✅ Nivel máximo" or (MEJORAS[item] .. " $" .. formato(precio))
		end
	elseif PASES[item] then
		if jugador:GetAttribute("Pase_" .. item) then
			p.ActionText = "✅ Ya lo tienes"
			p.Enabled = false
		else
			p.ActionText = "Comprar (Robux)"
			p.Enabled = true
		end
	end
	-- los escudos tienen precio fijo: el servidor ya puso el texto
end

local function ajustarPrompt(p)
	if p.Name == "PromptTienda" or p.Name == "PromptRobux" then
		table.insert(promptsTienda, p)
		actualizarTienda(p)
		return
	end
	if not SOLO_DUENO[p.Name] and not SOLO_OTROS[p.Name] then
		return
	end
	local objeto = p.Parent
	local function actualizar()
		local esMio = objeto:GetAttribute("DuenoId") == jugador.UserId
		if SOLO_DUENO[p.Name] then
			p.Enabled = esMio
		else
			p.Enabled = not esMio
		end
	end
	actualizar()
	objeto:GetAttributeChangedSignal("DuenoId"):Connect(actualizar)
end

for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		ajustarPrompt(d)
	end
end
workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then
		ajustarPrompt(d)
	end
end)

jugador.AttributeChanged:Connect(function(nombre)
	if nombre:sub(1, 6) == "Precio" or nombre:sub(1, 5) == "Pase_" then
		for _, p in ipairs(promptsTienda) do
			actualizarTienda(p)
		end
	end
end)

------------------------------------------------------------------
-- Efectos: huevos arcoíris e íconos de la tienda que giran
------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	local color = Color3.fromHSV((t * 0.25) % 1, 0.8, 1)
	for _, parte in ipairs(CollectionService:GetTagged("Arcoiris")) do
		parte.Color = color
	end
	for _, parte in ipairs(CollectionService:GetTagged("Girar")) do
		local pos = parte:GetAttribute("PosOriginal")
		if not pos then
			pos = parte.Position
			parte:SetAttribute("PosOriginal", pos)
		end
		parte.CFrame = CFrame.new(pos + Vector3.new(0, math.sin(t * 2) * 0.4, 0)) * CFrame.Angles(0, t, 0)
	end
	-- franjas de la banda: avanzan hacia atrás para que parezca que gira
	for _, franja in ipairs(CollectionService:GetTagged("FranjaCaminadora")) do
		local banda = franja.Parent and franja.Parent:FindFirstChild("Banda")
		if banda then
			local vel = banda:GetAttribute("Velocidad") or 16
			local z = ((franja:GetAttribute("Z0") or 0) + 6 + t * vel * 0.6) % 12 - 6
			franja.CFrame = banda.CFrame * CFrame.new(0, 0.17, z)
		end
	end
end)

------------------------------------------------------------------
-- HUD
------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "RobaHuevosHUD"
gui.ResetOnSpawn = false
gui.Parent = jugador:WaitForChild("PlayerGui")

local MARRON = Color3.fromRGB(60, 40, 25)
local DORADO = Color3.fromRGB(225, 195, 95)

local function etiqueta(padre, color, tamano, posicion, alineacion)
	local lbl = Instance.new("TextLabel")
	lbl.Size = tamano
	lbl.Position = posicion
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.TextColor3 = color
	lbl.TextStrokeTransparency = 0.6
	lbl.TextXAlignment = alineacion or Enum.TextXAlignment.Center
	lbl.Text = ""
	lbl.Parent = padre
	return lbl
end

local function panel(padre, tamano, posicion, ancla)
	local f = Instance.new("Frame")
	f.AnchorPoint = ancla or Vector2.zero
	f.Position = posicion
	f.Size = tamano
	f.BackgroundColor3 = MARRON
	f.BackgroundTransparency = 0.15
	f.Parent = padre
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
	local borde = Instance.new("UIStroke", f)
	borde.Color = DORADO
	borde.Thickness = 2
	return f
end

-- dinero
local marco = panel(gui, UDim2.fromOffset(260, 106), UDim2.new(0.5, 0, 0, 10), Vector2.new(0.5, 0))
local etiquetaDinero = etiqueta(marco, Color3.fromRGB(120, 255, 120), UDim2.new(1, -16, 0, 40), UDim2.fromOffset(8, 4))
local etiquetaIngreso = etiqueta(marco, Color3.fromRGB(255, 240, 180), UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 44))
local etiquetaRenacer = etiqueta(marco, Color3.fromRGB(255, 215, 80), UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 64))
local etiquetaEscudo = etiqueta(marco, Color3.fromRGB(140, 210, 255), UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, 84))

-- hora dorada
local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 124)
banner.Size = UDim2.fromOffset(380, 36)
banner.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
banner.Font = Enum.Font.FredokaOne
banner.TextScaled = true
banner.TextColor3 = Color3.fromRGB(80, 50, 0)
banner.Visible = false
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)

task.spawn(function()
	local ls = jugador:WaitForChild("leaderstats")
	local dinero = ls:WaitForChild("Dinero")
	local renacer = ls:WaitForChild("Renacer")

	local function actualizarDinero()
		etiquetaDinero.Text = "$" .. formato(dinero.Value)
		marco.Size = UDim2.fromOffset(272, 110)
		TweenService:Create(marco, TweenInfo.new(0.2), { Size = UDim2.fromOffset(260, 106) }):Play()
	end
	local function actualizarIngreso()
		etiquetaIngreso.Text = "+$" .. formato(jugador:GetAttribute("IngresoSeg") or 0) .. " / s"
	end
	local function actualizarRenacer()
		local costo = jugador:GetAttribute("CostoRenacer") or 0
		etiquetaRenacer.Text = "♻️ " .. renacer.Value .. "  •  Renacer: $" .. formato(costo)
	end

	actualizarDinero()
	actualizarIngreso()
	actualizarRenacer()
	dinero.Changed:Connect(actualizarDinero)
	renacer.Changed:Connect(actualizarRenacer)
	jugador:GetAttributeChangedSignal("IngresoSeg"):Connect(actualizarIngreso)
	jugador:GetAttributeChangedSignal("CostoRenacer"):Connect(actualizarRenacer)
end)

RunService.Heartbeat:Connect(function()
	local fin = ReplicatedStorage:GetAttribute("HoraDoradaFin")
	local resta = fin and (fin - workspace:GetServerTimeNow()) or 0
	if resta > 0 then
		banner.Visible = true
		banner.Text = "🌟 HORA DORADA  " .. math.ceil(resta) .. " s 🌟"
	else
		banner.Visible = false
	end
	local restaEscudo = (jugador:GetAttribute("EscudoHasta") or 0) - workspace:GetServerTimeNow()
	etiquetaEscudo.Text = restaEscudo > 0 and ("🛡️ Escudo: " .. formatoDuracion(restaEscudo)) or "🛡️ Sin escudo"
end)

------------------------------------------------------------------
-- Misiones del día (panel a la izquierda)
------------------------------------------------------------------
local panelMisiones = panel(gui, UDim2.fromOffset(270, 190), UDim2.new(0, 10, 0.5, 0), Vector2.new(0, 0.5))
etiqueta(panelMisiones, DORADO, UDim2.new(1, -16, 0, 28), UDim2.fromOffset(8, 6)).Text = "📋 Misiones del día"
local filas = {}
for i = 1, 3 do
	local y = 38 + (i - 1) * 50
	local texto = etiqueta(panelMisiones, Color3.new(1, 1, 1), UDim2.new(1, -16, 0, 18), UDim2.fromOffset(8, y), Enum.TextXAlignment.Left)
	local fondoBarra = Instance.new("Frame")
	fondoBarra.Size = UDim2.new(1, -16, 0, 14)
	fondoBarra.Position = UDim2.fromOffset(8, y + 22)
	fondoBarra.BackgroundColor3 = Color3.fromRGB(30, 20, 12)
	fondoBarra.Parent = panelMisiones
	Instance.new("UICorner", fondoBarra).CornerRadius = UDim.new(0, 7)
	local barra = Instance.new("Frame")
	barra.Size = UDim2.fromScale(0, 1)
	barra.BackgroundColor3 = Color3.fromRGB(110, 220, 110)
	barra.Parent = fondoBarra
	Instance.new("UICorner", barra).CornerRadius = UDim.new(0, 7)
	local cuenta = etiqueta(fondoBarra, Color3.new(1, 1, 1), UDim2.fromScale(1, 1), UDim2.fromScale(0, 0))
	filas[i] = { texto = texto, barra = barra, cuenta = cuenta }
end

local misiones = {}
local function dibujarMisiones()
	local premio = math.max(PREMIO_MISION_MINIMO, (jugador:GetAttribute("IngresoSeg") or 0) * PREMIO_MISION_SEGUNDOS)
	for i, fila in ipairs(filas) do
		local m = misiones[i]
		if m then
			fila.texto.Text = (m.hecha and "✅ " or "") .. m.texto
			fila.barra.Size = UDim2.fromScale(math.clamp(m.prog / m.meta, 0, 1), 1)
			fila.barra.BackgroundColor3 = m.hecha and Color3.fromRGB(255, 205, 60) or Color3.fromRGB(110, 220, 110)
			fila.cuenta.Text = m.hecha and "¡Completada!" or (formato(m.prog) .. " / " .. formato(m.meta) .. "   🎁 $" .. formato(premio))
		else
			fila.texto.Text = ""
			fila.barra.Size = UDim2.fromScale(0, 1)
			fila.cuenta.Text = ""
		end
	end
end

local eventoMisiones = ReplicatedStorage:WaitForChild("Misiones")
eventoMisiones.OnClientEvent:Connect(function(lista)
	misiones = lista or {}
	dibujarMisiones()
end)
jugador:GetAttributeChangedSignal("IngresoSeg"):Connect(dibujarMisiones)
eventoMisiones:FireServer() -- pedir las misiones al iniciar

------------------------------------------------------------------
-- Avisos
------------------------------------------------------------------
local lista = Instance.new("Frame")
lista.AnchorPoint = Vector2.new(0.5, 1)
lista.Position = UDim2.new(0.5, 0, 1, -110)
lista.Size = UDim2.fromOffset(460, 300)
lista.BackgroundTransparency = 1
lista.Parent = gui
local orden = Instance.new("UIListLayout", lista)
orden.VerticalAlignment = Enum.VerticalAlignment.Bottom
orden.HorizontalAlignment = Enum.HorizontalAlignment.Center
orden.Padding = UDim.new(0, 6)

local function mostrarAviso(texto, duracion)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 36)
	lbl.BackgroundColor3 = MARRON
	lbl.BackgroundTransparency = 0.2
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.Text = texto
	lbl.Parent = lista
	Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 10)
	local pad = Instance.new("UIPadding", lbl)
	pad.PaddingTop = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 5)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	task.delay(duracion or 3, function()
		local info = TweenInfo.new(0.5)
		TweenService:Create(lbl, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		task.wait(0.5)
		lbl:Destroy()
	end)
end

ReplicatedStorage:WaitForChild("Notificar").OnClientEvent:Connect(function(texto)
	mostrarAviso(texto)
end)

mostrarAviso("🥚 Compra huevos en la cinta con E", 8)
mostrarAviso("🏃 Usa tu caminadora para ser más rápido", 8)
mostrarAviso("🛒 La tienda está al final de la cinta", 8)

------------------------------------------------------------------
-- Caminadora: correr fijo en el centro de la banda
--   El servidor pone el atributo "CentroCaminadora" mientras corres.
--   Aquí se desactivan los controles, se fija al jugador en el centro
--   y se le hace "caminar" hacia adelante para que se vea corriendo.
------------------------------------------------------------------
local controles
pcall(function()
	controles = require(jugador:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
end)
local eventoSalir = ReplicatedStorage:WaitForChild("SalirCaminadora")

local botonBajar = Instance.new("TextButton")
botonBajar.AnchorPoint = Vector2.new(0.5, 1)
botonBajar.Position = UDim2.new(0.5, 0, 1, -60)
botonBajar.Size = UDim2.fromOffset(330, 46)
botonBajar.BackgroundColor3 = Color3.fromRGB(220, 70, 60)
botonBajar.Font = Enum.Font.FredokaOne
botonBajar.TextScaled = true
botonBajar.TextColor3 = Color3.new(1, 1, 1)
botonBajar.Text = "⬇️ Bajar de la caminadora (Espacio)"
botonBajar.Visible = false
botonBajar.Parent = gui
Instance.new("UICorner", botonBajar).CornerRadius = UDim.new(0, 12)
local rellenoBoton = Instance.new("UIPadding", botonBajar)
rellenoBoton.PaddingTop = UDim.new(0, 6)
rellenoBoton.PaddingBottom = UDim.new(0, 6)

local corriendo = false
local pistaCorrer -- animación de correr que se reproduce en bucle

-- usa la misma animación de correr del personaje (sirve para R6 y R15)
local function cargarAnimacionCorrer(char, hum)
	local animator = hum:FindFirstChildOfClass("Animator")
	local animate = char:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local anim = run and run:FindFirstChildOfClass("Animation")
	if not animator or not anim then
		return nil
	end
	local pista = animator:LoadAnimation(anim)
	pista.Priority = Enum.AnimationPriority.Action
	pista.Looped = true
	return pista
end

local function pedirBajar()
	if corriendo then
		eventoSalir:FireServer()
	end
end
botonBajar.Activated:Connect(pedirBajar)
UserInputService.InputBegan:Connect(function(input, procesado)
	if procesado then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
		pedirBajar()
	end
end)

RunService.Heartbeat:Connect(function()
	local centro = jugador:GetAttribute("CentroCaminadora")
	local char = jugador.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if centro and hrp and hum then
		if not corriendo then
			corriendo = true
			botonBajar.Visible = true
			if controles then
				controles:Disable()
			end
			pistaCorrer = cargarAnimacionCorrer(char, hum)
			if pistaCorrer then
				pistaCorrer:Play(0.2)
			end
		end
		-- fijar en el centro mirando hacia la consola, sin moverse; la altura la deja la física
		local adelante = centro.LookVector
		local pos = Vector3.new(centro.X, hrp.Position.Y, centro.Z)
		hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(adelante.X, 0, adelante.Z))
		hrp.AssemblyLinearVelocity = Vector3.new(0, hrp.AssemblyLinearVelocity.Y, 0)
		-- las piernas van más rápido cuanto más alto el nivel de la caminadora
		if pistaCorrer then
			pistaCorrer:AdjustSpeed(math.max(1, hum.WalkSpeed / 16) * 1.1)
		end
	elseif corriendo then
		corriendo = false
		botonBajar.Visible = false
		if controles then
			controles:Enable()
		end
		if pistaCorrer then
			pistaCorrer:Stop(0.2)
			pistaCorrer = nil
		end
	end
end)
