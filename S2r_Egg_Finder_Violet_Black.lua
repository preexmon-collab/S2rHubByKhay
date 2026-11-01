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
	Red = { h = 0.985, s = 1 }, Blue = { h = 0.6, s = 1 }, Purple = { h = 0.77, s = 1 }, Green = { h = 0.38, s = 0.9 }, Gold = { h = 0.12, s = 0.95 },
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
local INK = Color3.fromRGB(9, 9, 13) -- negro azulado del fondo del cristal
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
	local PANEL_BG_JPG = "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"
	local function embeddedBg(onFail)
		task.spawn(function()
			local ok = false
			pcall(function()
				local custom = getcustomasset or getsynasset
				if not (custom and writefile and isfile) then return end
				local function dec(str)
					local native
					pcall(function() native = (crypt and (crypt.base64decode or (crypt.base64 and crypt.base64.decode))) or base64_decode end)
					if native then
						local okd, r = pcall(native, str)
						if okd and type(r) == "string" and #r > 0 then return r end
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
				pcall(function() if makefolder and isfolder and not isfolder("S2R_EGG_FINDER") then makefolder("S2R_EGG_FINDER") end end)
				local path = "S2R_EGG_FINDER/panel_bg_v1.jpg"
				if not isfile(path) then writefile(path, dec(PANEL_BG_JPG)) end
				local c = custom(path)
				if type(c) == "string" and c ~= "" then
					bgImg.Image = c
					bgImg.Visible = true
					ok = true
				end
			end)
			if not ok and onFail then onFail() end
		end)
	end
	pcall(function()
		if getgenv().S2R_EGG_FINDER_ResolveImage then
			local function viaId()
				getgenv().S2R_EGG_FINDER_ResolveImage(84274209587973, bgImg, function(c) bgImg.Image = c end, function()
					bgImg.Visible = false -- no cargo: panel negro limpio
				end)
			end
			-- 1) la foto metida en el script  2) el enlace de catbox  3) el id de Roblox  4) negro limpio
			embeddedBg(function()
				if getgenv().S2R_EGG_FINDER_UrlImage then
					getgenv().S2R_EGG_FINDER_UrlImage("https://files.catbox.moe/usp8cw.png", bgImg, function(c) bgImg.Image = c end, viaId)
				else
					viaId()
				end
			end)
		else
			bgImg.Image = "rbxassetid://84274209587973"
		end
	end)
	-- (el fondo se queda quieto: sin zoom ni movimiento)
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
		if D.bg ~= "logo" then on = false end
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