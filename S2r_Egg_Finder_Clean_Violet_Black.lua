-- =====================================================================
-- S2R_EGG_FINDER  -  finder con UI liquid glass roja/negra, letra tipo codigo e intro original (una vez por sesion)
-- Toda la logica es la del Source Hub de siempre; solo cambia la interfaz.
-- Abrir / cerrar: boton flotante o RightShift
-- =====================================================================
local SH_TITLE = "S2R_EGG_FINDER" -- nombre que sale arriba en el panel
pcall(function() getgenv().SH_Title = SH_TITLE end)

-- ===== la intro solo sale UNA vez por sesion de Roblox =====
-- (si cambias de server o vuelves a ejecutar no sale; si cierras Roblox y vuelves a entrar, si)
do
	local G = getgenv()
	local skip = G.S2R_EGG_FINDER_IntroDone == true or G.S2R_EGG_FINDER_SkipIntro == true
	pcall(function()
		local td = game:GetService("TeleportService"):GetLocalPlayerTeleportData()
		if type(td) == "table" and td.S2R_EGG_FINDER then skip = true end
	end)
	G.S2R_EGG_FINDER_SkipIntro = skip
	G.S2R_EGG_FINDER_IntroDone = true
	-- se deja preparado para el siguiente server: al llegar alli ya sabra que la intro salio
	pcall(function()
		local q = queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
		if q then q("pcall(function() getgenv().S2R_EGG_FINDER_SkipIntro = true getgenv().S2R_EGG_FINDER_IntroDone = true end)") end
	end)
end

-- ===== S2R_EGG_FINDER loading screen: el panel y los botones solo aparecen al llegar a 100% =====
do
	local G = getgenv()
	G.S2R_EGG_FINDER_Loaded = false
	G.S2R_EGG_FINDER_Loader_Active = false
	G.S2R_EGG_FINDER_BypassReady = false -- al volver a ejecutar, el bypass se vuelve a pedir
	G.S2R_EGG_FINDER_NewsShown = false
	G.S2R_EGG_FINDER_HintShown = false
	G.S2R_EGG_FINDER_BypassSplashShown = false -- (se quedaba guardado y no volvia a salir)
	G.S2R_EGG_FINDER_BypassImg = nil
	G.S2R_EGG_FINDER_BypassHD = nil
	G.S2R_EGG_FINDER_LoadSet = function() end
	-- carga una imagen por id probando varias formas (Image, Decal, miniatura) hasta que una cargue
	G.S2R_EGG_FINDER_ResolveImage = function(id, target, apply, onFail)
		task.spawn(function()
			local CP = game:GetService("ContentProvider")
			local function loaded(c)
				apply(c)
				local ok = false
				pcall(function()
					CP:PreloadAsync({ target }, function(_, st)
						if st == Enum.AssetFetchStatus.Success then ok = true end
					end)
				end)
				if not ok then pcall(function() ok = target.IsLoaded == true end) end
				return ok
			end
			id = tostring(id)
			if loaded("rbxassetid://" .. id) then return end
			-- si es un Decal: sacar la imagen real que lleva dentro
			local got
			task.spawn(function()
				pcall(function()
					local objs = game:GetObjects("rbxassetid://" .. id)
					local o = objs and objs[1]
					if o then
						if o:IsA("Decal") or o:IsA("Texture") then got = o.Texture
						elseif o:IsA("ImageLabel") or o:IsA("ImageButton") then got = o.Image end
						pcall(function() o:Destroy() end)
					end
				end)
				got = got or false
			end)
			local t0 = os.clock()
			while got == nil and os.clock() - t0 < 3 do task.wait(0.05) end
			if type(got) == "string" and got ~= "" and loaded(got) then return end
			-- no cargo: NO se usa la miniatura de Roblox (en algunos dispositivos sale el gris con el logo de Roblox)
			pcall(apply, "")
			if onFail then pcall(onFail) end
		end)
	end
	-- imagen desde un enlace directo (catbox): se descarga una vez, se guarda en S2R_EGG_FINDER/ y se carga en HD
	G.S2R_EGG_FINDER_UrlImage = function(url, target, apply, onFail)
		task.spawn(function()
			local ok = false
			pcall(function()
				local custom = getcustomasset or getsynasset
				if not (custom and writefile and isfile) then return end
				-- solo se acepta si de verdad es una imagen (no una pagina de error)
				local function isImage(d)
					return type(d) == "string" and #d > 1000 and (d:sub(1, 4) == "\137PNG" or d:sub(1, 2) == "\255\216" or d:sub(1, 4) == "RIFF")
				end
				local name = tostring(url):match("([%w_%-]+%.%w+)$") or "img.png"
				local path = "S2R_EGG_FINDER/" .. name
				pcall(function() if makefolder and isfolder and not isfolder("S2R_EGG_FINDER") then makefolder("S2R_EGG_FINDER") end end)
				local function fileOk()
					local has = false
					pcall(function() has = isfile(path) end)
					if has and readfile then
						local okr, d = pcall(readfile, path)
						if okr and not isImage(d) then
							pcall(function() if delfile then delfile(path) end end) -- archivo roto: se borra
							has = false
						end
					end
					return has
				end
				local function download()
					for _ = 1, 2 do
						local okh, data = pcall(function() return game:HttpGet(url) end)
						if okh and isImage(data) then
							pcall(writefile, path, data)
							return true
						end
						task.wait(0.5)
					end
					return false
				end
				if not fileOk() then download() end
				if not fileOk() then return end
				local c = custom(path)
				if type(c) ~= "string" or c == "" then return end
				apply(c)
				-- comprobar que de verdad se ve (max 6 s)
				local loaded = false
				pcall(function()
					game:GetService("ContentProvider"):PreloadAsync({ target }, function(_, st)
						if st == Enum.AssetFetchStatus.Success then loaded = true end
					end)
				end)
				local t0 = os.clock()
				while not loaded and os.clock() - t0 < 6 do
					pcall(function() loaded = target.IsLoaded == true end)
					if loaded then break end
					task.wait(0.1)
				end
				if loaded then
					ok = true
				else
					pcall(function() if delfile then delfile(path) end end) -- no cargo: la proxima vez se descarga de nuevo
				end
			end)
			if not ok and onFail then pcall(onFail) end
		end)
	end
	G.S2R_EGG_FINDER_LoadDone = function() G.S2R_EGG_FINDER_Loaded = true end
	pcall(function()
		-- ya salio en esta sesion de Roblox (cambio de server o se volvio a ejecutar): sin intro
		if G.S2R_EGG_FINDER_SkipIntro then
			G.S2R_EGG_FINDER_Loaded = true
			return
		end
		local TS = game:GetService("TweenService")
		local RS = game:GetService("RunService")
		local parent
		pcall(function() if gethui then parent = gethui() end end)
		if not parent then
			pcall(function()
				local t = Instance.new("Folder")
				t.Parent = game:GetService("CoreGui")
				t:Destroy()
				parent = game:GetService("CoreGui")
			end)
		end
		if not parent then parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
		local old = parent:FindFirstChild("S2R_EGG_FINDER_Loader")
		if old then old:Destroy() end

		local gui = Instance.new("ScreenGui")
		gui.Name = "S2R_EGG_FINDER_Loader"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 500
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = parent

		-- ===== CARGA S2R_EGG_FINDER: foto "wait for it to load" + barra de cuadrados (16 s, sin skip) =====
		local INTRO_IMAGE = 89584936796953
		local INTRO_MUSIC = tonumber(G.S2R_EGG_FINDER_IntroMusicId) or 109356844790520 -- id de la cancion (16 s)
		local INTRO_MUSIC_FILE = "S2R_EGG_FINDER/intro_cwwpfn.mp3" -- se guarda aqui tras descargarlo (cambia el nombre si cambias de cancion)
		local DURATION = 10
		local IMG_RATIO = 1684 / 934
		local WHITE = Color3.new(1, 1, 1)
		local BLACK = Color3.new(0, 0, 0)
		local PIXEL = Enum.Font.Arcade

		local function tw(o, t, props, style, dir, rep, rev)
			local tn = TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out, rep or 0, rev or false), props)
			tn:Play()
			return tn
		end
		local function mk(class, props)
			local o = Instance.new(class)
			for k2, v in pairs(props) do if k2 ~= "Parent" then o[k2] = v end end
			if props.Parent then o.Parent = props.Parent end
			return o
		end

		local back = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0, BorderSizePixel = 0, Active = true, Parent = gui })
		local view = gui.AbsoluteSize
		if view.X < 10 then view = Vector2.new(1280, 720) end

		-- foto arriba
		local IW = math.min(view.X * 0.82, view.Y * 0.8 * IMG_RATIO)
		local IH = IW / IMG_RATIO
		local IMG_Y = 0 -- centrada (sin barra)
		local photo = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, IMG_Y), Size = UDim2.fromOffset(IW, IH), BackgroundTransparency = 1, Parent = back })
		local photoSc = mk("UIScale", { Scale = 0.97, Parent = photo })
		local img = mk("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageTransparency = 0, ZIndex = 2, Parent = photo })
		local mask -- (se crea justo despues)
		-- respaldo si la foto no carga: la frase escrita en rojo neon, inclinada como la foto
		local function textFallback()
			img.Visible = false
			local holder = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.9, 0.42), BackgroundTransparency = 1, Rotation = -12, ZIndex = 2, Parent = photo })
			local function line(z, strokeT, strokeW, textT)
				local t = mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.Kalam, Text = "wait for it to load", TextScaled = true, TextColor3 = Color3.fromRGB(160, 75, 255), TextTransparency = textT, ZIndex = z, Parent = holder })
				mk("UIStroke", { Color = Color3.fromRGB(160, 75, 255), Thickness = strokeW, Transparency = strokeT, Parent = t })
				local m2 = mask:Clone()
				m2.Parent = t
				task.spawn(function()
					-- sigue la misma mascara que la foto (se escribe a mano)
					while t.Parent do
						m2.Offset = mask.Offset
						t.TextTransparency = textT + img.ImageTransparency * 0.6
						task.wait()
					end
				end)
				return t
			end
			line(2, 0.86, 8, 0.6) -- brillo
			line(3, 0.4, 1.5, 0)  -- texto
		end
		-- "se escribe a mano": una mascara revela la frase siguiendo su inclinacion
		mask = mk("UIGradient", { Rotation = -12, Offset = Vector2.new(-0.72, 0), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.46, 0), NumberSequenceKeypoint.new(0.54, 1), NumberSequenceKeypoint.new(1, 1) }), Parent = img })
		G.S2R_EGG_FINDER_UrlImage("https://files.catbox.moe/5xdkb1.png", img, function(c) img.Image = c end, function()
			G.S2R_EGG_FINDER_ResolveImage(INTRO_IMAGE, img, function(a) img.Image = a end, textFallback)
		end)
		-- lineas VHS muy suaves + franja de escaneo
		local scan = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, IMG_Y), Size = UDim2.new(1, 0, 0, IH * 1.1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 4, Parent = back })
		for i = 0, math.clamp(math.floor(IH * 1.1 / 4), 20, 200) - 1 do
			mk("Frame", { Position = UDim2.fromOffset(0, i * 4), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 4, Parent = scan })
		end
		local band = mk("Frame", { Position = UDim2.new(0, 0, 0, -40), Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = WHITE, BackgroundTransparency = 0.96, BorderSizePixel = 0, ZIndex = 5, Parent = scan })
		mk("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = band })

		-- barra retro de cuadrados debajo de la foto (diseño base 620 px, se escala)
		local BW, BHt, INSET, NSQ, GAP = 620, 58, 9, 20, 6
		local stage = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, IMG_Y + IH * 0.29), Size = UDim2.fromOffset(BW, 100), BackgroundTransparency = 1, ZIndex = 6, Parent = back })
		local stageSc = mk("UIScale", { Scale = math.clamp(IW * 0.6 / BW, 0.5, 2.6), Parent = stage })
		local barGroup = mk("CanvasGroup", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, GroupTransparency = 1, ZIndex = 6, Parent = stage })
		stage.Visible = false -- (sin barra: solo la foto)
		local barPop = mk("UIScale", { Scale = 0.9, Parent = barGroup })
		local bar = mk("Frame", { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(BW, BHt), BackgroundColor3 = BLACK, BorderSizePixel = 0, ZIndex = 6, Parent = barGroup })
		mk("UICorner", { CornerRadius = UDim.new(0, 14), Parent = bar })
		mk("UIStroke", { Color = WHITE, Thickness = 5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = bar })
		local innerW = BW - INSET * 2
		local sqW = (innerW - GAP * (NSQ - 1)) / NSQ
		local squares = {}
		for i = 1, NSQ do
			local sq = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(INSET + (i - 1) * (sqW + GAP) + sqW / 2, BHt / 2), Size = UDim2.fromOffset(sqW, BHt - INSET * 2), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 7, Parent = bar })
			mk("UICorner", { CornerRadius = UDim.new(0, 3), Parent = sq })
			squares[i] = { f = sq, sc = mk("UIScale", { Parent = sq }) }
		end
		local mainTxt = mk("TextLabel", { Position = UDim2.fromOffset(2, BHt + 14), Size = UDim2.fromOffset(BW - 140, 28), BackgroundTransparency = 1, Font = PIXEL, Text = "LOADING", TextSize = 28, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, Parent = barGroup })
		local pct = mk("TextLabel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, BHt + 14), Size = UDim2.fromOffset(130, 28), BackgroundTransparency = 1, Font = PIXEL, Text = "0%", TextSize = 28, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 7, Parent = barGroup })
		local status = mk("TextLabel", { Visible = false, Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1, Text = "", Parent = barGroup })

		local shown = 0
		local function setProgress(a)
			local n = math.floor(a * NSQ + 1e-4)
			if n > shown then
				for i = shown + 1, n do
					local s = squares[i]
					s.f.BackgroundTransparency = 0
					s.sc.Scale = 0.35
					tw(s.sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
				end
				shown = n
			end
			pct.Text = tostring(math.floor(a * 100 + 0.5)) .. "%"
		end
		setProgress(0)

		local exiting, done = false, false
		-- musica: el audio subido a Roblox no suena en Blade Ball (privacidad de audio),
		-- asi que se usa el mp3 desde el executor. Si no esta, se descarga una vez del enlace.
		local INTRO_MUSIC_URL = tostring(G.S2R_EGG_FINDER_IntroMusicURL or "https://files.catbox.moe/cwwpfn.mp3") -- enlace directo al mp3
		local music = Instance.new("Sound")
		music.Name = "S2R_EGG_FINDER_IntroMusic"
		music.Volume = 0
		music.Looped = false
		music.Parent = game:GetService("SoundService")
		-- silencia todo el sonido del juego mientras dura la intro
		local muted, muteConns = {}, {}
		local function muteObj(o)
			if o == music or muted[o] ~= nil then return end
			if o:IsA("Sound") or o:IsA("SoundGroup") then
				local ok, v = pcall(function() return o.Volume end)
				if ok and type(v) == "number" and v > 0 then
					muted[o] = v
					pcall(function() o.Volume = 0 end)
				end
			end
		end
		local function muteAll()
			for _, svc in ipairs({ game:GetService("SoundService"), workspace, game:GetService("Players").LocalPlayer }) do
				pcall(function()
					for _, d in ipairs(svc:GetDescendants()) do muteObj(d) end
					muteConns[#muteConns + 1] = svc.DescendantAdded:Connect(function(d)
						if not exiting then task.defer(muteObj, d) end
					end)
				end)
			end
		end
		local function unmuteAll()
			for _, c in ipairs(muteConns) do pcall(function() c:Disconnect() end) end
			muteConns = {}
			for o, v in pairs(muted) do
				pcall(function() TS:Create(o, TweenInfo.new(1.2, Enum.EasingStyle.Quad), { Volume = v }):Play() end)
			end
			muted = {}
		end
		pcall(muteAll)
		task.spawn(function()
			pcall(function()
				local custom = getcustomasset or getsynasset
				local has = false
				pcall(function() has = isfile and isfile(INTRO_MUSIC_FILE) end)
				if not has and INTRO_MUSIC_URL ~= "" and writefile then
					pcall(function() if makefolder and isfolder and not isfolder("S2R_EGG_FINDER") then makefolder("S2R_EGG_FINDER") end end)
					local ok, data = pcall(function() return game:HttpGet(INTRO_MUSIC_URL) end)
					if ok and type(data) == "string" and #data > 20000 then
						pcall(writefile, INTRO_MUSIC_FILE, data)
						pcall(function() has = isfile(INTRO_MUSIC_FILE) end)
					end
				end
				local id = ""
				if has and custom then
					pcall(function() id = custom(INTRO_MUSIC_FILE) end)
				end
				if id == "" and INTRO_MUSIC and INTRO_MUSIC > 0 then id = "rbxassetid://" .. tostring(INTRO_MUSIC) end
				if id == "" or exiting then return end
				music.SoundId = id
				task.spawn(function() pcall(function() game:GetService("ContentProvider"):PreloadAsync({ music }) end) end)
				local w0 = os.clock()
				while not music.IsLoaded and os.clock() - w0 < 2 do task.wait(0.05) end
				if not music.Parent or exiting then return end
				music.TimePosition = 0
				music:Play()
				tw(music, 0.6, { Volume = 1 }, Enum.EasingStyle.Quad)
				task.wait(3)
				if music.Parent and (not music.IsLoaded or music.TimeLength == 0) then
					warn("[S2R_EGG_FINDER] La musica de la intro no cargo. Pon el mp3 en la carpeta del executor: " .. INTRO_MUSIC_FILE)
				end
			end)
		end)

		-- secuencia
		local t0 = os.clock()
		tw(photoSc, DURATION, { Scale = 1.02 }, Enum.EasingStyle.Linear)
		task.spawn(function()
			-- espera a que la foto cargue (max 5 s) y luego se "escribe"
			task.wait(0.4)
			local w0 = os.clock()
			while os.clock() - w0 < 5 do
				local ok = false
				pcall(function() ok = img.IsLoaded == true end)
				if ok then break end
				task.wait(0.1)
			end
			tw(mask, 3.2, { Offset = Vector2.new(0.72, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end)
		task.delay(1.6, function()
			tw(barGroup, 0.5, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
			tw(barPop, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
		end)
		-- como una tele / letrero: cada pocos segundos se apaga suave y vuelve a encenderse con dos destellos
		task.spawn(function()
			local rnd = Random.new()
			task.wait(4)
			while gui.Parent and not exiting do
				task.wait(rnd:NextNumber(2.6, 3.6))
				if exiting then break end
				-- se apaga
				tw(img, 0.22, { ImageTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(0.22 + rnd:NextNumber(0.25, 0.4))
				if exiting then break end
				-- vuelve: dos destellos rapidos y se queda encendida
				img.ImageTransparency = 0.2
				task.wait(0.05)
				img.ImageTransparency = 0.85
				task.wait(0.07)
				img.ImageTransparency = 0.1
				task.wait(0.04)
				img.ImageTransparency = 0.7
				task.wait(0.06)
				if exiting then break end
				tw(img, 0.25, { ImageTransparency = 0 }, Enum.EasingStyle.Quad)
			end
		end)
		task.spawn(function()
			while gui.Parent and not exiting do
				band.Position = UDim2.new(0, 0, 0, -40)
				tw(band, 2.6, { Position = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
				task.wait(3.4)
			end
		end)

		G.S2R_EGG_FINDER_LoadSet = function() end
		local conn
		conn = RS.Heartbeat:Connect(function()
			local a = math.clamp((os.clock() - t0) / DURATION, 0, 1)
			if not done then a = math.min(a, 0.97) end
			setProgress(a)
			mainTxt.Text = "LOADING" .. string.rep(".", math.floor(os.clock() * 2.5) % 4)
		end)

		G.S2R_EGG_FINDER_LoadDone = function()
			if done then return end
			done = true
			task.spawn(function()
				-- la carga dura 16 s aunque el script termine antes
				while os.clock() - t0 < DURATION - 1.1 do task.wait(0.05) end
				if music then tw(music, 1.1, { Volume = 0 }, Enum.EasingStyle.Quad) end
				pcall(unmuteAll) -- vuelve el sonido del juego
				while os.clock() - t0 < DURATION do task.wait(0.05) end
				exiting = true
				if conn then conn:Disconnect() end
				setProgress(1)
				mainTxt.Text = "COMPLETE"
				tw(barGroup, 0.4, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
				tw(barPop, 0.4, { Scale = 1.06 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				tw(img, 0.6, { ImageTransparency = 1 }, Enum.EasingStyle.Quad)
				tw(photoSc, 0.7, { Scale = 1.08 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				task.wait(0.45)
				scan.Visible = false
				tw(back, 0.7, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
				G.S2R_EGG_FINDER_Loaded = true -- el panel se abre aqui
				task.wait(0.8)
				if music then pcall(function() music:Stop() music:Destroy() end) end
				gui:Destroy()
			end)
		end
		task.delay(DURATION + 4, function() pcall(unmuteAll) end) -- seguro
		task.delay(DURATION + 2, function() pcall(function() if music and music.Parent and done then music:Destroy() end end) end)
		task.delay(90, function() G.S2R_EGG_FINDER_LoadDone() end) -- seguro por si algo falla
		G.S2R_EGG_FINDER_Loader_Active = true
	end)
end

---------------------------------------------------------------------------
-- todo el panel va dentro de S2R_EGG_FINDER_MAIN: al cambiar de diseño / tema / letra
-- se vuelve a montar entero con el estilo nuevo (sin repetir la intro)
---------------------------------------------------------------------------
local function S2R_EGG_FINDER_MAIN()
pcall(function()
	local d = { design = "Liquid", theme = "Purple" } -- por defecto: diseño Liquid y tema Purple
	if isfile and readfile and isfile("S2R_EGG_FINDER_Design.json") then
		local ok, r = pcall(function() return game:GetService("HttpService"):JSONDecode(readfile("S2R_EGG_FINDER_Design.json")) end)
		if ok and type(r) == "table" then d = r end
        d.theme = "Purple"
	end
	getgenv().S2R_EGG_FINDER_Design = d
end)

local Library = (function()
---------------------------------------------------------------------------
-- S2R_EGG_FINDER UI v3  (escrita desde cero, blanco y negro)
-- Pestañas arriba, grupos en 2 columnas con filas, ajustes que se despliegan
-- debajo de cada funcion. Misma API: _new / create_category / create_tab /
-- create_group / create_toggle / create_slider / create_dropdown /
-- create_button / create_textbox / create_keybind / link / notify
---------------------------------------------------------------------------
local Lib = {}
-- ===== DISEÑOS, TEMAS DE COLOR y LETRAS (se eligen en Misc > Style y se guardan) =====
local DS = (getgenv and getgenv().S2R_EGG_FINDER_Design) or {}
local DESIGNS = {
	Liquid = { radius = 1, tabs = "bottom", title = "center", bg = "logo", box = "glass", btn = "glass", row = "card", glass = 0.82, w = 600, h = 410, footer = true, border = 1.4 },
	Classic = { radius = 0.5, tabs = "top", title = "left", bg = "gradient", box = "flat", btn = "solid", row = "flat", glass = 0.95, w = 600, h = 410, footer = true, border = 1 },
	Neon = { radius = 1.2, tabs = "bottom", title = "center", bg = "solid", box = "outline", btn = "outline", row = "outline", glass = 1, w = 600, h = 410, footer = true, border = 2 },
	Minimal = { radius = 0.6, tabs = "top", title = "left", bg = "solid", box = "flat", btn = "glass", row = "flat", glass = 0.96, w = 580, h = 400, footer = false, border = 1 },
	Bubble = { radius = 1.8, tabs = "bottom", title = "center", bg = "logo", box = "glass", btn = "solid", row = "card", glass = 0.85, w = 600, h = 420, footer = true, border = 1.6 },
	Sharp = { radius = 0.2, tabs = "top", title = "left", bg = "gradient", box = "outline", btn = "solid", row = "outline", glass = 0.97, w = 610, h = 410, footer = true, border = 1.2 },
	Compact = { radius = 0.8, tabs = "bottom", title = "left", bg = "gradient", box = "flat", btn = "glass", row = "flat", glass = 0.92, w = 540, h = 370, footer = false, border = 1 },
	Wide = { radius = 1, tabs = "top", title = "center", bg = "logo", box = "glass", btn = "glass", row = "card", glass = 0.85, w = 680, h = 430, footer = true, border = 1.4 },
	Frost = { radius = 1.3, tabs = "bottom", title = "center", bg = "logo", box = "glass", btn = "outline", row = "card", glass = 0.55, w = 600, h = 410, footer = true, border = 1.2 },
	Midnight = { radius = 0.9, tabs = "top", title = "center", bg = "solid", box = "flat", btn = "solid", row = "card", glass = 1, w = 600, h = 410, footer = true, border = 1 },
}
Lib.DESIGN_ORDER = { "Liquid", "Classic", "Neon", "Minimal", "Bubble", "Sharp", "Compact", "Wide", "Frost", "Midnight" }
local THEMES = {
	Red = { h = 0.985, s = 1 }, Blue = { h = 0.6, s = 1 }, Purple = { h = 0.755, s = 0.92 }, Green = { h = 0.38, s = 0.9 }, Gold = { h = 0.12, s = 0.95 },
	Pink = { h = 0.91, s = 0.85 }, Cyan = { h = 0.52, s = 0.95 }, Orange = { h = 0.06, s = 1 }, Ice = { h = 0.56, s = 0.35 }, Mono = { h = 0, s = 0 },
}
Lib.THEME_ORDER = { "Red", "Blue", "Purple", "Green", "Gold", "Pink", "Cyan", "Orange", "Ice", "Mono" }
local FONTS = {
	Code = "rbxasset://fonts/families/RobotoMono.json", Gotham = false, Fredoka = "rbxasset://fonts/families/FredokaOne.json",
	Ubuntu = "rbxasset://fonts/families/Ubuntu.json", Montserrat = "rbxasset://fonts/families/Montserrat.json", Nunito = "rbxasset://fonts/families/Nunito.json",
	Oswald = "rbxasset://fonts/families/Oswald.json", Arcade = "rbxasset://fonts/families/PressStart2P.json", SourceSans = "rbxasset://fonts/families/SourceSansPro.json",
	Comic = "rbxasset://fonts/families/ComicNeueAngular.json",
}
Lib.FONT_ORDER = { "Code", "Gotham", "Fredoka", "Ubuntu", "Montserrat", "Nunito", "Oswald", "Arcade", "SourceSans", "Comic" }
local D = DESIGNS[DS.design] or DESIGNS.Liquid
local TM = THEMES.Purple
local FONT_FAMILY = FONTS[DS.font]
if FONT_FAMILY == nil then FONT_FAMILY = FONTS.Code end
-- recolorea un color del tema rojo original al tema elegido (mismo brillo, otro tono)
local function TH(r, g, b)
	local _, s, v = Color3.fromRGB(r, g, b):ToHSV()
	return Color3.fromHSV(TM.h, math.clamp(s * TM.s, 0, 1), v)
end
pcall(function() getgenv().S2R_EGG_FINDER_TH = TH end)
-- color del tema con la saturacion y el brillo que se quiera (tonos suaves para el cristal)
local function TC(sat, val) return Color3.fromHSV(TM.h, math.clamp(sat * TM.s, 0, 1), val) end
local INK = Color3.fromRGB(8, 6, 15) -- negro azulado del fondo del cristal
Lib.design = D
local TABS_TOP = D.tabs == "top"
local TITLE_LEFT = D.title == "left"
local BOX_T = (D.box == "outline" and 0.72) or (D.box == "flat" and 0.18) or 0.42
local BOX_ST = (D.box == "outline" and 0.1) or 0.25
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local LOGO = "" -- No old-brand icon
local HUB_TITLE = tostring((getgenv and getgenv().SH_Title) or "S2R_EGG_FINDER")
pcall(function() getgenv().S2R_EGG_FINDER_LOGO = LOGO end)
local TOGGLE_KEY = Enum.KeyCode.RightShift
local W, H = D.w or 600, D.h or 410
local HEAD, TABS, FOOT = 46, 42, (D.footer == false and 0 or 26)
local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local K = {
	bg = TH(8, 4, 5),
	panel = TH(26, 10, 13),
	line = TH(96, 44, 50),
	line2 = TH(140, 64, 70),
	soft = Color3.fromRGB(242, 234, 235),
	mute = Color3.fromRGB(192, 162, 165),
	dark = TH(44, 18, 21),
	knobOff = Color3.fromRGB(125, 96, 99),
}
local F, FB, FK = Enum.Font.GothamMedium, Enum.Font.GothamBold, Enum.Font.GothamBlack
-- texto blanco que se apaga a negro en el borde derecho (solo seleccionado / activo)
local FADE = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.84, WHITE), ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 20)) })
-- luz que revela el texto de izquierda a derecha
local REVEAL = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(0.45, WHITE), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(16, 16, 18)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 18)) })

local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, math.floor(r * (D.radius or 1) + 0.5)) }) end
local function stroke(c, t, tr) return new("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
-- cristal liquido: degradado rojo oscuro -> negro translucido y borde blanco arriba -> rojo abajo
local function glassify(box, st)
	new("UIGradient", { Parent = box, Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, TC(0.45, 0.26)), ColorSequenceKeypoint.new(0.5, TC(0.3, 0.12)), ColorSequenceKeypoint.new(1, INK) }) })
	if st then
		new("UIGradient", { Parent = st, Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), TC(0.6, 0.95)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.78), NumberSequenceKeypoint.new(1, 0.45) }) })
	end
end
-- textura del boton JOIN: base oscura del tema, toque blanco en diagonal, reflejo y borde blanco -> color
local function joinGlass(b, st, z, soft, round, hot)
	-- liquid glass: humo oscuro con un tinte suave del tema, luz blanca en el borde de arriba,
	-- un toque del tema en el borde de abajo y un reflejo fino arriba
	b.BackgroundColor3 = WHITE
	local top = (hot and TC(0.72, 0.78)) or (soft and TC(0.4, 0.2)) or TC(0.5, 0.3)
	local bottom = (hot and TC(0.85, 0.3)) or INK
	new("UIGradient", { Parent = b, Rotation = 90, Color = ColorSequence.new(top, bottom) })
	if st then
		st.Color = WHITE
		st.Thickness = 1.2
		st.Transparency = 0
		new("UIGradient", { Parent = st, Rotation = 90, Color = ColorSequence.new(WHITE, TC(0.6, 0.95)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0.78), NumberSequenceKeypoint.new(1, 0.45) }) })
	end
	local function cr() return round and new("UICorner", { CornerRadius = UDim.new(1, 0) }) or corner(soft and 16 or 12) end
	local gl = new("Frame", { Parent = b, Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = z or 3 }, { cr() })
	new("UIGradient", { Parent = gl, Rotation = 90, Transparency = soft and NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.95), NumberSequenceKeypoint.new(1, 1) }) or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 1) }) })
	return nil, gl
end
-- estilo de cada caja segun el diseño: cristal (como el JOIN), plano o solo borde
local function styleBox(box, st)
	if D.box == "outline" then
		box.BackgroundColor3 = TH(10, 3, 5)
		if st then st.Color = TH(255, 62, 70) st.Thickness = 1.4 end
	elseif D.box == "flat" then
		box.BackgroundColor3 = TH(44, 16, 20)
		if st then st.Thickness = 0 end
	else
		-- cristal como el JOIN; el interior un poco transparente para que se vea el logo de fondo
		joinGlass(box, st, 1, true)
	end
end
local BTN_BASE = D.btn == "solid" and TH(150, 24, 34) or TH(52, 16, 20)
local BTN_T = (D.btn == "outline" and 1) or (D.btn == "solid" and 0) or 0.2
local function tween(o, t, props, style, dir, rep, rev)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out, rep or 0, rev or false), props)
	tw:Play()
	return tw
end
local function txt(parent, props)
	props.Parent = parent
	props.BackgroundTransparency = 1
	props.Font = props.Font or F
	props.TextColor3 = props.TextColor3 or WHITE
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return new("TextLabel", props)
end
-- flecha dibujada con dos rayitas (los simbolos de texto en algunas letras salen como un cuadrado)
-- side = false: v / ^ (desplegables)   side = true: > / v (ajustes que se despliegan)
local function drawChevron(parent, z, side)
	z = z or 4
	local hold = new("Frame", { Parent = parent, AnchorPoint = side and Vector2.new(0.5, 0.5) or Vector2.new(1, 0.5), Position = side and UDim2.fromScale(0.5, 0.5) or UDim2.new(1, -9, 0.5, 0), Size = UDim2.fromOffset(10, 10), BackgroundTransparency = 1, ZIndex = z })
	local function bar() return new("Frame", { Parent = hold, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(7, 2), BackgroundColor3 = K.mute, BorderSizePixel = 0, ZIndex = z + 1 }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) }) end
	local a, b = bar(), bar()
	local m = { frame = hold }
	function m.set(open, instant)
		local t = instant and 0 or 0.3
		local c = open and WHITE or K.mute
		if side then
			-- cerrado ">"   abierto "v"
			tween(a, t, { Position = open and UDim2.new(0.5, -2, 0.5, 0) or UDim2.new(0.5, 0, 0.5, -2), Rotation = 45, BackgroundColor3 = c })
			tween(b, t, { Position = open and UDim2.new(0.5, 2, 0.5, 0) or UDim2.new(0.5, 0, 0.5, 2), Rotation = -45, BackgroundColor3 = c })
		else
			-- cerrado "v"   abierto "^"
			tween(a, t, { Position = UDim2.new(0.5, -2, 0.5, 0), Rotation = open and -45 or 45, BackgroundColor3 = c })
			tween(b, t, { Position = UDim2.new(0.5, 2, 0.5, 0), Rotation = open and 45 or -45, BackgroundColor3 = c })
		end
	end
	m.set(false, true)
	return m
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
-- arrastre con un solo dedo: en movil cada dedo es un "input" distinto; solo se sigue el que empezo
local function sameDrag(startInput, i)
	if not startInput then return false end
	if startInput.UserInputType == Enum.UserInputType.Touch then return i == startInput end
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.MouseButton1
end
getgenv().S2R_EGG_FINDER_SameDrag = sameDrag
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end
local function safe(cb, ...)
	if type(cb) ~= "function" then return end
	local ok, err = pcall(cb, ...)
	if not ok then warn("[" .. HUB_TITLE .. "] callback error: " .. tostring(err)) end
end
local function smooth(frame)
	local s = { goal = frame.Position }
	RunService.Heartbeat:Connect(function(dt)
		local c, g = frame.Position, s.goal
		local dx, dy = g.X.Offset - c.X.Offset, g.Y.Offset - c.Y.Offset
		if math.abs(dx) < 0.05 and math.abs(dy) < 0.05 and c.X.Scale == g.X.Scale and c.Y.Scale == g.Y.Scale then
			if dx ~= 0 or dy ~= 0 then frame.Position = g end
			return
		end
		local a = 1 - math.exp(-dt * 20)
		frame.Position = UDim2.new(g.X.Scale, c.X.Offset + dx * a, g.Y.Scale, c.Y.Offset + dy * a)
	end)
	return s
end
local function guiParent()
	local ok, p = pcall(function() return gethui and gethui() end)
	if ok and p then return p end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then
		local t = Instance.new("Folder")
		local okp = pcall(function() t.Parent = cg end)
		t:Destroy()
		if okp then return cg end
	end
	return lp:WaitForChild("PlayerGui")
end

function Lib._new()
	local rt = { _flags = {}, _config = {} }
	local gui = new("ScreenGui", { Name = "S2R_EGG_FINDERPanel", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100 })
	pcall(function() gui.ScreenInsets = Enum.ScreenInsets.None end)
	-- si se vuelve a ejecutar: se quita el panel anterior (y sus bucles se paran solos)
	pcall(function()
		for _, par in ipairs({ guiParent(), lp:FindFirstChildOfClass("PlayerGui") }) do
			for _, nm in ipairs({ "S2R_EGG_FINDERPanel", "SourceHubPanel" }) do
				local o = par and par:FindFirstChild(nm)
				if o then o:Destroy() end
			end
		end
	end)
	gui.Parent = guiParent()
	-- letra tipo codigo en todo el panel (RobotoMono), manteniendo el grosor de cada texto
	do
		local MONO = FONT_FAMILY
		local WEIGHT = { [Enum.Font.Gotham] = Enum.FontWeight.Regular, [Enum.Font.GothamMedium] = Enum.FontWeight.Medium, [Enum.Font.GothamBold] = Enum.FontWeight.Bold, [Enum.Font.GothamBlack] = Enum.FontWeight.Bold }
		local function monoize(o)
			if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
				local w = WEIGHT[o.Font]
				if w then pcall(function() o.FontFace = Font.new(MONO, w) end) end
			end
		end
		pcall(function() getgenv().S2R_EGG_FINDER_Mono = monoize end)
		if MONO then gui.DescendantAdded:Connect(monoize) else pcall(function() getgenv().S2R_EGG_FINDER_Mono = nil end) end
	end

	-----------------------------------------------------------------------
	-- ventana
	-----------------------------------------------------------------------

	-----------------------------------------------------------------------
	-- sonidos estilo iPhone (generados, van dentro del script)
	-----------------------------------------------------------------------
	local SND = {}
	do
		local DATA = {
			tap = "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",
			toggle_on = "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",
			toggle_off = "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",
			open = "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",
			close = "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",
		}
		local VOL = { tap = 0.45, toggle_on = 0.55, toggle_off = 0.5, open = 0.55, close = 0.5 }
		local function b64dec(str)
			local native
			pcall(function() native = (crypt and (crypt.base64decode or (crypt.base64 and crypt.base64.decode))) or base64_decode end)
			if native then
				local ok, r = pcall(native, str)
				if ok and type(r) == "string" and #r > 0 then return r end
			end
			local map, chars = {}, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
			for i = 1, 64 do map[chars:byte(i)] = i - 1 end
			local out, n = {}, 0
			for i = 1, #str, 4 do
				local a, b, c, d = str:byte(i, i + 3)
				a, b = map[a], map[b]
				c = c and map[c]
				d = d and map[d]
				if not a or not b then break end
				local v = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
				n += 1 out[n] = string.char(math.floor(v / 65536) % 256)
				if c then n += 1 out[n] = string.char(math.floor(v / 256) % 256) end
				if d then n += 1 out[n] = string.char(v % 256) end
			end
			return table.concat(out)
		end
		task.spawn(function()
			pcall(function()
				local custom = getcustomasset or getsynasset
				if not (custom and writefile and isfile) then return end
				pcall(function() if makefolder and isfolder and not isfolder("S2R_EGG_FINDER") then makefolder("S2R_EGG_FINDER") end end)
				for name, data in pairs(DATA) do
					pcall(function()
						local path = "S2R_EGG_FINDER/snd_" .. name .. "_v1.ogg"
						if not isfile(path) then writefile(path, b64dec(data)) end
						pcall(function() local old = game:GetService("SoundService"):FindFirstChild("S2R_EGG_FINDER_" .. name) if old then old:Destroy() end end)
						local sd = Instance.new("Sound")
						sd.Name = "S2R_EGG_FINDER_" .. name
						sd.SoundId = custom(path)
						sd.Volume = VOL[name] or 0.5
						sd.Parent = game:GetService("SoundService")
						SND[name] = sd
					end)
				end
			end)
		end)
	end
	local function sfx(name)
		local sd = SND[name]
		if not sd or rt._mute then return end
		pcall(function() game:GetService("SoundService"):PlayLocalSound(sd) end)
	end
	local root = new("Frame", { Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), BackgroundTransparency = 1, Visible = false })
	local fit = new("UIScale", { Parent = root })
	local userScale = 1
	local function refit()
		local v = gui.AbsoluteSize
		local big = math.clamp(math.min(v.X / 1280, v.Y / 820), 1, 1.75)
		if UIS.TouchEnabled and not UIS.MouseEnabled then
			-- movil: mas pequeño para que se vea el juego
			fit.Scale = math.max(0.4, math.min(0.8, (v.X - 40) / W, (v.Y * 0.74) / H))
		else
			fit.Scale = math.max(0.45, math.min(big, (v.X - 24) / W, (v.Y - 24) / H))
		end
		fit.Scale = math.clamp(fit.Scale * userScale, 0.25, 3)
	end
	function rt:set_user_scale(x) userScale = math.clamp(tonumber(x) or 1, 0.4, 1.6) refit() end
	function rt:get_user_scale() return userScale end
	function rt:get_scale() return fit.Scale end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
	refit()
	local win = new("CanvasGroup", { Parent = root, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = K.bg, BackgroundTransparency = 1 - (D.glass or 0.82), GroupTransparency = 1 }, { corner(20) })
	local winStroke = stroke(WHITE, D.border or 1.4, 0.05)
	winStroke.Parent = win
	-- borde de cristal: blanco arriba, rojo abajo
	new("UIGradient", { Parent = winStroke, Rotation = 90, Color = ColorSequence.new(WHITE, TH(255, 62, 70)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0.2) }) })
	local pop = new("UIScale", { Parent = win, Scale = 0.96 })
	-- mascara para que la ventana se "despliegue" de arriba a abajo como una hoja (y se pliegue al cerrar)
	local sheetGrad = new("UIGradient", { Parent = win, Rotation = 90, Enabled = false, Offset = Vector2.new(0, 0.6), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1) }) })
	-- fondo con imagen (se mueve muy lento) + capa oscura para que se lea todo
	local bgHold = new("Frame", { Parent = win, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 0 })
	local bgImg = new("ImageLabel", { Parent = bgHold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ImageTransparency = 1, ScaleType = Enum.ScaleType.Crop, ZIndex = 0 })
	local bgSc = new("UIScale", { Parent = bgImg })
	local bgShade = new("Frame", { Parent = bgHold, Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH(22, 2, 6), BackgroundTransparency = 0.48, BorderSizePixel = 0, ZIndex = 0 })
	new("UIGradient", { Parent = bgShade, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.22, 0.35), NumberSequenceKeypoint.new(0.75, 0.45), NumberSequenceKeypoint.new(1, 0.05) }) })
	-- tu foto del panel va DENTRO del script (no depende de descargas): se guarda una vez y se carga
	-- Clean black panel: original branded image and remote background removed.
	bgImg.Visible = false
	bgImg.Image = ""
	bgImg.ImageTransparency = 1
	bgShade.BackgroundColor3 = Color3.fromRGB(8, 6, 15)
	bgShade.BackgroundTransparency = 0.06
	rt._logoOff = true
	-- decoracion liquid: manchas de luz del tema que flotan muy despacio detras de todo
	if D.bg ~= "solid" then
		for i, bl in ipairs({ { 0.12, 0.2, 280, 0.8 }, { 0.88, 0.78, 320, 0.84 }, { 0.6, 0.02, 220, 0.86 } }) do
			local blob = new("Frame", { Parent = win, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(bl[1], bl[2]), Size = UDim2.fromOffset(bl[3], bl[3]), BackgroundColor3 = TC(0.75, 0.85), BackgroundTransparency = bl[4], BorderSizePixel = 0, ZIndex = 0 }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
			new("UIGradient", { Parent = blob, Rotation = 45 + i * 60, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.55, 0.7), NumberSequenceKeypoint.new(1, 1) }) })
			pcall(function()
				TweenService:Create(blob, TweenInfo.new(7 + i * 2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.fromScale(bl[1] + (i % 2 == 0 and -0.14 or 0.14), bl[2] + 0.16) }):Play()
			end)
		end
	end
	if D.bg ~= "logo" then
		rt._logoOff = true
		bgImg.ImageTransparency = 1
		if D.bg == "solid" then
			bgShade.BackgroundColor3 = K.bg
			bgShade.BackgroundTransparency = 0.02
		end
	end

	-- fondo negro para la cabecera y las pestañas
	-- reflejo de cristal arriba
	local spec = new("Frame", { Parent = win, Size = UDim2.new(1, 0, 0.45, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 0 })
	new("UIGradient", { Parent = spec, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.84), NumberSequenceKeypoint.new(1, 1) }) })
	local topShade = new("Frame", { Parent = win, Size = UDim2.new(1, 0, 0, HEAD + 2), BackgroundColor3 = TH(10, 3, 5), BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 1 })
	new("UIGradient", { Parent = topShade, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.15) }) })
	-- cabecera
	local head = new("Frame", { Parent = win, Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, ZIndex = 2 })
	local headL = new("Frame", { Parent = head, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -110, 1, 0), BackgroundTransparency = 1, ZIndex = 2 })
	new("UIListLayout", { Parent = headL, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder })
	local logoHold = new("Frame", { Parent = headL, LayoutOrder = 1, Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1, ZIndex = 3, Visible = false }) -- (sin logo dentro del panel)
	local logoImg = new("ImageLabel", { Parent = logoHold, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Image = LOGO, ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
	local logoSc = new("UIScale", { Parent = logoImg })
	-- S2R_EGG_FINDER en el centro de la cabecera, con brillo suave detras y luz que lo recorre
	-- letra de pincel (lo mas parecido a la de la intro que trae Roblox), inclinada como la intro
	local BRUSH = nil
	pcall(function() BRUSH = Font.new("rbxasset://fonts/families/Kalam.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal) end)
	local titleGlow = txt(head, { AnchorPoint = TITLE_LEFT and Vector2.new(0, 0.5) or Vector2.new(0.5, 0.5), Position = UDim2.new(TITLE_LEFT and 0 or 0.5, TITLE_LEFT and 16 or 0, 0.5, 2), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, Text = HUB_TITLE, Font = Enum.Font.Kalam, TextSize = 30, TextColor3 = TH(255, 62, 70), TextTransparency = 0.7, TextXAlignment = Enum.TextXAlignment.Center, Rotation = -7, ZIndex = 3 })
	new("UIStroke", { Parent = titleGlow, Color = TH(255, 62, 70), Thickness = 5, Transparency = 0.82 })
	titleGlow.TextTransparency = 0.85 -- (brillo fijo, sin pulso)
	local headTitle = txt(head, { AnchorPoint = TITLE_LEFT and Vector2.new(0, 0.5) or Vector2.new(0.5, 0.5), Position = UDim2.new(TITLE_LEFT and 0 or 0.5, TITLE_LEFT and 16 or 0, 0.5, 2), Size = UDim2.fromOffset(0, 34), AutomaticSize = Enum.AutomaticSize.X, Text = HUB_TITLE, Font = Enum.Font.Kalam, TextSize = 30, TextColor3 = Color3.fromRGB(245, 245, 248), TextXAlignment = Enum.TextXAlignment.Center, Rotation = -7, ZIndex = 4 })
	new("UIStroke", { Parent = headTitle, Color = TH(110, 0, 6), Thickness = 1, Transparency = 0.4 })
	if BRUSH then pcall(function() headTitle.FontFace = BRUSH titleGlow.FontFace = BRUSH end) end
	local headGrad = new("UIGradient", { Parent = headTitle, Color = REVEAL, Offset = Vector2.new(1, 0) })
	-- cada pocos segundos una luz roja recorre el nombre S2R_EGG_FINDER
	local NEON = TH(255, 50, 56)
	local SHIMMER = ColorSequence.new({ ColorSequenceKeypoint.new(0, NEON), ColorSequenceKeypoint.new(0.4, NEON), ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(0.6, NEON), ColorSequenceKeypoint.new(1, NEON) })
	local TITLE_REVEAL = ColorSequence.new({ ColorSequenceKeypoint.new(0, NEON), ColorSequenceKeypoint.new(0.45, NEON), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(16, 16, 18)), ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 18)) })
	headGrad.Color = TITLE_REVEAL
	task.spawn(function()
		task.wait(2)
		while headTitle.Parent do
			headGrad.Color = SHIMMER
			headGrad.Offset = Vector2.new(-1, 0)
			tween(headGrad, 1.1, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(3.6)
		end
	end)
	-- S2R_EGG_FINDER en foto (la del usuario): si carga, sustituye al texto; si no, se queda el texto
	local TITLE_URL = nil -- Text title only; prevents displaying the old branded artwork
	local titleImgGlow = new("ImageLabel", { Parent = head, AnchorPoint = TITLE_LEFT and Vector2.new(0, 0.5) or Vector2.new(0.5, 0.5), Position = UDim2.new(TITLE_LEFT and 0 or 0.5, TITLE_LEFT and 16 or 0, 0.5, 4), Size = UDim2.fromOffset(290, 50), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, ImageColor3 = TH(255, 62, 70), ImageTransparency = 0.86, Visible = false, ZIndex = 3 })
	local titleImg = new("ImageLabel", { Parent = head, AnchorPoint = TITLE_LEFT and Vector2.new(0, 0.5) or Vector2.new(0.5, 0.5), Position = UDim2.new(TITLE_LEFT and 0 or 0.5, TITLE_LEFT and 16 or 0, 0.5, 4), Size = UDim2.fromOffset(270, 44), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, Visible = false, ZIndex = 4 })
	-- aparece de izquierda a derecha al abrir el panel
	local titleImgGrad = new("UIGradient", { Parent = titleImg, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) }), Offset = Vector2.new(1, 0) })
	local titleIsImage = false
	local titleCanSquash = false
	local function revealTitleImg()
		if not titleIsImage then return end
		titleImgGrad.Offset = Vector2.new(-1, 0)
		tween(titleImgGrad, 0.9, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	end
	-- el logo se carga y, si falla, se vuelve a intentar unas cuantas veces (mientras tanto sale "S2R_EGG_FINDER" escrito)
	local function loadTitle(attempt)
		if not getgenv().S2R_EGG_FINDER_UrlImage or not TITLE_URL or titleIsImage or not head.Parent then return end
		getgenv().S2R_EGG_FINDER_UrlImage(TITLE_URL, titleImg, function(c)
			titleImg.Image = c
			titleImgGlow.Image = c
			-- tamaño segun la foto: si es alargada (recortada al texto) va ajustada a la cabecera;
			-- si es mas cuadrada (con margen alrededor) se amplia para que S2R_EGG_FINDER se vea grande
			pcall(function()
				local d = readfile("S2R_EGG_FINDER/" .. (TITLE_URL:match("([%w_%-]+%.%w+)$")))
				if type(d) == "string" and d:sub(1, 4) == "\137PNG" then
					local w = string.unpack(">I4", d, 17)
					local h = string.unpack(">I4", d, 21)
					if w > 0 and h > 0 then
						local aspect = w / h
						local maxW = aspect >= 2.4 and 260 or 300
						local tH = aspect >= 2.4 and 36 or 46
						local tW = math.min(tH * aspect, maxW)
						-- caja con la misma proporcion que la foto: asi se puede "aplastar" como una tele
						titleImg.Size = UDim2.fromOffset(tW, tW / aspect)
						titleImg.ScaleType = Enum.ScaleType.Stretch
						titleImgGlow.ScaleType = Enum.ScaleType.Stretch
						titleImgGlow.Size = UDim2.fromOffset(tW + 10, tW / aspect + 4)
						titleCanSquash = true
					end
				end
			end)
			titleImg.Visible = true
			titleImgGlow.Visible = true
			headTitle.Visible = false
			titleGlow.Visible = false
			titleIsImage = true
			revealTitleImg()
		end, function()
			titleIsImage = false
			titleImg.Visible = false
			titleImgGlow.Visible = false
			headTitle.Visible = true
			titleGlow.Visible = true
			if attempt < 6 then task.delay(2 + attempt, function() pcall(loadTitle, attempt + 1) end) end
		end)
	end
	pcall(loadTitle, 1)
	-- glitch del logo cada 3 segundos: se separa en dos colores, tiembla un instante y queda un brillo suave
	do
		local rnd = Random.new()
		local busy = false
		local ghosts = {}
		local function getGhosts()
			if #ghosts > 0 then return ghosts end
			for _, c in ipairs({ Color3.fromRGB(255, 50, 80), Color3.fromRGB(70, 210, 255) }) do
				local g = titleImg:Clone()
				for _, ch in ipairs(g:GetChildren()) do ch:Destroy() end
				g.ImageColor3 = c
				g.ImageTransparency = 1
				g.ZIndex = 3
				g.Parent = head
				ghosts[#ghosts + 1] = g
			end
			return ghosts
		end
		local function glitch()
			if busy then return end
			busy = true
			pcall(function()
				if titleIsImage and titleImg.Visible then
					local base = titleImg.Position
					local gs = getGhosts()
					for _, g in ipairs(gs) do
						g.Image = titleImg.Image
						g.Size = titleImg.Size
						g.AnchorPoint = titleImg.AnchorPoint
						g.ScaleType = titleImg.ScaleType
					end
					for _ = 1, rnd:NextInteger(3, 5) do
						local dx = rnd:NextInteger(2, 5)
						gs[1].Position = base + UDim2.fromOffset(-dx, rnd:NextInteger(-1, 1))
						gs[2].Position = base + UDim2.fromOffset(dx, rnd:NextInteger(-1, 1))
						gs[1].ImageTransparency, gs[2].ImageTransparency = 0.4, 0.45
						titleImg.Position = base + UDim2.fromOffset(rnd:NextInteger(-2, 2), 0)
						titleImg.ImageTransparency = rnd:NextNumber(0, 0.2)
						task.wait(rnd:NextNumber(0.03, 0.05))
						gs[1].ImageTransparency, gs[2].ImageTransparency = 1, 1
						titleImg.Position = base
						titleImg.ImageTransparency = 0
						task.wait(rnd:NextNumber(0.03, 0.07))
					end
					titleImgGlow.ImageTransparency = 0.5
					tween(titleImgGlow, 0.9, { ImageTransparency = 0.86 }, Enum.EasingStyle.Quad)
				elseif headTitle.Visible then
					local base = headTitle.Position
					for _ = 1, 3 do
						headTitle.Position = base + UDim2.fromOffset(rnd:NextInteger(-3, 3), 0)
						headTitle.TextTransparency = rnd:NextNumber(0, 0.35)
						task.wait(0.04)
						headTitle.Position = base
						headTitle.TextTransparency = 0
						task.wait(0.05)
					end
				end
			end)
			busy = false
		end
		task.spawn(function()
			task.wait(3)
			while head.Parent do
				task.wait(3)
				if root.Visible then glitch() end
			end
		end)
	end
	-- agarre para mover la ventana (arriba en el centro)
	local grip = new("Frame", { Parent = root, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 10), Size = UDim2.fromOffset(64, 5), BackgroundColor3 = WHITE, BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 5 }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	-- botones de arriba a la derecha: dos burbujas de cristal (la textura del JOIN) con iconos dibujados
	--   –  = minimizar (se guarda en el logo)     X = cerrar S2R_EGG_FINDER del todo
	local ctrl = new("Frame", { Parent = head, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(66, 30), BackgroundTransparency = 1, ZIndex = 3 })
	local function headBtn(x, kind)
		local b = new("TextButton", { Parent = ctrl, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, x, 0.5, 0), Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 0.45, AutoButtonColor = false, Text = "", ZIndex = 4 }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		local bs = stroke(WHITE, 1.2, 0.2)
		bs.Parent = b
		joinGlass(b, bs, 4, false, true)
		local base = b.BackgroundColor3
		local bars = {}
		local function bar(rot)
			bars[#bars + 1] = new("Frame", { Parent = b, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(11, 2), BackgroundColor3 = WHITE, BorderSizePixel = 0, Rotation = rot, ZIndex = 6 }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		end
		if kind == "close" then bar(45) bar(-45) else bar(0) end
		local hot = kind == "close" and Color3.fromRGB(220, 40, 52) or TH(130, 24, 32)
		local bSc = new("UIScale", { Parent = b })
		local function lit(on)
			tween(b, 0.25, { BackgroundColor3 = on and hot or base, BackgroundTransparency = on and 0.15 or 0.45 }, Enum.EasingStyle.Quint)
			for _, f in ipairs(bars) do tween(f, 0.3, { Size = UDim2.fromOffset(on and 13 or 11, 2) }, Enum.EasingStyle.Back) end
		end
		b.MouseEnter:Connect(function() lit(true) tween(bSc, 0.3, { Scale = 1.08 }, Enum.EasingStyle.Back) end)
		b.MouseLeave:Connect(function() lit(false) tween(bSc, 0.3, { Scale = 1 }, Enum.EasingStyle.Quint) end)
		b.InputBegan:Connect(function(i) if isPress(i) then lit(true) tween(bSc, 0.12, { Scale = 0.85 }, Enum.EasingStyle.Quad) end end)
		b.InputEnded:Connect(function(i) if isPress(i) then tween(bSc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back) task.delay(0.25, function() lit(false) end) end end)
		return b
	end
	local closeBtn = headBtn(50, "close")
	local minBtn = headBtn(16, "min")
	-- (sin linea bajo la cabecera)
	-- linea roja fina con un brillo que la recorre de vez en cuando
	local accent = new("Frame", { Parent = win, Position = UDim2.fromOffset(0, HEAD), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = TC(0.6, 1), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 3, Visible = not TABS_TOP })
	local accentGrad = new("UIGradient", { Parent = accent, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 1) }) })
	task.spawn(function()
		while gui.Parent do
			accentGrad.Offset = Vector2.new(-1, 0)
			tween(accentGrad, 1.6, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(4)
		end
	end)

	-- barra de pestañas
	-- pestañas repartidas a lo ancho y centradas (todas del mismo tamaño)
	-- cristal liquido que se pone encima de la pestaña elegida (por debajo del texto)
	local glassLayer = new("Frame", { Parent = win, Position = TABS_TOP and UDim2.fromOffset(0, HEAD + 1) or UDim2.new(0, 0, 1, -(FOOT + TABS)), Size = UDim2.new(1, 0, 0, TABS), BackgroundTransparency = 1, ZIndex = 2 })
	local glassShadow = new("Frame", { Parent = glassLayer, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-300, TABS / 2 + 3), Size = UDim2.fromOffset(100, 30), BackgroundColor3 = BLACK, BackgroundTransparency = 0.72, BorderSizePixel = 0, ZIndex = 2 }, { corner(15) })
	-- gota de cristal: base translucida con toque rojo, reflejo arriba y borde blanco -> rojo (sin linea blanca)
	local glass = new("Frame", { Parent = glassLayer, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(-300, TABS / 2), Size = UDim2.fromOffset(100, 30), BackgroundColor3 = WHITE, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 3 }, { corner(15) })
	local glassSt = new("UIStroke", { Parent = glass, Color = WHITE, Thickness = 1.2, Transparency = 0.2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	new("UIGradient", { Parent = glassSt, Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(1, TH(255, 62, 70)) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 0.3) }) })
	new("UIGradient", { Parent = glass, Rotation = 90, Color = ColorSequence.new(TC(0.65, 0.62), TC(0.8, 0.2)) })
	local glassTint = new("Frame", { Parent = glass, Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH(255, 62, 70), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, { corner(15) })
	new("UIGradient", { Parent = glassTint, Rotation = 20, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(0.6, 0.9), NumberSequenceKeypoint.new(1, 0.95) }) })
	local glassGloss = new("Frame", { Parent = glass, Size = UDim2.new(1, 0, 0.5, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, { corner(15) })
	new("UIGradient", { Parent = glassGloss, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(1, 1) }) })
	local glassSc = new("UIScale", { Parent = glass })
	local tabBar = new("Frame", { Parent = win, Position = TABS_TOP and UDim2.fromOffset(0, HEAD + 1) or UDim2.new(0, 0, 1, -(FOOT + TABS)), Size = UDim2.new(1, 0, 0, TABS), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 4 })
	new("UIListLayout", { Parent = tabBar, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	new("UIPadding", { Parent = tabBar, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	-- separacion suave (degradado) entre pestañas y contenido, sin linea dura
	-- dock de abajo para las pestañas
	local dock = new("Frame", { Parent = win, Position = TABS_TOP and UDim2.fromOffset(8, HEAD + 4) or UDim2.new(0, 8, 1, -(FOOT + TABS) + 3), Size = UDim2.new(1, -16, 0, TABS - 6), BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 1 }, { corner(18) })
	do
		local ds = stroke(WHITE, 1, 0.35)
		ds.Parent = dock
		new("UIGradient", { Parent = ds, Rotation = 90, Color = ColorSequence.new(WHITE, TH(255, 62, 70)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 0.5) }) })
		new("UIGradient", { Parent = dock, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.85) }) })
	end
	local sep = new("Frame", { Parent = win, Position = UDim2.new(0, 0, 1, -(FOOT + TABS + 1)), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 2, Visible = false })
	new("UIGradient", { Parent = sep, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })

	-- zona de contenido
	local TOP = HEAD + 2 + (TABS_TOP and TABS + 2 or 0)
	local body = new("Frame", { Parent = win, Position = UDim2.fromOffset(0, TOP), Size = UDim2.new(1, 0, 1, -(TOP + FOOT + (TABS_TOP and 2 or TABS + 1))), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1 })

	-- pie
	local foot = new("Frame", { Parent = win, Visible = D.footer ~= false, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, FOOT), BackgroundTransparency = 1, ZIndex = 2 })
	-- fondo de cristal oscuro con linea de luz arriba (blanca en el centro, roja en los lados)
	-- pie negro
	local footBg = new("Frame", { Parent = foot, Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH(8, 3, 4), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 2 })
	local footLine = new("Frame", { Parent = foot, Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 })
	new("UIGradient", { Parent = footLine, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 1) }) })
	-- avatar redondo con aro rojo
	local av = new("ImageLabel", { Parent = foot, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = K.dark, Image = "", ZIndex = 4 }, { corner(9) })
	local avSt = new("UIStroke", { Parent = av, Color = WHITE, Thickness = 1.4, Transparency = 0 })
	avSt.Transparency = 0.5
	pcall(function() av.Image = Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end)
	txt(foot, { Position = UDim2.fromOffset(36, 0), Size = UDim2.new(0.6, 0, 1, 0), Text = "<b>" .. tostring(lp.DisplayName) .. "</b>  <font color=\"#8a8088\">@" .. tostring(lp.Name) .. "</font>", RichText = true, Font = FB, TextSize = 11, TextColor3 = WHITE, ZIndex = 4, TextTruncate = Enum.TextTruncate.AtEnd })
	-- a la derecha: pastilla de cristal con FPS y ping en vivo
	local stats = new("Frame", { Parent = foot, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(112, 18), BackgroundColor3 = WHITE, BackgroundTransparency = 0.93, BorderSizePixel = 0, ZIndex = 3 }, { corner(9) })
	new("UIStroke", { Parent = stats, Color = WHITE, Transparency = 0.8, Thickness = 1 })
	new("Frame", { Parent = stats, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4 }, { corner(3) })
	local statsTxt = txt(stats, { Position = UDim2.fromOffset(18, 0), Size = UDim2.new(1, -24, 1, 0), Text = "-- FPS  ·  -- ms", Font = FB, TextSize = 9, TextColor3 = Color3.fromRGB(220, 210, 212), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
	task.spawn(function()
		local frames, last = 0, os.clock()
		local hb = game:GetService("RunService").Heartbeat:Connect(function() frames += 1 end)
		while gui.Parent do
			task.wait(1)
			local now = os.clock()
			local fps = math.floor(frames / math.max(now - last, 0.001) + 0.5)
			frames, last = 0, now
			local ping = 0
			pcall(function() ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5) end)
			statsTxt.Text = fps .. " FPS  ·  " .. ping .. " ms"
		end
		hb:Disconnect()
	end)

	-----------------------------------------------------------------------
	-- notificaciones (abajo a la derecha)
	-----------------------------------------------------------------------
	local toastBox = new("Frame", { Parent = gui, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(250, 400), BackgroundTransparency = 1, ZIndex = 300 })
	new("UIListLayout", { Parent = toastBox, VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
	local toastN = 0
	local function notify(title, text, dur)
		dur = tonumber(dur) or 3
		toastN += 1
		local holder = new("Frame", { Parent = toastBox, LayoutOrder = toastN, Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, ZIndex = 300 })
		local t = new("CanvasGroup", { Parent = holder, Position = UDim2.fromOffset(40, 0), Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, GroupTransparency = 1, ZIndex = 300 }, { corner(6), stroke(K.line2, 1, 0) })
		new("Frame", { Parent = t, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 2, 1, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 301 })
		txt(t, { Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -24, 0, 15), Text = tostring(title or HUB_TITLE), Font = FB, TextSize = 12, ZIndex = 301 })
		txt(t, { Position = UDim2.fromOffset(14, 25), Size = UDim2.new(1, -24, 0, 14), Text = tostring(text or ""), Font = F, TextSize = 10, TextColor3 = K.mute, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 301 })
		local prog = new("Frame", { Parent = t, Visible = false, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 302 })
		tween(t, 0.45, { Position = UDim2.fromOffset(0, 0) })
		tween(t, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
		tween(prog, dur, { Size = UDim2.new(0, 0, 0, 1) }, Enum.EasingStyle.Linear)
		task.delay(dur, function()
			tween(t, 0.3, { Position = UDim2.fromOffset(40, 0), GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.32, function()
				tween(holder, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
				task.delay(0.27, function() holder:Destroy() end)
			end)
		end)
	end

	-----------------------------------------------------------------------
	-- teclas
	-----------------------------------------------------------------------
	local binds, capturing = {}, nil
	local myGen = (getgenv().S2R_EGG_FINDER_Gen or 0) + 1
	getgenv().S2R_EGG_FINDER_Gen = myGen
	UIS.InputBegan:Connect(function(i, gp)
		if getgenv().S2R_EGG_FINDER_Gen ~= myGen then return end
		if capturing then
			if i.UserInputType == Enum.UserInputType.Keyboard then
				local cb = capturing
				capturing = nil
				cb(i.KeyCode)
			end
			return
		end
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		-- RightShift abre/cierra aunque el juego la use (Shift Lock); no si estas escribiendo
		if i.KeyCode == TOGGLE_KEY then
			local typing = false
			pcall(function() typing = UIS:GetFocusedTextBox() ~= nil end)
			if not typing then rt._toggleWindow() end
			return
		end
		if gp then return end
		for _, b in ipairs(binds) do if b.key == i.KeyCode then b.fn() end end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		for _, b in ipairs(binds) do if b.release and b.key == i.KeyCode then b.release() end end
	end)

	-----------------------------------------------------------------------
	-- pestañas y paginas
	-----------------------------------------------------------------------
	local pages, tabs, tabList, currentTab = {}, {}, {}, nil
	local allScrolls = {}
	local openDrops = {}
	local function closeDrops(except)
		for d in pairs(openDrops) do if d ~= except then d(false) end end
	end
	local function lockScroll(v) for _, s in ipairs(allScrolls) do s.ScrollingEnabled = not v end end

	local function popGroups(p)
		for i, g in ipairs(p.groups) do
			g.sc.Scale = 0.95
			g.st.Transparency = 1
			g.box.BackgroundTransparency = 1
			task.delay(math.min(i - 1, 10) * 0.05, function()
				tween(g.sc, 0.55, { Scale = 1 }, Enum.EasingStyle.Quint)
				tween(g.st, 0.5, { Transparency = BOX_ST }, Enum.EasingStyle.Quad)
				tween(g.box, 0.5, { BackgroundTransparency = BOX_T }, Enum.EasingStyle.Quad)
			end)
		end
	end

	-- posicion de cada pestaña (todas iguales, repartidas a lo ancho)
	local glassDragging, glassInput, glassStartX, glassMoved = false, nil, 0, false
	local function tabGeom(i)
		local n = math.max(#tabList, 1)
		local tw = (W - 20) / n - 6 + 6 / n
		return 10 + (i - 1) * (tw + 6) + tw / 2, tw
	end
	-- ancho del cristal = lo que ocupa el icono + el nombre de esa pestaña (ajustado a cada texto)
	local TextService = game:GetService("TextService")
	local function glassW(i)
		local t = tabList[i]
		if not t then local _, tw = tabGeom(i) return tw end
		if not t.cw then
			local tw = #t.name * 8
			pcall(function() tw = TextService:GetTextSize(t.name, 13, FB, Vector2.new(1000, 100)).X end)
			t.cw = ((t.icon and 20 or 0) + tw) * 1.12 + 30
		end
		local _, maxW = tabGeom(i)
		return math.min(t.cw, maxW)
	end
	local function placeGlass(cx, gw, instant)
		local pos, size = UDim2.fromOffset(cx, TABS / 2), UDim2.fromOffset(gw, 30)
		local spos = UDim2.fromOffset(cx, TABS / 2 + 3)
		if instant then
			glass.Position, glass.Size, glassShadow.Position, glassShadow.Size = pos, size, spos, size
		else
			-- se desliza suave hasta la pestaña y cambia de ancho a la vez (sin estirones ni rebotes)
			tween(glass, 0.45, { Position = pos, Size = size }, Enum.EasingStyle.Quint)
			tween(glassShadow, 0.5, { Position = spos, Size = size }, Enum.EasingStyle.Quint)
		end
	end
	local function moveGlass(i, instant)
		local cx = tabGeom(i)
		placeGlass(cx, glassW(i), instant)
	end
	local selectTab -- (se define justo debajo; el arrastre la necesita)
	local glassLastPos = Vector2.new()
	-- mueve el cristal al punto X de la pantalla y cambia de seccion al pasar por cada pestaña
	local function dragTo(px)
		local k = glassLayer.AbsoluteSize.X / W
		if k <= 0.01 then return end
		local lx = (px - glassLayer.AbsolutePosition.X) / k
		local n = math.max(#tabList, 1)
		local _, tw = tabGeom(1)
		lx = math.clamp(lx, 10 + tw / 2, W - 10 - tw / 2)
		-- el cristal sigue al dedo; su ancho es el de la pestaña que tiene debajo
		local idxNow = math.clamp(math.floor((lx - 10) / (tw + 6)) + 1, 1, n)
		local sz = UDim2.fromOffset(glassW(idxNow), 30)
		tween(glass, 0.18, { Position = UDim2.fromOffset(lx, TABS / 2), Size = sz }, Enum.EasingStyle.Quint)
		tween(glassShadow, 0.2, { Position = UDim2.fromOffset(lx, TABS / 2 + 3), Size = sz }, Enum.EasingStyle.Quint)
		local idx = math.clamp(math.floor((lx - 10) / (tw + 6)) + 1, 1, n)
		local t = tabList[idx]
		if t and currentTab ~= t.name and selectTab then
			sfx("tap")
			selectTab(t.name)
		end
	end
	local function dragMove(pos)
		if not glassDragging then return end
		-- solo el dedo que empezo en las pestañas (se reconoce por estar cerca de donde iba)
		if (pos - glassLastPos).Magnitude > 160 then return end
		glassLastPos = pos
		if not glassMoved then
			if math.abs(pos.X - glassStartX) < 8 then return end
			glassMoved = true
			-- al cogerlo con el dedo solo brilla un poco mas el borde (sin hincharse)
			tween(glassSt, 0.25, { Transparency = 0 }, Enum.EasingStyle.Quad)
		end
		dragTo(pos.X)
	end
	local function dragEnd(pos)
		if not glassDragging then return end
		if pos and (pos - glassLastPos).Magnitude > 160 then return end -- era otro dedo (joystick)
		glassDragging = false
		glassInput = nil
		tween(glassSt, 0.35, { Transparency = 0.2 }, Enum.EasingStyle.Quad)
		if currentTab and tabs[currentTab] then moveGlass(tabs[currentTab].idx) end
	end
	-- movil: aviso de dedo moviendose / levantado
	UIS.TouchMoved:Connect(function(touch) dragMove(Vector2.new(touch.Position.X, touch.Position.Y)) end)
	UIS.TouchEnded:Connect(function(touch) dragEnd(Vector2.new(touch.Position.X, touch.Position.Y)) end)
	-- PC: raton
	UIS.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement and glassInput and glassInput.UserInputType == Enum.UserInputType.MouseButton1 then
			dragMove(Vector2.new(i.Position.X, i.Position.Y))
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and glassInput and glassInput.UserInputType == Enum.UserInputType.MouseButton1 then
			dragEnd(nil)
		end
	end)
	function selectTab(name, silent)
		if currentTab == name then return end
		if tabs[name] and not glassDragging then moveGlass(tabs[name].idx, silent) end
		local prev = currentTab and tabs[currentTab]
		currentTab = name
		closeDrops()
		local dir = 1
		if prev and tabs[name] and tabs[name].idx < prev.idx then dir = -1 end
		for n, t in pairs(tabs) do
			local on = n == name
			t.sel = on
			tween(t.label, 0.3, { TextColor3 = on and WHITE or K.mute, TextStrokeTransparency = 1, TextTransparency = on and 0 or 0.2 })
			if t.isc then tween(t.isc, on and 0.5 or 0.35, { Scale = on and 1.12 or 0.84 }, on and Enum.EasingStyle.Back or Enum.EasingStyle.Quint) end
			if t.icon then tween(t.icon, 0.3, t.icon:IsA("TextLabel") and { TextColor3 = on and WHITE or K.mute } or { ImageColor3 = on and WHITE or K.mute }) end
			t.fade.Enabled = false -- (texto blanco limpio, sin la ultima letra negra)
			-- solo la elegida tiene pastilla y linea roja; crecen desde el centro
			if on then
				if silent then
					t.pill.Size = UDim2.new(1, 0, 0, 28)
					t.pill.BackgroundTransparency = 0.9
					t.pillStroke.Transparency = 0.82
					t.bar.Size = UDim2.new(1, -18, 0, 2)
				else
					t.pill.Size = UDim2.new(0.4, 0, 0, 22)
					t.pill.BackgroundTransparency = 1
					t.pillStroke.Transparency = 1
					t.bar.Size = UDim2.new(0, 0, 0, 2)
					tween(t.pill, 0.45, { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 0.9 }, Enum.EasingStyle.Back)
					tween(t.pillStroke, 0.4, { Transparency = 0.82 }, Enum.EasingStyle.Quad)
					task.delay(0.12, function() if t.sel then tween(t.bar, 0.45, { Size = UDim2.new(1, -18, 0, 2) }, Enum.EasingStyle.Back) end end)
				end
			else
				tween(t.pill, 0.25, { Size = UDim2.new(0.4, 0, 0, 22), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
				tween(t.pillStroke, 0.2, { Transparency = 1 }, Enum.EasingStyle.Quad)
				tween(t.bar, 0.2, { Size = UDim2.new(0, 0, 0, 2) }, Enum.EasingStyle.Quad)
				tween(t.label, 0.3, { TextColor3 = K.mute })
			end
			if on and t.icon and not silent then
				-- el icono da un saltito al elegir la seccion
				t.icon.Rotation = -18
				tween(t.icon, 0.6, { Rotation = 0 }, Enum.EasingStyle.Elastic)
			end
		end
		for n, p in pairs(pages) do
			if n == name then
				p.group.Visible = true
				p.group.ZIndex = 2
				if silent then
					p.group.GroupTransparency = 0
					p.group.Position = UDim2.new()
					p.depth.Scale = 1
				else
					-- la nueva entra deslizandose desde el lado de la pestaña, justo cuando la otra ya se va
					p.group.GroupTransparency = 1
					p.group.Position = UDim2.fromOffset(46 * dir, 0)
					p.depth.Scale = 0.985
					local myTab = name
					task.delay(0.1, function()
						if currentTab ~= myTab then return end
						tween(p.group, 0.38, { GroupTransparency = 0 }, Enum.EasingStyle.Sine)
						tween(p.group, 0.6, { Position = UDim2.new() }, Enum.EasingStyle.Quint)
						tween(p.depth, 0.6, { Scale = 1 }, Enum.EasingStyle.Quint)
						popGroups(p)
					end)
				end
			elseif p.group.Visible then
				-- la anterior se va hacia atras y se apaga
				p.group.ZIndex = 1
				if silent then
					p.group.Visible = false
				else
					-- la anterior sale hacia el otro lado y se apaga
					tween(p.group, 0.3, { Position = UDim2.fromOffset(-46 * dir, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
					tween(p.group, 0.22, { GroupTransparency = 1 }, Enum.EasingStyle.Sine)
					task.delay(0.31, function() if currentTab ~= n then p.group.Visible = false end end)
				end
			end
		end
	end

	local function getPage(name, iconId)
		if pages[name] then return pages[name] end
		local idx = #tabList + 1
		local pg = new("CanvasGroup", { Parent = body, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, GroupTransparency = 1 })
		local scroll = new("ScrollingFrame", { Parent = pg, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y })
		table.insert(allScrolls, scroll)
		local wrap = new("Frame", { Parent = scroll, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
		new("UIPadding", { Parent = wrap, PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 14), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
		local cols = {}
		for c = 1, 2 do
			local col = new("Frame", { Parent = wrap, Position = c == 1 and UDim2.new() or UDim2.new(0.5, 5, 0, 0), Size = UDim2.new(0.5, -5, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
			new("UIListLayout", { Parent = col, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
			cols[c] = col
		end
		local p = { group = pg, scroll = scroll, cols = cols, groups = {}, count = { 0, 0 }, depth = new("UIScale", { Parent = pg }) }
		pages[name] = p

		-- boton de la pestaña
		local btn = new("TextButton", { Parent = tabBar, LayoutOrder = idx, Size = UDim2.new(0.25, -5, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3 })
		new("UIPadding", { Parent = btn, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
		local inner = new("Frame", { Parent = btn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, ZIndex = 3 })
		new("UIListLayout", { Parent = inner, FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder })
		local icon
		if iconId then
			if tostring(iconId):sub(1, 6) == "glyph:" then
				-- icono hecho con un simbolo de texto (ej. el infinito de Immortal)
				icon = new("TextLabel", { Parent = inner, LayoutOrder = 1, Size = UDim2.fromOffset(16, 14), BackgroundTransparency = 1, Text = tostring(iconId):sub(7), Font = Enum.Font.GothamBlack, TextSize = 17, TextColor3 = K.mute, ZIndex = 3 })
			elseif tostring(iconId):sub(1, 6) == "sheet:" then
				-- icono de una hoja de iconos (Lucide): "sheet:ID:x:y" (48x48)
				local id, x, y = tostring(iconId):match("^sheet:(%d+):(%d+):(%d+)$")
				icon = new("ImageLabel", { Parent = inner, LayoutOrder = 1, Size = UDim2.fromOffset(15, 15), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(id), ImageRectOffset = Vector2.new(tonumber(x) or 0, tonumber(y) or 0), ImageRectSize = Vector2.new(48, 48), ImageColor3 = K.mute, ZIndex = 3 })
			else
				icon = new("ImageLabel", { Parent = inner, LayoutOrder = 1, Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(iconId), ImageColor3 = K.mute, ZIndex = 3 })
			end
		end
		local label = txt(inner, { LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, Text = name, Font = FB, TextSize = 13, TextColor3 = K.mute, TextStrokeColor3 = WHITE, TextStrokeTransparency = 1, ZIndex = 3 })
		local fade = new("UIGradient", { Parent = label, Color = FADE, Enabled = false })
		-- pastilla de la pestaña elegida (dentro del boton, nunca se corta)
		local pill = new("Frame", { Parent = btn, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0, 0, 0, 28), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 2 }, { corner(8) })
		local pillStroke = new("UIStroke", { Parent = pill, Color = WHITE, Thickness = 1, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		-- linea roja dentro de la pastilla, abajo
		local bar = new("Frame", { Parent = pill, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -3), Size = UDim2.new(0, 0, 0, 2), BackgroundColor3 = TH(255, 62, 70), BorderSizePixel = 0, ZIndex = 3 }, { corner(1) })
		pill.Visible = false -- (ahora va el cristal liquido)
		local isc = new("UIScale", { Parent = inner, Scale = 0.84 })
		local t = { idx = idx, name = name, button = btn, label = label, icon = icon, fade = fade, bar = bar, pill = pill, pillStroke = pillStroke, inner = inner, isc = isc, sel = false }
		tabs[name] = t
		table.insert(tabList, t)
		-- en movil no hay "raton encima": solo color al pasar el raton en PC, sin cambiar tamaño
		local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
		btn.MouseEnter:Connect(function() if not touchOnly and not t.sel then tween(label, 0.2, { TextColor3 = K.soft }) end end)
		btn.MouseLeave:Connect(function() if not t.sel then tween(label, 0.2, { TextColor3 = K.mute }) end end)
		btn.Activated:Connect(function()
			if currentTab ~= name then sfx("tap") end
			selectTab(name)
		end)
		-- al pulsar empieza el arrastre: el cristal sigue al dedo y cambia de seccion al pasar
		btn.InputBegan:Connect(function(i)
			if isPress(i) and not glassDragging then
				glassDragging = true
				glassInput = i
				glassStartX = i.Position.X
				glassLastPos = Vector2.new(i.Position.X, i.Position.Y)
				glassMoved = false
			end
		end)
		for _, tt in ipairs(tabList) do tt.button.Size = UDim2.new(1 / #tabList, -6 + 6 / #tabList, 1, 0) end
		if currentTab and tabs[currentTab] then moveGlass(tabs[currentTab].idx, true) end
		if idx == 1 then selectTab(name, true) end
		return p
	end

	-----------------------------------------------------------------------
	-- grupos y filas
	-----------------------------------------------------------------------
	local function makeGroupBox(p, title, side)
		local c = (side == "right" and 2) or (side == "left" and 1) or (p.count[1] <= p.count[2] and 1 or 2)
		p.count[c] += 1
		local outer = new("Frame", { Parent = p.cols[c], LayoutOrder = p.count[c], Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = WHITE, BackgroundTransparency = BOX_T, BorderSizePixel = 0 }, { corner(16) })
		local st = stroke(WHITE, 1.2, BOX_ST) styleBox(outer, st)
		-- brillo pequeño en el borde al pasar el raton
		outer.MouseEnter:Connect(function() tween(st, 0.25, { Thickness = 1.6 }) end)
		outer.MouseLeave:Connect(function() tween(st, 0.35, { Thickness = 1.2 }) end)
		st.Parent = outer
		local sc = new("UIScale", { Parent = outer })
		local box = new("Frame", { Parent = outer, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 2 })
		new("UIListLayout", { Parent = box, SortOrder = Enum.SortOrder.LayoutOrder })
		local hd = new("Frame", { Parent = box, LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1 })
		-- (sin cuadradito blanco delante del titulo)
		txt(hd, { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Text = string.upper(tostring(title)), Font = FB, TextSize = 10, TextColor3 = K.mute, TextTruncate = Enum.TextTruncate.AtEnd })
		local g = { box = box, n = 0 }
		table.insert(p.groups, { sc = sc, st = st, box = outer })
		return g
	end

	-- fila base: linea arriba, titulo y descripcion
	local function row(parent, order, h, title, desc, maxW, top)
		local r = new("Frame", { Parent = parent, LayoutOrder = order, Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true })
		-- (sin linea entre filas)
		local hasDesc = desc ~= nil and tostring(desc) ~= "" and tostring(desc) ~= tostring(title)
		local up = hasDesc or top
		local tl = txt(r, { Position = UDim2.fromOffset(12, up and 7 or 0), Size = UDim2.new(1, -24, 0, up and 15 or 40), Text = tostring(title), Font = FB, TextSize = 12, TextColor3 = K.soft, TextTruncate = Enum.TextTruncate.AtEnd })
		new("UISizeConstraint", { Parent = tl, MaxSize = Vector2.new(maxW or 170, 1000) })
		if hasDesc then
			txt(r, { Position = UDim2.fromOffset(12, 22), Size = UDim2.new(0.62, -12, 0, 13), Text = tostring(desc), Font = F, TextSize = 10, TextColor3 = K.mute, TextTruncate = Enum.TextTruncate.AtEnd })
		end
		return r, tl
	end
	local function hover(r)
		local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
		local rsc = new("UIScale", { Parent = r })
		local function press(i) if isPress(i) then tween(rsc, 0.12, { Scale = 0.985 }, Enum.EasingStyle.Quad) end end
		local function release(i) if isPress(i) then tween(rsc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back) end end
		r.InputBegan:Connect(press)
		r.InputEnded:Connect(release)
		-- tambien cuando se toca un boton de la fila (el boton se queda con el toque)
		r.DescendantAdded:Connect(function(d)
			if d:IsA("GuiButton") then
				d.InputBegan:Connect(press)
				d.InputEnded:Connect(release)
			end
		end)
		-- resalte de cristal: aparece un fondo de cristal suave con un toque rojo muy ligero (sin linea)
		local hl = new("Frame", { Parent = r, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -4), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, { corner(9) })
		local hlTint = new("Frame", { Parent = hl, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 1 }, { corner(9) })
		new("UIGradient", { Parent = hlTint, Rotation = 20, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.6, 0.96), NumberSequenceKeypoint.new(1, 1) }) })
		local hlSt = new("UIStroke", { Parent = hl, Color = WHITE, Thickness = 1, Transparency = 1 })
		local function lit(on)
			tween(hl, 0.3, { BackgroundTransparency = on and 0.955 or 1 }, Enum.EasingStyle.Quint)
			tween(hlTint, 0.3, { BackgroundTransparency = on and 0 or 1 }, Enum.EasingStyle.Quint)
			tween(hlSt, 0.3, { Transparency = on and 0.86 or 1 }, Enum.EasingStyle.Quint)
		end
		r.MouseEnter:Connect(function() if not touchOnly then lit(true) end end)
		r.MouseLeave:Connect(function() if not touchOnly then lit(false) end end)
		-- en movil: se enciende al tocar y se apaga solo
		if touchOnly then
			local litId = 0
			local function touchLit(i)
				if not isPress(i) then return end
				litId += 1
				local my = litId
				lit(true)
				task.delay(0.45, function() if my == litId then lit(false) end end)
			end
			r.InputBegan:Connect(touchLit)
			r.DescendantAdded:Connect(function(d) if d:IsA("GuiButton") then d.InputBegan:Connect(touchLit) end end)
		end
	end
	local function args(flag, v)
		if type(flag) == "table" then v = flag flag = v.flag end
		return flag, v or {}
	end
	local function boxButton(parent, w, text)
		local b = new("TextButton", { Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 20), Size = UDim2.fromOffset(w, 24), BackgroundColor3 = BTN_BASE, BackgroundTransparency = BTN_T, AutoButtonColor = false, Text = "", ZIndex = 3 }, { corner(12) })
		local s = stroke(K.line2, 1, 0)
		s.Parent = b
		local sBase = K.line2
		if D.btn == "glass" then
			b.BackgroundTransparency = 0.45
			joinGlass(b, s, 3)
			sBase = WHITE
		end
		local l = txt(b, { Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -18, 1, 0), Text = tostring(text or ""), Font = FB, TextSize = 11, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 })
		local bsc = new("UIScale", { Parent = b })
		local glow = new("UIStroke", { Parent = b, Color = WHITE, Thickness = 4, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		local touchOnly = UIS.TouchEnabled and not UIS.MouseEnabled
		b.MouseEnter:Connect(function()
			if touchOnly then return end
			tween(s, 0.2, { Color = WHITE })
			tween(glow, 0.25, { Transparency = 0.86 })
			if D.btn == "glass" then tween(b, 0.25, { BackgroundTransparency = 0.15 }) else tween(b, 0.25, { BackgroundColor3 = TH(110, 26, 34) }) end
			tween(bsc, 0.3, { Scale = 1.04 }, Enum.EasingStyle.Back)
		end)
		b.MouseLeave:Connect(function()
			tween(s, 0.25, { Color = sBase })
			tween(glow, 0.3, { Transparency = 1 })
			tween(b, 0.3, D.btn == "glass" and { BackgroundTransparency = 0.45 } or { BackgroundColor3 = BTN_BASE })
			tween(bsc, 0.3, { Scale = 1 })
		end)
		return b, l, s
	end
	local function flashBtn(b, l)
		tween(b, 0.08, { BackgroundColor3 = WHITE })
		tween(l, 0.08, { TextColor3 = BLACK })
		task.delay(0.14, function()
			tween(b, 0.35, { BackgroundColor3 = D.btn == "glass" and WHITE or BTN_BASE })
			tween(l, 0.35, { TextColor3 = WHITE })
		end)
	end

	local function makeGroup(p, gTitle, side)
		local g = makeGroupBox(p, gTitle, side)
		local function nextOrder() g.n += 10 return g.n end

		function g:create_toggle(flag, v)
			flag, v = args(flag, v)
			local state = v.default == true
			if flag and rt._flags[flag] ~= nil then state = rt._flags[flag] == true end
			local order = nextOrder()
			local r, tl = row(g.box, order, 40, v.title or flag or "Toggle", v.description, 185)
			hover(r)
			local tfade = new("UIGradient", { Parent = tl, Color = FADE, Enabled = false })
			local hit = new("TextButton", { Parent = r, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 2 })
			-- interruptor de cristal liquido: carril translucido con reflejo; al encender se llena de rojo
			local track = new("Frame", { Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 20), Size = UDim2.fromOffset(40, 22), BackgroundColor3 = WHITE, BackgroundTransparency = 0.9, BorderSizePixel = 0, ZIndex = 3 }, { corner(11) })
			local ts = stroke(WHITE, 1, 0.55)
			ts.Parent = track
			new("UIGradient", { Parent = ts, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.7) }) })
			local fill = new("Frame", { Parent = track, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 3 }, { corner(11) })
			new("UIGradient", { Parent = fill, Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, TH(255, 112, 118)), ColorSequenceKeypoint.new(1, TH(180, 18, 30)) }) })
			local tGloss = new("Frame", { Parent = track, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 4 }, { corner(11) })
			new("UIGradient", { Parent = tGloss, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.5, 0.94), NumberSequenceKeypoint.new(1, 1) }) })
			-- bolita de cristal (blanca con reflejo y borde fino)
			local knob = new("Frame", { Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 11, 0.5, 0), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5 }, { corner(9) })
			new("UIGradient", { Parent = knob, Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(1, Color3.fromRGB(208, 208, 215)) }) })
			local kst = stroke(BLACK, 1, 0.78)
			kst.Parent = knob
			local m = { frame = r, _order = order, _group = g }
			local function render(anim)
				local pos = state and UDim2.new(1, -11, 0.5, 0) or UDim2.new(0, 11, 0.5, 0)
				-- apagado = cristal transparente, encendido = cristal rojo (el texto se queda igual)
				tl.TextColor3 = WHITE
				local fillT = state and 0.12 or 1
				local stC = state and TH(255, 160, 165) or WHITE
				if anim then
					-- la bolita se estira mientras viaja (como una gota) y vuelve a su forma
					tween(knob, 0.16, { Size = UDim2.fromOffset(25, 16) }, Enum.EasingStyle.Quad)
					tween(knob, 0.45, { Position = pos }, Enum.EasingStyle.Back)
					task.delay(0.16, function() tween(knob, 0.32, { Size = UDim2.fromOffset(18, 18) }, Enum.EasingStyle.Back) end)
					tween(fill, 0.3, { BackgroundTransparency = fillT }, Enum.EasingStyle.Quint)
					tween(ts, 0.3, { Color = stC, Transparency = state and 0.3 or 0.55 }, Enum.EasingStyle.Quint)
				else
					knob.Position, fill.BackgroundTransparency = pos, fillT
					ts.Color, ts.Transparency = stC, state and 0.3 or 0.55
				end
				tfade.Enabled = false
			end
			render(false)
			function m:set_value(val, silent)
				state = val == true
				if flag then rt._flags[flag] = state end
				render(true)
				if m.notify_on and not silent then notify(tostring(v.title or flag or "Toggle"), state and "Enabled" or "Disabled", 1.6) end
				if not silent then safe(v.callback, state) end
			end
			function m:get_value() return state end
			function m:set_visible(x) r.Visible = x if m._sub then m._sub.Visible = x and m._open or false end end
			function m:is_visible() return r.Visible end
			if flag then rt._flags[flag] = state end
			hit.Activated:Connect(function()
				m:set_value(not state)
				sfx(state and "toggle_on" or "toggle_off")
			end)
			-- tecla asignada (se configura en el desplegable de ajustes)
			local bindText = "None"
			local bind
			bind = { key = nil, hold = false,
				fn = function() if bind.hold then m:set_value(true) else m:set_value(not state) end end,
				release = function() if bind.hold then m:set_value(false) end end }
			table.insert(binds, bind)
			m.start_bind = function(done)
				bindText = "..."
				capturing = function(code)
					if code == Enum.KeyCode.Escape or code == Enum.KeyCode.Backspace then
						bind.key = nil
						bindText = "None"
					else
						bind.key = code
						bindText = code.Name
					end
					if done then done(bindText) end
				end
			end
			m.bind_text = function() return bindText end
			m.kind, m.title, m.desc = "toggle", v.title or flag, v.description
			m.notify_on = false
			m._row, m._track = r, track
			if state and v.callback then task.defer(safe, v.callback, state) end
			return m
		end

		function g:create_slider(flag, v)
			flag, v = args(flag, v)
			local mn, mx = tonumber(v.minimum) or 0, tonumber(v.maximum) or 100
			local value = tonumber(v.default) or mn
			if flag and tonumber(rt._flags[flag]) then value = tonumber(rt._flags[flag]) end
			value = math.clamp(value, mn, mx)
			local r = row(g.box, nextOrder(), 48, v.title or flag or "Slider", nil, 170, true)
			hover(r)
			local valTxt = txt(r, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 7), Size = UDim2.fromOffset(80, 15), Text = "", Font = FB, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right })
			local hitBar = new("TextButton", { Parent = r, Position = UDim2.new(0, 6, 0, 24), Size = UDim2.new(1, -12, 0, 20), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 3 })
			local track = new("Frame", { Parent = r, Position = UDim2.new(0, 12, 0, 33), Size = UDim2.new(1, -24, 0, 3), BackgroundColor3 = K.dark, BorderSizePixel = 0, ZIndex = 2 }, { corner(2) })
			local fill = new("Frame", { Parent = track, Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, { corner(2) })
			local knob = new("Frame", { Parent = track, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(9, 9), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4 }, { corner(2) })
			local function snap(x)
				local inc = tonumber(v.increment)
				if inc and inc > 0 and inc < 1 then
					local s = math.floor(x / inc + 0.5) * inc
					return math.floor(s * 1000 + 0.5) / 1000
				end
				if v.rounding == true then return math.floor(x + 0.5) end
				return math.floor(x * 10 + 0.5) / 10
			end
			local function render(val, anim)
				local a = mx > mn and (val - mn) / (mx - mn) or 0
				if anim then
					tween(fill, 0.1, { Size = UDim2.fromScale(a, 1) }, Enum.EasingStyle.Quad)
					tween(knob, 0.1, { Position = UDim2.fromScale(a, 0.5) }, Enum.EasingStyle.Quad)
				else
					fill.Size = UDim2.fromScale(a, 1)
					knob.Position = UDim2.fromScale(a, 0.5)
				end
				valTxt.Text = tostring(val) .. (v.suffix or "")
			end
			render(value)
			local m = { frame = r }
			local function commit(val, silent, anim)
				val = math.clamp(snap(val), mn, mx)
				value = val
				render(val, anim)
				if flag then rt._flags[flag] = val end
				if not silent then safe(v.callback, val) end
			end
			function m:set_value(val, silent) commit(tonumber(val) or mn, silent, true) end
			function m:get_value() return value end
			function m:set_visible(x) r.Visible = x end
			if flag then rt._flags[flag] = value end
			m.kind, m.title, m.desc, m.min, m.max, m.suffix = "slider", v.title or flag, v.description, mn, mx, v.suffix
			m.default = value
			local dragging = false
			local function fromX(px) commit(mn + math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1) * (mx - mn), false, false) end
			hitBar.InputBegan:Connect(function(i)
				if isPress(i) then
					dragging = true
					lockScroll(true)
					tween(knob, 0.2, { Size = UDim2.fromOffset(13, 13) }, Enum.EasingStyle.Back)
					tween(valTxt, 0.2, { TextColor3 = WHITE })
					fromX(i.Position.X)
				end
			end)
			UIS.InputChanged:Connect(function(i) if dragging and isMove(i) then fromX(i.Position.X) end end)
			UIS.InputEnded:Connect(function(i)
				if dragging and isPress(i) then
					dragging = false
					lockScroll(false)
					tween(knob, 0.3, { Size = UDim2.fromOffset(9, 9) }, Enum.EasingStyle.Back)
				end
			end)
			return m
		end

		function g:create_dropdown(flag, v)
			flag, v = args(flag, v)
			local opts = v.options or {}
			local cur = v.default
			if cur == nil then cur = opts[1] end
			if flag and rt._flags[flag] ~= nil then cur = rt._flags[flag] end
			local r = row(g.box, nextOrder(), 40, v.title or flag or "Dropdown", v.description, 118)
			local b, bl = boxButton(r, 128, "")
			local arrow = drawChevron(b, 4)
			bl.Size = UDim2.new(1, -26, 1, 0)
			local list = new("ScrollingFrame", { Parent = r, Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = WHITE, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3 })
			new("UIListLayout", { Parent = list, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
			local m = { frame = r }
			local isOpen = false
			local function paint() bl.Text = cur ~= nil and tostring(cur) or "None" end
			local function build()
				for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				for i, o in ipairs(opts) do
					local on = o == cur
					local ob = new("TextButton", { Parent = list, LayoutOrder = i, Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = WHITE, BackgroundTransparency = on and 0.92 or 1, AutoButtonColor = false, Text = "", ZIndex = 4 }, { corner(4) })
					txt(ob, { Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), Text = tostring(o), Font = on and FB or F, TextSize = 11, TextColor3 = on and WHITE or K.mute, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5 })
					if on then new("Frame", { Parent = ob, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5 }, { corner(2) }) end
					ob.MouseEnter:Connect(function() if o ~= cur then tween(ob, 0.15, { BackgroundTransparency = 0.96 }) end end)
					ob.MouseLeave:Connect(function() if o ~= cur then tween(ob, 0.2, { BackgroundTransparency = 1 }) end end)
					ob.Activated:Connect(function()
						sfx("tap")
						m:set_value(o)
						m._toggle(false)
					end)
				end
			end
			local function setOpen(x)
				isOpen = x
				if x then
					closeDrops(m._toggle)
					openDrops[m._toggle] = true
					build()
				else
					openDrops[m._toggle] = nil
				end
				local lh = math.min(#opts, 6) * 26
				tween(r, 0.4, { Size = UDim2.new(1, 0, 0, x and (46 + lh) or 40) })
				tween(list, 0.4, { Size = UDim2.new(1, -24, 0, x and lh or 0) })
				arrow.set(x)
			end
			m._toggle = setOpen
			paint()
			function m:set_value(val, silent)
				cur = val
				paint()
				if isOpen then build() end
				if flag then rt._flags[flag] = val end
				if not silent then safe(v.callback, val) end
			end
			function m:get_value() return cur end
			function m:set_options(o, sel)
				opts = o or {}
				if sel ~= nil then cur = sel elseif not table.find(opts, cur) then cur = opts[1] end
				paint()
				if isOpen then build() setOpen(true) end
			end
			function m:add_option(o, sel) table.insert(opts, o) if sel then self:set_value(o) end if isOpen then build() end end
			function m:get_options() return opts end
			function m:set_visible(x) r.Visible = x end
			function m:unfold() setOpen(true) end
			function m:set_locked_open() end
			if flag then rt._flags[flag] = cur end
			b.Activated:Connect(function() sfx("tap") setOpen(not isOpen) end)
			m.kind, m.title, m.desc = "dropdown", v.title or flag, v.description
			return m
		end

		function g:create_multi(flag, v)
			flag, v = args(flag, v)
			local opts = v.options or {}
			local sel = {}
			for _, o in ipairs(v.default or {}) do sel[o] = true end
			local r = row(g.box, nextOrder(), 40, v.title or flag or "Select", v.description, 118)
			local b, bl = boxButton(r, 128, "")
			local arrow = drawChevron(b, 4)
			bl.Size = UDim2.new(1, -26, 1, 0)
			local list = new("ScrollingFrame", { Parent = r, Position = UDim2.fromOffset(12, 42), Size = UDim2.new(1, -24, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = WHITE, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 3 })
			new("UIListLayout", { Parent = list, Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder })
			local m = { frame = r }
			local isOpen = false
			local ACC = TH(255, 62, 70)
			local function selectedList()
				local out, seen = {}, {}
				for _, o in ipairs(opts) do if sel[o] then out[#out + 1] = o seen[o] = true end end
				for o in pairs(sel) do if not seen[o] then out[#out + 1] = o end end
				return out
			end
			local function paint()
				local l = selectedList()
				if #l == 0 then bl.Text = tostring(v.none_text or "None")
				elseif #l == 1 then bl.Text = tostring(l[1])
				else bl.Text = #l .. " selected" end
			end
			local function build()
				local keep = list.CanvasPosition
				for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				for i, o in ipairs(opts) do
					local on = sel[o] == true
					local ob = new("TextButton", { Parent = list, LayoutOrder = i, Size = UDim2.new(1, -4, 0, 24), BackgroundColor3 = on and ACC or WHITE, BackgroundTransparency = on and 0.82 or 1, AutoButtonColor = false, Text = "", ZIndex = 4 }, { corner(8) })
					-- casilla de cristal
					local cb = new("Frame", { Parent = ob, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = on and ACC or WHITE, BackgroundTransparency = on and 0 or 0.88, BorderSizePixel = 0, ZIndex = 5 }, { corner(5) })
					local cbs = stroke(WHITE, 1, on and 0.2 or 0.55)
					cbs.Parent = cb
					if on then
						new("Frame", { Parent = cb, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, { corner(2) })
					end
					txt(ob, { Position = UDim2.fromOffset(28, 0), Size = UDim2.new(1, -34, 1, 0), Text = tostring(o), Font = on and FB or F, TextSize = 11, TextColor3 = on and WHITE or K.mute, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 5 })
					ob.MouseEnter:Connect(function() if not sel[o] then tween(ob, 0.15, { BackgroundTransparency = 0.94 }) end end)
					ob.MouseLeave:Connect(function() if not sel[o] then tween(ob, 0.2, { BackgroundTransparency = 1 }) end end)
					ob.Activated:Connect(function()
						if sel[o] then sel[o] = nil else sel[o] = true end
						sfx(sel[o] and "toggle_on" or "toggle_off")
						paint()
						build()
						if flag then rt._flags[flag] = selectedList() end
						safe(v.callback, selectedList(), o, sel[o] == true)
					end)
				end
				list.CanvasPosition = keep
			end
			local function setOpen(x)
				isOpen = x
				if x then
					closeDrops(m._toggle)
					openDrops[m._toggle] = true
					build()
				else
					openDrops[m._toggle] = nil
				end
				local lh = math.min(math.max(#opts, 1), 7) * 26
				tween(r, 0.4, { Size = UDim2.new(1, 0, 0, x and (46 + lh) or 40) })
				tween(list, 0.4, { Size = UDim2.new(1, -24, 0, x and lh or 0) })
				arrow.set(x)
			end
			m._toggle = setOpen
			paint()
			function m:get_selected() return selectedList() end
			function m:is_selected(o) return sel[o] == true end
			function m:set_selected(list2, silent)
				sel = {}
				for _, o in ipairs(list2 or {}) do sel[o] = true end
				paint()
				if isOpen then build() end
				if not silent then safe(v.callback, selectedList()) end
			end
			function m:set_options(o)
				opts = o or {}
				paint()
				if isOpen then build() setOpen(true) end
			end
			function m:get_options() return opts end
			function m:set_visible(x) r.Visible = x end
			b.Activated:Connect(function() sfx("tap") setOpen(not isOpen) end)
			m.kind, m.title, m.desc = "multi", v.title or flag, v.description
			return m
		end

		function g:create_button(flag, v)
			flag, v = args(flag, v)
			local r = row(g.box, nextOrder(), 40, v.title or "Button", v.description, 160)
			hover(r)
			local b, bl = boxButton(r, 84, tostring(v.button_text or "Run"))
			bl.TextXAlignment = Enum.TextXAlignment.Center
			local bs = new("UIScale", { Parent = b })
			b.Activated:Connect(function()
				sfx("tap")
				bs.Scale = 0.92
				tween(bs, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
				flashBtn(b, bl)
				safe(v.callback)
			end)
			return { frame = r, set_visible = function(_, x) r.Visible = x end }
		end

		function g:create_textbox(flag, v)
			flag, v = args(flag, v)
			local r = row(g.box, nextOrder(), 40, v.title or flag or "Text", v.description, 118)
			local box = new("TextBox", { Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 20), Size = UDim2.fromOffset(140, 24), BackgroundColor3 = TH(52, 16, 20), BackgroundTransparency = 0.2, Text = tostring(v.default or ""), PlaceholderText = tostring(v.placeholder or ""), PlaceholderColor3 = K.mute, TextColor3 = WHITE, Font = F, TextSize = 11, ClearTextOnFocus = false, ClipsDescendants = true, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3 }, { corner(12) })
			new("UIPadding", { Parent = box, PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) })
			local s = stroke(K.line2, 1, 0)
			s.Parent = box
			if D.btn == "glass" then
				box.BackgroundColor3 = TH(48, 14, 18)
				box.BackgroundTransparency = 0.45
				s.Color = WHITE
				s.Transparency = 0.25
				new("UIGradient", { Parent = s, Rotation = 90, Color = ColorSequence.new(WHITE, TH(255, 62, 70)), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(1, 0.3) }) })
			end
			box.Focused:Connect(function() sfx("tap") tween(s, 0.2, { Color = WHITE }) end)
			box.FocusLost:Connect(function(enter)
				tween(s, 0.25, { Color = D.btn == "glass" and WHITE or K.line2 })
				if flag then rt._flags[flag] = box.Text end
				safe(v.callback, box.Text, enter)
			end)
			local m = { frame = r }
			function m:get_value() return box.Text end
			function m:get_display_value() return box.Text end
			function m:set_value(x) box.Text = tostring(x or "") end
			function m:clear() box.Text = "" end
			function m:focus() box:CaptureFocus() end
			function m:set_visible(x) r.Visible = x end
			function m:is_visible() return r.Visible end
			return m
		end

		function g:create_keybind(flag, v)
			flag, v = args(flag, v)
			local r = row(g.box, nextOrder(), 40, v.title or "Keybind", v.description, 170)
			local b, bl = boxButton(r, 74, "None")
			bl.TextXAlignment = Enum.TextXAlignment.Center
			local bind = { key = nil, fn = function() safe(v.callback) end }
			table.insert(binds, bind)
			b.Activated:Connect(function()
				sfx("tap")
				bl.Text = "..."
				capturing = function(code)
					if code == Enum.KeyCode.Escape or code == Enum.KeyCode.Backspace then bind.key = nil bl.Text = "None" else bind.key = code bl.Text = code.Name end
					if flag then rt._flags[flag] = bind.key and bind.key.Name or nil end
				end
			end)
			return { frame = r, set_visible = function(_, x) r.Visible = x end }
		end

		-- fila de solo texto: titulo a la izquierda y valor a la derecha (se actualiza con set_text)
		function g:create_label(flag, v)
			flag, v = args(flag, v)
			local r = row(g.box, nextOrder(), 40, v.title or flag or "Label", v.description, 150)
			hover(r)
			local val = txt(r, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0, 20), Size = UDim2.new(0.55, -12, 0, 16), Text = tostring(v.text or ""), Font = FB, TextSize = 11, TextColor3 = WHITE, RichText = true, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3 })
			local m = { frame = r, value = val }
			function m:set_text(x) val.Text = tostring(x or "") end
			function m:get_text() return val.Text end
			function m:set_color(c) val.TextColor3 = c end
			function m:set_visible(x) r.Visible = x end
			return m
		end
		return g
	end

	-----------------------------------------------------------------------
	-- ajustes vinculados: se despliegan debajo de la funcion
	-----------------------------------------------------------------------
	function rt:link(owner, list, resettable)
		if not owner or not owner._row then return end
		local r = owner._row
		local g = owner._group
		if not owner._sub then
			local sub = new("Frame", { Parent = g.box, LayoutOrder = owner._order + 1, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true, Visible = false })
			new("Frame", { Parent = sub, Position = UDim2.fromOffset(14, 4), Size = UDim2.new(0, 1, 1, -8), BackgroundColor3 = WHITE, BackgroundTransparency = 0.75, BorderSizePixel = 0, ZIndex = 2 })
			local inner = new("Frame", { Parent = sub, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 })
			local lay = new("UIListLayout", { Parent = inner, SortOrder = Enum.SortOrder.LayoutOrder })
			-- cuadro de referencia de 100x100 para pasar pixeles de pantalla a tamaño real del panel
			-- (en pantallas grandes el panel esta agrandado y la altura salia de mas: dejaba un hueco)
			local ref = new("Frame", { Parent = sub, Size = UDim2.fromOffset(100, 100), BackgroundTransparency = 1, Visible = true })
			local function contentH()
				local k = ref.AbsoluteSize.Y / 100
				if k <= 0.01 then k = 1 end
				return math.ceil(lay.AbsoluteContentSize.Y / k)
			end
			owner._sub, owner._inner, owner._open, owner._n = sub, inner, false, 0
			-- flecha para desplegar
			local chev = new("TextButton", { Parent = r, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -56, 0, 20), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = WHITE, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 5 }, { corner(5) })
			local chevT = drawChevron(chev, 6, true)
			chev.MouseEnter:Connect(function() tween(chev, 0.2, { BackgroundTransparency = 0.92 }) end)
			chev.MouseLeave:Connect(function() tween(chev, 0.2, { BackgroundTransparency = 1 }) end)
			local function setSub(x)
				owner._open = x
				local hgt = contentH()
				if x then
					sub.Visible = r.Visible
					tween(sub, 0.45, { Size = UDim2.new(1, 0, 0, hgt + 4) })
				else
					tween(sub, 0.35, { Size = UDim2.new(1, 0, 0, 0) }).Completed:Connect(function() if not owner._open then sub.Visible = false end end)
				end
				chevT.set(x)
			end
			lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				if owner._open then sub.Size = UDim2.new(1, 0, 0, contentH() + 4) end
			end)
			chev.Activated:Connect(function() sfx("tap") setSub(not owner._open) end)
			owner._setSub = setSub
			-- tecla para esta funcion
			if owner.start_bind then
				owner._n += 1
				local kr = row(inner, owner._n, 40, "Keybind", nil)
				local kb, kl = boxButton(kr, 74, owner.bind_text())
				kl.TextXAlignment = Enum.TextXAlignment.Center
				kb.Activated:Connect(function()
					sfx("tap")
					kl.Text = "..."
					owner.start_bind(function(t) if kl.Parent then kl.Text = t end end)
				end)
			end
		end
		for _, hd in ipairs(list or {}) do
			if hd and hd.frame then
				owner._n += 1
				hd.frame.Parent = owner._inner
				hd.frame.LayoutOrder = owner._n
				owner._links = owner._links or {}
				table.insert(owner._links, hd)
			end
		end
		if resettable and not owner._reset then
			owner._reset = true
			local rr = row(owner._inner, 9999, 40, "Reset all to default", nil, 150)
			local rb, rl = boxButton(rr, 84, "Reset")
			rl.TextXAlignment = Enum.TextXAlignment.Center
			rb.Activated:Connect(function()
				sfx("tap")
				for _, hd in ipairs(owner._links or {}) do
					if hd.kind == "slider" and hd.default ~= nil then pcall(function() hd:set_value(hd.default) end) end
				end
				flashBtn(rb, rl)
				rl.Text = "Done"
				task.delay(0.9, function() if rl.Parent then rl.Text = "Reset" end end)
			end)
		end
	end

	-- saca una opcion de los ajustes de otra (o la devuelve dentro) con animacion:
	-- al separarla sale "de dentro" de la opcion padre como una tarjeta de cristal rojo
	function rt:detach(owner, hd, separate, instant)
		if not owner or not owner._row or not hd or not hd.frame then return end
		local f = hd.frame
		local g = owner._group
		if not hd._h then
			local okH, h = pcall(function() return f.Size.Y.Offset end)
			hd._h = (okH and type(h) == "number" and h > 0) and h or 40
		end
		hd._linkOrder = hd._linkOrder or f.LayoutOrder
		local H = hd._h
		if separate then
			if f.Parent == g.box then return end
			f.Parent = g.box
			f.LayoutOrder = owner._order + 2
			f.Visible = owner._row.Visible
			if instant then f.Size = UDim2.new(1, 0, 0, H) return end
			-- la opcion padre "empuja" y de ella sale la nueva fila
			local osc = owner._row:FindFirstChildOfClass("UIScale")
			if osc then osc.Scale = 1.04 tween(osc, 0.5, { Scale = 1 }, Enum.EasingStyle.Back) end
			f.Size = UDim2.new(1, 0, 0, 0)
			local fsc = f:FindFirstChildOfClass("UIScale")
			if fsc then fsc.Scale = 0.8 tween(fsc, 0.6, { Scale = 1 }, Enum.EasingStyle.Back) end
			tween(f, 0.5, { Size = UDim2.new(1, 0, 0, H) }, Enum.EasingStyle.Quint)
			-- destello de cristal rojo + brillo que la cruza
			local fl = new("Frame", { Parent = f, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -4), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.35, BorderSizePixel = 0, ZIndex = 1 }, { corner(10) })
			local flSt = new("UIStroke", { Parent = fl, Color = WHITE, Thickness = 1.2, Transparency = 0.1 })
			new("UIGradient", { Parent = flSt, Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(1, TH(255, 62, 70)) }) })
			local shG = new("UIGradient", { Parent = fl, Rotation = 20, Offset = Vector2.new(-1, 0), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.45, 0.2), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(0.55, 0.2), NumberSequenceKeypoint.new(1, 0.2) }) })
			tween(shG, 0.8, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Quad)
			task.delay(0.35, function()
				tween(fl, 0.7, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
				tween(flSt, 0.7, { Transparency = 1 }, Enum.EasingStyle.Quint)
			end)
			task.delay(1.1, function() pcall(function() fl:Destroy() end) end)
			sfx("toggle_on")
		else
			if f.Parent == owner._inner then return end
			local function back()
				f.Parent = owner._inner
				f.LayoutOrder = hd._linkOrder
				f.Size = UDim2.new(1, 0, 0, H)
				f.Visible = true
			end
			if instant then back() return end
			-- vuelve a meterse dentro de la opcion padre
			local fsc = f:FindFirstChildOfClass("UIScale")
			if fsc then tween(fsc, 0.35, { Scale = 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
			tween(f, 0.35, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.37, function()
				back()
				if fsc then fsc.Scale = 1 end
				local osc = owner._row:FindFirstChildOfClass("UIScale")
				if osc then osc.Scale = 0.97 tween(osc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back) end
			end)
			sfx("toggle_off")
		end
	end

	-- "separar": una opcion escondida sale de dentro de otra (debajo de ella) con animacion,
	-- o vuelve a meterse dentro y se esconde
	function rt:split(owner, hd, show, instant)
		if not owner or not owner._row or not hd or not hd.frame then return end
		local f = hd.frame
		if not hd._h then
			local okH, h = pcall(function() return f.Size.Y.Offset end)
			hd._h = (okH and type(h) == "number" and h > 0) and h or 40
		end
		local H = hd._h
		f.LayoutOrder = owner._order + 2 -- justo debajo (y de sus ajustes)
		hd._splitId = (hd._splitId or 0) + 1
		local my = hd._splitId
		local fsc = f:FindFirstChildOfClass("UIScale")
		local osc = owner._row:FindFirstChildOfClass("UIScale")
		if instant then
			f.Visible = show and owner._row.Visible or false
			f.Size = UDim2.new(1, 0, 0, H)
			if fsc then fsc.Scale = 1 end
			return
		end
		-- tarjeta de cristal rojo (copia de la fila) que viaja entre Auto Parry y su sitio nuevo
		local function makeGhost(fromRow)
			local k = win.AbsoluteSize.X / W
			if k <= 0.01 then return nil end
			local g = new("Frame", { Parent = win, Position = UDim2.fromOffset((fromRow.AbsolutePosition.X - win.AbsolutePosition.X) / k, (fromRow.AbsolutePosition.Y - win.AbsolutePosition.Y) / k), Size = UDim2.fromOffset(fromRow.AbsoluteSize.X / k, H), BackgroundColor3 = TH(48, 14, 18), BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = 40 }, { corner(10) })
			local gst = new("UIStroke", { Parent = g, Color = WHITE, Thickness = 1.3, Transparency = 0.1 })
			new("UIGradient", { Parent = gst, Rotation = 90, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, WHITE), ColorSequenceKeypoint.new(1, TH(255, 62, 70)) }) })
			local tint = new("Frame", { Parent = g, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0, ZIndex = 40 }, { corner(10) })
			new("UIGradient", { Parent = tint, Rotation = 20, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.6, 0.85), NumberSequenceKeypoint.new(1, 0.95) }) })
			local gloss = new("Frame", { Parent = g, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 40 }, { corner(10) })
			new("UIGradient", { Parent = gloss, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.72), NumberSequenceKeypoint.new(0.45, 0.94), NumberSequenceKeypoint.new(1, 1) }) })
			local t1 = txt(g, { Position = UDim2.fromOffset(12, 7), Size = UDim2.new(1, -24, 0, 15), Text = tostring(hd.title or "Auto Spam"), Font = FB, TextSize = 12, TextColor3 = WHITE, ZIndex = 41 })
			local t2 = txt(g, { Position = UDim2.fromOffset(12, 22), Size = UDim2.new(1, -24, 0, 13), Text = tostring(hd.desc or ""), Font = F, TextSize = 10, TextColor3 = Color3.fromRGB(235, 205, 207), ZIndex = 41 })
			local gsc = new("UIScale", { Parent = g })
			local shine = new("Frame", { Parent = g, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 42 }, { corner(10) })
			local shG = new("UIGradient", { Parent = shine, Rotation = 20, Offset = Vector2.new(-1.2, 0), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.5, 0.65), NumberSequenceKeypoint.new(0.58, 1), NumberSequenceKeypoint.new(1, 1) }) })
			return { f = g, sc = gsc, st = gst, parts = { g, tint, gloss }, texts = { t1, t2 }, shine = shG, k = k }
		end
		local function fadeGhost(gh, t)
			tween(gh.f, t, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
			for i = 2, #gh.parts do tween(gh.parts[i], t, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad) end
			for _, tx in ipairs(gh.texts) do tween(tx, t, { TextTransparency = 1 }, Enum.EasingStyle.Quad) end
			tween(gh.st, t, { Transparency = 1 }, Enum.EasingStyle.Quad)
			task.delay(t + 0.05, function() pcall(function() gh.f:Destroy() end) end)
		end
		if show then
			-- 1) Auto Parry se carga: se hunde un poco
			if osc then tween(osc, 0.16, { Scale = 0.96 }, Enum.EasingStyle.Quad) end
			task.delay(0.16, function()
				if my ~= hd._splitId then return end
				-- 2) de Auto Parry sale una tarjeta de cristal rojo con "Auto Spam" que baja a su sitio nuevo
				local gh = makeGhost(owner._row)
				if osc then tween(osc, 0.55, { Scale = 1 }, Enum.EasingStyle.Back) end
				f.Visible = owner._row.Visible
				f.Size = UDim2.new(1, 0, 0, 0)
				if fsc then fsc.Scale = 1 end
				tween(f, 0.5, { Size = UDim2.new(1, 0, 0, H) }, Enum.EasingStyle.Quint)
				if gh then
					gh.sc.Scale = 0.94
					tween(gh.sc, 0.25, { Scale = 1.05 }, Enum.EasingStyle.Quad)
					task.delay(0.25, function() tween(gh.sc, 0.4, { Scale = 1 }, Enum.EasingStyle.Back) end)
					tween(gh.shine, 0.7, { Offset = Vector2.new(1.2, 0) }, Enum.EasingStyle.Quad)
					-- sigue a la fila nueva mientras se abre su hueco
					local t0 = os.clock()
					local conn
					conn = game:GetService("RunService").RenderStepped:Connect(function()
						if not gh.f.Parent or os.clock() - t0 > 0.62 then if conn then conn:Disconnect() end return end
						local a = math.clamp((os.clock() - t0) / 0.55, 0, 1)
						a = 1 - (1 - a) ^ 4
						local fromY = (owner._row.AbsolutePosition.Y - win.AbsolutePosition.Y) / gh.k
						local toY = (f.AbsolutePosition.Y - win.AbsolutePosition.Y) / gh.k
						local x = (f.AbsolutePosition.X - win.AbsolutePosition.X) / gh.k
						gh.f.Position = UDim2.fromOffset(x, fromY + (toY - fromY) * a)
					end)
					-- 3) al llegar, la tarjeta se funde con la opcion de verdad
					task.delay(0.6, function() fadeGhost(gh, 0.45) end)
				end
			end)
			sfx("toggle_on")
		else
			-- vuelve: la tarjeta sube desde Auto Spam hasta Auto Parry y se funde con el
			local gh = makeGhost(f)
			if gh then
				for _, tx in ipairs(gh.texts) do tx.TextTransparency = 0 end
				gh.sc.Scale = 1.03
				tween(gh.sc, 0.45, { Scale = 0.92 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				local t0 = os.clock()
				local fromY = (f.AbsolutePosition.Y - win.AbsolutePosition.Y) / gh.k
				local conn
				conn = game:GetService("RunService").RenderStepped:Connect(function()
					if not gh.f.Parent or os.clock() - t0 > 0.5 then if conn then conn:Disconnect() end return end
					local a = math.clamp((os.clock() - t0) / 0.42, 0, 1)
					a = a * a * a
					local toY = (owner._row.AbsolutePosition.Y - win.AbsolutePosition.Y) / gh.k
					gh.f.Position = UDim2.new(0, gh.f.Position.X.Offset, 0, fromY + (toY - fromY) * a)
				end)
				task.delay(0.36, function() fadeGhost(gh, 0.2) end)
			end
			-- su hueco se cierra a la vez
			tween(f, 0.4, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.42, function()
				if my ~= hd._splitId then return end
				f.Visible = false
				f.Size = UDim2.new(1, 0, 0, H)
				if fsc then fsc.Scale = 1 end
				-- Auto Parry "se la traga": salto y brillo rojo
				if osc then osc.Scale = 1.05 tween(osc, 0.5, { Scale = 1 }, Enum.EasingStyle.Back) end
				local glow = new("Frame", { Parent = owner._row, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -8, 1, -4), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 1 }, { corner(10) })
				tween(glow, 0.6, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
				task.delay(0.65, function() pcall(function() glow:Destroy() end) end)
			end)
			sfx("toggle_off")
		end
	end

	-- piezas de la libreria para construir cosas propias con el mismo estilo
	rt.kit = { joinGlass = joinGlass, TH = TH, design = D, styleBox = styleBox, glassify = glassify, gui = gui, new = new, corner = corner, stroke = stroke, tween = tween, txt = txt, hover = hover, sfx = sfx, isPress = isPress, K = K, F = F, FB = FB, FK = FK, WHITE = WHITE, BLACK = BLACK, title = HUB_TITLE }
	function rt:create_category() return self end
	function rt:create_tab(title, iconId)
		title = tostring(title or "Tab")
		local p = getPage(title, iconId)
		local tab = {}
		function tab:create_group(gTitle, side)
			if type(gTitle) == "table" then side = gTitle.side or side gTitle = gTitle.title end
			return makeGroup(p, tostring(gTitle or "Group"), side)
		end
		function tab:create_panel()
			p.scroll.Visible = false
			local holder = new("Frame", { Parent = p.group, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
			new("UIPadding", { Parent = holder, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
			local box = new("Frame", { Parent = holder, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = BOX_T, BorderSizePixel = 0, ClipsDescendants = true }, { corner(16) })
			local st = stroke(WHITE, 1.2, BOX_ST) styleBox(box, st)
			st.Parent = box
			box.MouseEnter:Connect(function() tween(st, 0.25, { Thickness = 1.6 }) end)
			box.MouseLeave:Connect(function() tween(st, 0.35, { Thickness = 1.2 }) end)
			local sc = new("UIScale", { Parent = box })
			table.insert(p.groups, { sc = sc, st = st, box = box })
			return box
		end
		function tab:set_enabled(v) if tabs[title] then tabs[title].button.Visible = v ~= false end end
		function tab:is_enabled() return tabs[title] == nil or tabs[title].button.Visible end
		return tab
	end
	function rt:notify(msg)
		if getgenv().S2R_EGG_FINDER_TopBanner then
			local title = type(msg) == "table" and (msg.title or msg.Title) or HUB_TITLE
			local text = type(msg) == "table" and (msg.text or msg.content or msg.Content or msg.description) or tostring(msg or "")
			local dur = type(msg) == "table" and (msg.duration or msg.Duration) or 2.5
			local ok = pcall(function()
				getgenv().S2R_EGG_FINDER_TopBanner({ title = string.upper(tostring(title)), text = tostring(text or ""), kind = type(msg) == "table" and msg.kind or nil, icon = type(msg) == "table" and msg.icon or nil, width = 250, duration = math.clamp(tonumber(dur) or 2.5, 1.2, 5) })
			end)
			if ok then return end
		end
		if type(msg) == "table" then
			notify(msg.title or msg.Title or HUB_TITLE, msg.text or msg.content or msg.Content or msg.description or "", msg.duration or msg.Duration)
		else
			notify(HUB_TITLE, tostring(msg or ""), 3)
		end
	end
	function rt:load() return self._flags end
	function rt:_save() return true end
	function rt:close_all_dropdowns() closeDrops() end
	function rt:update_keybind_list() end

	-----------------------------------------------------------------------
	-- abrir / cerrar: la ventana se despliega hacia abajo desde la cabecera
	-----------------------------------------------------------------------
	local open, token = false, 0
	local function intro(my)
		for i, t in ipairs(tabList) do
			t.label.TextTransparency = 1
			if t.icon then if t.icon:IsA("TextLabel") then t.icon.TextTransparency = 1 else t.icon.ImageTransparency = 1 end end
			t.inner.Position = UDim2.new(0.5, 0, 0.5, 8) -- (centrado en la pestaña)
			task.delay(0.2 + (i - 1) * 0.05, function()
				if token ~= my then return end
				tween(t.label, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
				if t.icon then tween(t.icon, 0.4, t.icon:IsA("TextLabel") and { TextTransparency = 0 } or { ImageTransparency = 0 }, Enum.EasingStyle.Quad) end
				tween(t.inner, 0.5, { Position = UDim2.fromScale(0.5, 0.5) })
			end)
		end
		local p = currentTab and pages[currentTab]
		if p then
			p.group.GroupTransparency = 1
			task.delay(0.3, function()
				if token ~= my then return end
				tween(p.group, 0.4, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
				popGroups(p)
			end)
		end
		logoSc.Scale = 0.3
		tween(logoSc, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
		headGrad.Color = TITLE_REVEAL
		headGrad.Offset = Vector2.new(-1, 0)
		task.delay(0.1, function() if token == my then tween(headGrad, 0.9, { Offset = Vector2.new(1, 0) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) end end)
		if titleIsImage then
			titleImgGrad.Offset = Vector2.new(-1, 0)
			task.delay(0.1, function() if token == my then revealTitleImg() end end)
		end
	end
	-- el juego de detras se desenfoca mientras el panel esta abierto
	local blur
	pcall(function()
		local L = game:GetService("Lighting")
		local old = L:FindFirstChild("S2R_EGG_FINDER_Blur")
		if old then old:Destroy() end
		blur = Instance.new("BlurEffect")
		blur.Name = "S2R_EGG_FINDER_Blur"
		blur.Size = 0
		blur.Parent = L
	end)
	local CENTER = UDim2.fromScale(0.5, 0.5)
	local lastFrom = nil -- de donde salio la ventana (el logo), para volver ahi al cerrar
	-- convierte un punto de la pantalla en desplazamiento dentro de la ventana
	local function offsetFrom(pt)
		if not pt then return nil end
		local c = root.AbsolutePosition + root.AbsoluteSize / 2
		local sc = math.max(fit.Scale, 0.01)
		return UDim2.new(0.5, (pt.X - c.X) / sc, 0.5, (pt.Y - c.Y) / sc)
	end
	local fabRef -- boton del logo (se asigna al crearlo)
	local function fabCenter()
		if fabRef and fabRef.Parent then return fabRef.AbsolutePosition + fabRef.AbsoluteSize / 2 end
		return nil
	end
	local function setOpen(v, fromPt, power)
		if open == v then return end
		fromPt = fromPt or fabCenter() -- siempre sale del logo y vuelve a el
		open = v
		token += 1
		local my = token
		if v then
			refit()
			root.Visible = true
			sfx("open")
			local start = offsetFrom(fromPt)
			lastFrom = fromPt
			win.GroupTransparency = 1
			sheetGrad.Enabled = false
			win.Rotation = 0
			if power then
				-- la primera vez (al acabar la intro): aparece directamente en el centro, como una pantalla que se enciende sola
				win.Position = CENTER
				pop.Scale = 0.965
				win.GroupTransparency = 1
				task.spawn(function()
					win.GroupTransparency = 0.55
					task.wait(0.07)
					if token ~= my then return end
					win.GroupTransparency = 0.88
					task.wait(0.06)
					if token ~= my then return end
					tween(win, 0.55, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
				end)
				tween(pop, 0.9, { Scale = 1 }, Enum.EasingStyle.Quint)
			else
				-- sale del logo: crece desde el boton hasta el centro, sin girar, con un pequeño rebote al llegar
				win.Position = start or UDim2.new(0.5, 0, 0.5, 30)
				pop.Scale = start and (52 / W) or 0.85
				tween(win, 0.14, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
				tween(win, 0.5, { Position = CENTER }, Enum.EasingStyle.Quint)
				tween(pop, 0.6, { Scale = 1 }, Enum.EasingStyle.Back)
			end
			-- el logo se hunde un momento, como si "soltara" la ventana
			if not power then pcall(function()
				local fs = fabRef and fabRef:FindFirstChildOfClass("UIScale")
				if fs then fs.Scale = 0.82 tween(fs, 0.5, { Scale = 1 }, Enum.EasingStyle.Back) end
			end) end
			if blur then tween(blur, 0.6, { Size = rt._blurOn == false and 0 or 14 }, Enum.EasingStyle.Quad) end
			intro(my)
		else
			closeDrops()
			sfx("close")
			local target = offsetFrom(fromPt or fabCenter() or lastFrom)
			-- vuelve al logo: coge un poco de impulso y se mete encogiendose en el boton (sin girar)
			sheetGrad.Enabled = false
			tween(pop, 0.42, { Scale = target and (52 / W) or 0.85 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			tween(win, 0.42, { Position = target or UDim2.new(0.5, 0, 0.5, 24), Rotation = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.3, function() if token == my then tween(win, 0.12, { GroupTransparency = 1 }, Enum.EasingStyle.Quad) end end)
			-- al llegar, el logo "se la traga": pequeño salto
			task.delay(0.42, function()
				if token ~= my then return end
				pcall(function()
					local fs = fabRef and fabRef:FindFirstChildOfClass("UIScale")
					if fs then fs.Scale = 1.18 tween(fs, 0.45, { Scale = 1 }, Enum.EasingStyle.Back) end
				end)
			end)
			if blur then tween(blur, 0.4, { Size = 0 }, Enum.EasingStyle.Quad) end
			task.delay(0.44, function() if token == my then root.Visible = false end end)
		end
	end
	function rt._toggleWindow() setOpen(not open) end
	-- opciones de estilo (pestaña Misc > Style)
	function rt:set_blur(on)
		rt._blurOn = on ~= false
		if blur and open then tween(blur, 0.3, { Size = rt._blurOn and 14 or 0 }, Enum.EasingStyle.Quad) end
	end
	function rt:set_sounds(on) rt._mute = on == false end
	function rt:set_bg_logo(on)
		on = false -- branded background permanently disabled
		rt._logoOff = on == false
		pcall(function() tween(bgImg, 0.35, { ImageTransparency = rt._logoOff and 1 or 0.25 }, Enum.EasingStyle.Quad) end)
	end
	function rt:set_glass(op)
		op = math.clamp(tonumber(op) or 0.82, 0.3, 1)
		win.BackgroundTransparency = 1 - op
		pcall(function() bgShade.BackgroundTransparency = math.clamp(0.48 + (0.82 - op) * 0.5, 0.2, 0.85) end)
	end
	minBtn.Activated:Connect(function() setOpen(false) end)

	-- boton flotante (abre / cierra, se puede mover)
	local fab = new("TextButton", { Parent = gui, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -44, 0.5, 0), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = TH(30, 8, 11), BackgroundTransparency = 0.15, Text = "", AutoButtonColor = false, ZIndex = 60 }, { corner(16) })
	local fabScale = new("UIScale", { Parent = fab, Scale = 0 })
	fabRef = fab
	-- borde con degradado rojo -> blanco -> rojo
	-- borde dibujado por dentro del cuadro (un marco interior), asi no sale nada fuera
	local fabInner = new("Frame", { Parent = fab, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -4, 1, -4), BackgroundTransparency = 1, ZIndex = 61 }, { corner(14) })
	local fabStroke = new("UIStroke", { Parent = fabInner, Color = WHITE, Thickness = 1.4, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
	new("UIGradient", { Parent = fabStroke, Rotation = 45, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, TH(255, 62, 70)), ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(1, TH(255, 62, 70)) }) })
	-- fondo con un toque rojo abajo
	local fabTint = new("Frame", { Parent = fab, Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH(255, 62, 70), BorderSizePixel = 0, ZIndex = 60 }, { corner(16) })
	new("UIGradient", { Parent = fabTint, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.6, 0.92), NumberSequenceKeypoint.new(1, 0.7) }) })
	local fabLogo = new("ImageLabel", { Parent = fab, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, Image = LOGO, ScaleType = Enum.ScaleType.Fit, ZIndex = 62 })
	-- al pasar el raton: crece un poco y brilla mas (solo PC)
	if not (UIS.TouchEnabled and not UIS.MouseEnabled) then
		fab.MouseEnter:Connect(function() tween(fabLogo, 0.3, { Size = UDim2.fromOffset(38, 38) }, Enum.EasingStyle.Back) tween(fabStroke, 0.25, { Thickness = 1.8 }) end)
		fab.MouseLeave:Connect(function() tween(fabLogo, 0.3, { Size = UDim2.fromOffset(34, 34) }) tween(fabStroke, 0.25, { Thickness = 1.4 }) end)
	end
	do
		local down, moved, startIn, startPos = false, 0, nil, nil
		local fabMove = smooth(fab)
		local fabInput
		fab.InputBegan:Connect(function(i)
			if isPress(i) and not down then
				fabInput = i
				down, moved, startIn, startPos = true, 0, i.Position, fab.Position
				tween(fabScale, 0.2, { Scale = 0.9 })
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if down and isMove(i) and sameDrag(fabInput, i) then
				local d = i.Position - startIn
				moved = math.max(moved, d.Magnitude)
				if moved > 8 then fabMove.goal = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y) end
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if down and isPress(i) and sameDrag(fabInput, i) then
				down = false
				fabInput = nil
				tween(fabScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
				if moved <= 8 then setOpen(not open, fab.AbsolutePosition + fab.AbsoluteSize / 2) end
			end
		end)
	end
	-- X: S2R_EGG_FINDER se cierra del todo (panel, logo, avisos, desenfoque, sonidos y bucles)
	function rt:destroy()
		if rt._dead then return end
		rt._dead = true
		getgenv().S2R_EGG_FINDER_Gen = (getgenv().S2R_EGG_FINDER_Gen or 0) + 1 -- las teclas dejan de hacer nada
		getgenv().S2R_EGG_FINDER_Rebuild = nil
		pcall(function() if rt._onDestroy then rt._onDestroy() end end)
		sfx("close")
		tween(pop, 0.35, { Scale = 0.85 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		tween(win, 0.3, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
		if blur then tween(blur, 0.3, { Size = 0 }, Enum.EasingStyle.Quad) end
		tween(fabScale, 0.3, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.4, function()
			pcall(function() gui:Destroy() end)
			pcall(function() if blur then blur:Destroy() end end)
			pcall(function()
				for _, n in ipairs({ "tap", "toggle_on", "toggle_off", "open", "close" }) do
					local o = game:GetService("SoundService"):FindFirstChild("S2R_EGG_FINDER_" .. n)
					if o then o:Destroy() end
				end
			end)
			pcall(function()
				for _, par in ipairs({ guiParent(), lp:FindFirstChildOfClass("PlayerGui") }) do
					local h = par and par:FindFirstChild("S2R_EGG_FINDER_TopBanners")
					if h then h:Destroy() end
				end
			end)
		end)
	end
	closeBtn.Activated:Connect(function() rt:destroy() end)

	do -- mover la ventana: desde la cabecera o desde la barrita de abajo (fuera del panel)
		local drag, startPos, startIn
		local winMove = smooth(root)
		local dragInput
		local gripHit = new("TextButton", { Parent = root, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 2), Size = UDim2.fromOffset(120, 22), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 6 })
		local function begin(i)
			if isPress(i) and not drag then
				dragInput = i
				drag, startPos, startIn = true, winMove.goal, i.Position
				-- la barrita se alarga y brilla mientras mueves la ventana
				tween(grip, 0.3, { Size = UDim2.fromOffset(92, 5), BackgroundTransparency = 0, BackgroundColor3 = TH(255, 62, 70) }, Enum.EasingStyle.Back)
			end
		end
		head.InputBegan:Connect(begin)
		gripHit.InputBegan:Connect(begin)
		gripHit.MouseEnter:Connect(function() if not drag then tween(grip, 0.25, { Size = UDim2.fromOffset(76, 5), BackgroundTransparency = 0.15 }) end end)
		gripHit.MouseLeave:Connect(function() if not drag then tween(grip, 0.25, { Size = UDim2.fromOffset(64, 5), BackgroundTransparency = 0.35 }) end end)
		UIS.InputChanged:Connect(function(i)
			if drag and isMove(i) and sameDrag(dragInput, i) then
				local d = i.Position - startIn
				winMove.goal = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if isPress(i) and drag and sameDrag(dragInput, i) then
				drag = false
				dragInput = nil
				tween(grip, 0.4, { Size = UDim2.fromOffset(64, 5), BackgroundTransparency = 0.35, BackgroundColor3 = WHITE }, Enum.EasingStyle.Back)
			end
		end)
	end
	do -- esquina de abajo a la derecha (fuera del panel): esquina redondeada; se arrastra para agrandar / achicar (suave)
		local rz = new("TextButton", { Parent = root, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 14, 1, 14), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 50 })
		-- solo se ve la esquina de abajo a la derecha de un cuadrado redondeado (asi el angulo queda curvo)
		local clip = new("Frame", { Parent = rz, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -6, 1, -6), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 51 })
		local arc = new("Frame", { Parent = clip, AnchorPoint = Vector2.new(1, 1), Position = UDim2.fromScale(1, 1), Size = UDim2.fromOffset(44, 44), BackgroundTransparency = 1, ZIndex = 51 }, { new("UICorner", { CornerRadius = UDim.new(0, 12) }) })
		local arcSt = new("UIStroke", { Parent = arc, Color = WHITE, Thickness = 3, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
		local rzSc = new("UIScale", { Parent = clip })
		local active, rzInput, startD, startS = false, nil, 1, 1
		local target = userScale
		local follow
		local function center() return root.AbsolutePosition + root.AbsoluteSize / 2 end
		local function lit(on)
			tween(arcSt, 0.3, { Color = on and TH(255, 70, 80) or WHITE, Thickness = on and 4 or 3, Transparency = on and 0 or 0.1 }, Enum.EasingStyle.Quint)
			tween(rzSc, 0.35, { Scale = on and 1.18 or 1 }, Enum.EasingStyle.Back)
		end
		-- el panel sigue al dedo poco a poco (sin saltos)
		local function startFollow()
			if follow then return end
			follow = RunService.RenderStepped:Connect(function(dt)
				local cur = userScale
				local nxt = cur + (target - cur) * math.min(1, dt * 14)
				if math.abs(target - nxt) < 0.002 then nxt = target end
				rt:set_user_scale(nxt)
				if rt._onUserScale then pcall(rt._onUserScale, userScale) end
				if nxt == target and not active then
					follow:Disconnect()
					follow = nil
				end
			end)
		end
		rz.MouseEnter:Connect(function() if not active then lit(true) end end)
		rz.MouseLeave:Connect(function() if not active then lit(false) end end)
		rz.InputBegan:Connect(function(i)
			if isPress(i) and not active then
				active, rzInput = true, i
				startD = math.max((Vector2.new(i.Position.X, i.Position.Y) - center()).Magnitude, 20)
				startS = userScale
				target = userScale
				lockScroll(true)
				lit(true)
				startFollow()
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if active and isMove(i) and sameDrag(rzInput, i) then
				local d = (Vector2.new(i.Position.X, i.Position.Y) - center()).Magnitude
				target = math.clamp(startS * d / startD, 0.4, 1.6)
			end
		end)
		UIS.InputEnded:Connect(function(i)
			if active and isPress(i) and sameDrag(rzInput, i) then
				active, rzInput = false, nil
				lockScroll(false)
				lit(false)
			end
		end)
	end

	-- novedades (una vez por ejecucion)
	local function showNews()
		if getgenv().S2R_EGG_FINDER_NewsShown then return end
		getgenv().S2R_EGG_FINDER_NewsShown = true
		local items = {
			{ "New UI", "S2R_EGG_FINDER now uses the new glass panel." },
			{ "Auto Parry", "Remote or Keypress mode, accuracy, random accuracy, auto ability." },
			{ "Auto Play", "Plays for you: distance, speed, jumps, anti AFK, auto vote." },
			{ "Hit Sounds", "14 hit sounds with volume control." },
			{ "Performance", "No Render, FPS Booster, Low Graphics." },
		}
		local back = new("TextButton", { Parent = win, Size = UDim2.fromScale(1, 1), BackgroundColor3 = BLACK, BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 80 })
		local hh = 62 + #items * 42
		local panel = new("CanvasGroup", { Parent = back, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(340, hh), BackgroundColor3 = BLACK, GroupTransparency = 1, ZIndex = 81 }, { corner(8), stroke(K.line2, 1, 0) })
		local sc = new("UIScale", { Parent = panel, Scale = 0.95 })
		txt(panel, { Position = UDim2.fromOffset(16, 12), Size = UDim2.new(1, -60, 0, 18), Text = "WHAT'S NEW", Font = FK, TextSize = 13, ZIndex = 83 })
		txt(panel, { Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -60, 0, 13), Text = HUB_TITLE, Font = FB, TextSize = 10, TextColor3 = K.mute, ZIndex = 83 })
		local function close()
			if not back.Parent then return end
			tween(sc, 0.25, { Scale = 0.95 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			tween(panel, 0.22, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
			tween(back, 0.25, { BackgroundTransparency = 1 })
			task.delay(0.3, function() back:Destroy() end)
		end
		local x = new("TextButton", { Parent = panel, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1, Text = "×", Font = FB, TextSize = 20, TextColor3 = WHITE, AutoButtonColor = false, ZIndex = 84 })
		x.Activated:Connect(close)
		back.Activated:Connect(close)
		for i, it in ipairs(items) do
			local y = 54 + (i - 1) * 42
			new("Frame", { Parent = panel, Position = UDim2.fromOffset(16, y), Size = UDim2.new(1, -32, 0, 1), BackgroundColor3 = K.line, BorderSizePixel = 0, ZIndex = 82 })
			new("Frame", { Parent = panel, Position = UDim2.fromOffset(16, y + 14), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 83 }, { corner(1) })
			txt(panel, { Position = UDim2.fromOffset(28, y + 7), Size = UDim2.new(1, -44, 0, 15), Text = it[1], Font = FB, TextSize = 12, ZIndex = 83 })
			txt(panel, { Position = UDim2.fromOffset(28, y + 23), Size = UDim2.new(1, -44, 0, 13), Text = it[2], Font = F, TextSize = 10, TextColor3 = K.mute, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 83 })
		end
		tween(back, 0.3, { BackgroundTransparency = 0.35 })
		tween(panel, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
		tween(sc, 0.5, { Scale = 1 })
	end

	task.spawn(function()
		local g = getgenv()
		local t0 = os.clock()
		-- espera a la pantalla de carga: todo sale junto al llegar a 100%
		while g.S2R_EGG_FINDER_Loader_Active and not g.S2R_EGG_FINDER_Loaded and os.clock() - t0 < 120 do task.wait(0.1) end
		task.wait(0.15)
		setOpen(true, nil, true) -- se enciende en el centro (luego ya abre y cierra desde el logo)
		task.delay(0.6, function() tween(fabScale, 0.8, { Scale = 1 }, Enum.EasingStyle.Back) end)
	end)
	return rt
end

return Lib
end)()


---------------------------------------------------------------------------
-- S2R_EGG_FINDER (antes Source Hub Finder): todas las funciones, sobre la UI
---------------------------------------------------------------------------
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
if not player then
	player = Players.PlayerAdded:Wait()
end
local LocalPlayer = player

-- ===== Notificaciones de arriba (estilo "isla") =====
-- Baja desde arriba como una burbuja pequeña, se estira hasta ser una pastilla de cristal gris,
-- el contenido entra deslizandose, una barra fina marca el tiempo y al irse se encoge y sube.
local S2R_EGG_FINDER_TopBanner
do
	local TS = game:GetService("TweenService")
	local function tw(o, t, props, style, dir)
		local x = TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
		x:Play()
		return x
	end
	local WHITE = Color3.new(1, 1, 1)
	local function seq(t) local k = {} for i = 1, #t, 2 do k[#k + 1] = NumberSequenceKeypoint.new(t[i], t[i + 1]) end return NumberSequence.new(k) end
	local function mk(class, props, parent)
		local o = Instance.new(class)
		for k, v in pairs(props) do o[k] = v end
		o.Parent = parent
		return o
	end
	local stack = {} -- visibles; la mas nueva arriba
	local function relayout()
		local y
		for _, e in ipairs(stack) do
			y = y or e.inset
			e.y = y
			tw(e.card, 0.45, { Position = UDim2.new(0.5, 0, 0, y) }, Enum.EasingStyle.Quint)
			y = y + e.h + 8 * e.scale
		end
	end
	local holder
	local function getHolder()
		if holder and holder.Parent then return holder end
		local parent
		pcall(function() if gethui then parent = gethui() end end)
		if not parent then pcall(function() parent = game:GetService("CoreGui") end) end
		if not parent then parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") end
		local old = parent:FindFirstChild("S2R_EGG_FINDER_TopBanners")
		if old then old:Destroy() end
		holder = Instance.new("ScreenGui")
		holder.Name = "S2R_EGG_FINDER_TopBanners"
		holder.ResetOnSpawn = false
		holder.IgnoreGuiInset = true
		holder.DisplayOrder = 400
		holder.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		pcall(function() holder.ScreenInsets = Enum.ScreenInsets.None end)
		-- misma letra tipo codigo que el panel
		holder.DescendantAdded:Connect(function(d)
			local f = getgenv().S2R_EGG_FINDER_Mono
			if f then pcall(f, d) end
		end)
		holder.Parent = parent
		return holder
	end
	local function chipFor(text)
		local t = string.lower(tostring(text or ""))
		if t == "enabled" or t == "on" then return "ON", true end
		if t == "disabled" or t == "off" then return "OFF", false end
		return nil
	end

	-- iconos con simbolos (sin letras) segun el tipo de aviso
	local KINDS = {
		-- c0/c1 = icono, t = simbolo, base = cristal de fondo, edge = color del borde (la misma textura del JOIN, solo cambia el color)
		warn = { g = "!", c0 = Color3.fromRGB(255, 216, 112), c1 = Color3.fromRGB(240, 150, 28), t = Color3.fromRGB(46, 26, 0), base = Color3.fromRGB(40, 38, 36), edge = Color3.fromRGB(255, 196, 90) },
		error = { g = "!", c0 = Color3.fromRGB(255, 128, 128), c1 = Color3.fromRGB(205, 34, 46), t = WHITE, base = Color3.fromRGB(42, 34, 36), edge = Color3.fromRGB(255, 96, 104) },
		ok = { g = "check", c0 = Color3.fromRGB(150, 240, 176), c1 = Color3.fromRGB(38, 168, 88), t = WHITE, base = Color3.fromRGB(32, 40, 36), edge = Color3.fromRGB(110, 230, 150) },
		remove = { g = "x", c0 = Color3.fromRGB(255, 140, 146), c1 = Color3.fromRGB(190, 30, 44), t = WHITE, base = Color3.fromRGB(42, 34, 36), edge = Color3.fromRGB(255, 110, 118) },
		info = { g = "!", c0 = Color3.fromRGB(255, 255, 255), c1 = Color3.fromRGB(176, 176, 184), t = Color3.fromRGB(30, 30, 34), base = Color3.fromRGB(38, 38, 42), edge = Color3.fromRGB(225, 225, 232) },
	}
	-- o = { title, text, duration (nil = se queda), kind, icon, width, key }
	local function showNow(o)
		local g = getHolder()
		local key = o.key or tostring(o.title or "")
		-- si ya hay una igual, se actualiza en vez de apilar otra
		for _, e in ipairs(stack) do
			if e.key == key and not e.closed and e.update then
				e.update(o)
				return e.handle
			end
		end
		local v = g.AbsoluteSize
		local scale = 1
		if v.Y > 10 then scale = math.clamp(math.min(v.X / 1280, v.Y / 820), 0.78, 1.5) end
		local inset = 10
		pcall(function() inset = game:GetService("GuiService"):GetGuiInset().Y + 8 end)
		local H = 38 -- pequeña
		local W = math.clamp(tonumber(o.width) or 210, 180, 230)

		-- la burbuja (al principio es un circulo del alto de la pastilla)
		local card = mk("CanvasGroup", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, inset - 40 * scale), Size = UDim2.fromOffset(H, H), BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1 }, g)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, card)
		local sc = mk("UIScale", { Scale = scale * 0.55 }, card)
		-- degradado gris de fondo + reflejo blanco arriba
		-- fondo de cristal gris (el degradado va en un hijo: si va en el CanvasGroup oscurece TODO, texto incluido)
		local fillBg = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(52, 52, 58), BackgroundTransparency = 0.1, BorderSizePixel = 0, ZIndex = 0 }, card)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fillBg)
		mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, Color3.fromRGB(150, 150, 150)) }, fillBg)
		-- toque blanco en diagonal (como el cristal del JOIN)
		local tint = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1 }, card)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, tint)
		mk("UIGradient", { Rotation = 20, Transparency = seq({ 0, 0.9, 0.6, 0.96, 1, 0.98 }) }, tint)
		local gloss = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 1 }, card)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, gloss)
		mk("UIGradient", { Rotation = 90, Transparency = seq({ 0, 0.82, 0.45, 0.95, 1, 1 }) }, gloss)
		-- borde fino blanco -> gris
		local st = mk("UIStroke", { Color = WHITE, Thickness = 1.2, Transparency = 0.1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, card)
		local stG = mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(WHITE, WHITE), Transparency = seq({ 0, 0.1, 0.5, 0.6, 1, 0.25 }) }, st)

		-- icono redondo
		local IS = 28
		local tile = mk("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, (H - IS) / 2, 0.5, 0), Size = UDim2.fromOffset(IS, IS), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, card)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, tile)
		local tileG = mk("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 170, 178)) }, tile)
		local tileSc = mk("UIScale", { Scale = 0 }, tile)
		local glyph = mk("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.62, 0.62), BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold, Text = "!", TextScaled = true, TextColor3 = Color3.fromRGB(22, 22, 25), Rotation = -90, ZIndex = 4 }, tile)

		-- textos (entran deslizandose)
		local TX = H + 2
		local content = mk("Frame", { Position = UDim2.fromOffset(TX + 14, 0), Size = UDim2.new(1, -TX - 12, 1, 0), BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 3 }, card)
		local title = mk("TextLabel", { Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, -8, 0, 15), BackgroundTransparency = 1, Font = o.titleFont or Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE, TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 }, content)
		local sub = mk("TextLabel", { Position = UDim2.fromOffset(0, 19), Size = UDim2.new(1, -8, 0, 13), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextSize = 10, TextColor3 = Color3.fromRGB(228, 228, 234), TextTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 4 }, content)
		-- etiqueta ON / OFF
		local chip = mk("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(30, 16), BackgroundColor3 = WHITE, BorderSizePixel = 0, Visible = false, ZIndex = 4 }, content)
		mk("UICorner", { CornerRadius = UDim.new(1, 0) }, chip)
		local chl = mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 9, TextColor3 = Color3.fromRGB(18, 18, 20), ZIndex = 5 }, chip)
		local chipSc = mk("UIScale", {}, chip)
		local function fadeText(on, t)
			tw(title, t, { TextTransparency = on and 0 or 1 }, Enum.EasingStyle.Quad)
			tw(sub, t, { TextTransparency = on and 0 or 1 }, Enum.EasingStyle.Quad)
		end
		-- iconos dibujados con rayitas (los simbolos de texto salian como un cuadrado)
		local function drawIcon(bars)
			local f = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Visible = false, ZIndex = 4 }, tile)
			local list = {}
			for _, b in ipairs(bars) do
				local bf = mk("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, b[1], 0.5, b[2]), Size = UDim2.fromOffset(b[3], b[5] or 2.5), Rotation = b[4], BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 5 }, f)
				mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bf)
				list[#list + 1] = bf
			end
			return f, list
		end
		local iconX, barsX = drawIcon({ { 0, 0, 13, 45 }, { 0, 0, 13, -45 } })
		local iconC, barsC = drawIcon({ { -3, 2, 7, 45 }, { 2, -1, 13, -50 } })
		local iconE, barsE = drawIcon({ { 0, -2, 9, 90, 3 }, { 0, 5, 3, 0, 3 } })
		local function setKind(k)
			local K = KINDS[k] or KINDS.info
			local g = tostring(o.icon or K.g)
			iconX.Visible = g == "x"
			iconC.Visible = g == "check"
			iconE.Visible = g == "!"
			glyph.Visible = g ~= "x" and g ~= "check" and g ~= "!"
			glyph.Text = glyph.Visible and g or ""
			for _, bf in ipairs(barsX) do bf.BackgroundColor3 = K.t end
			for _, bf in ipairs(barsC) do bf.BackgroundColor3 = K.t end
			for _, bf in ipairs(barsE) do bf.BackgroundColor3 = K.t end
			glyph.TextColor3 = K.t
			tileG.Color = ColorSequence.new(K.c0, K.c1)
			tw(fillBg, 0.3, { BackgroundColor3 = K.base }, Enum.EasingStyle.Quad)
			stG.Color = ColorSequence.new(WHITE, K.edge)
		end
		setKind(o.kind)
		-- brillo que cruza
		local sheen = mk("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, card)
		local shg = mk("UIGradient", { Rotation = 15, Offset = Vector2.new(-1.2, 0), Transparency = seq({ 0, 1, 0.42, 1, 0.5, 0.86, 0.58, 1, 1, 1 }) }, sheen)
		local function doSheen(t)
			shg.Offset = Vector2.new(-1.2, 0)
			tw(shg, t or 0.8, { Offset = Vector2.new(1.2, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		end

		local entry = { card = card, h = H * scale, scale = scale, inset = inset, timed = o.duration ~= nil, key = key }
		local timerId = 0
		local close
		local function apply(opts, first)
			title.Text = tostring(opts.title or "S2R_EGG_FINDER")
			sub.Text = tostring(opts.text or "")
			if opts.kind then setKind(opts.kind) end
			local chipText, on = chipFor(opts.text)
			chip.Visible = chipText ~= nil
			if chipText then
				chl.Text = chipText
				chip.BackgroundColor3 = on and WHITE or Color3.fromRGB(70, 70, 76)
				chl.TextColor3 = on and Color3.fromRGB(18, 18, 20) or Color3.fromRGB(200, 200, 206)
				title.Size = UDim2.new(1, -44, 0, 15)
				sub.Size = UDim2.new(1, -44, 0, 13)
				if not first then chipSc.Scale = 0.5 tw(chipSc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back) end
			end
			timerId += 1
			local my = timerId
			if opts.duration then
				entry.timed = true
				task.delay(opts.duration, function() if my == timerId and close then close() end end)
			end
		end
		entry.update = function(opts)
			apply(opts, false)
			-- pequeño salto y el icono da una vuelta
			sc.Scale = scale * 1.05
			tw(sc, 0.4, { Scale = scale }, Enum.EasingStyle.Back)
			glyph.Rotation = -90
			tw(glyph, 0.5, { Rotation = 0 }, Enum.EasingStyle.Back)
			doSheen(0.6)
		end
		table.insert(stack, 1, entry)
		-- como mucho 4 a la vez: se va la mas vieja que se cierra sola
		if #stack > 4 then
			for i = #stack, 1, -1 do
				local e = stack[i]
				if e.timed and e ~= entry and e.close then e.close() break end
			end
		end
		relayout()
		apply(o, true)

		-- entrada: cae la burbuja con rebote, se estira a pastilla y entra el contenido
		tw(card, 0.25, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
		tw(sc, 0.5, { Scale = scale }, Enum.EasingStyle.Back)
		tw(tileSc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		tw(glyph, 0.6, { Rotation = 0 }, Enum.EasingStyle.Back)
		task.delay(0.22, function()
			if entry.closed then return end
			tw(card, 0.55, { Size = UDim2.fromOffset(W, H) }, Enum.EasingStyle.Quint)
			task.delay(0.12, function()
				if entry.closed then return end
				content.Position = UDim2.fromOffset(TX + 14, 0)
				tw(content, 0.45, { Position = UDim2.fromOffset(TX, 0) }, Enum.EasingStyle.Quint)
				fadeText(true, 0.35)
			end)
			task.delay(0.3, function() doSheen(0.8) end)
		end)

		-- salida: el contenido se va, la pastilla vuelve a burbuja, sube y se apaga
		close = function()
			if entry.closed then return end
			entry.closed = true
			for i, e in ipairs(stack) do if e == entry then table.remove(stack, i) break end end
			relayout()
			local y0 = entry.y or inset
			tw(content, 0.18, { Position = UDim2.fromOffset(TX - 8, 0) }, Enum.EasingStyle.Quad)
			fadeText(false, 0.15)
			chip.Visible = false
			tw(card, 0.32, { Size = UDim2.fromOffset(H, H) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.26, function()
				tw(tileSc, 0.25, { Scale = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
				tw(sc, 0.3, { Scale = scale * 0.6 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
				tw(card, 0.3, { Position = UDim2.new(0.5, 0, 0, y0 - 30 * scale), GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			end)
			task.delay(0.62, function()
				pcall(function() card:Destroy() end)
				-- ya se fue del todo: ahora entra la siguiente de la cola
				if entry.onDone then pcall(entry.onDone) end
			end)
		end
		entry.close = close
		-- "correcto": el icono se vuelve un check y la pastilla brilla un momento
		entry.success = function(opts)
			opts = opts or {}
			if entry.closed then return end
			setKind("ok")
			glyph.Rotation = -90
			tw(glyph, 0.5, { Rotation = 0 }, Enum.EasingStyle.Back)
			if opts.title then title.Text = tostring(opts.title) end
			if opts.text then sub.Text = tostring(opts.text) end
			sc.Scale = scale * 1.06
			tw(sc, 0.5, { Scale = scale }, Enum.EasingStyle.Back)
			doSheen(0.7)
			timerId += 1
			local my = timerId
			entry.timed = true
			task.delay(opts.duration or 3, function() if my == timerId and close then close() end end)
		end
		entry.handle = { close = function() close() end, card = card, success = function(opts) entry.success(opts) end, _entry = entry }
		return entry.handle
	end

	-- cola: solo se ve UNA a la vez. Si llega otra, la que esta se va (tras un momento minimo)
	-- y la nueva sale cuando la anterior ya se fue. Las repetidas se juntan en vez de apilarse.
	local current, queue = nil, {}
	local pump
	local function hurry(cur)
		local wait = math.max(0, 0.9 - (os.clock() - (cur.shownAt or 0)))
		task.delay(wait, function()
			if current == cur and not cur.closed and cur.close then cur.close() end
		end)
	end
	local function start(o)
		local h = showNow(o)
		current = h and h._entry or nil
		if current then
			current.shownAt = os.clock()
			current.onDone = pump
			if #queue > 0 then hurry(current) end
		end
		return h
	end
	pump = function()
		current = nil
		local nxt = table.remove(queue, 1)
		if nxt then start(nxt) end
	end
	S2R_EGG_FINDER_TopBanner = function(o)
		local key = o.key or tostring(o.title or "")
		if current and not current.closed then
			-- la misma que se esta viendo: se actualiza (sin salir otra encima)
			if current.key == key and current.update then
				current.update(o)
				return current.handle
			end
			-- una igual ya esperando: se reemplaza por la nueva
			for i, q in ipairs(queue) do
				if (q.key or tostring(q.title or "")) == key then
					queue[i] = o
					return nil
				end
			end
			table.insert(queue, o)
			while #queue > 3 do table.remove(queue, 1) end
			hurry(current)
			return nil
		end
		if current and current.closed then
			-- se esta yendo: la nueva espera a que termine
			table.insert(queue, o)
			while #queue > 3 do table.remove(queue, 1) end
			return nil
		end
		return start(o)
	end
	getgenv().S2R_EGG_FINDER_TopBanner = S2R_EGG_FINDER_TopBanner
end


print("[S2R_EGG_FINDER] Loading...")

local API_URL = "https://privatedontleakorelsejejjkeo3333.lovable.app/api/getPets"
local REFRESH_INTERVAL = 0.5 -- el feed se actualiza 2 veces por segundo
local MAX_ITEMS = 300
local DEFAULT_RARITY = "Secret"
local FORCE_INTERVAL = 3
local TITLE = SH_TITLE
local AUTHOR = "S2R_EGG_FINDER Team"

local POST_URL = "https://privatedontleakorelsejejjkeo3333.lovable.app/api/addPet"
local AUTO_POST = true
local POST_MIN_VALUE = 50000000
local POST_SCAN_INTERVAL = 8
local POST_COOLDOWN = 300

-- Blacklist (persisted)
local blacklist = {} -- [petName] = true
local blacklistFile = "SourcesHub_Blacklist.json"
local blacklistMode = false

local function loadBlacklist()
	if isfile and readfile and isfile(blacklistFile) then
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(blacklistFile))
		end)
		if ok and type(data) == "table" then
			for _, name in ipairs(data) do
				if type(name) == "string" and name ~= "" then
					blacklist[name] = true
				end
			end
		end
	end
end

local function saveBlacklist()
	if not writefile then
		return
	end
	local arr = {}
	for name in pairs(blacklist) do
		arr[#arr + 1] = name
	end
	table.sort(arr)
	pcall(function()
		writefile(blacklistFile, HttpService:JSONEncode(arr))
	end)
end

local function isBlacklisted(e)
	return e and e.name and blacklist[e.name] == true
end

local function blacklistNames()
	local names = {}
	for name in pairs(blacklist) do
		names[#names + 1] = name
	end
	table.sort(names)
	return names
end

loadBlacklist()

-- Filtro de rareza (varias a la vez). Vacio = se ven todas
local rarityFilter = {} -- [rareza] = true
local FILTER_FILE = "S2R_EGG_FINDER_Filters.json"
pcall(function()
	if isfile and readfile and isfile(FILTER_FILE) then
		local d = HttpService:JSONDecode(readfile(FILTER_FILE))
		if type(d) == "table" then
			for _, r in ipairs(d) do if type(r) == "string" then rarityFilter[r] = true end end
		end
	end
end)
local function saveFilter()
	if not writefile then return end
	local arr = {}
	for r in pairs(rarityFilter) do arr[#arr + 1] = r end
	table.sort(arr)
	pcall(function() writefile(FILTER_FILE, HttpService:JSONEncode(arr)) end)
end
local function passesFilter(e)
	if next(rarityFilter) == nil then return true end
	return rarityFilter[tostring(e.rarity)] == true
end

-- Rareza para el Auto-Join (varias a la vez). Vacio = usa el filtro del feed
local autoJoinRarity = {}
local AJ_FILE = "S2R_EGG_FINDER_AutoJoin.json"
pcall(function()
	if isfile and readfile and isfile(AJ_FILE) then
		local d = HttpService:JSONDecode(readfile(AJ_FILE))
		if type(d) == "table" then
			for _, r in ipairs(d) do if type(r) == "string" then autoJoinRarity[r] = true end end
		end
	end
end)
local function saveAutoJoin()
	if not writefile then return end
	local arr = {}
	for r in pairs(autoJoinRarity) do arr[#arr + 1] = r end
	table.sort(arr)
	pcall(function() writefile(AJ_FILE, HttpService:JSONEncode(arr)) end)
end
local function passesAutoJoin(e)
	if next(autoJoinRarity) ~= nil then
		return autoJoinRarity[tostring(e.rarity)] == true
	end
	return passesFilter(e)
end

local rarityByName, colorByName = {}, {}
local rarityColor = {} -- [rareza] = Color3 del juego
local displayByName, iconByName = {}, {}

local function findIcon(e)
	for _, k in ipairs({ "Icon", "IconId", "Image", "ImageId", "Thumbnail" }) do
		local v = e[k]
		if v ~= nil then
			local id = tostring(v):match("(%d%d%d%d%d+)")
			if id then
				return id
			end
		end
	end
	return nil
end

do
	local ok, err = pcall(function()
		local dataFolder = ReplicatedStorage:WaitForChild("Data", 5)
		if not dataFolder then
			error("Data folder missing")
		end
		local assetsModule = dataFolder:WaitForChild("Assets", 5)
		if not assetsModule then
			error("Assets module missing")
		end
		local Assets = require(assetsModule)
		if type(Assets) ~= "table" or type(Assets.Directory) ~= "table" then
			error("Assets.Directory missing")
		end
		for id, e in pairs(Assets.Directory) do
			if type(e) == "table" and type(e.Rarity) == "table" then
				local r = e.Rarity.DisplayName or e.Rarity._id
				local icon = findIcon(e)
				rarityByName[id] = r
				if r and typeof(e.Rarity.Color) == "Color3" then rarityColor[r] = e.Rarity.Color end
				colorByName[id] = e.Rarity.Color
				displayByName[id] = e.DisplayName or tostring(id)
				iconByName[id] = icon
				if e.DisplayName then
					rarityByName[e.DisplayName] = r
					colorByName[e.DisplayName] = e.Rarity.Color
					displayByName[e.DisplayName] = e.DisplayName
					iconByName[e.DisplayName] = icon
				end
			end
		end
	end)
	if not ok then
		warn("[S2R_EGG_FINDER] Gagal load Assets (rarity pakai fallback API/default):", err)
	end
end

local function getRarity(petName)
	return rarityByName[petName]
end

local function getRarityColor(petName)
	local c = colorByName[petName]
	if typeof(c) == "Color3" then
		return c
	end
	return nil
end

local function formatValue(v)
	local units = { { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if v >= u[1] then
			return ("$%.1f%s/s"):format(v / u[1], u[2])
		end
	end
	return ("$%d/s"):format(math.floor(v))
end

local function formatAge(tsMs)
	local s = math.max(0, math.floor(os.time() - tsMs / 1000))
	return ("%d:%02d"):format(math.floor(s / 60), s % 60)
end

local function richColor(c)
	return ("rgb(%d,%d,%d)"):format(
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

local function escapeRich(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function httpGet(url)
	local okR, res = pcall(function()
		local fn = (syn and syn.request) or http_request or request
		if fn then
			return fn({ Url = url, Method = "GET" })
		end
		return nil
	end)
	if okR and res and res.Body then
		return res.Body
	end
	local ok, body = pcall(function()
		return game:HttpGet(url)
	end)
	if ok and body then
		return body
	end
	local ok2, body2 = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if ok2 then
		return body2
	end
	return nil
end

---------------------------------------------------------------------------
-- UI (la de Blade Ball)
---------------------------------------------------------------------------
local UI = Library._new()
local kit = UI.kit
local gui = kit.gui
local new, corner, stroke, tween, txt, hover, sfx = kit.new, kit.corner, kit.stroke, kit.tween, kit.txt, kit.hover, kit.sfx
local TH = kit.TH
local DSN = kit.design -- el diseño elegido (botones, filas...)
local K, F, FB, WHITE, BLACK = kit.K, kit.F, kit.FB, kit.WHITE, kit.BLACK
local ACCENT = TH(255, 70, 80) -- acento rojo
local ERR = Color3.fromRGB(255, 110, 110) -- solo para errores
local FILL = ColorSequence.new(TH(255, 100, 108), TH(170, 18, 30))
local DARK_TXT = Color3.fromRGB(255, 255, 255) -- texto sobre los botones rojos

-- tipo de aviso -> icono (simbolo, sin letras): warn "!" ambar, error "!" rojo, ok "✓" verde, remove "✕", info "!" blanco
local KIND_BY_TITLE = { ["SERVER FULL"] = "warn", BLACKLISTED = "remove", UNBLACKLISTED = "ok", FORCE = "info", FEED = "ok", ["BLACKLIST MODE"] = "info", BLACKLIST = "warn", FILTER = "ok" }
local function notify(title, text, dur, kind)
	pcall(function()
		UI:notify({ title = title, text = text, duration = dur or 2.5, kind = kind or KIND_BY_TITLE[tostring(title)] or "info" })
	end)
end

local FinderTab = UI:create_tab("Finder", "7733774602")
local MiscTab = UI:create_tab("Misc", "132243429647479")

-- boton de cristal: normal, "red" (principal: capsula roja brillante con barrido de luz), "on" (rojo lleno), "off" (apagado)
local TS = game:GetService("TweenService")
local GLASS_BTN = DSN.btn == "solid" and TH(150, 24, 34) or TH(52, 16, 20)
local BTN_T = (DSN.btn == "outline" and 1) or (DSN.btn == "solid" and 0) or 0.2
local function smallBtn(parent, text, w, style)
	local filled = style == "red" or style == "on"
	local b = new("TextButton", { Parent = parent, AnchorPoint = Vector2.new(1, 0.5), Size = UDim2.fromOffset(w, 24), BackgroundColor3 = GLASS_BTN, BackgroundTransparency = BTN_T, AutoButtonColor = false, Text = "", ZIndex = 3 }, { corner(12) })
	local s = stroke(WHITE, 1, 0.55)
	s.Parent = b
	if DSN.btn == "outline" then s.Color = TH(255, 62, 70) s.Transparency = 0.2 end
	local glassy = DSN.btn == "glass"
	if glassy then
		-- textura del JOIN: color del tema arriba que baja a negro (el JOIN y el FORCE elegido, mas encendidos)
		b.BackgroundTransparency = (style == "on" and 0.05) or (style == "off" and 0.6) or (filled and 0.15) or 0.3
		kit.joinGlass(b, s, 3, false, false, filled)
	elseif filled then
		b.BackgroundColor3 = style == "on" and TH(120, 22, 30) or TH(48, 14, 18)
		b.BackgroundTransparency = style == "on" and 0.2 or 0.45
		if DSN.btn == "solid" then
			b.BackgroundColor3 = style == "on" and TH(255, 70, 80) or TH(210, 34, 46)
			b.BackgroundTransparency = 0
		elseif DSN.btn == "outline" then
			b.BackgroundTransparency = style == "on" and 0.6 or 1
		end
	end
	if not glassy then
		-- reflejo de cristal arriba
		local gl = new("Frame", { Parent = b, Size = UDim2.new(1, 0, 0.55, 0), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 4 }, { corner(12) })
		new("UIGradient", { Parent = gl, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.84), NumberSequenceKeypoint.new(1, 1) }) })
	end
	local l = txt(b, { Size = UDim2.fromScale(1, 1), Text = tostring(text), Font = FB, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 6 })
	if style == "red" then
		-- JOIN: texto un poco a la izquierda y una flecha (chevron) dibujada que se mueve
		l.Size = UDim2.new(1, -12, 1, 0)
		l.TextSize = 11
		local chev = new("Frame", { Parent = b, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -9, 0.5, 0), Size = UDim2.fromOffset(8, 10), BackgroundTransparency = 1, ZIndex = 6 })
		new("Frame", { Parent = chev, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, -2), Size = UDim2.fromOffset(7, 2), Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, { corner(1) })
		new("Frame", { Parent = chev, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 2), Size = UDim2.fromOffset(7, 2), Rotation = -45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, { corner(1) })
		pcall(function()
			TS:Create(chev, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.new(1, -6, 0.5, 0) }):Play()
		end)
	elseif style == "block" then
		-- icono de "prohibido" (circulo con raya) en vez de letras
		l.Text = ""
		local ic = new("Frame", { Parent = b, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = 6 }, { corner(6) })
		local ring = stroke(WHITE, 1.6, 0.05)
		ring.Parent = ic
		new("Frame", { Parent = ic, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), Rotation = -45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 6 }, { corner(1) })
		b.MouseEnter:Connect(function() tween(ring, 0.2, { Color = TH(255, 90, 100) }) end)
		b.MouseLeave:Connect(function() tween(ring, 0.25, { Color = WHITE }) end)
	end
	if filled then
		l.TextColor3 = WHITE
		l.TextStrokeTransparency = 1
	end
	if style == "off" then
		l.TextColor3 = Color3.fromRGB(120, 96, 99)
		s.Transparency = 0.75
	end
	local base = s.Color
	local bsc = new("UIScale", { Parent = b })
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	b.MouseEnter:Connect(function()
		if touchOnly or style == "off" then return end
		tween(s, 0.2, { Color = WHITE })
		tween(bsc, 0.3, { Scale = 1.06 }, Enum.EasingStyle.Back)
	end)
	b.MouseLeave:Connect(function()
		tween(s, 0.25, { Color = base })
		tween(bsc, 0.3, { Scale = 1 })
	end)
	b.InputBegan:Connect(function(i) if kit.isPress(i) then tween(bsc, 0.1, { Scale = 0.9 }, Enum.EasingStyle.Quad) end end)
	b.InputEnded:Connect(function(i) if kit.isPress(i) then tween(bsc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back) end end)
	return b, l
end

-- toque fiable: vale el Activated normal y tambien soltar el dedo cerca de donde se toco
local function onTap(btn, fn)
	local last, startPos = 0, nil
	local function fire()
		if os.clock() - last < 0.35 then return end
		last = os.clock()
		fn()
	end
	btn.Activated:Connect(fire)
	btn.InputBegan:Connect(function(i) if kit.isPress(i) then startPos = i.Position end end)
	btn.InputEnded:Connect(function(i)
		if kit.isPress(i) and startPos and (i.Position - startPos).Magnitude < 22 then fire() end
		startPos = nil
	end)
end

-- ===== pestaña Finder: feed en vivo a todo lo ancho =====
local feedBox = FinderTab:create_panel()
local top = new("Frame", { Parent = feedBox, Size = UDim2.new(1, 0, 0, 34), BackgroundTransparency = 1, ZIndex = 2 })
local liveDot = new("Frame", { Parent = top, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(6, 6), BackgroundColor3 = ACCENT, BorderSizePixel = 0, ZIndex = 3 }, { corner(3) })
task.spawn(function()
	while liveDot.Parent do
		tween(liveDot, 0.6, { BackgroundTransparency = 0.7 }, Enum.EasingStyle.Sine)
		task.wait(0.6)
		tween(liveDot, 0.6, { BackgroundTransparency = 0 }, Enum.EasingStyle.Sine)
		task.wait(0.6)
	end
end)
txt(top, { Position = UDim2.fromOffset(24, 0), Size = UDim2.fromOffset(66, 34), Text = "LIVE FEED", Font = FB, TextSize = 10, TextColor3 = K.mute, ZIndex = 3 })
local feedStatus = txt(top, { Position = UDim2.fromOffset(90, 0), Size = UDim2.new(1, -428, 1, 0), Text = "Connecting...", Font = F, TextSize = 10, TextColor3 = K.mute, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3 })
local detectedLabel = txt(top, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -252, 0.5, 0), Size = UDim2.fromOffset(80, 16), Text = "0 detected", Font = FB, TextSize = 10, TextColor3 = K.soft, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3 })
local clearBtn = smallBtn(top, "Clear", 52)
clearBtn.Position = UDim2.new(1, -10, 0.5, 0)
local blHeadBtn, blHeadLbl = smallBtn(top, "Filters", 74)
local updateFilterLabel -- (se define con el panel de filtros)
blHeadBtn.Position = UDim2.new(1, -68, 0.5, 0)

-- selector de vista: Lista (una debajo de otra) / Grid (iconos grandes con JOIN debajo)
local VIEW_FILE = "SourcesHub_View.txt"
local viewMode = "list"
pcall(function()
	if isfile and readfile and isfile(VIEW_FILE) then
		local v = readfile(VIEW_FILE)
		if v == "grid" or v == "list" then viewMode = v end
	end
end)
local seg = new("Frame", { Parent = top, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -148, 0.5, 0), Size = UDim2.fromOffset(96, 24), BackgroundColor3 = GLASS_BTN, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 3 }, { corner(12) })
do local ss = stroke(WHITE, 1, 0.55) ss.Parent = seg if DSN.btn == "glass" and kit.joinGlass then seg.BackgroundTransparency = 0.45 kit.joinGlass(seg, ss, 3) end end
local segPill = new("Frame", { Parent = seg, Position = UDim2.fromOffset(2, 2), Size = UDim2.new(0.5, -2, 1, -4), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, { corner(10) })
new("UIGradient", { Parent = segPill, Rotation = 90, Color = FILL })
local segList = new("TextLabel", { Parent = seg, Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, Text = "List", Font = FB, TextSize = 10, TextColor3 = DARK_TXT, ZIndex = 4 })
local segGrid = new("TextLabel", { Parent = seg, Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.5, 1), BackgroundTransparency = 1, Text = "Grid", Font = FB, TextSize = 10, TextColor3 = K.mute, ZIndex = 4 })
local function paintSeg(anim)
	local g = viewMode == "grid"
	local pos = g and UDim2.new(0.5, 0, 0, 2) or UDim2.fromOffset(2, 2)
	if anim then tween(segPill, 0.35, { Position = pos }, Enum.EasingStyle.Quint) else segPill.Position = pos end
	tween(segList, 0.25, { TextColor3 = g and K.mute or DARK_TXT })
	tween(segGrid, 0.25, { TextColor3 = g and DARK_TXT or K.mute })
end
paintSeg(false)
local topSep = new("Frame", { Parent = feedBox, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 2 })
new("UIGradient", { Parent = topSep, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) })

local feed = new("ScrollingFrame", { Parent = feedBox, Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 1, -36), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.6, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y, ZIndex = 2 })
local listLayout = new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
local gridLayout = new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, 176), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left })
local function applyLayout()
	listLayout.Parent = viewMode == "list" and feed or nil
	gridLayout.Parent = viewMode == "grid" and feed or nil
end
applyLayout()
new("UIPadding", { Parent = feed, PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 10) })
local emptyLabel = txt(feedBox, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 17), Size = UDim2.new(1, -40, 0, 20), Text = "Waiting for pets...", Font = FB, TextSize = 11, TextColor3 = K.mute, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 2 })

-- ===== pestaña Misc: todo lo importante =====
local AG = MiscTab:create_group("Joiner", "left")
local IG = MiscTab:create_group("Style", "right")
local SG = MiscTab:create_group("Status", "left")
local HG = MiscTab:create_group(TITLE, "right")

local statusRow = SG:create_label("status", { title = "Status", text = "Connecting..." })
local postRow = SG:create_label("post_stats", { title = "Post stats", text = "Scan:0 Post:0" })

local function setStatus(text)
	text = tostring(text)
	feedStatus.Text = text
	statusRow:set_text(text)
	local bad = text == "Disconnected" or text == "Join failed"
	statusRow:set_color(bad and ERR or WHITE)
end

---------------------------------------------------------------------------
-- unirse a servidores
---------------------------------------------------------------------------
local forceKey = nil -- pet que se esta forzando (tambien lo usa el aviso de servidor lleno)
-- el juego saca su PROPIO aviso ("Teleport could not ... instance is full"): se esconde, asi solo queda el de S2R_EGG_FINDER
local function isTpMsg(t)
	t = string.lower(tostring(t or ""))
	if not t:find("teleport") and not t:find("instance is full") then return false end
	return (t:find("full") or t:find("could not") or t:find("failed") or t:find("unable")) ~= nil
end
local hiddenTp = setmetatable({}, { __mode = "k" })
local lastTpNotify = 0
local reported = false
local function hideGameTpNotice(lbl)
	pcall(function()
		if not lbl.Parent or not isTpMsg(lbl.Text) then return end
		lbl.Visible = false
		local sg = lbl:FindFirstAncestorWhichIsA("LayerCollector")
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
		-- 1) se esconde el aviso entero: se sube por los padres hasta su pantalla (mientras no sean de media pantalla de alto)
		local box = lbl
		while box.Parent and box.Parent ~= sg and box.Parent:IsA("GuiObject") do
			local par = box.Parent
			if par.AbsoluteSize.Y > vp.Y * 0.45 then break end
			box = par
		end
		box.Visible = false
		-- 2) el fondo del aviso a veces es un "hermano" del texto (no su padre): tambien se esconde
		local holder = box.Parent
		if holder and holder:IsA("GuiObject") then
			for _, sib in ipairs(holder:GetChildren()) do
				if sib:IsA("GuiObject") and sib ~= box and sib.Visible then
					local a, b2 = sib.AbsolutePosition, box.AbsolutePosition
					if math.abs(a.Y - b2.Y) < 40 and math.abs(sib.AbsoluteSize.Y - box.AbsoluteSize.Y) < 70 then sib.Visible = false end
				end
			end
		end
		-- 3) si el aviso tiene su propia pantalla de avisos, se apaga entera unos segundos
		if sg and sg:IsA("ScreenGui") then
			local n = string.lower(sg.Name)
			if not n:find("S2R_EGG_FINDER") and (n:find("notif") or n:find("alert") or n:find("message") or n:find("popup") or #sg:GetChildren() <= 3) and sg.Enabled then
				sg.Enabled = false
				task.delay(6, function() pcall(function() sg.Enabled = true end) end)
			end
		end
		if not reported then
			reported = true
			-- por si hace falta ajustarlo: en la consola (F9) sale donde estaba el aviso
			warn("[S2R_EGG_FINDER] aviso del juego escondido: " .. lbl:GetFullName())
		end
		if not hiddenTp[box] then
			hiddenTp[box] = true
			if os.clock() - lastTpNotify > 1 then
				lastTpNotify = os.clock()
				notify("SERVER FULL", "Pick another server", 3, "warn")
			end
		end
	end)
end
-- se busca en la interfaz del juego y en la de Roblox (CoreGui)
local gamePg = player:FindFirstChildOfClass("PlayerGui")
local function tpRoots()
	local roots = {}
	if gamePg then roots[#roots + 1] = gamePg end
	pcall(function() roots[#roots + 1] = game:GetService("CoreGui") end)
	return roots
end
local function sweepTpNotices()
	for _, root in ipairs(tpRoots()) do
		pcall(function()
			for _, d in ipairs(root:GetDescendants()) do
				if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Visible and d.Text ~= "" and isTpMsg(d.Text) then
					hideGameTpNotice(d)
				end
			end
		end)
	end
end
-- despues de cada JOIN se vigila unos segundos (el aviso a veces sale tarde o se vuelve a mostrar)
local sweepUntil, sweeping = 0, false
local function sweepSoon()
	sweepUntil = os.clock() + 6
	if sweeping then return end
	sweeping = true
	task.spawn(function()
		while os.clock() < sweepUntil do
			sweepTpNotices()
			task.wait(0.1)
		end
		sweeping = false
	end)
end
pcall(function() if getgenv().S2R_EGG_FINDER_TPHide then getgenv().S2R_EGG_FINDER_TPHide:Disconnect() end end)
pcall(function() if getgenv().S2R_EGG_FINDER_TPHide2 then getgenv().S2R_EGG_FINDER_TPHide2:Disconnect() end end)
local function watchNew(d)
	if d:IsA("TextLabel") or d:IsA("TextButton") then
		task.defer(function() if isTpMsg(d.Text) then hideGameTpNotice(d) end end)
		-- si el texto se pone despues (el aviso se reutiliza), tambien se pilla
		if os.clock() < sweepUntil then
			local c
			c = d:GetPropertyChangedSignal("Text"):Connect(function()
				if isTpMsg(d.Text) then hideGameTpNotice(d) end
				if os.clock() > sweepUntil and c then c:Disconnect() end
			end)
		end
	end
end
if gamePg then getgenv().S2R_EGG_FINDER_TPHide = gamePg.DescendantAdded:Connect(watchNew) end
pcall(function() getgenv().S2R_EGG_FINDER_TPHide2 = game:GetService("CoreGui").DescendantAdded:Connect(watchNew) end)

local pendingJoin = nil -- { jobId, tries }: el ultimo JOIN, para reintentar si el server esta lleno
local JOIN_RETRIES = 6
local joinServer -- (se define justo debajo)
pcall(function() if getgenv().S2R_EGG_FINDER_TPConn then getgenv().S2R_EGG_FINDER_TPConn:Disconnect() end end)
getgenv().S2R_EGG_FINDER_TPConn = TeleportService.TeleportInitFailed:Connect(function(_, result, errorMessage)
	warn("[" .. TITLE .. "] TeleportInitFailed:", tostring(result), tostring(errorMessage))
	-- quita el aviso grande de Roblox y el del juego, y pone solo el nuestro
	pcall(function() game:GetService("GuiService"):ClearError() end)
	sweepSoon()
	if gui and gui.Parent then
		local msg = string.lower(tostring(errorMessage or "") .. " " .. tostring(result))
		local pj = pendingJoin
		if result == Enum.TeleportResult.GameFull or msg:find("full") then
			setStatus("Server full")
			lastTpNotify = os.clock()
			if forceKey then
				notify("SERVER FULL", "Retrying in a moment...", 3, "warn")
			elseif pj and pj.tries < JOIN_RETRIES then
				-- se vuelve a intentar entrar al MISMO server (alguien puede salir)
				pj.tries += 1
				notify("SERVER FULL", ("Retrying %d/%d..."):format(pj.tries, JOIN_RETRIES), 2, "warn")
				task.delay(1.2, function()
					if pendingJoin == pj and gui.Parent then joinServer(pj.jobId, true) end
				end)
			else
				pendingJoin = nil
				notify("SERVER FULL", "Pick another server", 3, "warn")
			end
		else
			setStatus("Join failed")
			-- fallo raro (teleport ocupado, red...): un par de reintentos rapidos
			if pj and pj.tries < 2 and not forceKey then
				pj.tries += 1
				task.delay(0.8, function()
					if pendingJoin == pj and gui.Parent then joinServer(pj.jobId, true) end
				end)
			end
		end
	end
end)

function joinServer(jobId, isRetry)
	jobId = tostring(jobId or "")
	if not isRetry then pendingJoin = { jobId = jobId, tries = 0 } end
	if jobId == "" or jobId == "nil" then
		warn("[" .. TITLE .. "] Join failed: empty jobId")
		return
	end
	if jobId == tostring(game.JobId) then
		warn("[" .. TITLE .. "] Already in this server")
		return
	end

	local placeId = game.PlaceId
	setStatus("Joining...")
	sweepSoon()

	-- Method 1: TeleportToPlaceInstance (player arg)
	local ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId, player, "", { S2R_EGG_FINDER = true })
	end)
	if ok then
		return
	end
	warn("[" .. TITLE .. "] Join method 1 failed:", err)

	-- Method 2: TeleportToPlaceInstance (no player arg)
	ok, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(placeId, jobId)
	end)
	if ok then
		return
	end
	warn("[" .. TITLE .. "] Join method 2 failed:", err)

	-- Method 3: request-based (some executors)
	local fn = (syn and syn.request) or http_request or request
	if fn then
		ok, err = pcall(function()
			fn({
				Url = "https://gamejoin.roblox.com/v1/join-game-instance",
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["User-Agent"] = "Roblox/WinInet",
				},
				Body = HttpService:JSONEncode({
					placeId = placeId,
					gameId = jobId,
				}),
			})
		end)
		if ok then
			-- Still need TeleportService after ticket in most cases; try again
			pcall(function()
				TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
			end)
			return
		end
		warn("[" .. TITLE .. "] Join method 3 failed:", err)
	end

	setStatus("Join failed")
	warn("[" .. TITLE .. "] All join methods failed for jobId:", jobId)
end

---------------------------------------------------------------------------
-- estado
---------------------------------------------------------------------------
local autoJoinState, autoForceState = false, false
local lastAutoJoinJob = nil
local ajSeen = {} -- pets que ya estaban (o ya se intentaron) al activar el Auto-Join
local ajBusyUntil = 0
local forceJobId, forceRun = nil, 0
local forceName = nil
local render, startForce, stopForce
local hidden = {}
local latest = {}
local ageLabels = {}
local forcingRow -- (se crea abajo)

local function keyOf(e)
	return e.jobId .. "|" .. e.name .. "|" .. tostring(e.ts)
end

stopForce = function()
	forceRun += 1
	forceKey, forceJobId, forceName = nil, nil, nil
	if forcingRow then forcingRow:set_text("None") end
end

startForce = function(key, jobId, name)
	forceRun += 1
	local myRun = forceRun
	forceKey, forceJobId, forceName = key, jobId, name
	if forcingRow then forcingRow:set_text(escapeRich(name or jobId)) end
	notify("FORCE", "Forcing " .. tostring(name or jobId), 2.5)
	task.spawn(function()
		while forceRun == myRun and autoForceState and gui.Parent do
			if jobId == game.JobId then
				stopForce()
				render(true)
				break
			end
			joinServer(jobId)
			task.wait(FORCE_INTERVAL)
		end
	end)
end

---------------------------------------------------------------------------
-- blacklist
---------------------------------------------------------------------------
local blModeToggle, blCountRow = nil, nil

local refreshFeedNames -- (se define abajo, con la lista "Choose pet")
local function refreshBlacklistUI()
	if refreshFeedNames then pcall(refreshFeedNames) end
	local names = blacklistNames()
	if blCountRow then blCountRow:set_text(tostring(#names)) end
end

local function setBlacklistMode(v, fromToggle)
	blacklistMode = v == true
	if updateFilterLabel then updateFilterLabel() end
	if blModeToggle and not fromToggle and blModeToggle:get_value() ~= blacklistMode then
		blModeToggle:set_value(blacklistMode, true)
	end
	if blacklistMode then
		setStatus("Click a log to blacklist")
	else
		setStatus("Connected")
	end
	render(true)
end

local function addBlacklist(name)
	if not name or name == "" then return end
	blacklist[name] = true
	saveBlacklist()
	refreshBlacklistUI()
	setStatus("Blacklisted: " .. tostring(name):sub(1, 18))
	notify("BLACKLISTED", tostring(name), 2.5)
end

local function removeBlacklist(name)
	if not name or not blacklist[name] then return end
	blacklist[name] = nil
	saveBlacklist()
	refreshBlacklistUI()
	setStatus("Unblacklisted: " .. tostring(name):sub(1, 16))
	notify("UNBLACKLISTED", tostring(name), 2.5)
	render(true)
end

---------------------------------------------------------------------------
-- filas del feed
---------------------------------------------------------------------------
local function clearRows()
	for _, c in ipairs(feed:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	table.clear(ageLabels)
end

local function subText(entry)
	local parts = {}
	table.insert(parts, formatAge(entry.ts))

	local rarityText = escapeRich(entry.rarity)
	if entry.rarityColor then
		rarityText = ("<font color=\"%s\">%s</font>"):format(richColor(entry.rarityColor), rarityText)
	end
	table.insert(parts, rarityText)
	return table.concat(parts, "  |  ")
end

local ROW_H = 50
-- estilo de cada fila del feed: tarjeta de cristal, plana o solo borde
local function rowStyle(f, st)
	if DSN.row == "outline" then
		f.BackgroundTransparency = 0.94
		st.Color = TH(255, 62, 70)
		st.Transparency = 0.35
	elseif DSN.row == "flat" then
		f.BackgroundColor3 = TH(60, 20, 26)
		f.BackgroundTransparency = 0.45
		st.Thickness = 0
	else
		kit.glassify(f, st)
	end
end

local function addRow(data, order)
	local row = new("Frame", { Parent = feed, LayoutOrder = order, Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = WHITE, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 2 }, { corner(12) })
	local rs = stroke(WHITE, 1, 0.35)
	rs.Parent = row
	rowStyle(row, rs)
	hover(row)

	-- linea roja a la izquierda
	local bar = new("Frame", { Parent = row, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0), Size = UDim2.fromOffset(3, 30), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, { corner(2) })
	new("UIGradient", { Parent = bar, Rotation = 90, Color = ColorSequence.new(TH(255, 120, 126), TH(120, 10, 22)) })

	-- icono
	local ih = new("Frame", { Parent = row, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 15, 0.5, 0), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = BLACK, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 3 }, { corner(8) })
	local ihs = stroke(WHITE, 1, 0.85)
	ihs.Parent = ih
	new("ImageLabel", { Parent = ih, Position = UDim2.fromOffset(3, 3), Size = UDim2.new(1, -6, 1, -6), BackgroundTransparency = 1, Image = data.iconId and ("rbxassetid://" .. tostring(data.iconId)) or "", ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })

	-- nombre + valor
	local title = txt(row, { Position = UDim2.fromOffset(60, 8), Size = UDim2.new(1, -262, 0, 18), Text = "", RichText = true, Font = FB, TextSize = 13, TextColor3 = WHITE, TextScaled = true, ZIndex = 3 })
	new("UITextSizeConstraint", { Parent = title, MaxTextSize = 13, MinTextSize = 8 })
	title.Text = ("%s  <font color=\"rgb(255,90,98)\">[ %s ]</font>"):format(escapeRich(data.name), formatValue(data.value))

	-- tiempo + rareza
	local sub = txt(row, { Position = UDim2.fromOffset(60, 28), Size = UDim2.new(1, -262, 0, 14), Text = "", RichText = true, Font = F, TextSize = 10, TextColor3 = K.mute, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3 })
	sub.Text = subText(data)
	table.insert(ageLabels, { label = sub, entry = data })

	-- botones: BL / JOIN / FORCE
	local canForce = autoForceState
	local selected = canForce and forceKey == data.key
	local forceStyle = "off"
	if selected then
		forceStyle = "on"
	elseif canForce then
		forceStyle = nil
	end
	local force = smallBtn(row, "FORCE", 58, forceStyle)
	force.Position = UDim2.new(1, -10, 0.5, 0)
	local join = smallBtn(row, "JOIN", 72, "red")
	join.Size = UDim2.fromOffset(72, 28)
	join.Position = UDim2.new(1, -74, 0.5, 0)
	local blBtn = smallBtn(row, "", 28, "block")
	blBtn.Size = UDim2.fromOffset(28, 28)
	blBtn.Position = UDim2.new(1, -152, 0.5, 0)

	onTap(join, function()
		sfx("tap")
		joinServer(data.jobId)
	end)

	onTap(force, function()
		if not autoForceState then
			notify("FORCE", "Turn on Auto-Force first (Auto tab)", 2.5, "warn")
			return
		end
		sfx("tap")
		if forceKey == data.key then
			stopForce()
		else
			startForce(data.key, data.jobId, data.name)
		end
		render(true)
	end)

	onTap(blBtn, function()
		if data.name and data.name ~= "" then
			sfx("tap")
			addBlacklist(data.name)
			render(true)
		end
	end)

	-- modo blacklist: tocar la fila la manda a la blacklist
	if blacklistMode then
		local pick = new("TextButton", { Parent = row, Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH(255, 50, 60), BackgroundTransparency = 0.55, AutoButtonColor = false, Text = "TAP TO BLACKLIST", Font = FB, TextSize = 11, TextColor3 = WHITE, ZIndex = 8, BorderSizePixel = 0 }, { corner(8) })
		local ps = stroke(WHITE, 1, 0.4)
		ps.Parent = pick
		onTap(pick, function()
			if data.name and data.name ~= "" then
				sfx("toggle_on")
				addBlacklist(data.name)
				setBlacklistMode(false)
				setStatus("Blacklisted: " .. tostring(data.name):sub(1, 18))
			end
		end)
	end
end

-- tarjeta grande para la vista Grid: foto grande, nombre, valor y JOIN debajo
local function addCard(data, order)
	local card = new("Frame", { Parent = feed, LayoutOrder = order, BackgroundColor3 = WHITE, BackgroundTransparency = 0.4, BorderSizePixel = 0, ZIndex = 2 }, { corner(14) })
	local cs = stroke(WHITE, 1, 0.35)
	cs.Parent = card
	rowStyle(card, cs)
	hover(card)

	-- foto
	local ih = new("Frame", { Parent = card, Position = UDim2.fromOffset(8, 8), Size = UDim2.new(1, -16, 0, 84), BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 3 }, { corner(8) })
	local ihs = stroke(WHITE, 1, 0.88)
	ihs.Parent = ih
	local shine = new("Frame", { Parent = ih, Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 3 }, { corner(8) })
	new("UIGradient", { Parent = shine, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.92), NumberSequenceKeypoint.new(1, 1) }) })
	if data.iconId then
		local pic = new("ImageLabel", { Parent = ih, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(72, 72), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(data.iconId), ScaleType = Enum.ScaleType.Fit, ZIndex = 4 })
		local psc = new("UIScale", { Parent = pic, Scale = 0.85 })
		tween(psc, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		txt(ih, { Size = UDim2.fromScale(1, 1), Text = "?", Font = FB, TextSize = 28, TextColor3 = K.mute, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 4 })
	end
	-- BL pequeño en la esquina de la foto
	local blBtn = smallBtn(ih, "", 22, "block")
	blBtn.Size = UDim2.fromOffset(22, 22)
	blBtn.Position = UDim2.new(1, -4, 0, 13)
	blBtn.ZIndex = 5

	-- nombre, valor, tiempo + rareza
	local name = txt(card, { Position = UDim2.fromOffset(8, 96), Size = UDim2.new(1, -16, 0, 16), Text = tostring(data.name), Font = FB, TextSize = 12, TextScaled = true, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
	new("UITextSizeConstraint", { Parent = name, MaxTextSize = 12, MinTextSize = 7 })
	txt(card, { Position = UDim2.fromOffset(8, 112), Size = UDim2.new(1, -16, 0, 14), Text = formatValue(data.value), Font = FB, TextSize = 11, TextColor3 = TH(255, 110, 118), TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 3 })
	local sub = txt(card, { Position = UDim2.fromOffset(8, 127), Size = UDim2.new(1, -16, 0, 12), Text = "", RichText = true, Font = F, TextSize = 9, TextColor3 = K.mute, TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3 })
	sub.Text = subText(data)
	table.insert(ageLabels, { label = sub, entry = data })

	-- JOIN debajo (y FORCE al lado si Auto-Force esta encendido)
	local join = smallBtn(card, "JOIN", 10, "red")
	join.AnchorPoint = Vector2.new(0, 1)
	join.Position = UDim2.new(0, 8, 1, -8)
	join.Size = autoForceState and UDim2.new(0.5, -11, 0, 26) or UDim2.new(1, -16, 0, 26)
	onTap(join, function()
		sfx("tap")
		joinServer(data.jobId)
	end)
	if autoForceState then
		local selected = forceKey == data.key
		local force = smallBtn(card, "FORCE", 10, selected and "on" or nil)
		force.AnchorPoint = Vector2.new(1, 1)
		force.Position = UDim2.new(1, -8, 1, -8)
		force.Size = UDim2.new(0.5, -11, 0, 26)
		onTap(force, function()
			sfx("tap")
			if forceKey == data.key then
				stopForce()
			else
				startForce(data.key, data.jobId, data.name)
			end
			render(true)
		end)
	end
	onTap(blBtn, function()
		if data.name and data.name ~= "" then
			sfx("tap")
			addBlacklist(data.name)
			render(true)
		end
	end)

	if blacklistMode then
		local pick = new("TextButton", { Parent = card, Size = UDim2.fromScale(1, 1), BackgroundColor3 = TH(255, 50, 60), BackgroundTransparency = 0.55, AutoButtonColor = false, Text = "TAP TO\nBLACKLIST", TextWrapped = true, Font = FB, TextSize = 12, TextColor3 = WHITE, ZIndex = 8, BorderSizePixel = 0 }, { corner(10) })
		local ps = stroke(WHITE, 1.2, 0.3)
		ps.Parent = pick
		onTap(pick, function()
			if data.name and data.name ~= "" then
				sfx("toggle_on")
				addBlacklist(data.name)
				setBlacklistMode(false)
				setStatus("Blacklisted: " .. tostring(data.name):sub(1, 18))
			end
		end)
	end
end

local lastSig = nil

function render(forceRebuild)
	local vis = {}
	for _, e in ipairs(latest) do
		if not hidden[keyOf(e)] and not isBlacklisted(e) and passesFilter(e) then
			vis[#vis + 1] = e
		end
	end
	local count = math.min(#vis, MAX_ITEMS)

	-- solo se reconstruye la lista si algo cambio (asi no parpadea cada segundo)
	local parts = { viewMode, tostring(autoForceState), tostring(forceKey), tostring(blacklistMode) }
	for i = 1, count do
		parts[#parts + 1] = vis[i].key
	end
	local sig = table.concat(parts, "#")
	if forceRebuild or sig ~= lastSig then
		lastSig = sig
		local scroll = feed.CanvasPosition
		clearRows()
		for i = 1, count do
			if viewMode == "grid" then addCard(vis[i], i) else addRow(vis[i], i) end
		end
		feed.CanvasPosition = scroll
	end
	detectedLabel.Text = #vis .. " detected"
	emptyLabel.Visible = #vis == 0

	-- Auto-Join: solo cuentan los pets que salen DESPUES de activarlo (los de antes se ignoran)
	if autoJoinState and #latest > 0 and os.clock() >= ajBusyUntil then
		for _, e in ipairs(latest) do
			if not ajSeen[e.key] then
				ajSeen[e.key] = true
				local jid = tostring(e.jobId)
				if not hidden[keyOf(e)] and not isBlacklisted(e) and passesAutoJoin(e) and jid ~= tostring(game.JobId) then
					lastAutoJoinJob = jid
					ajBusyUntil = os.clock() + 4 -- mientras entra, no salta a otro
					notify("AUTO-JOIN", tostring(e.name) .. "  " .. formatValue(e.value), 2, "ok")
					joinServer(jid)
					break
				end
			end
		end
	end
end

onTap(clearBtn, function()
	sfx("tap")
	for _, e in ipairs(latest) do
		hidden[keyOf(e)] = true
	end
	render(true)
	notify("FEED", "Cleared", 1.6)
end)

local viewDrop -- (desplegable "Feed view" de Settings)
local function setView(m)
	if viewMode == m then return end
	viewMode = m
	if viewDrop then pcall(function() viewDrop:set_value(m == "grid" and "Grid" or "List", true) end) end
	pcall(function() if writefile then writefile(VIEW_FILE, m) end end)
	sfx("tap")
	paintSeg(true)
	applyLayout()
	feed.CanvasPosition = Vector2.new()
	render(true)
end
do
	local segHit = new("TextButton", { Parent = seg, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false, Text = "", ZIndex = 6 })
	local drag -- { input, x0, moved }
	local function relX(px) return math.clamp((px - seg.AbsolutePosition.X) / math.max(seg.AbsoluteSize.X, 1), 0, 1) end
	segHit.InputBegan:Connect(function(i)
		if kit.isPress(i) and not drag then drag = { input = i, x0 = i.Position.X, moved = false } end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if not drag then return end
		if drag.input.UserInputType == Enum.UserInputType.Touch then
			if i ~= drag.input then return end
		elseif i.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		if math.abs(i.Position.X - drag.x0) > 5 then drag.moved = true end
		if drag.moved then
			-- la pastilla sigue al dedo
			local a = math.clamp(relX(i.Position.X) - 0.25, 0, 0.5)
			segPill.Position = UDim2.new(a, math.floor(2 * (1 - a / 0.5) + 0.5), 0, 2)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if not drag then return end
		local same = (drag.input.UserInputType == Enum.UserInputType.Touch and i == drag.input)
			or (drag.input.UserInputType == Enum.UserInputType.MouseButton1 and i.UserInputType == Enum.UserInputType.MouseButton1)
		if not same then return end
		local target = relX(i.Position.X) >= 0.5 and "grid" or "list"
		drag = nil
		if target == viewMode then paintSeg(true) else setView(target) end
	end)
end

-- ===== panel de FILTERS (boton del Finder): rareza + blacklist con chips =====
local RARITY_FIRST = { "Secret", "Eternal", "Divine", "Celestial", "OG", "Brainrot God", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }
local function rarityOptions()
	local set = { Secret = true, Eternal = true, Divine = true }
	for _, r in pairs(rarityByName) do if type(r) == "string" then set[r] = true end end
	for _, e in ipairs(latest) do if e.rarity then set[tostring(e.rarity)] = true end end
	for r in pairs(rarityFilter) do set[r] = true end
	local out, used = {}, {}
	for _, r in ipairs(RARITY_FIRST) do
		if set[r] then out[#out + 1] = r used[r] = true end
	end
	local rest = {}
	for r in pairs(set) do if not used[r] then rest[#rest + 1] = r end end
	table.sort(rest)
	for _, r in ipairs(rest) do out[#out + 1] = r end
	return out
end

local FP_W = 268
local fPanel = new("Frame", { Parent = feedBox, Position = UDim2.new(1, 10, 0, 38), Size = UDim2.new(0, FP_W, 1, -44), BackgroundColor3 = WHITE, BackgroundTransparency = 0.06, BorderSizePixel = 0, Active = true, Visible = false, ZIndex = 20 }, { corner(14) })
do
	local fs = stroke(WHITE, 1.2, 0.2)
	fs.Parent = fPanel
	kit.glassify(fPanel, fs)
end
txt(fPanel, { Position = UDim2.fromOffset(14, 6), Size = UDim2.new(1, -60, 0, 16), Text = "Filters", Font = FB, TextSize = 13, TextColor3 = WHITE, ZIndex = 21 })
txt(fPanel, { Position = UDim2.fromOffset(14, 22), Size = UDim2.new(1, -60, 0, 13), Text = "Choose what you want to see", Font = F, TextSize = 10, TextColor3 = K.mute, ZIndex = 21 })
local fClose = new("TextButton", { Parent = fPanel, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, AutoButtonColor = false, Text = "", ZIndex = 22 }, { corner(13) })
new("Frame", { Parent = fClose, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(11, 2), Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 23 }, { corner(1) })
new("Frame", { Parent = fClose, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(11, 2), Rotation = -45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 23 }, { corner(1) })
local fScroll = new("ScrollingFrame", { Parent = fPanel, Position = UDim2.fromOffset(0, 42), Size = UDim2.new(1, 0, 1, -42), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = WHITE, ScrollBarImageTransparency = 0.5, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 21 })
new("UIListLayout", { Parent = fScroll, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder })
new("UIPadding", { Parent = fScroll, PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

-- tarjeta con titulo, explicacion corta y una cuadricula dentro
local function fCard(order, title, hint, cell, pad)
	local card = new("Frame", { Parent = fScroll, LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = BLACK, BackgroundTransparency = 0.6, BorderSizePixel = 0, ZIndex = 21 }, { corner(12) })
	local cs = stroke(TH(255, 62, 70), 1, 0.65)
	cs.Parent = card
	new("UIPadding", { Parent = card, PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
	new("UIListLayout", { Parent = card, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
	local h = new("Frame", { Parent = card, LayoutOrder = 1, Size = UDim2.new(1, 0, 0, title ~= "" and 30 or 0), BackgroundTransparency = 1, ZIndex = 21 })
	if title ~= "" then
		txt(h, { Size = UDim2.new(1, 0, 0, 15), Text = title, Font = FB, TextSize = 12, TextColor3 = WHITE, ZIndex = 21 })
		txt(h, { Position = UDim2.fromOffset(0, 15), Size = UDim2.new(1, 0, 0, 13), Text = hint, Font = F, TextSize = 9, TextColor3 = K.mute, ZIndex = 21 })
	end
	local grid = new("Frame", { Parent = card, LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, ZIndex = 21 })
	new("UIGridLayout", { Parent = grid, CellSize = cell, CellPadding = UDim2.fromOffset(pad or 6, pad or 6), SortOrder = Enum.SortOrder.LayoutOrder })
	return grid
end

-- chip de rareza: punto con el color de la rareza; al elegirla se enciende con el color del tema
local function rarityChip(parent, order, r, on, onClick)
	local col = rarityColor[r] or Color3.fromRGB(200, 200, 210)
	local b = new("TextButton", { Parent = parent, LayoutOrder = order, BackgroundColor3 = GLASS_BTN, BackgroundTransparency = 0.3, AutoButtonColor = false, Text = "", ZIndex = 22 }, { corner(14) })
	local st = stroke(WHITE, 1, 0.65)
	st.Parent = b
	kit.joinGlass(b, st, 22)
	local fill = new("Frame", { Parent = b, Size = UDim2.fromScale(1, 1), BackgroundColor3 = col, BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 22 }, { corner(14) })
	new("UIGradient", { Parent = fill, Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.7) }) })
	local dot = new("Frame", { Parent = b, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0), Size = UDim2.fromOffset(10, 10), BackgroundColor3 = col, BorderSizePixel = 0, ZIndex = 23 }, { corner(5) })
	local ds = stroke(WHITE, 1, 0.5)
	ds.Parent = dot
	local l = txt(b, { Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -32, 1, 0), Text = tostring(r), Font = FB, TextSize = 11, TextColor3 = K.soft, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 23 })
	local sc = new("UIScale", { Parent = b })
	local state = on == true
	local function paint(t)
		tween(fill, t, { BackgroundTransparency = state and 0 or 1 })
		tween(st, t, { Transparency = state and 0.1 or 0.65, Color = state and col or WHITE })
		tween(l, t, { TextColor3 = state and WHITE or K.mute })
	end
	paint(0)
	onTap(b, function()
		state = not state
		sfx(state and "toggle_on" or "toggle_off")
		sc.Scale = 0.9
		tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		paint(0.2)
		onClick(state)
	end)
end

-- foto de un pet (del feed o del juego)
local function iconFor(name)
	for _, e in ipairs(latest) do
		if e.name == name and e.iconId then return e.iconId end
	end
	return iconByName[name]
end
-- tarjeta de pet con foto: al tocarla se oculta (sale tachada en rojo) o vuelve a verse
local function petTile(parent, order, name, hiddenNow, onClick)
	local b = new("TextButton", { Parent = parent, LayoutOrder = order, BackgroundColor3 = BLACK, BackgroundTransparency = 0.55, AutoButtonColor = false, Text = "", ZIndex = 22 }, { corner(12) })
	local st = stroke(WHITE, 1, 0.8)
	st.Parent = b
	kit.joinGlass(b, st, 22)
	local icon = iconFor(name)
	local pic
	if icon then
		pic = new("ImageLabel", { Parent = b, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(42, 42), BackgroundTransparency = 1, Image = "rbxassetid://" .. tostring(icon), ScaleType = Enum.ScaleType.Fit, ZIndex = 23 })
	else
		pic = txt(b, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(42, 42), Text = "?", Font = FB, TextSize = 22, TextColor3 = K.mute, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23 })
	end
	local nm = txt(b, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -8, 0, 14), Text = tostring(name), Font = FB, TextSize = 10, TextScaled = true, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 23 })
	new("UITextSizeConstraint", { Parent = nm, MaxTextSize = 10, MinTextSize = 6 })
	-- marca de "oculto": circulo rojo con una X en la esquina
	local badge = new("Frame", { Parent = b, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = TH(235, 40, 52), BorderSizePixel = 0, ZIndex = 24 }, { corner(8) })
	new("Frame", { Parent = badge, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 2), Rotation = 45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 25 }, { corner(1) })
	new("Frame", { Parent = badge, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(9, 2), Rotation = -45, BackgroundColor3 = WHITE, BorderSizePixel = 0, ZIndex = 25 }, { corner(1) })
	local bsc = new("UIScale", { Parent = badge })
	local sc = new("UIScale", { Parent = b })
	local state = hiddenNow == true
	local function paint(t)
		bsc.Scale = state and 1 or 0
		if t > 0 and state then bsc.Scale = 0.3 tween(bsc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back) end
		tween(st, t, { Transparency = state and 0.1 or 0.8, Color = state and TH(255, 62, 70) or WHITE })
		tween(b, t, { BackgroundTransparency = state and 0.3 or 0.55 })
		if pic:IsA("ImageLabel") then tween(pic, t, { ImageTransparency = state and 0.6 or 0 }) end
		tween(nm, t, { TextTransparency = state and 0.45 or 0 })
	end
	paint(0)
	onTap(b, function()
		state = not state
		sfx(state and "toggle_on" or "toggle_off")
		sc.Scale = 0.92
		tween(sc, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
		paint(0.2)
		onClick(state)
	end)
end

local rarWrap = fCard(1, "Rarities", "Only show these (none = all)", UDim2.new(0.5, -3, 0, 30))
local blWrap = fCard(2, "Hide pets", "Tap a pet to hide it", UDim2.new(1 / 3, -4, 0, 74))
local actWrap = fCard(3, "", "", UDim2.new(1, 0, 0, 28))
local typeBox = new("TextBox", { Parent = fScroll, LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = GLASS_BTN, BackgroundTransparency = 0.15, Text = "", PlaceholderText = "Pet name + Enter to hide", PlaceholderColor3 = K.mute, TextColor3 = WHITE, Font = F, TextSize = 11, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22 }, { corner(15) })
new("UIPadding", { Parent = typeBox, PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) })
do local ts = stroke(WHITE, 1, 0.6) ts.Parent = typeBox end

local rarSig, blSig = "", ""
local function rebuildChips(force)
	local ro = rarityOptions()
	local s1 = table.concat(ro, "|")
	if force or s1 ~= rarSig then
		rarSig = s1
		for _, c in ipairs(rarWrap:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for i, r in ipairs(ro) do
			rarityChip(rarWrap, i, r, rarityFilter[r], function(on)
				if on then rarityFilter[r] = true else rarityFilter[r] = nil end
				saveFilter()
				if updateFilterLabel then updateFilterLabel() end
				render(true)
			end)
		end
	end
	local seen, names = {}, {}
	for _, e in ipairs(latest) do
		if e.name and not seen[e.name] then seen[e.name] = true names[#names + 1] = e.name end
	end
	for n in pairs(blacklist) do
		if not seen[n] then seen[n] = true names[#names + 1] = n end
	end
	table.sort(names)
	local s2 = table.concat(names, "|") .. "#" .. table.concat(blacklistNames(), "|")
	if force or s2 ~= blSig then
		blSig = s2
		for _, c in ipairs(blWrap:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for i, n in ipairs(names) do
			petTile(blWrap, i, n, blacklist[n], function(on)
				if on then blacklist[n] = true else blacklist[n] = nil end
				saveBlacklist()
				blSig = table.concat(names, "|") .. "#" .. table.concat(blacklistNames(), "|")
				notify(on and "BLACKLISTED" or "UNBLACKLISTED", tostring(n), 1.6)
				render(true)
			end)
		end
	end
end
refreshFeedNames = function()
	if fPanel.Visible then rebuildChips(false) end
end

local fOpen = false
updateFilterLabel = function()
	if blacklistMode then
		blHeadLbl.Text = "Done"
		return
	end
	local n = 0
	for _ in pairs(rarityFilter) do n += 1 end
	blHeadLbl.Text = fOpen and "Close" or (n > 0 and ("Filters (" .. n .. ")") or "Filters")
end
local function setFilters(on)
	fOpen = on
	if on then
		rebuildChips(true)
		fPanel.Visible = true
		fPanel.Position = UDim2.new(1, 10, 0, 38)
		tween(fPanel, 0.45, { Position = UDim2.new(1, -(FP_W + 6), 0, 38) }, Enum.EasingStyle.Quint)
		sfx("open")
	else
		tween(fPanel, 0.35, { Position = UDim2.new(1, 10, 0, 38) }, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		task.delay(0.36, function() if not fOpen then fPanel.Visible = false end end)
		sfx("close")
	end
	updateFilterLabel()
end
updateFilterLabel()

-- botones rapidos (mismo ancho, en una fila)
do
	local function actBtn(order, text, fn)
		local b = smallBtn(actWrap, text, 10)
		b.AnchorPoint = Vector2.new(0, 0)
		b.LayoutOrder = order
		b.ZIndex = 22
		onTap(b, fn)
	end
	actBtn(1, "Tap a log", function()
		setFilters(false)
		setBlacklistMode(true)
		notify("BLACKLIST MODE", "Tap a pet in the feed to hide it", 2.5)
	end)
	actBtn(2, "Unhide all", function()
		table.clear(blacklist)
		saveBlacklist()
		refreshBlacklistUI()
		rebuildChips(true)
		notify("BLACKLIST", "All pets visible again", 2, "ok")
		render(true)
	end)
	actBtn(3, "All rarities", function()
		table.clear(rarityFilter)
		saveFilter()
		rebuildChips(true)
		updateFilterLabel()
		render(true)
	end)
end
typeBox.FocusLost:Connect(function(enter)
	local t = tostring(typeBox.Text or ""):match("^%s*(.-)%s*$")
	if enter and t ~= "" then
		addBlacklist(t)
		typeBox.Text = ""
		rebuildChips(true)
		render(true)
	end
end)
onTap(fClose, function() setFilters(false) end)

onTap(blHeadBtn, function()
	sfx("tap")
	if blacklistMode then
		setBlacklistMode(false)
	else
		setFilters(not fOpen)
	end
end)

---------------------------------------------------------------------------
-- controles (pestañas Auto e Info)
---------------------------------------------------------------------------
AG:create_toggle("auto_join", {
	title = "Auto-Join",
	description = "Only new pets from now on",
	default = false,
	callback = function(v)
		autoJoinState = v
		if v then
			-- todo lo que ya esta en el feed cuenta como viejo: solo se entra a los que salgan a partir de ahora
			ajSeen = {}
			for _, e in ipairs(latest) do ajSeen[e.key] = true end
			ajBusyUntil = 0
			notify("AUTO-JOIN", "Waiting for new pets...", 2, "info")
		end
		render()
	end,
})
-- rarezas para el Auto-Join: al activarlo te mete solo en servers con esas rarezas en cuanto salgan
local function ajList()
	local l = {}
	for r in pairs(autoJoinRarity) do l[#l + 1] = r end
	table.sort(l)
	return l
end
local ajMulti = AG:create_multi("aj_rarity", {
	title = "Join rarity",
	description = "Auto-Join only these",
	none_text = "Any",
	options = rarityOptions(),
	default = ajList(),
	callback = function(list)
		autoJoinRarity = {}
		for _, r in ipairs(list) do autoJoinRarity[r] = true end
		saveAutoJoin()
		lastAutoJoinJob = nil
		render()
	end,
})
local ajSig = ""
local function refreshAJOptions()
	local o = rarityOptions()
	local sig = table.concat(o, "|")
	if sig ~= ajSig then
		ajSig = sig
		ajMulti:set_options(o)
	end
end

local autoForceToggle = AG:create_toggle("auto_force", {
	title = "Auto-Force",
	description = "Enables FORCE on the feed",
	default = false,
	callback = function(v)
		autoForceState = v
		if not v then
			stopForce()
		end
		render(true)
	end,
})
local forceSlider = AG:create_slider("force_interval", {
	title = "Force interval",
	minimum = 1,
	maximum = 10,
	default = FORCE_INTERVAL,
	rounding = true,
	suffix = "s",
	callback = function(v)
		FORCE_INTERVAL = v
	end,
})
UI:link(autoForceToggle, { forceSlider }, true)
forcingRow = AG:create_label("forcing", { title = "Forcing", text = "None" })

refreshBlacklistUI()

SG:create_toggle("auto_post", {
	title = "Auto Post",
	description = "Sends good pets from your server",
	default = AUTO_POST,
	callback = function(v)
		AUTO_POST = v
	end,
})

HG:create_label("author", { title = "Author", text = AUTHOR })
local STYLE_FILE = "S2R_EGG_FINDER_Style.json"
local style = { scale = 100, glass = 0, logo = true, blur = true, sounds = true } -- glass 0 = el del diseño
pcall(function()
	if isfile and readfile and isfile(STYLE_FILE) then
		local d = HttpService:JSONDecode(readfile(STYLE_FILE))
		if type(d) == "table" then for k, v in pairs(d) do if style[k] ~= nil and type(v) == type(style[k]) then style[k] = v end end end
	end
end)
local saveToken = 0
local function saveStyle()
	saveToken += 1
	local my = saveToken
	task.delay(0.5, function()
		if my ~= saveToken or not writefile then return end
		pcall(function() writefile(STYLE_FILE, HttpService:JSONEncode(style)) end)
	end)
end
pcall(function()
	UI:set_user_scale(style.scale / 100)
	UI:set_bg_logo(style.logo)
	UI:set_blur(style.blur)
	UI:set_sounds(style.sounds)
end)

viewDrop = IG:create_dropdown("feed_view", {
	title = "Feed view",
	description = "List or big icons",
	options = { "List", "Grid" },
	default = viewMode == "grid" and "Grid" or "List",
	callback = function(v)
		setView(v == "Grid" and "grid" or "list")
	end,
})
local scaleSlider = IG:create_slider("ui_scale", {
	title = "UI Scale",
	minimum = 40,
	maximum = 160,
	default = style.scale,
	rounding = true,
	suffix = "%",
	callback = function(v)
		style.scale = v
		saveStyle()
		UI:set_user_scale(v / 100)
	end,
})
-- si se agranda con la flecha de la esquina, el slider se mueve solo
UI._onUserScale = function(x)
	style.scale = math.floor(x * 100 + 0.5)
	saveStyle()
	pcall(function() scaleSlider:set_value(style.scale, true) end)
end
IG:create_toggle("ui_logo", {
	title = "Background logo",
	description = "S2R_EGG_FINDER logo behind the panel",
	default = style.logo,
	callback = function(v)
		style.logo = v
		saveStyle()
		UI:set_bg_logo(v)
	end,
})
IG:create_toggle("ui_blur", {
	title = "Blur game",
	description = "Blurs the game while open",
	default = style.blur,
	callback = function(v)
		style.blur = v
		saveStyle()
		UI:set_blur(v)
	end,
})
IG:create_toggle("ui_sounds", {
	title = "Sounds",
	description = "Taps and toggle sounds",
	default = style.sounds,
	callback = function(v)
		style.sounds = v
		saveStyle()
		UI:set_sounds(v)
	end,
})
-- diseño completo, tema de color y letra: se guardan y el panel se vuelve a montar con el estilo nuevo
UI._onDestroy = function()
	forceRun += 1
	autoJoinState, autoForceState = false, false
	pcall(function() if getgenv().S2R_EGG_FINDER_TPConn then getgenv().S2R_EGG_FINDER_TPConn:Disconnect() getgenv().S2R_EGG_FINDER_TPConn = nil end end)
	pcall(function() if getgenv().S2R_EGG_FINDER_TPHide then getgenv().S2R_EGG_FINDER_TPHide:Disconnect() getgenv().S2R_EGG_FINDER_TPHide = nil end end)
	pcall(function() if getgenv().S2R_EGG_FINDER_TPHide2 then getgenv().S2R_EGG_FINDER_TPHide2:Disconnect() getgenv().S2R_EGG_FINDER_TPHide2 = nil end end)
end
local DESIGN_FILE = "S2R_EGG_FINDER_Design.json"
local DSel = getgenv().S2R_EGG_FINDER_Design or {}
local function applyDesign(field, value)
	if DSel[field] == value then return end
	DSel[field] = value
	if field == "design" then style.glass = 0 saveStyle() end
	pcall(function() if writefile then writefile(DESIGN_FILE, HttpService:JSONEncode(DSel)) end end)
	notify("STYLE", "Applying " .. tostring(value) .. "...", 1.4, "ok")
	task.delay(0.35, function()
		if getgenv().S2R_EGG_FINDER_Rebuild then getgenv().S2R_EGG_FINDER_Rebuild() end
	end)
end
local designDrop = IG:create_dropdown("ui_design", {
	title = "Design",
	description = "10 complete UI styles",
	options = Library.DESIGN_ORDER,
	default = DSel.design or "Liquid",
	callback = function(v) applyDesign("design", v) end,
})
local themeDrop = IG:create_dropdown("ui_theme", {
	title = "Theme",
	description = "Main color",
	options = Library.THEME_ORDER,
	default = DSel.theme or "Purple",
	callback = function(v) applyDesign("theme", v) end,
})
local fontDrop = IG:create_dropdown("ui_font", {
	title = "Font",
	description = "Text style",
	options = Library.FONT_ORDER,
	default = DSel.font or "Code",
	callback = function(v) applyDesign("font", v) end,
})

---------------------------------------------------------------------------
-- datos
---------------------------------------------------------------------------
local function fetchPets()
	local body = httpGet(API_URL)
	if not body then
		return false
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end

	local list = {}
	for _, p in ipairs(decoded) do
		if p.petName and p.jobId and tonumber(p.value) then
			local name = tostring(p.petName)
			local rarity = getRarity(name)
				or (p.rarity and tostring(p.rarity))
				or DEFAULT_RARITY
			table.insert(list, {
				name = name,
				value = tonumber(p.value),
				jobId = tostring(p.jobId),
				iconId = p.iconId,
				key = tostring(p.jobId) .. "|" .. name .. "|" .. tostring(p.timestamp),
				ts = tonumber(p.timestamp) or (os.time() * 1000),
				rarity = rarity,
				rarityColor = getRarityColor(name),
			})
		end
	end
	table.sort(list, function(a, b)
		return (a.ts or 0) > (b.ts or 0)
	end)
	latest = list
	return true
end

local postedAt = {}
local postOk, postFail, scanCount, lastPostStatus = 0, 0, 0, "-"
local postPauseUntil = 0

local VALUE_PATTERN = "^%s*%$?%s*([%d%.,]+)%s*([KkMmBbTt]?)%s*/%s*[sS]%s*$"
local UNIT_MUL = { K = 1e3, M = 1e6, B = 1e9, T = 1e12 }

local function parseValue(text)
	local clean = tostring(text):gsub("<[^>]+>", "")
	local num, unit = clean:match(VALUE_PATTERN)
	if not num then
		return nil
	end
	local n = tonumber((num:gsub(",", "")))
	if not n then
		return nil
	end
	return n * (UNIT_MUL[unit:upper()] or 1)
end

local function resolveName(inst)
	local cur = inst.Parent
	for _ = 1, 8 do
		if not cur or cur == workspace then
			return nil
		end
		local key = displayByName[cur.Name] and cur.Name or nil
		if not key then
			for _, ch in ipairs(cur:GetChildren()) do
				if ch:IsA("TextLabel") then
					local t = tostring(ch.Text):gsub("<[^>]+>", "")
					t = t:match("^%s*(.-)%s*$")
					if displayByName[t] then
						key = t
						break
					end
				end
			end
		end
		if key then
			return displayByName[key], iconByName[key]
		end
		cur = cur.Parent
	end
	return nil
end

local function scanPets()
	local found, seen, n = {}, {}, 0
	for _, d in ipairs(workspace:GetDescendants()) do
		n += 1
		if n % 3000 == 0 then
			task.wait()
		end
		if d:IsA("TextLabel") then
			local value = parseValue(d.Text)
			if value and value >= POST_MIN_VALUE then
				local name, icon = resolveName(d)
				if name then
					local k = name .. "|" .. math.floor(value)
					if not seen[k] then
						seen[k] = true
						table.insert(found, { name = name, value = value, icon = icon })
					end
				end
			end
		end
	end
	return found
end

local function alreadyListed(name, value)
	for _, e in ipairs(latest) do
		if e.jobId == game.JobId and e.name == name and math.abs(e.value - value) <= value * 0.05 then
			return true
		end
	end
	return false
end

local function httpPost(url, body)
	local fn = (syn and syn.request) or http_request or request
	if not fn then
		return nil, "no request fn"
	end
	local ok, res = pcall(fn, {
		Url = url,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = body,
	})
	if ok and type(res) == "table" then
		return tonumber(res.StatusCode), res.Body
	end
	return nil, tostring(res)
end

task.spawn(function()
	while gui.Parent do
		if not AUTO_POST or game.JobId == "" then
			postRow:set_text("Post: off")
		elseif os.clock() >= postPauseUntil then
			local ok, found = pcall(scanPets)
			if ok then
				scanCount = #found
				for _, pet in ipairs(found) do
					local key = game.JobId .. "|" .. pet.name .. "|" .. math.floor(pet.value)
					local last = postedAt[key]
					if (not last or os.clock() - last > POST_COOLDOWN) and not alreadyListed(pet.name, pet.value) then
						postedAt[key] = os.clock()
						local body = HttpService:JSONEncode({
							petName = pet.name,
							value = pet.value,
							jobId = game.JobId,
							iconId = pet.icon and tostring(pet.icon) or "",
							timestamp = os.time() * 1000,
						})
						local status, resp = httpPost(POST_URL, body)
						if status and status >= 200 and status < 300 then
							postOk += 1
						else
							postFail += 1
							postedAt[key] = os.clock() - POST_COOLDOWN + 60
							if status == 429 then
								postPauseUntil = os.clock() + 30
							end
						end
						lastPostStatus = status and tostring(status) or tostring(resp):sub(1, 14)
						if status == 429 then
							break
						end
						task.wait(0.5)
					end
				end
			else
				warn("[" .. TITLE .. "] Scan gagal:", found)
			end
			postRow:set_text(("Scan:%d Post:%d/%d (%s)"):format(scanCount, postOk, postOk + postFail, lastPostStatus))
		end
		task.wait(POST_SCAN_INTERVAL)
	end
end)

task.spawn(function()
	while gui.Parent do
		for _, item in ipairs(ageLabels) do
			if item.label.Parent then
				item.label.Text = subText(item.entry)
			end
		end
		task.wait(1)
	end
end)

task.spawn(function()
	while gui.Parent do
		local ok = fetchPets()
		if not blacklistMode then
			setStatus(ok and "Connected" or "Disconnected")
		end
		if ok then
			render()
			if refreshFeedNames then pcall(refreshFeedNames) end
			pcall(refreshAJOptions)
		end
		task.wait(REFRESH_INTERVAL)
	end
end)

-- fin de la carga: la intro termina y se abre el panel
pcall(function() getgenv().S2R_EGG_FINDER_LoadDone() end)

end
getgenv().S2R_EGG_FINDER_Rebuild = function()
	local ok, err = pcall(S2R_EGG_FINDER_MAIN)
	if not ok then warn("[S2R_EGG_FINDER] rebuild error: " .. tostring(err)) end
end
S2R_EGG_FINDER_MAIN()