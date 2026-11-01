-- John Hub | COMPLETE Chilli Finder live-feed port
-- Source: section 52_finder#1 from the user-provided Chilli Hub script.
-- Finder-only: the farm/event/admin/predictor sections are not included.
-- The live feed belongs to chillihub.pro and requires a valid existing booking.
-- Run in the intended Roblox game with an executor supporting request/http_request.
local CODE = [=======[
-- JOHN HUB | Original Chilli Finder live-feed engine (user-provided source).
-- Visual branding adapted; existing ChilliFinder account/booking remains required.
-- Backend session/API communications preserved. No license or authorization bypass.
local function JohnHubRunSource()
		local ctx2 = {}
		local gameRef2 = game

		local function getService2(serviceName)
			return gameRef2:GetService(serviceName)
		end

		local Players2, ReplicatedStorage2 = getService2("Players"), getService2("ReplicatedStorage")
		local RunService2 = getService2("RunService")
		local TeleportService2 = getService2("TeleportService")
		local HttpService2 = getService2("HttpService")
		ctx2.HttpService = HttpService2
		local UserInputService = getService2("UserInputService")
		local TweenService = getService2("TweenService")
		local localPlayer2 = Players2.LocalPlayer
		local genv2 = (getgenv and getgenv()) or _G
		ctx2.genv = genv2

		if ctx2.genv.ChilliFinderPanelCleanup then
			pcall(ctx2.genv.ChilliFinderPanelCleanup)
		end

		local chilliFinderEmbedded = ctx2.genv.ChilliFinderEmbedded
		ctx2.genv.ChilliFinderEmbedded = nil

		if not chilliFinderEmbedded then
			ctx2.genv.ChilliFinderHidden = nil
		end

		local tempValueFinder, connections3 = true, {}

		local function trackConnection2(event, input)
			local connection = event:Connect(input)
			connections3[#connections3 + 1] = connection
			return connection
		end

		ctx2.getServerTimeNow = function()
			return workspace:GetServerTimeNow()
		end

		local robloxMcpUrl, apiToken, chilliFinderSessionFile, chilliFinderSettingsFile, chillihubUrl = "https://chillihub.pro/roblox-mcp/", "KfGWXYNjIls2MxhBVIF1BsWAG4qw", "ChilliFinder_session.json", "ChilliFinder_settings.json", "https://chillihub.pro"
		ctx2.robloxMcpUrl = robloxMcpUrl
		ctx2.fieldValue = apiToken
		Players2 = (request or http_request) or (syn and syn.request)
		local httpRequest = Players2 or (http and http.request)
		ctx2.httpRequest = httpRequest
		local bxor = bit32.bxor
		local band = bit32.band
		local lshift = bit32.lshift
		local rshift, startTime = bit32.rshift, 0

		local function runUntilTimeout(input, inputFinder)
			if input then
				if (inputFinder % 2048) == 0 then
					if (os.clock() - startTime) > 0.003 then
						task.wait()
						startTime = os.clock()
					end
				end
			end
		end

		local function scanItemsFinder(items, amount, input)
			for index = 1, #items, 1 do
				amount = bxor(amount, items:byte(index))
				amount = (((amount % 256) * 16777216) + (amount * 403)) % 4294967296
				runUntilTimeout(input, index)
			end

			return amount
		end

		local function doStepFinder(input)
			input = bxor(input, lshift(input, 13))
			input = bxor(input, rshift(input, 17))
			return bxor(input, lshift(input, 5))
		end

		local function doStep12(text, textFinder, input)
			local scanItemsFinderResult, packedArgs = scanItemsFinder(text .. textFinder, 3735928559,
				input), table.pack(scanItemsFinder(textFinder .. text, 3405691582, input))
			return ("%08x%08x"):format(scanItemsFinderResult, table.unpack(packedArgs, 1, packedArgs.n))
		end

		local cache = {}

		for index = 0, 9, 1 do
			cache[48 + index] = index
		end

		for index = 0, 5, 1 do
			cache[97 + index], cache[65 + index] = 10 + index, 10 + index
		end

		ctx2.scanItems = function(items, text)
			local textFinder = ("%08x%08x"):format(math.random(0, 2147483646), math.random(0, 2147483646))
			local scanItemsFinderResult, scanItemsFinderResultFinder, tempValue2 = scanItemsFinder(text .. textFinder,
				2166136261), scanItemsFinder(textFinder .. text, 2654435769), table.create(#items)

			for index = 1, #items, 1 do
				scanItemsFinderResult, scanItemsFinderResultFinder = doStepFinder(scanItemsFinderResult), doStepFinder(scanItemsFinderResultFinder)
				tempValue2[index] = ("%02x"):format(bxor(items:byte(index), band(bxor(rshift(scanItemsFinderResult, 8),
					rshift(scanItemsFinderResultFinder, 16)), 255)))
			end

			items = table.concat(tempValue2)
			return "c3." .. (textFinder .. ("." .. (items .. ("." .. doStep12(items, text)))))
		end

		ctx2.hasTimedOut = function(text, textFinder, value)
			local match, tempValue2, tempValue5 = tostring(text):match("^c3%.(%x+)%.(%x+)%.(%x+)$")
			startTime = os.clock()

			if match then
				if (#tempValue2 % 2) == 1 then
					return
				elseif doStep12(tempValue2, textFinder, value) ~= tempValue5 then
					return
				end
			else
				return
			end

			local scanItemsFinderResult, scanItemsFinderResultFinder, length = scanItemsFinder(textFinder .. match,
				2166136261), scanItemsFinder(match .. textFinder, 2654435769), #tempValue2 // 2
			tempValue5 = buffer.create(length)

			for index = 1, length, 1 do
				scanItemsFinderResult, scanItemsFinderResultFinder = doStepFinder(scanItemsFinderResult), doStepFinder(scanItemsFinderResultFinder)
				text, match = tempValue2:byte((index * 2) - 1, index * 2)
				buffer.writeu8(tempValue5, index - 1, bxor((cache[text] * 16) + cache[match],
					band(bxor(rshift(scanItemsFinderResult, 8), rshift(scanItemsFinderResultFinder, 16)), 255)))
				runUntilTimeout(value, index)
			end

			textFinder, length, match, value = ctx2.HttpService, ctx2.HttpService, pcall(ctx2.HttpService.JSONDecode,
				ctx2.HttpService, buffer.tostring(tempValue5))
			return ((match and (type(value) == "table")) and value) or nil
		end

		ctx2.tryCall = function()
			local callResult, result = pcall(function()
				return gethwid and gethwid()
			end)

			if callResult then
				if result then
					if result ~= "" then
						return tostring(result)
					end
				end
			end

			callResult, result = pcall(function()
				return getService2("RbxAnalyticsService"):GetClientId()
			end)

			return (callResult and tostring(result)) or tostring(localPlayer2.UserId)
		end

		ctx2.tryCall2 = function()
			local callResult, result = pcall(function()
				return getService2("RbxAnalyticsService"):GetClientId()
			end)

			if callResult then
				if result then
					if result ~= "" then
						return tostring(result)
					end
				end
			end

			callResult = ctx2.tryCall
			return callResult()
		end

		local function readJsonFile(input)
			local callResult, tempValue2 = pcall(function()
				local HttpService3, packedArgs = ctx2.HttpService, table.pack(readfile(input))
				return HttpService3:JSONDecode(table.unpack(packedArgs, 1, packedArgs.n))
			end)

			return ((callResult and (type(tempValue2) == "table")) and tempValue2) or nil
		end

		local itemsFinder, items2 = {{"Any", 0}, {"Secret+", 8}, {"Eternal+", 9}, {"Divine", 10}}, {{"Qi", 1e+18},
			{"Qa", 1000000000000000}, {"T", 1000000000000}, {"B", 1000000000}, {"M", 1000000}, {"K", 1000}}

		local function scanTableFinder(text)
			for _, item in ipairs(items2) do
				if text >= item[2] then
					return ("%.2f"):format(text / item[2]):gsub("%.?0+$", "") .. item[1]
				end
			end

			return tostring(text)
		end

		local function doStep13(text)
			text = tostring(text):gsub("[%s,$]", ""):lower():gsub("/s$", "")

			if text == "" then
				return 0
			elseif text == "any" then
				return 0
			end

			local match, tempValue2 = text:match("^(%d*%.?%d+)(%a*)$")
			match = tonumber(match)
			if not (match) then
				return nil
			end

			if tempValue2 == "" then
				return match
			end

			for _, item in ipairs(items2) do
				if item[1]:lower() == tempValue2 then
					return match * item[2]
				end
			end
		end

		local jsonFile, entries = readJsonFile(chilliFinderSettingsFile) or {}, {gap = 5, hold = true, reload = true,
			list = 0, night = 10, age = 30}

		for key, value in next, entries, nil do
			if jsonFile[key] == nil then
				jsonFile[key] = value
			end
		end

		jsonFile.min = math.max(5000000000, tonumber(jsonFile.min) or 0)
		jsonFile.age = math.clamp(tonumber(jsonFile.age) or 30, 0, 120)
		jsonFile.night = math.clamp((((jsonFile.night == false) and 0) or tonumber(jsonFile.night)) or 10, 0, 60)

		if jsonFile.rar == nil then
			jsonFile.rar = ({0, 6, 8, 9, 10})[jsonFile.minR or 1] or 0
		end

		if not (table.find({0, 8, 9, 10}, jsonFile.rar)) then
			jsonFile.rar = 0
		end

		jsonFile.minV = nil
		jsonFile.minR = nil

		if jsonFile.force == false then
			jsonFile.gap = 0
		end

		if jsonFile.dur then
			Players2 = tonumber(jsonFile.gap)

			if Players2 then
				if Players2 > 0 then
					jsonFile.gap = math.min(60, jsonFile.dur)
				end
			end
		end

		jsonFile.gap = math.clamp(math.floor((tonumber(jsonFile.gap) or 0) + 0.5), 0, 60)
		jsonFile.dur = nil
		local deadline

		local function hasTimedOutFinder()
			deadline = os.clock() + 1
		end

		local tempValue6, entriesFinder = ("%x"):format((scanItemsFinder(gameRef2.JobId, 2166136261))), {eggs = {},
			seen = {}, top = {}, sample = {}, failed = {}, inbox = {}, last = 0, wsAt = 0}
		ctx2.fieldValue2 = entriesFinder
		ctx2.fieldValue2.arrived = os.clock()
		ctx2.fieldValue2.me = ctx2.HttpService:GenerateGUID(false)
		ctx2.fieldValue2.msg = ""
		ctx2.fieldValue2.msgAt = 0
		ctx2.fieldValue2.auto = false
		ctx2.fieldValue2.dirty = true
		ctx2.genv.ChilliFinderOwner = ctx2.fieldValue2.me

		local function hasTimedOut2()
			local genvFinder, fieldValue2 = ctx2.genv, ctx2.fieldValue2

			if genvFinder.ChilliFinderOwner == fieldValue2.me then
				local genv3 = ctx2.genv
				genv3.ChilliFinderBeat = os.clock()
				return true
			end

			genvFinder = ctx2.genv
			fieldValue2 = genvFinder.ChilliFinderOwner
			local isNegated, tempValue2 = not fieldValue2

			if fieldValue2 then
				genvFinder = nil
				genvFinder, tempValue2 = ctx2.genv, (os.clock() - (ctx2.genv.ChilliFinderBeat or 0)) > 3
			else
				tempValue2 = isNegated
			end

			if tempValue2 then
				genvFinder, fieldValue2, isNegated = ctx2.genv, ctx2.genv, ctx2.fieldValue2
				genvFinder.ChilliFinderOwner, fieldValue2.ChilliFinderBeat = isNegated.me, os.clock()
				return true
			end

			return false
		end

		local textValue = "ChilliFinder_vault.dat"
		local textValueFinder = "cF9#vLt2" .. (ctx2.tryCall2() .. "qZ7!mW4x")
		local textValue2 = "cF9#vLt2" .. (ctx2.tryCall() .. "qZ7!mW4x")

		local function readCachedFile()
			local callResult, result = pcall(readfile, textValue)
			local ok2

			if callResult then
				local hasTimedOut4 = ctx2.hasTimedOut
				local fieldValueResult = hasTimedOut4(result, textValueFinder)

				if fieldValueResult then
					ok2 = fieldValueResult
				else
					hasTimedOut4 = ctx2.hasTimedOut
					ok2 = (hasTimedOut4(result, textValue2))
				end
			else
				ok2 = callResult
			end

			return ok2 or {}
		end

		ctx2.saveFile = function(input)
			local scanItems9, httpService = ctx2.scanItems, ctx2.HttpService
			pcall(writefile, textValue, ctx2.scanItems(ctx2.HttpService:JSONEncode(input), textValueFinder))
		end

		local cachedFile = readCachedFile()
		ctx2.cachedFile = cachedFile
		entries, Players2 = readJsonFile(chilliFinderSessionFile), false

		if entries then
			if entries.token then
				if ctx2.cachedFile.s then
				else
					ctx2.cachedFile.s = entries
					Players2 = true
				end
			else
			end
		else
		end

		if jsonFile.user ~= nil then
			if jsonFile.user ~= "" then
				if ctx2.cachedFile.u then
				else
					readJsonFile = jsonFile.user
					ctx2.cachedFile.u = readJsonFile
					Players2 = true
				end
			else
			end

			jsonFile.user = nil
			pcall(writefile, chilliFinderSettingsFile, ctx2.HttpService:JSONEncode(jsonFile))
		else
		end

		if entries then
			pcall(delfile, chilliFinderSessionFile)
		end

		if Players2 then
			ctx2.saveFile(ctx2.cachedFile)
		end

		local function toNumberOrDefault3()
			ctx2.cachedFile = readCachedFile()
			local tempValue2 = ctx2.cachedFile.s
			local tempValue5, tempValue7 = (type(tempValue2) == "table") and tonumber(tempValue2.endTs)

			if tempValue5 then
				local tempValue8
				tempValue8, tempValue7 = ctx2.getServerTimeNow, tempValue2.endTs > (ctx2.getServerTimeNow() * 1000)
			else
				tempValue7 = tempValue5
			end

			return (tempValue7 and tempValue2) or nil
		end

		ctx2.fieldValue2.sess = toNumberOrDefault3()

		ctx2.field = function()
			local saveFile
			saveFile, ctx2.cachedFile.s = ctx2.fieldValue2, ctx2.fieldValue2.sess
			saveFile = ctx2.saveFile
			saveFile(ctx2.cachedFile)
		end

		local function checkStateFinder()
			local fieldValue2 = ctx2.fieldValue2
			local tempValue2, tempValue5 = fieldValue2.sess ~= nil

			if tempValue2 then
				local getServerTimeNowFinder, tempValue7 = ctx2.getServerTimeNow
				tempValue7, tempValue5 = ctx2.fieldValue2, (getServerTimeNowFinder() * 1000) < ctx2.fieldValue2.sess.endTs
			else
				tempValue5 = tempValue2
			end

			return tempValue5
		end

		entries = (ctx2.fieldValue2.sess and ctx2.fieldValue2.sess.username)
			or (ctx2.cachedFile.rt and (ctx2.cachedFile.u or "?"))
		ctx2.fieldValue2.who = entries or nil

		local function checkState2()
			local checkStateFinderResult = checkStateFinder()
			local tempValue2

			if checkStateFinderResult then
				tempValue2 = checkStateFinderResult
			else
				local fieldValue2 = ctx2.fieldValue2
				tempValue2 = fieldValue2.who ~= nil
			end

			return tempValue2
		end

		local function doStep14(input)
			local getServerTimeNowFinder = ctx2.getServerTimeNow
			return math.max(0, getServerTimeNowFinder() - ((input.at or 0) / 1000))
		end

		local configMap = {Golden = {"Golden", {255, 206, 70}}, Silver = {"Silver", {215, 225, 240}},
			Rainbow = {"Rainbow"}, Scrambled = {"Scrambled", {190, 130, 255}}, Enchanted = {"Enchanted", {100, 225,
			255}}, Sakura = {"Bloom", {255, 160, 210}}, Spectral = {"Spectral", {110, 240, 220}}}
		local colorSequence = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
			ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 210, 60)), ColorSequenceKeypoint.new(0.5,
			Color3.fromRGB(90, 230, 110)), ColorSequenceKeypoint.new(0.75, Color3.fromRGB(70, 160,
			255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 90, 255))})

		local function clampValueFinder(input)
			local computed, text = math.floor(doStep14(input)), (checkStateFinder() and "") or " ago"
			return ((((computed < 60)
				and (computed .. "s")) or ((computed < 3600)
				and ((computed // 60) .. "m"))) or ((computed // 3600) .. "h")) .. text
		end

		ctx2.tryCall3 = function()
			local fieldValue2Finder = ctx2.fieldValue2
			local fieldValueFinder, fieldValue2 = fieldValue2Finder.ws, ctx2.fieldValue2
			fieldValue2.ws = nil

			if fieldValueFinder then
				pcall(function()
					fieldValueFinder:Close()
				end)
			end
		end

		ctx2.runUntilTimeout = function(msg)
			local fieldValue2Finder, fieldValue22, fieldValue2 = ctx2.fieldValue2, ctx2.fieldValue2, ctx2.fieldValue2
			fieldValue2Finder.msg, fieldValue22.msgAt = msg, os.clock()
			fieldValue2.dirty = true
		end

		local tempValue9

		local function checkState6(input)
			tempValue9 = nil

			if input then
				local runUntilTimeoutFinder = ctx2.runUntilTimeout
				runUntilTimeoutFinder(input)
			end

			input = ctx2.fieldValue2
			input.dirty = true
		end

		local function readAttributeFinder()
			local number, getServerTimeNowFinder = tonumber(workspace:GetAttribute("AreaEggCyclePeriodSeconds"))
				or 300, ctx2.getServerTimeNow
			local serverTimeNowFinder = getServerTimeNowFinder()
			return (jsonFile.night > 0)
				and (((math.ceil(serverTimeNowFinder / number) * number) - serverTimeNowFinder) < (jsonFile.night + 10))
		end

		local function hasTimedOut3()
			if not (tempValue9) then
				return
			end
			tempValue9.tries += 1
			local fieldValue2 = ctx2.fieldValue2
			fieldValue2.tried[tempValue9.e.jobId] = os.clock()
			fieldValue2 = ctx2.genv
			fieldValue2.ChilliFinderJoinAt = os.clock()
			local tempValue9Ref, tempValue9RefFinder, next_ = tempValue9, tempValue9, os.clock() + 3
			tempValue9Ref.fly = nil
			tempValue9RefFinder.next = next_

			pcall(function()
				local fieldValue2Finder = ctx2.fieldValue2
				TeleportService2:SetTeleportSetting("__ChilliFinderAuto",
					(fieldValue2Finder.auto and tempValue9.e.jobId) or false)
			end)

			if jsonFile.reload then
				pcall(function()
					TeleportService2:SetTeleportSetting("__ChilliFinderAutoLoad", true)
				end)

				-- JOHN HUB: Reload THIS Finder only after joining, never the unrelated Chilli Hub.
				local queueFn = (queue_on_teleport or queueonteleport)
					 or (syn and syn.queue_on_teleport)
					 or (fluxus and fluxus.queue_on_teleport)
				local ownSource = ctx2.genv.JohnHubStandaloneSource
				if type(queueFn) == "function" and type(ownSource) == "string" then
					local resume = 'local ok,on=pcall(function() return game:GetService("TeleportService"):GetTeleportSetting("__ChilliFinderAutoLoad") end)\n'
						.. 'if ok and on == true then\n'
						.. 'if not game:IsLoaded() then game.Loaded:Wait() end\n'
						.. ownSource .. '\nend'
					local queued, queueError = pcall(queueFn, resume)
					if not queued then warn("[John Hub Finder] Auto-reload unavailable: " .. tostring(queueError)) end
				else
					warn("[John Hub Finder] Auto-reload unavailable: executor cannot queue teleport code")
				end
			end

			fieldValue2 = ctx2.genv

			if fieldValue2.ChilliFinderBeforeTeleport then
				pcall(ctx2.genv.ChilliFinderBeforeTeleport)
			end

			local tempValue9Ref2 = tempValue9

			task.spawn(function()
				local callResult, result = pcall(TeleportService2.TeleportToPlaceInstance, TeleportService2,
					tempValue9Ref2.e.placeId, tempValue9Ref2.e.jobId, localPlayer2)

				if not (callResult) then
					if tempValue9 == tempValue9Ref2 then
						local tempValue9Ref3, tempValue9Ref4, why, next_2 = tempValue9, tempValue9, tostring(result):sub(1,
							40), os.clock() + 0.1
						tempValue9Ref3.why = why
						tempValue9Ref4.next = next_2
					end
				end
			end)
		end

		ctx2.fieldValue2.tried = {}

		local function checkState7(firstValue, firstValueFinder)
			if not (checkStateFinder()) then
				local runUntilTimeoutFinder, fieldValue2 = ctx2.runUntilTimeout, ctx2.fieldValue2
				return runUntilTimeoutFinder((fieldValue2.who and "No active booking. Book hours at chillihub.pro") or "Sign in with an active Finder booking first")
			end

			if not (hasTimedOut2()) then
				local runUntilTimeoutFinder = ctx2.runUntilTimeout
				return runUntilTimeoutFinder("Finder runs in another script")
			end

			if firstValue then
				if firstValue.jobId then
					if firstValue.placeId then
						if firstValue.jobId == gameRef2.JobId then
							return
						end
					else
						return
					end
				else
					return
				end
			else
				return
			end

			if readAttributeFinder() then
				local runUntilTimeoutFinder = ctx2.runUntilTimeout
				return runUntilTimeoutFinder("Night is close, join again after the reset")
			end
			local state, now2, isRecent = {e = firstValue, tries = 0, next = 0, why = "", a = firstValueFinder,
				force = if firstValueFinder then not firstValueFinder else jsonFile.gap > 0}, os.clock(), (firstValueFinder
				and 8) or ((jsonFile.gap > 0) and jsonFile.gap)
			state.stop = now2 + (isRecent or 15)
			tempValue9 = state
			isRecent = ctx2.fieldValue2
			isRecent.dirty = true
			hasTimedOut3()
		end

		trackConnection2(TeleportService2.TeleportInitFailed, function(input, inputFinder, input2)
			if input ~= localPlayer2 then
				return
			elseif not (tempValue9) then
				return
			end

			local tempValue9Ref, tempValue9RefFinder, tempValue9Ref2, why = tempValue9, tempValue9, tempValue9, tostring(((input2 ~= "") and input2) or inputFinder):gsub("Enum%.TeleportResult%.",
				""):sub(1, 40)
			tempValue9Ref.fly = nil
			tempValue9RefFinder.why = why
			tempValue9Ref2.next = 0

			if not (tempValue9.force) then
				why = ctx2.fieldValue2
				why.failed[tempValue9.e.jobId] = os.clock() + (((tempValue9.a and (jsonFile.gap > 0)) and 1) or 120)
				tempValue9Ref = tempValue9.a
				checkState6((if tempValue9Ref then not tempValue9Ref else "Could not join: " .. tempValue9.why) or nil)
			end

			tempValue9Ref = ctx2.fieldValue2
			tempValue9Ref.dirty = true
		end)

		trackConnection2(localPlayer2.OnTeleport, function(input)
			local tempValue2 = tempValue9
				and ((input == Enum.TeleportState.Started) or (input == Enum.TeleportState.InProgress))

			if tempValue2 then
				input = tempValue9
				input.fly = os.clock()
			end
		end)

		local tempValue10

		local function scanItems3()
			tempValue10 = nil

			if (type(jsonFile.only) == "table") and (#jsonFile.only > 0) then
				tempValue10 = {}
				local ipairsFn, only = ipairs, jsonFile.only

				for _, item in ipairsFn(only) do
					tempValue10[item] = true
				end
			end
		end

		scanItems3()

		local function doStep15(input)
			local isRecent, tempValue2 = ((input.value or 0) >= jsonFile.min) and ((input.rarity or 0) >= jsonFile.rar)

			if isRecent then
				local tempValue10Ref = tempValue10
				local isNegated = not tempValue10Ref

				if tempValue10Ref then
					local tempValue10RefFinder = tempValue10
					tempValue2 = tempValue10RefFinder[input.name] == true
				else
					tempValue2 = isNegated
				end
			else
				tempValue2 = isRecent
			end

			return tempValue2
		end

		local function readAttribute2()
			local number = tonumber(workspace:GetAttribute("AreaEggCyclePeriodSeconds")) or 300
			local getServerTimeNowFinder, tempValue2 = ctx2.getServerTimeNow, (math.floor(ctx2.getServerTimeNow() / number) * number) - 5
			return tempValue2 * 1000
		end

		local function scanItems4()
			local attribute2 = readAttribute2()

			if not (checkStateFinder()) then
				local fieldValue2, fieldValue2Finder = ctx2.fieldValue2, ctx2.fieldValue2
				fieldValue2.top = fieldValue2Finder.sample
				return
			end

			local list3, ipairsFn, fieldValue22 = {}, ipairs, ctx2.fieldValue2
			local eggs2 = fieldValue22.eggs

			for index, item in ipairsFn(eggs2) do
				if item.jh ~= tempValue6 then
					if item.jobId ~= gameRef2.JobId then
						if (item.at or 0) >= attribute2 then
							if doStep15(item) then
								index = ctx2.fieldValue2

								if index.auto then
									if not ((jsonFile.age > 0) and (doStep14(item) > jsonFile.age)) then
										if jsonFile.age == 0 then
											fieldValue22 = ctx2.fieldValue2

											if not ((item.at or 0) <= (fieldValue22.autoAt or 0)) then
												list3[#list3 + 1] = item
											end
										else
											list3[#list3 + 1] = item
										end
									end
								else
									list3[#list3 + 1] = item
								end
							end
						end
					end
				end
			end

			table.sort(list3, function(input, inputFinder)
				if input.value ~= inputFinder.value then
					return input.value > inputFinder.value
				end
				return (input.at or 0) > (inputFinder.at or 0)
			end)

			fieldValue22, eggs2 = ctx2.fieldValue2, ctx2.fieldValue2
			fieldValue22.pick = list3
			eggs2.pickSet = {}
			ipairsFn = ipairs

			for index, item in ipairsFn(list3) do
				index = ctx2.fieldValue2
				index.pickSet[item] = true
			end

			if (jsonFile.list or 0) > 0 then
				fieldValue22, eggs2 = {}, ctx2.fieldValue2

				for _, egg in ipairs(eggs2.eggs) do
					if egg.jh ~= tempValue6 then
						if egg.jobId ~= gameRef2.JobId then
							if (egg.at or 0) >= attribute2 then
								fieldValue22[#fieldValue22 + 1] = egg
							end
						end
					end
				end

				if jsonFile.list == 2 then
					table.sort(fieldValue22, function(input, inputFinder)
						return (input.at or 0) > (inputFinder.at or 0)
					end)
				else
					table.sort(fieldValue22, function(input, inputFinder)
						return (input.value or 0) > (inputFinder.value or 0)
					end)
				end

				list3 = fieldValue22
			else
				list3 = table.clone(list3)

				table.sort(list3, function(input, inputFinder)
					return (input.at or 0) > (inputFinder.at or 0)
				end)
			end

			for index = #list3, 31, -1 do
				list3[index] = nil
			end

			eggs2 = ctx2.fieldValue2
			eggs2.top = list3
		end

		local function scanItems5(value, items)
			local ipairsFn, tempValue2 = ipairs, ((type(value) == "table") and value) or {}

			for index, item in ipairsFn(tempValue2) do
				index = (type(item) == "table") and ((item.id or item.uid) or (tostring(item.name) .. tostring(item.at)))

				if index then
					value = ctx2.fieldValue2

					if not (value.seen[index]) then
						local fieldValue2 = ctx2.fieldValue2
						fieldValue2.seen[index] = true
						local fieldValue2Finder, tempValue5 = ctx2.fieldValue2
						tempValue5, fieldValue2Finder.last = ctx2.fieldValue2, math.max(ctx2.fieldValue2.last,
							tonumber(item.id) or 0)
						item.value = tonumber(item.value) or 0
						fieldValue2, fieldValue2Finder = ctx2.fieldValue2
						fieldValue2Finder, fieldValue2.eggs[#ctx2.fieldValue2.eggs + 1] = ctx2.fieldValue2, item
						tempValue5 = ctx2.fieldValue2
						tempValue5.dirty = true
					end
				end
			end

			if not (items) then
				value = ctx2.getServerTimeNow
				tempValue2, ipairsFn = (value() - 300) * 1000, ctx2.fieldValue2
				local length = #ipairsFn.eggs

				for index = length, 1, -1 do
					local fieldValue2 = ctx2.fieldValue2

					if (fieldValue2.eggs[index].at or 0) < tempValue2 then
						local fieldValue2Finder, tempValue5 = ctx2.fieldValue2
						tempValue5, fieldValue2Finder.seen[ctx2.fieldValue2.eggs[index].id or ""] = ctx2.fieldValue2, nil
						table.remove(ctx2.fieldValue2.eggs, index)
					end
				end
			end

			value = ctx2.fieldValue2

			if #value.eggs > 60 then
				local function isJobId(input)
					return (((doStep15(input) and (input.jobId ~= gameRef2.JobId)) and (doStep14(input) <= 300)) and 1) or 0
				end

				table.sort(ctx2.fieldValue2.eggs, function(input, inputFinder)
					local isJobIdResult, isJobIdResultFinder = isJobId(input), isJobId(inputFinder)
					if isJobIdResult ~= isJobIdResultFinder then
						return isJobIdResult > isJobIdResultFinder
					end
					return (input.value or 0) > (inputFinder.value or 0)
				end)

				items = ctx2.fieldValue2
				ipairsFn = #items.eggs - 60

				for index = 1, ipairsFn, 1 do
					tempValue2, index = ctx2.fieldValue2
					index, tempValue2.seen[table.remove(ctx2.fieldValue2.eggs).id or ""] = ctx2.fieldValue2, nil
				end
			end
		end

		local function doStep17(acct)
			local fieldValue2, fieldValue2Finder = ctx2.fieldValue2, ctx2.fieldValue2
			local who, who2 = fieldValue2Finder.who

			if who then
				who2 = who
			else
				fieldValue2Finder = ctx2.fieldValue2
				local sess = fieldValue2Finder.sess

				if sess then
					local fieldValue22 = ctx2.fieldValue2
					who2 = fieldValue22.sess.username
				else
					who2 = sess
				end
			end

			fieldValue2.who = who2
			fieldValue2Finder = ctx2.tryCall3
			fieldValue2Finder()
			who2 = ctx2.fieldValue2
			who2.sess = nil
			fieldValue2Finder = ctx2.field
			fieldValue2Finder()
			checkState6()
			who = ctx2.fieldValue2
			who.auto = false
			table.clear(ctx2.fieldValue2.eggs)
			table.clear(ctx2.fieldValue2.seen)
			fieldValue2, fieldValue2Finder = ctx2.fieldValue2, ctx2.fieldValue2
			fieldValue2.last = 0
			fieldValue2Finder.dirty = true
			fieldValue2Finder = ctx2.fieldValue2
			fieldValue2Finder.acct = acct
		end

		local tempValue11

		local function scanTable3(keyName)
			if not (tempValue11) then
				tempValue11 = {}

				pcall(function()
					local rarityGradients, nextFn, directory = (ReplicatedStorage2:FindFirstChild("Assets") and ReplicatedStorage2.Assets:FindFirstChild("UI"))
						and ReplicatedStorage2.Assets.UI:FindFirstChild("RarityGradients"), next, require(ReplicatedStorage2.Data.Assets).Directory

					for _, item in nextFn, directory, nil do
						if type(item) == "table" then
							if item.DisplayName then
								local rarity, icon = item.Rarity, item.Icon
								local rarity2, tempValue11Ref = (rarityGradients and rarity)
									and rarityGradients:FindFirstChild(tostring((rarity._id or rarity.DisplayName) or "")), tempValue11
								tempValue11Ref[item.DisplayName] = {icon = (((type(icon) == "number") and ("rbxassetid://" .. icon)) or ((type(icon) == "string") and ((tonumber(icon) and ("rbxassetid://" .. icon)) or icon))) or "",
									color = ((rarity and (typeof(rarity.Color) == "Color3")) and rarity.Color) or Color3.new(1, 1,
									1), grad = (rarity2
									and ((rarity2:IsA("UIGradient") and rarity2) or rarity2:FindFirstChildWhichIsA("UIGradient",
									true))) or nil}
							end
						end
					end
				end)
			end

			local tempValue2 = tempValue11[keyName] or {icon = "", color = Color3.new(1, 1, 1)}
			return tempValue2
		end

		local function getColor(input, inputFinder, input2)
			return Color3.fromRGB(input, inputFinder, input2)
		end

		local function scanTable4(items)
			local iMap2 = {}

			for index, item in ipairs(items) do
				iMap2[index] = ColorSequenceKeypoint.new(item[1], item[2])
			end

			return ColorSequence.new(iMap2)
		end

		local stateFinder = {}
		stateFinder.Hud = {Color = scanTable4({{0, getColor(255, 107, 2)}, {1, getColor(255, 238, 1)}}),
			Rotation = -90, Stroke = getColor(60, 24, 0), Light = getColor(255, 222, 55)}
		stateFinder.Join = {Color = scanTable4({{0, getColor(22, 211, 22)}, {1, getColor(153, 255, 106)}}),
			Rotation = -90, Stroke = getColor(8, 52, 8), Light = getColor(200, 255, 170)}
		stateFinder.Stop = {Color = scanTable4({{0, getColor(200, 15, 24)}, {1, getColor(255, 96, 96)}}),
			Rotation = -90, Stroke = getColor(70, 6, 6), Light = getColor(255, 180, 180)}
		stateFinder.Off = {Color = scanTable4({{0, getColor(70, 76, 90)}, {1, getColor(128, 136, 152)}}),
			Rotation = -90, Stroke = getColor(20, 22, 28), Light = getColor(190, 196, 210)}
		stateFinder.Blue = {Color = scanTable4({{0, getColor(41, 109, 211)}, {1, getColor(80, 217, 255)}}),
			Rotation = -90, Stroke = getColor(10, 30, 70), Light = getColor(170, 225, 255)}
		stateFinder.Field = {Color = scanTable4({{0, getColor(78, 74, 100)}, {1, getColor(52, 49, 70)}}),
			Rotation = -90, Stroke = getColor(18, 16, 28), Light = getColor(128, 122, 150)}
		stateFinder.Knob = {Color = scanTable4({{0, getColor(255, 255, 255)}, {1, getColor(200, 205, 218)}}),
			Rotation = -90, Stroke = getColor(34, 34, 46), Light = getColor(255, 255, 255)}
		stateFinder.Gold = {Color = scanTable4({{0, getColor(255, 107, 2)}, {1, getColor(255, 238, 1)}}),
			Rotation = -90, Stroke = getColor(60, 24, 0), Light = getColor(255, 222, 55)}
		stateFinder.Head = {Color = scanTable4({{0, getColor(255, 92, 30)}, {0.53, getColor(255, 184, 60)}, {1,
			getColor(236, 96, 24)}}), Rotation = 0}
		stateFinder.HeadVip = {Color = scanTable4({{0, getColor(196, 0, 255)}, {0.5, getColor(206, 36, 255)}, {0.72,
			getColor(232, 130, 255)}, {0.88, getColor(204, 0, 255)}, {1, getColor(150, 0, 240)}}), Rotation = 0}
		stateFinder.HudVip = {Color = scanTable4({{0, getColor(106, 31, 208)}, {1, getColor(230, 120, 255)}}),
			Rotation = -90, Stroke = getColor(40, 8, 70), Light = getColor(225, 170, 255)}

		local function doStep18()
			local HttpService3 = ctx2.HttpService
			return HttpService3:GenerateGUID(false):gsub("-", ""):sub(1, 14)
		end

		local function cleanup(input)
			local callResult, result = pcall(function()
				return input:Clone()
			end)

			if callResult then
				if not (result) then
					return nil
				end
			else
				return nil
			end

			for _, descendant in ipairs(result:GetDescendants()) do
				if descendant:IsA("LuaSourceContainer") then
					descendant:Destroy()
				end
			end

			return result
		end

		local function collectDescendants(data)
			data.Name = doStep18()

			for _, descendant in ipairs(data:GetDescendants()) do
				descendant.Name = doStep18()
			end
		end

		local function checkState8(container)
			if not (container) then
				return nil
			end
			return {Button = container, Gradient = container:FindFirstChildOfClass("UIGradient"),
				Stroke = container:FindFirstChild("UIStroke"), Light = container:FindFirstChild("UIStrokeClr"), Label = container:FindFirstChild("Label")
				or container:FindFirstChild("TextLabel"), Scale = container:FindFirstChild("PressScale")
				or container:FindFirstChild("BtnScale")}
		end

		local function checkState9(data, style)
			if data then
				if data.Style == style then
					return
				end
			else
				return
			end

			data.Style = style

			if data.Gradient then
				data.Gradient.Color, data.Gradient.Rotation = style.Color, style.Rotation
			end

			if data.Stroke then
				data.Stroke.Color = style.Stroke
			end

			if data.Light then
				data.Light.Color = style.Light
			end
		end

		local function checkState10(data, text)
			if data then
				if data.Text ~= text then
					data.Text = text
				end
			end
		end

		local tweenInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local function buildUIScale(data)
			if not (data) then
				return
			end
			local scale = data.Scale or Instance.new("UIScale")
			scale.Scale, scale.Parent = 1, data.Button
			data.Scale = scale

			local function animate(input)
				TweenService:Create(scale, tweenInfo, {Scale = input}):Play()
			end

			trackConnection2(data.Button.MouseEnter, function()
				animate(1.06)
			end)

			trackConnection2(data.Button.MouseLeave, function()
				animate(1)
			end)

			trackConnection2(data.Button.MouseButton1Down, function()
				animate(0.94)
			end)

			trackConnection2(data.Button.MouseButton1Up, function()
				animate(1.06)
			end)
		end

		local function trySound()
			pcall(function()
				local sound = Instance.new("Sound")
				sound.SoundId, sound.Volume, sound.PlaybackSpeed = "rbxassetid://100671636189844", 3.4, 0.93 + (math.random() * 0.13)
				local gameplay = getService2("SoundService"):FindFirstChild("Gameplay")

				if gameplay then
					if gameplay:IsA("SoundGroup") then
						sound.SoundGroup = gameplay
					end
				end

				sound.Parent = getService2("SoundService")
				sound:Play()
				getService2("Debris"):AddItem(sound, 3)
			end)
		end

		local function tryCallFinder(callback, callbackFinder)
			trackConnection2(callback.Activated, function()
				trySound()
				local callResult, result = pcall(callbackFinder)

				if not (callResult) then
					warn("[John Hub Finder] " .. tostring(result))
				end

				callResult = ctx2.fieldValue2
				callResult.dirty = true
			end)
		end

		local factor, amountFinder, factorFinder, setmetatableFn, weakCache = 2.3120369911193848, 556, 86.24, setmetatable, {__mode = "k"}
		local setmetatableFnResult, entries2 = setmetatableFn({}, weakCache), {}

		local function doStep19(input)
			local tempValue2 = input and ((entries2.panel and entries2.panel.AbsoluteSize.X) or 0)
			local tempValue5 = tempValue2 or ((entries2.btn and entries2.btn.Size.X.Offset) or 0)
			return ((tempValue5 > 0) and ((factor * tempValue5) / ((input and amountFinder) or factorFinder))) or nil
		end

		local function readAttribute3(input, inputFinder, input2)
			for _, descendant in ipairs(input:GetDescendants()) do
				if descendant:IsA("UIStroke") then
					if not (descendant:GetAttribute("own")) then
						local callResult, result = pcall(function()
							return descendant.StrokeSizingMode
						end)

						if if callResult then result ~= Enum.StrokeSizingMode.ScaledSize else not callResult then
							setmetatableFnResult[descendant] = {r = descendant.Thickness / (input2 or factor), p = inputFinder}
						end
					end
				end
			end
		end

		local function scanTable5()
			for key, value in pairs(setmetatableFnResult) do
				local doStep19Result = doStep19(value.p)

				if doStep19Result then
					if key.Parent then
						key.Thickness = value.r * doStep19Result
					end
				end
			end
		end

		local hui, tempValue12 = (gethui and gethui()) or getService2("CoreGui")

		local function doStep20()
			local playerGui = localPlayer2:FindFirstChildOfClass("PlayerGui")
			local hud = playerGui and (playerGui:FindFirstChild("HUD"))
			local gameHUD = hud and (hud:FindFirstChild("GameHUD"))
			local rightButtons, activePets, leftControls = gameHUD
				and (gameHUD:FindFirstChild("RightButtons")), playerGui
				and (playerGui:FindFirstChild("ActivePets")), gameHUD and (gameHUD:FindFirstChild("LeftControls"))
			local hudElements = {Hud = hud, GameHud = gameHUD, Column = rightButtons, Left = leftControls,
				Shop = leftControls and leftControls:FindFirstChild("ShopBTN"), Index = leftControls
				and leftControls:FindFirstChild("IndexBTN"), Slow = leftControls
				and leftControls:FindFirstChild("Slowmode"), Eggs = rightButtons
				and rightButtons:FindFirstChild("EggsButton"), Pets = rightButtons
				and rightButtons:FindFirstChild("PetsButton"), ActivePets = activePets, Growing = playerGui
				and playerGui:FindFirstChild("GrowingEggs")}

			if hud then
				if gameHUD then
					if rightButtons then
						if hudElements.Eggs then
							if hudElements.Pets then
								if hudElements.Shop then
									if hudElements.Index then
										if hudElements.Slow then
											if activePets then
												if activePets:FindFirstChild("Frame") then
													return hudElements
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

		local function createScreenGui(data)
			local screenGui = Instance.new("ScreenGui")
			screenGui.Name, screenGui.Archivable, screenGui.ResetOnSpawn, screenGui.IgnoreGuiInset, screenGui.ZIndexBehavior, screenGui.DisplayOrder = doStep18(), false, false, data.IgnoreGuiInset, data.ZIndexBehavior, data.DisplayOrder

			pcall(function()
				screenGui.ScreenInsets = data.ScreenInsets
			end)

			return screenGui
		end

		local tweenInfo2 = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tweenInfo3, tempValue13, tween, tween2 = TweenInfo.new(0.24, Enum.EasingStyle.Quad,
			Enum.EasingDirection.In), false

		local function playTween(input)
			local column = tempValue12 and tempValue12.Column

			if column then
				if not (column.Parent) then
					return
				end
			else
				return
			end

			if tween2 then
				tween2:Cancel()
			end

			local position = column.Position
			tween2 = TweenService:Create(column, (input and tweenInfo3) or tweenInfo2,
				{Position = UDim2.new(position.X.Scale, (input and math.ceil(column.AbsoluteSize.X * 1.03)) or 0,
				position.Y.Scale, position.Y.Offset)})
			tween2:Play()
		end

		local function scanItems6()
			local ipairsFn, cacheFinder, activePets = ipairs, {}, tempValue12.ActivePets
			cacheFinder[1], cacheFinder[2] = activePets, tempValue12.Growing

			for index, item in ipairsFn(cacheFinder) do
				if item and item.Enabled then
					activePets, index = item:FindFirstChild("Frame") and item.Frame:FindFirstChild("Close"), false

					if activePets then
						if getconnections then
							local indexRef = index

							for _, itemFinder in ipairs(getconnections(activePets.Activated)) do
								indexRef = if pcall(function()
									itemFinder:Fire()
								end) then true else indexRef
							end

							if not (indexRef) then
								item.Enabled = false
							end
						else
							item.Enabled = false
						end
					else
						item.Enabled = false
					end
				end
			end
		end

		local function chilliFinderPanelOpen(input)
			if tempValue13 then
				return
			elseif not (entries2.panel) then
				return
			end

			tempValue13 = true
			local fieldValue2 = ctx2.fieldValue2
			fieldValue2.dirty = true
			fieldValue2 = ctx2.genv

			if fieldValue2.ChilliStealPanelClose then
				pcall(ctx2.genv.ChilliStealPanelClose, input)
			end

			scanItems6()
			playTween(true)
			entries2.gui.Enabled = true

			if tween then
				tween:Cancel()
			end

			scanTable5()
			fieldValue2 = ctx2.fieldValue2
			fieldValue2.dirty = true
			if input then
				entries2.panel.Position = entries2.home
				return
			end
			entries2.panel.Position = UDim2.new(entries2.home.X.Scale, math.ceil(entries2.panel.AbsoluteSize.X * 1.392),
				entries2.home.Y.Scale, entries2.home.Y.Offset)
			tween = TweenService:Create(entries2.panel, tweenInfo2, {Position = entries2.home})
			tween:Play()
		end

		local function chilliFinderPanelClose(input, inputFinder)
			if tempValue13 then
				if not (entries2.panel) then
					return
				end
			else
				return
			end

			tempValue13 = false

			if not (input) then
				playTween(false)
			end

			if tween then
				tween:Cancel()
			end

			if inputFinder then
				entries2.gui.Enabled = false
				return
			end
			local tween3 = TweenService:Create(entries2.panel, tweenInfo3, {Position = UDim2.new(entries2.home.X.Scale,
				math.ceil(entries2.panel.AbsoluteSize.X * 1.392), entries2.home.Y.Scale, entries2.home.Y.Offset)})
			tween = tween3

			tween3.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed then
					if tween == tween3 then
						if not (tempValue13) then
							entries2.gui.Enabled = false
						end
					end
				end
			end)

			tween3:Play()
		end

		ctx2.genv.ChilliFinderPanelClose = chilliFinderPanelClose
		ctx2.genv.ChilliFinderPanelOpen = chilliFinderPanelOpen

		local function doStep23()
			local cacheFinder, state, list3, shop, index = {}, {c = tempValue12.Left}, {}, tempValue12.Shop, tempValue12.Index
			list3[1], list3[2], list3[3] = shop, index, tempValue12.Slow
			state.list = list3
			state.on = tempValue12.GameHud
			cacheFinder[1] = state
			state = tempValue12.Hud:FindFirstChild("TradmilHud")
			list3 = state and (state:FindFirstChild("LeftControls"))
			shop, index = list3 and (list3:FindFirstChild("ShopBTN")), list3 and (list3:FindFirstChild("SpeedMulti"))

			if shop then
				if index then
					cacheFinder[2] = {c = list3, list = {shop, index}, on = state}
				end
			end

			return cacheFinder
		end

		local function destroyInstances()
			local cleanupResult = cleanup(tempValue12.Shop)
			if not cleanupResult then
				return false
			end
			local nameList2 = {"GamepadGlyph", "AlertBadge"}

			for index, item in ipairs(nameList2) do
				index = cleanupResult:FindFirstChild(item)

				if index then
					if item == "GamepadGlyph" then
						index:Destroy()
					end
				end
			end

			for value in pairs(cleanupResult:GetAttributes()) do
				cleanupResult:SetAttribute(value, nil)
			end

			nameList2 = checkState8(cleanupResult)
			nameList2.Label = cleanupResult:FindFirstChild("txt")
			checkState10(nameList2.Label, "John Hub")
			checkState9(nameList2, stateFinder.Hud)
			local entries2Ref = entries2
			entries2Ref.badge = cleanupResult:FindFirstChild("AlertBadge")
			entries2Ref = entries2
			entries2Ref.badgeT = entries2Ref.badge and entries2.badge:FindFirstChildWhichIsA("TextLabel", true)
			entries2Ref = entries2
			entries2Ref.bIcon = cleanupResult:FindFirstChild("ImageLabel")

			if entries2.bIcon then
				entries2.bIcon.Image = (tempValue12.Eggs:FindFirstChild("ImageLabel") and tempValue12.Eggs.ImageLabel.Image)
					or entries2.bIcon.Image
			end

			entries2Ref = entries2
			entries2Ref.bIcon0 = entries2Ref.bIcon and entries2.bIcon.Image
			local entries2Finder, entries2RefFinder = entries2, entries2
			entries2.left0 = {}
			entries2Finder.lset = {}
			entries2RefFinder.ldy = {}
			entries2Finder, entries2Ref = ipairs, table.pack(doStep23())

			for index, item in entries2Finder(table.unpack(entries2Ref, 1, entries2Ref.n)) do
				index, entries2RefFinder = ipairs, item.list

				for _, itemFinder in index(entries2RefFinder) do
					entries2.left0[itemFinder] = itemFinder.Position
				end
			end

			cleanupResult.Position = entries2.left0[tempValue12.Shop]
			cleanupResult.Visible = false
			collectDescendants(cleanupResult)
			cleanupResult.Parent = tempValue12.Left

			local function checkState11()
				if tempValue13 then
					chilliFinderPanelClose()
				else
					chilliFinderPanelOpen()
				end

				local fieldValue2 = ctx2.fieldValue2
				fieldValue2.dirty = true
			end

			local uiScale, amount, scale, amount4, textValue3, connection = cleanupResult:FindFirstChildOfClass("UIScale")
				or Instance.new("UIScale", cleanupResult), 0, 1, 22, "Rest"

			local function handleEvent(deltaTime)
				local tempValue2, computed, amountRef = uiScale.Scale - scale, math.exp(-amount4 * deltaTime), amount
				local tempValue5 = (amountRef + (amount4 * tempValue2)) * deltaTime
				amountRef, deltaTime = (tempValue2 + tempValue5) * computed, amount
				amount = (deltaTime - (amount4 * tempValue5)) * computed

				if math.abs(amountRef) < 0.0005 then
					if math.abs(amount) < 0.0005 then
						uiScale.Scale = scale

						if connection then
							connection:Disconnect()
							connection = nil
						end
					else
						uiScale.Scale = scale + amountRef
					end
				else
					uiScale.Scale = scale + amountRef
				end
			end

			local function helper()
				local guiState = cleanupResult.GuiState
				local mouseEnabled = (((guiState == Enum.GuiState.Press) and "Sunk") or (((guiState == Enum.GuiState.Hover) and UserInputService.MouseEnabled) and "Raised"))
					or "Rest"
				if mouseEnabled == textValue3 then
					return
				end
				guiState = ((mouseEnabled == "Sunk") and 42) or ((textValue3 == "Sunk") and 26)
				amount4 = guiState or 22
				guiState = nil
				guiState, textValue3 = (((mouseEnabled == "Sunk") and 0.94) or ((mouseEnabled == "Raised") and 1.07))
					or 1, mouseEnabled
				scale = guiState

				if mouseEnabled == "Sunk" then
					trySound()
				end

				if not (connection) then
					connection = RunService2.PreRender:Connect(handleEvent)
					connections3[#connections3 + 1] = connection
				end
			end

			trackConnection2(cleanupResult:GetPropertyChangedSignal("GuiState"), helper)

			trackConnection2(cleanupResult.Activated, function()
				local callResult, result = pcall(checkState11)

				if not (callResult) then
					warn("[John Hub Finder] " .. tostring(result))
				end
			end)

			entries2RefFinder, entries2Finder = entries2, entries2
			entries2.hudGui = cleanupResult
			entries2RefFinder.btn = cleanupResult
			entries2Finder.hp = nameList2
			return true
		end

		local function scanItems7(position, input)
			local udim2, list3 = ipairs, position.list

			for _, item in udim2(list3) do
				if entries2.lset[item] ~= item.Position then
					local left0, lset, position2, udim22 = entries2.left0, entries2.lset, item.Position, entries2.lset[item]
						and (entries2.ldy[position.c] or UDim2.new())
					left0[item], lset[item] = position2 - (udim22 or UDim2.new()), nil
				end
			end

			list3 = entries2.left0[position.list[2]] - entries2.left0[position.list[1]]
			udim2 = (input and UDim2.new(0, 0, list3.Y.Scale, list3.Y.Offset)) or UDim2.new()
			entries2.ldy[position.c] = udim2
			local ipairsFn, list4 = ipairs, position.list

			for _, item in ipairsFn(list4) do
				position = entries2.left0[item] + udim2

				if item.Position ~= position then
					item.Position = position
				end

				entries2.lset[item] = (input and position) or nil
			end
		end

		local function tryCall3()
			local ipairsFn, tempValue2 = ipairs, (tempValue12 and doStep23()) or {}

			for _, item in ipairsFn(tempValue2) do
				if entries2.left0 then
					pcall(scanItems7, item, false)
				end
			end
		end

		local function checkState12()
			local btn = entries2.btn
			if not (btn) then
				return
			end
			local hasTimedOut2Result = hasTimedOut2()
			local visible

			if hasTimedOut2Result then
				local genvFinder = ctx2.genv
				visible = not genvFinder.ChilliFinderHidden
			else
				visible = hasTimedOut2Result
			end

			hasTimedOut2Result = doStep23()
			local entry = hasTimedOut2Result[1]
			entry = if hasTimedOut2Result[2] then if hasTimedOut2Result[2].on.Visible then if hasTimedOut2Result[1].on.Visible then entry else hasTimedOut2Result[2] else entry else entry

			for _, item in ipairs(hasTimedOut2Result) do
				scanItems7(item, false)
			end

			hasTimedOut2Result = entry.list[1]

			if btn.Parent ~= entry.c then
				btn.Parent = entry.c
			end

			local tempValue2 = entries2.left0[entry.list[2]] - entries2.left0[hasTimedOut2Result]
			local position = entries2.left0[hasTimedOut2Result] - UDim2.new(0, 0, tempValue2.Y.Scale,
				tempValue2.Y.Offset)

			if btn.Position ~= position then
				btn.Position = position
			end

			if btn.AnchorPoint ~= hasTimedOut2Result.AnchorPoint then
				btn.AnchorPoint = hasTimedOut2Result.AnchorPoint
			end

			if btn.Size ~= hasTimedOut2Result.Size then
				btn.Size = hasTimedOut2Result.Size
			end

			if btn.Visible ~= visible then
				btn.Visible = visible
			end
		end

		local function checkState13()
			local fieldValue, chilliStealPanelFrame = entries2.cS

			if fieldValue then
				local genvFinder = ctx2.genv
				chilliStealPanelFrame = genvFinder.ChilliStealPanelFrame
			else
				chilliStealPanelFrame = fieldValue
			end

			fieldValue = nil

			if chilliStealPanelFrame then
				local genvFinder = ctx2.genv
				fieldValue = genvFinder.ChilliStealPanelFrame()
			else
				fieldValue = chilliStealPanelFrame
			end

			if entries2.cS and fieldValue then
				local ipairsFn, children = ipairs, table.pack(fieldValue:GetChildren())

				for _, item in ipairsFn(table.unpack(children, 1, children.n)) do
					if (item:IsA("GuiButton") and (item.AbsoluteSize.X > 0))
						and (item.AbsoluteSize.X < (fieldValue.AbsoluteSize.X * 0.3)) then
						local count, ipairsFnFinder = 0, ipairs
						chilliStealPanelFrame = table.pack(item:GetDescendants())

						for _, itemFinder in ipairsFnFinder(table.unpack(chilliStealPanelFrame, 1, chilliStealPanelFrame.n)) do
							if itemFinder:IsA("UIStroke") then
								count += 1

								if entries2.cS[count] then
									pcall(function()
										entries2.cS[count].StrokeSizingMode = itemFinder.StrokeSizingMode
									end)

									entries2.cS[count].Thickness = itemFinder.Thickness
								end
							else
							end
						end

						break
					end
				end
			end
		end

		local function doStep24()
			local ctx3 = {}
			local frame = tempValue12.ActivePets.Frame
			local uiStroke, entries2Ref = frame:FindFirstChildOfClass("UIStroke"), entries2
			entries2Ref.sbase = (uiStroke and uiStroke.Thickness) or factor
			local cleanupResult = cleanup(frame)
			if not cleanupResult then
				return false
			end
			local header, scrollingFrame, close = cleanupResult:FindFirstChild("Header"), cleanupResult:FindFirstChild("ScrollingFrame"), cleanupResult:FindFirstChild("Close")
			uiStroke = scrollingFrame and (scrollingFrame:FindFirstChild("Template"))
			local spacer = uiStroke and (uiStroke:FindFirstChild("Spacer"))
			local unequip = spacer and (spacer:FindFirstChild("Unequip", true))

			if unequip and (unequip.Parent ~= spacer) then
				entries2Ref = unequip.Parent
				unequip.Parent = spacer
				unequip.AnchorPoint = Vector2.new(1, 0.5)
				entries2Ref:Destroy()
			end

			local textLabel = spacer and (spacer:FindFirstChild("TextLabel"))

			if ((header and scrollingFrame) and close) and spacer then
				if unequip then
					if not (textLabel) then
						cleanupResult:Destroy()
						return false
					end
				else
					cleanupResult:Destroy()
					return false
				end
			else
				cleanupResult:Destroy()
				return false
			end

			for _, child in ipairs(scrollingFrame:GetChildren()) do
				if child ~= uiStroke then
					if child:IsA("GuiObject") then
						child:Destroy()
					end
				end
			end

			entries2Ref = cleanupResult:FindFirstChild("EquipBest")

			if entries2Ref then
				entries2Ref:Destroy()
			end

			entries2Ref = cleanupResult:FindFirstChildOfClass("UIAspectRatioConstraint")
			local aspectRatio, mouseEnabled = (entries2Ref and entries2Ref.AspectRatio)
				or 1.25, UserInputService.MouseEnabled
			local listLayout = not mouseEnabled
			local listLayout2, listLayout3, chilliStealPanelFrame = (if mouseEnabled then listLayout else 1.2)
				or 1, (if mouseEnabled then listLayout else 1.15) or 1

			if chilliFinderEmbedded then
				mouseEnabled = ctx2.genv
				chilliStealPanelFrame = mouseEnabled.ChilliStealPanelFrame
			else
				chilliStealPanelFrame = chilliFinderEmbedded
			end

			mouseEnabled = nil

			if chilliStealPanelFrame then
				listLayout = ctx2.genv
				mouseEnabled = listLayout.ChilliStealPanelFrame()
			else
				mouseEnabled = chilliStealPanelFrame
			end

			listLayout = mouseEnabled and (mouseEnabled:FindFirstChildOfClass("UIAspectRatioConstraint"))
			chilliStealPanelFrame = (listLayout and listLayout.AspectRatio) or (0.86 / listLayout3)
			local tempValue2 = chilliStealPanelFrame / aspectRatio
			cleanupResult.Size = (listLayout and mouseEnabled.Size) or UDim2.new(0.3 * listLayout2, 0,
				(0.62 * listLayout2) * listLayout3, 0)

			if entries2Ref then
			else
				entries2Ref = Instance.new("UIAspectRatioConstraint")
				entries2Ref.Parent = cleanupResult
			end

			entries2Ref.AspectRatio, entries2Ref.AspectType = chilliStealPanelFrame, Enum.AspectType.FitWithinMaxSize
			header.Size = UDim2.new(header.Size.X.Scale, header.Size.X.Offset, header.Size.Y.Scale * tempValue2,
				header.Size.Y.Offset)
			header.Position = UDim2.new(header.Position.X.Scale, header.Position.X.Offset,
				header.Position.Y.Scale * tempValue2, header.Position.Y.Offset)
			close.Size = UDim2.new(close.Size.X.Scale, close.Size.X.Offset, close.Size.Y.Scale * tempValue2,
				close.Size.Y.Offset)
			listLayout, listLayout2, aspectRatio = scrollingFrame.Size.Y.Scale, scrollingFrame.Position.Y.Scale, scrollingFrame.AnchorPoint.Y
			local listLayout4, textLabel2, listLayout5, hPat, factor2, frame2 = (listLayout2 - (listLayout * aspectRatio)) * tempValue2, 1 - ((1 - (listLayout2 + (listLayout * (1 - aspectRatio)))) * tempValue2), 0.115 * tempValue2, 0.02 * tempValue2, 0.06 * tempValue2, Instance.new("Frame")
			frame2.BackgroundTransparency, frame2.AnchorPoint, frame2.Position, frame2.Size = 1, Vector2.new(0.5,
				0), UDim2.new(0.5, 0, listLayout4 + hPat, 0), UDim2.new(0.92, 0, listLayout5, 0)
			frame2.Parent = cleanupResult
			listLayout = Instance.new("UIListLayout")
			listLayout.FillDirection, listLayout.HorizontalAlignment, listLayout.VerticalAlignment, listLayout.SortOrder, listLayout.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0.02, 0)
			listLayout.Parent = frame2
			local cacheFinder, nameList2 = {}, {"force", "min", "rar", "acct"}

			for index, item in ipairs(nameList2) do
				listLayout2 = unequip:Clone()
				listLayout2.AnchorPoint, listLayout2.Size = Vector2.new(0.5, 0.5), UDim2.new(0.235, 0, 1, 0)
				listLayout2.LayoutOrder = index
				listLayout2.Parent = frame2
				listLayout = checkState8(listLayout2)
				listLayout.Label.AnchorPoint, listLayout.Label.Position, listLayout.Label.Size = Vector2.new(0.5,
					0.5), UDim2.new(0.5, 0, 0.68, 0), UDim2.new(0.88, 0, 0.52, 0)
				listLayout.Cap = listLayout.Label:Clone()
				listLayout.Cap.Position, listLayout.Cap.Size, listLayout.Cap.Parent = UDim2.new(0.5, 0, 0.25,
					0), UDim2.new(0.88, 0, 0.33, 0), listLayout2
				cacheFinder[item] = listLayout
			end

			mouseEnabled = textLabel:Clone()
			mouseEnabled.AnchorPoint, mouseEnabled.Position, mouseEnabled.Size = Vector2.new(0.5, 0), UDim2.new(0.5, 0,
				(listLayout4 + (hPat * 1.6)) + listLayout5, 0), UDim2.new(0.9, 0, factor2, 0)
			mouseEnabled.TextXAlignment = Enum.TextXAlignment.Center
			listLayout = mouseEnabled:FindFirstChildOfClass("UIGradient")

			if listLayout then
				listLayout:Destroy()
			end

			mouseEnabled.Parent = cleanupResult
			nameList2 = ((listLayout4 + (hPat * 2.2)) + listLayout5) + factor2
			scrollingFrame.Size = UDim2.new(scrollingFrame.Size.X.Scale, scrollingFrame.Size.X.Offset,
				textLabel2 - nameList2, 0)
			scrollingFrame.Position = UDim2.new(scrollingFrame.Position.X.Scale, scrollingFrame.Position.X.Offset,
				nameList2 + ((textLabel2 - nameList2) * aspectRatio), 0)
			local tempValue5, entries2RefFinder = (listLayout4 + (hPat * 1.6)) + listLayout5, entries2
			entries2RefFinder.geo = {top = nameList2, st = tempValue5, bottom = textLabel2, aY = aspectRatio,
				gap = hPat, sx = scrollingFrame.Size.X, px = scrollingFrame.Position.X}

			local function collectChildren(amount)
				local clone = spacer:Clone()

				for _, child in ipairs(clone:GetChildren()) do
					if not (child:IsA("UIStroke")) then
						if not (child:IsA("UICorner")) then
							if not (child:IsA("UIGradient")) then
								child:Destroy()
							end
						end
					end
				end

				clone.AnchorPoint, clone.Position, clone.Size = Vector2.new(0.5, 0), UDim2.new(0.5, 0, tempValue5,
					0), UDim2.new(0.92, 0, amount * tempValue2, 0)
				clone.Visible = false
				clone.Parent = cleanupResult
				return clone
			end

			local children = collectChildren(((UserInputService.TouchEnabled
				and not UserInputService.KeyboardEnabled) and 0.46) or 0.32)
			entries2RefFinder, listLayout5 = collectChildren(0.13), Instance.new("UIGridLayout")
			listLayout5.CellSize, listLayout5.CellPadding, listLayout5.HorizontalAlignment, listLayout5.VerticalAlignment, listLayout5.SortOrder = UDim2.new(0.15,
				0, 0.64, 0), UDim2.new(0.025, 0, 0, 0), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder
			listLayout5.Parent = entries2RefFinder
			chilliStealPanelFrame = entries2
			chilliStealPanelFrame.opts, chilliStealPanelFrame.gl = {}, listLayout5
			entries2.tsc = {}

			for index = 1, 8, 1 do
				listLayout4 = unequip:Clone()
				listLayout4.LayoutOrder = index
				listLayout4.Parent = entries2RefFinder
				local checkState8Result = checkState8(listLayout4)
				buildUIScale(checkState8Result)

				if checkState8Result.Label then
					checkState8Result.Label.Size = UDim2.fromScale(0.88, 0.64)
					entries2.tsc[index] = Instance.new("UITextSizeConstraint", checkState8Result.Label)
				end

				tryCallFinder(listLayout4, function()
					if checkState8Result.pick then
						checkState8Result.pick()
						hasTimedOutFinder()
					end

					local fieldValue2 = ctx2.fieldValue2
					fieldValue2.drawer = nil
				end)

				entries2.opts[index] = checkState8Result
			end

			local function listLayout6(data, inputFinder, input4, input5, input6, callback, input7, input8, input9)
				local childrenFinder, uiElement = collectChildren(0.13), checkState8(unequip:Clone())
				uiElement.Button.AnchorPoint, uiElement.Button.Position, uiElement.Button.Size, uiElement.Button.Parent = Vector2.new(1,
					0.5), UDim2.new(0.96, 0, 0.5, 0), UDim2.new(0.24, 0, 0.66, 0), childrenFinder
				checkState9(uiElement, data)
				uiElement.Label.Visible = false
				local textBox = Instance.new("TextBox")
				textBox.BackgroundTransparency, textBox.AnchorPoint, textBox.Position, textBox.Size, textBox.FontFace, textBox.TextScaled, textBox.TextColor3, textBox.ClearTextOnFocus, textBox.ZIndex, textBox.Parent = 1, Vector2.new(0.5,
					0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.86, 0.7), uiElement.Label.FontFace, true, Color3.new(1, 1, 1), true, uiElement.Label.ZIndex + 1, uiElement.Button
				uiElement = Instance.new("UIStroke", textBox)
				uiElement:SetAttribute("own", true)
				uiElement.Thickness = 1
				uiElement.Transparency = 0.3
				local frame3 = Instance.new("Frame")
				frame3.BackgroundColor3, frame3.BackgroundTransparency, frame3.AnchorPoint, frame3.Position, frame3.Size = getColor(30,
					28, 42), 0, Vector2.new(0, 0.5), UDim2.new(0.06, 0, 0.5, 0), UDim2.new(0.6, 0, 0.3, 0)
				frame3.Parent = childrenFinder
				Instance.new("UICorner", frame3).CornerRadius = UDim.new(0.3, 0)
				uiElement = Instance.new("UIStroke", frame3)
				uiElement:SetAttribute("own", true)
				uiElement.Color = Color3.new(0, 0, 0)
				uiElement.Thickness = 2
				uiElement.Transparency = 0.15
				local frame4 = Instance.new("Frame")
				frame4.BackgroundColor3, frame4.Size = Color3.new(1, 1, 1), UDim2.fromScale(0, 1)
				frame4.Parent = frame3
				Instance.new("UICorner", frame4).CornerRadius = UDim.new(0.3, 0)
				uiElement = Instance.new("UIGradient", frame4)
				uiElement.Color, uiElement.Rotation = data.Color, data.Rotation
				uiElement = checkState8(unequip:Clone())
				local button = uiElement.Button
				button.AnchorPoint, button.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(1.7, 1.7)
				button.ZIndex = 5
				button.Active = false
				button.Parent = frame3
				checkState9(uiElement, stateFinder.Knob)
				uiElement.Label.Visible = false
				data = Instance.new("UIAspectRatioConstraint", button)
				data.AspectRatio, data.AspectType, data.DominantAxis = 0.55, Enum.AspectType.FitWithinMaxSize, Enum.DominantAxis.Height
				uiElement = Instance.new("TextButton")
				uiElement.Text, uiElement.BackgroundTransparency, uiElement.Position, uiElement.Size = "", 1, UDim2.new(0.02,
					0, 0, 0), UDim2.new(0.68, 0, 1, 0)
				uiElement.ZIndex = 6
				uiElement.Parent = childrenFinder
				local input

				local function doStep25(input2)
					frame4.Size, button.Position = UDim2.fromScale(input2, 1), UDim2.fromScale(input2, 0.5)
				end

				local function clampValue(amount)
					local computed = math.clamp((amount - frame3.AbsolutePosition.X) / math.max(1, frame3.AbsoluteSize.X), 0, 1)
					doStep25(computed)
					amount = input4(computed)

					if amount ~= callback() then
						input7(amount)
						checkState10(textBox, input5(amount))

						if input9 then
							input9(amount)
						end
					end
				end

				trackConnection2(uiElement.InputBegan, function(input2)
					if (input2.UserInputType == Enum.UserInputType.MouseButton1)
						or (input2.UserInputType == Enum.UserInputType.Touch) then
						input = input2
						clampValue(input2.Position.X)
					end
				end)

				trackConnection2(UserInputService.InputChanged, function(input2)
					local input3 = input
						and ((input2 == input) or ((input.UserInputType == Enum.UserInputType.MouseButton1) and (input2.UserInputType == Enum.UserInputType.MouseMovement)))

					if input3 then
						clampValue(input2.Position.X)
					end
				end)

				trackConnection2(UserInputService.InputEnded, function(input2)
					local input3 = input and ((input2 == input) or (input2.UserInputType == Enum.UserInputType.MouseButton1))

					if input3 then
						input = nil
						doStep25(inputFinder(callback()))
						hasTimedOutFinder()
						input2 = ctx2.fieldValue2
						input2.dirty = true
					end
				end)

				trackConnection2(textBox.FocusLost, function()
					local input6Result = input6(textBox.Text)

					if input6Result then
						input7(input6Result)
						hasTimedOutFinder()
					else
						local runUntilTimeoutFinder = ctx2.runUntilTimeout
						runUntilTimeoutFinder(input8)
					end

					textBox.Text = input5(callback())
					input6Result = ctx2.fieldValue2
					input6Result.dirty = true
				end)

				uiElement = {f = childrenFinder, sync = function()
					if not (input) then
						doStep25(inputFinder(callback()))
					end

					if not (textBox:IsFocused()) then
						checkState10(textBox, input5(callback()))
					end
				end}

				return uiElement
			end

			local factor3 = 5.298317366548036

			local function roundSigFigs(amount)
				local factor4 = 10 ^ math.floor(math.log10(amount) - 1)
				return math.floor((amount / factor4) + 0.5) * factor4
			end

			local function toStringOff(text)
				return ((text > 0) and (((((text % 1) == 0) and ("%d"):format(text)) or tostring(text)) .. "s")) or "Off"
			end

			listLayout4 = entries2

			listLayout4.sl = {force = listLayout6(stateFinder.Join, function(amount)
				return amount / 60
			end, function(amount)
				return math.floor((amount * 60) + 0.5)
			end, toStringOff, function(text)
				text = text:lower():gsub("[%ss]", "")
				local tempValue7 = ((text == "off") and 0) or tonumber(text)
				return tempValue7 and math.clamp(math.floor(tempValue7 + 0.5), 0, 60)
			end, function()
				return jsonFile.gap
			end, function(gap)
				jsonFile.gap = gap
			end, "Type seconds from 0 to 60, like 5", function(input)
				checkState10(cacheFinder.force.Label, toStringOff(input))
			end), min = listLayout6(stateFinder.Blue, function(amount)
				return math.clamp(math.log(amount / 5000000000) / factor3, 0, 1)
			end, function(input)
				return math.clamp(roundSigFigs(5000000000 * (200 ^ input)), 5000000000, 1000000000000)
			end, function(input)
				return scanTableFinder(input) .. "/s"
			end, function(input)
				local doStep13Result = doStep13(input)
				return doStep13Result and math.max(5000000000, doStep13Result)
			end, function()
				return jsonFile.min
			end, function(min)
				jsonFile.min = min
			end, "Type a value like 50B or 1.5T (5B/s or more)", function(input)
				checkState10(cacheFinder.min.Label, scanTableFinder(input) .. "/s")
			end)}

			listLayout5 = header:FindFirstChildOfClass("UIGradient")

			if listLayout5 then
				listLayout5.Color, listLayout5.Rotation = stateFinder.Head.Color, stateFinder.Head.Rotation
			end

			listLayout6, listLayout4, frame2, entries2Ref, hPat = entries2, entries2, entries2, header:FindFirstChild("Stroke"), header:FindFirstChild("Pattern")
			listLayout6.hg = listLayout5
			listLayout4.hStroke = entries2Ref
			frame2.hPat = hPat
			hPat = header:FindFirstChild("Title")
			checkState10(hPat, "John Hub | Egg Finder")

			if hPat then
				hPat:FindFirstChildOfClass("UIStroke")
				listLayout = {edge = Instance.new("UIStroke")}
				listLayout.edge.Color, listLayout.edge.Thickness, listLayout.edge.Enabled = Color3.new(1, 1, 1), 2, false
				listLayout.edge:SetAttribute("own", true)
				listLayout.eg = Instance.new("UIGradient", listLayout.edge)
				listLayout.eg.Rotation, listLayout.eg.Color = -11, scanTable4({{0, getColor(225, 170, 255)}, {0.5,
					getColor(250, 225, 255)}, {1, getColor(190, 120, 255)}})
				listLayout.edge.Parent = header
				listLayout.ink = Instance.new("ImageLabel")
				listLayout.ink.BackgroundTransparency, listLayout.ink.Image, listLayout.ink.ImageColor3, listLayout.ink.ScaleType, listLayout.ink.AnchorPoint, listLayout.ink.ZIndex, listLayout.ink.Visible, listLayout.ink.Parent = 1, "rbxassetid://100155632293857", getColor(0,
					0, 0), Enum.ScaleType.Stretch, Vector2.new(0.5, 0.5), math.max(1, hPat.ZIndex - 1), false, hPat.Parent
				entries2.glx = listLayout
			end

			local checkState8ResultFinder = checkState8(header:FindFirstChild("PlusEquip"))

			if checkState8ResultFinder then
				checkState8ResultFinder.Button.AnchorPoint, checkState8ResultFinder.Button.Size, checkState8ResultFinder.Button.Position = Vector2.new(0.5,
					0.5), UDim2.new(0.24, 0, 0.5, 0), UDim2.new(0.85, 0, 0.5, 0)

				if checkState8ResultFinder.Label then
					checkState8ResultFinder.Label.Size = UDim2.fromScale(0.84, 0.62)
				end

				buildUIScale(checkState8ResultFinder)

				pcall(function()
					checkState8ResultFinder.Button.Active, checkState8ResultFinder.Button.Interactable = true, true
				end)

				for _, descendant in ipairs(checkState8ResultFinder.Button:GetDescendants()) do
					if descendant:IsA("GuiObject") then
						pcall(function()
							descendant.Active = false
						end)
					end
				end

				local startTimeFinder = 0

				local function hasTimedOut4()
					if (os.clock() - startTimeFinder) < 0.25 then
						return
					end
					startTimeFinder = os.clock()
					trySound()

					if not (checkStateFinder()) then
						local fieldValue2Finder = ctx2.fieldValue2
						if fieldValue2Finder.who then
							local runUntilTimeoutFinder = ctx2.runUntilTimeout
							return runUntilTimeoutFinder("No active booking. Book hours at chillihub.pro")
						end
						local fieldValue22, fieldValue2 = ctx2.fieldValue2, ctx2.fieldValue2
						fieldValue22.drawer = "sign"
						fieldValue2.view = nil
						fieldValue2Finder = ctx2.runUntilTimeout
						return fieldValue2Finder("Sign in with your chillihub.pro account to use Auto Join")
					end

					local fieldValue23, fieldValue24 = ctx2.fieldValue2, ctx2.fieldValue2
					fieldValue23.auto = not fieldValue24.auto
					fieldValue23, fieldValue24 = ctx2.fieldValue2, ctx2.getServerTimeNow
					fieldValue23.autoAt = fieldValue24() * 1000
					scanItems4()
					fieldValue23 = ctx2.fieldValue2

					if not (fieldValue23.auto) then
						pcall(function()
							TeleportService2:SetTeleportSetting("__ChilliFinderAuto", false)
						end)
					end

					fieldValue24 = ctx2.fieldValue2
					fieldValue24.dirty = true
				end

				trackConnection2(checkState8ResultFinder.Button.Activated, hasTimedOut4)

				trackConnection2(checkState8ResultFinder.Button.InputBegan, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						hasTimedOut4()
					elseif input.UserInputType == Enum.UserInputType.Touch then
						hasTimedOut4()
					end
				end)
			end

			for _, descendant in ipairs(close:GetDescendants()) do
				if descendant:IsA("ImageLabel") then
					descendant:Destroy()
				elseif descendant:IsA("ImageButton") then
					descendant:Destroy()
				end
			end

			listLayout5 = checkState8(close)

			if listLayout5.Label then
				if listLayout5.Label:IsA("TextLabel") then
					listLayout5.Label.Visible, listLayout5.Label.RichText, listLayout5.Label.Text = true, false, ">"
				end
			end

			buildUIScale(listLayout5)

			tryCallFinder(close, function()
				chilliFinderPanelClose()
			end)

			listLayout6 = spacer:FindFirstChild("Icon")

			if listLayout6 then
				listLayout6.AnchorPoint, listLayout6.Size, listLayout6.Position = Vector2.new(0.5, 0.5), UDim2.new(0.15, 0,
					1.3, 0), UDim2.new(0.09, 0, 0.5, 0)
			end

			textLabel.AnchorPoint, textLabel.TextXAlignment = Vector2.new(0, 0.5), Enum.TextXAlignment.Left
			textLabel.Size, textLabel.Position = UDim2.new(0.5, 0, 0.4, 0), UDim2.new(0.18, 0, 0.3, 0)

			if not (textLabel:FindFirstChildOfClass("UIGradient")) then
				Instance.new("UIGradient").Parent = textLabel
			end

			factor2 = textLabel:Clone()
			factor2.Name = "Value"
			factor2.Size, factor2.Position = UDim2.new(0.5, 0, 0.36, 0), UDim2.new(0.18, 0, 0.72, 0)
			factor2.Parent = spacer
			factor2:FindFirstChildOfClass("UIGradient"):Destroy()
			factor2.RichText = true
			unequip.AnchorPoint, unequip.Size, unequip.Position = Vector2.new(1, 0.5), UDim2.new(0.2, 0, 0.7,
				0), UDim2.new(0.975, 0, 0.5, 0)
			listLayout5 = checkState8(unequip).Label

			if listLayout5 then
				listLayout5.Size = UDim2.fromScale(0.8, 0.56)
			end

			chilliStealPanelFrame = spacer:FindFirstChild("Btns")

			if chilliStealPanelFrame then
				chilliStealPanelFrame:Destroy()
			end

			uiStroke.Size = UDim2.new(uiStroke.Size.X.Scale, uiStroke.Size.X.Offset, uiStroke.Size.Y.Scale * 0.48,
				uiStroke.Size.Y.Offset)
			uiStroke.Visible = false
			uiStroke.Parent = nil
			entries2.cards = {}

			for index = 1, 30, 1 do
				chilliStealPanelFrame = uiStroke:Clone()
				chilliStealPanelFrame.Visible = false
				chilliStealPanelFrame.LayoutOrder = index
				chilliStealPanelFrame.Parent = scrollingFrame
				local spacer2, state = chilliStealPanelFrame:FindFirstChild("Spacer"), {f = chilliStealPanelFrame}
				state.icon = spacer2:FindFirstChild("Icon")
				state.name = spacer2:FindFirstChild("TextLabel")
				state.val = spacer2:FindFirstChild("Value")
				state.b = checkState8(spacer2:FindFirstChild("Unequip"))
				state.ng = state.name:FindFirstChildOfClass("UIGradient")
				state.name.TextScaled, state.name.TextTruncate, state.name.Size = false, Enum.TextTruncate.AtEnd, UDim2.new(0.585,
					0, 0.4, 0)
				listLayout2 = state.val:Clone()
				listLayout2.Name, listLayout2.RichText, listLayout2.TextScaled, listLayout2.AnchorPoint, listLayout2.Position, listLayout2.Size, listLayout2.AutomaticSize, listLayout2.TextXAlignment, listLayout2.ZIndex = "Mut", false, false, Vector2.new(0.5,
					1), UDim2.new(0.09, 0, 0.97, 0), UDim2.new(0, 0, 0.3, 0), Enum.AutomaticSize.X, Enum.TextXAlignment.Center, (state.icon
					and (state.icon.ZIndex + 1)) or listLayout2.ZIndex
				listLayout2.Visible = false
				listLayout2.Parent = spacer2
				state.mh, state.mg = listLayout2, Instance.new("UIGradient", listLayout2)
				buildUIScale(state.b)

				tryCallFinder(state.b.Button, function()
					local fieldValue = state.e
					if not (fieldValue) then
						return
					end

					if not (checkStateFinder()) then
						local fieldValue2 = ctx2.fieldValue2
						if fieldValue2.who then
							local runUntilTimeoutFinder = ctx2.runUntilTimeout
							return runUntilTimeoutFinder("No active booking. Book hours at chillihub.pro")
						end
						fieldValue2 = ctx2.fieldValue2
						fieldValue2.drawer = "sign"
						fieldValue2 = ctx2.runUntilTimeout
						return fieldValue2("Sign in with your chillihub.pro account to join")
					end

					if tempValue9 then
						if tempValue9.e == fieldValue then
							checkState6("Stopped")
						else
							checkState7(fieldValue)
						end
					else
						checkState7(fieldValue)
					end
				end)

				entries2.cards[index] = state
			end

			entries2.tpl = uiStroke

			do
				entries2Ref = entries2.geo
				header = entries2Ref.bottom - entries2Ref.top
				frame2 = (uiStroke.Size.Y.Scale * header) * 0.72
				listLayout = collectChildren(frame2 / tempValue2)
				listLayout.AnchorPoint, listLayout.Position = Vector2.new(0.5, 1), UDim2.new(0.5, 0, entries2Ref.bottom, 0)
				listLayout.Visible = true
				entries2Ref.bottom = (entries2Ref.bottom - frame2) - entries2Ref.gap
				chilliStealPanelFrame = entries2Ref.bottom - entries2Ref.top
				scrollingFrame.Size, scrollingFrame.Position = UDim2.new(entries2Ref.sx.Scale, entries2Ref.sx.Offset,
					chilliStealPanelFrame, 0), UDim2.new(entries2Ref.px.Scale, entries2Ref.px.Offset, entries2Ref.top + (chilliStealPanelFrame * entries2Ref.aY), 0)
				uiStroke.Size = UDim2.new(uiStroke.Size.X.Scale, uiStroke.Size.X.Offset, 0.2, 0)
				listLayout5 = entries2

				for _, card in ipairs(listLayout5.cards) do
					card.f.Size = uiStroke.Size
				end

				factor2 = entries2
				factor2.foot, entries2Ref.bFull, entries2Ref.bFoot, entries2Ref.cFull = listLayout, (entries2Ref.bottom + frame2) + entries2Ref.gap, entries2Ref.bottom, (0.2 * chilliStealPanelFrame) / header
				listLayout2 = entries2.cards[1]
				listLayout3 = listLayout2.name:Clone()
				listLayout3.Name, listLayout3.Text, listLayout3.TextScaled, listLayout3.TextTruncate, listLayout3.AnchorPoint, listLayout3.Position, listLayout3.Size = "Link", "https://chillihub.pro", true, Enum.TextTruncate.None, Vector2.new(0,
					0.5), UDim2.new(0.05, 0, 0.32, 0), UDim2.new(0.62, 0, 0.4, 0)
				listLayout3.Parent = listLayout
				aspectRatio = listLayout3:FindFirstChildOfClass("UIGradient")

				if aspectRatio then
					aspectRatio.Color = ColorSequence.new(Color3.new(1, 1, 1), getColor(225, 225, 235))
					aspectRatio.Rotation = 90
				end

				listLayout4 = listLayout2.val:Clone()
				listLayout4.Name, listLayout4.RichText, listLayout4.TextScaled, listLayout4.AnchorPoint, listLayout4.Position, listLayout4.Size = "Sub", true, true, Vector2.new(0,
					0.5), UDim2.new(0.05, 0, 0.72, 0), UDim2.new(0.62, 0, 0.32, 0)
				listLayout4.Text = "<font color=\"#C8C2DC\">Create your account and get Chilli Finder</font>"
				listLayout4.Parent = listLayout
				local checkState8Result = checkState8(unequip:Clone())
				checkState8Result.Button.AnchorPoint, checkState8Result.Button.Position, checkState8Result.Button.Size, checkState8Result.Button.Parent = Vector2.new(1,
					0.5), UDim2.new(0.97, 0, 0.5, 0), UDim2.new(0.27, 0, 0.62, 0), listLayout
				checkState10(checkState8Result.Label, "Copy Link")
				checkState8Result.Label.Size = UDim2.fromScale(0.82, 0.56)
				checkState9(checkState8Result, stateFinder.Gold)
				buildUIScale(checkState8Result)

				tryCallFinder(checkState8Result.Button, function()
					local callResult = pcall(setclipboard, chillihubUrl)
					checkState10(checkState8Result.Label, (callResult and "Copied!") or "chillihub.pro")
					local runUntilTimeoutFinder = ctx2.runUntilTimeout
					runUntilTimeoutFinder((callResult and "chillihub.pro copied, paste it in your browser") or "Open chillihub.pro in your browser")

					task.delay(2, function()
						checkState10(checkState8Result.Label, "Copy Link")
					end)
				end)
			end

			local frame3 = Instance.new("Frame")
			frame3.BackgroundTransparency, frame3.AnchorPoint, frame3.Position, frame3.Size = 1, Vector2.new(0.5,
				0), UDim2.new(0.5, 0, nameList2, 0), UDim2.new(0.9, 0, (textLabel2 - nameList2) - 0.02, 0)
			frame3.Visible = false
			frame3.ZIndex = 5
			frame3.Parent = cleanupResult
			listLayout2 = Instance.new("UIListLayout")
			listLayout2.Padding, listLayout2.SortOrder, listLayout2.HorizontalAlignment = UDim.new((chilliFinderEmbedded and 0.022) or 0.018,
				0), Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center
			listLayout2.Parent = frame3
			local fontFace = textLabel.FontFace

			local function destroyInstancesFinder(layoutOrder, input, text)
				local clone = textLabel:Clone()
				local uiGradient = clone:FindFirstChildOfClass("UIGradient")

				if uiGradient then
					uiGradient:Destroy()
				end

				clone.AnchorPoint, clone.Position, clone.Size, clone.LayoutOrder, clone.TextXAlignment, clone.Text = Vector2.zero, UDim2.new(), UDim2.new(1,
					0, input, 0), layoutOrder, Enum.TextXAlignment.Center, text or ""
				clone.ZIndex = 6
				clone.Parent = frame3
				return clone
			end

			local function createFrame(layoutOrder, input)
				local frame4 = Instance.new("Frame")
				frame4.BackgroundTransparency, frame4.Size = 1, UDim2.new(1, 0, input, 0)
				frame4.LayoutOrder = layoutOrder
				frame4.ZIndex = 6
				frame4.Parent = frame3
				frame4:SetAttribute("ac", true)
				return frame4
			end

			local function doStep26(layoutOrder, input, inputFinder, input2, input3, parent)
				local clone = unequip:Clone()
				clone.AnchorPoint, clone.Position, clone.Size = Vector2.new(1, 0.5), UDim2.new(1, 0, 0.5,
					0), UDim2.new(input, 0, 1, 0)
				clone.LayoutOrder = layoutOrder
				clone.ZIndex = 7
				clone.Parent = parent
				layoutOrder = checkState8(clone)
				checkState10(layoutOrder.Label, inputFinder)

				if layoutOrder.Label then
					layoutOrder.Label.Size = UDim2.fromScale(0.84, 0.6)
				end

				checkState9(layoutOrder, input2)
				buildUIScale(layoutOrder)
				tryCallFinder(clone, input3)
				return layoutOrder
			end

			local function doStep27(input, inputFinder, input2)
				local frame4, destroyInstancesFinderResult = createFrame(input,
					(chilliFinderEmbedded and 0.085) or 0.07), destroyInstancesFinder(0, 1, inputFinder)
				destroyInstancesFinderResult.AnchorPoint, destroyInstancesFinderResult.Position, destroyInstancesFinderResult.Size, destroyInstancesFinderResult.TextXAlignment = Vector2.new(0,
					0.5), UDim2.new(0.02, 0, 0.5, 0), UDim2.new(0.64, 0, 0.62, 0), Enum.TextXAlignment.Left
				destroyInstancesFinderResult.Parent = frame4
				return doStep26(0, 0.3, "", stateFinder.Blue, input2, frame4)
			end

			entries2Ref = createFrame(9, 0)
			Instance.new("UIFlexItem", entries2Ref).FlexMode = Enum.UIFlexMode.Fill
			local frame4 = Instance.new("Frame")
			frame4.BackgroundTransparency, frame4.AnchorPoint, frame4.Position = 1, Vector2.new(0.5,
				0.5), UDim2.fromScale(0.5, 0.5)
			frame4.ZIndex = 6
			frame4.Parent = entries2Ref

			local function parent()
				frame4.Size = UDim2.new(1, 0, 0, frame3.AbsoluteSize.Y * 0.095)
			end

			parent()
			trackConnection2(frame3:GetPropertyChangedSignal("AbsoluteSize"), parent)
			listLayout4 = Instance.new("UIListLayout")
			listLayout4.FillDirection, listLayout4.HorizontalAlignment, listLayout4.VerticalAlignment, listLayout4.SortOrder, listLayout4.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0.025, 0)
			listLayout4.Parent = frame4

			local function doStep28(data, placeholderText)
				local uiStroke2 = checkState8(unequip:Clone())
				local button = uiStroke2.Button
				button.AnchorPoint, button.Position, button.Size = Vector2.new(0.5, 0), UDim2.new(0.5, 0, data,
					0), UDim2.new(0.92, 0, 0.22, 0)
				button.Active = false
				checkState9(uiStroke2, stateFinder.Field)
				uiStroke2.Label.Visible = false
				data = Instance.new("TextBox")
				data.BackgroundTransparency, data.AnchorPoint, data.Position, data.Size, data.FontFace, data.TextScaled, data.TextColor3, data.PlaceholderText, data.PlaceholderColor3, data.Text, data.ClearTextOnFocus, data.TextXAlignment = 1, Vector2.new(0,
					0.5), UDim2.new(0.05, 0, 0.5, 0), UDim2.new(0.9, 0, 1, 0), fontFace, true, Color3.new(1, 1, 1), placeholderText, getColor(196, 190, 214), "", false, Enum.TextXAlignment.Left
				data.ZIndex = uiStroke2.Label.ZIndex + 1
				placeholderText = Instance.new("UIPadding", data)
				placeholderText.PaddingTop, placeholderText.PaddingBottom = UDim.new(0.21, 0), UDim.new(0.21, 0)
				uiStroke2 = Instance.new("UIStroke", data)
				uiStroke2:SetAttribute("own", true)
				uiStroke2.Thickness = 1.2
				uiStroke2.Transparency = 0.35
				data.Parent = button
				button.Parent = children
				return data
			end

			local function doStep29(data, input, inputFinder, input2)
				local clone = unequip:Clone()
				clone.AnchorPoint, clone.Position, clone.Size = Vector2.new(0.5, 0), UDim2.new(data, 0, 0.73,
					0), UDim2.new(0.44, 0, 0.22, 0)
				clone.Parent = children
				data = checkState8(clone)
				checkState10(data.Label, input)
				data.Label.Size = UDim2.fromScale(0.86, 0.82)
				checkState9(data, inputFinder)
				buildUIScale(data)
				tryCallFinder(clone, input2)
				return data
			end

			entries2Ref = entries2.cards[1].val:Clone()
			entries2Ref.Name, entries2Ref.RichText, entries2Ref.TextScaled, entries2Ref.TextXAlignment, entries2Ref.AnchorPoint, entries2Ref.Position, entries2Ref.Size = "Hint", true, true, Enum.TextXAlignment.Center, Vector2.new(0.5,
				0), UDim2.new(0.5, 0, 0.04, 0), UDim2.new(0.9, 0, 0.15, 0)
			entries2Ref.Parent = children
			entries2.hint0 = "<font color=\"#C8C2DC\">Sign in with your </font><font color=\"#FFFFFF\">chillihub.pro</font><font color=\"#C8C2DC\"> account</font>"
			listLayout6 = entries2
			entries2Ref.Text, listLayout6.hint = listLayout6.hint0, entries2Ref
			local usernameOrEmail = doStep28(0.23, "Username or email")
			ctx3.usernameOrEmail = usernameOrEmail
			local password = doStep28(0.48, "Password")
			ctx3.usernameOrEmail.Text = tostring(ctx2.cachedFile.u or "")
			listLayout6 = ctx2.fieldValue2
			local sess, tempValue8, tempValue14 = (listLayout6.sess and "")
				or tostring(ctx2.cachedFile.p or ""), false, false
			ctx3.sess = sess

			if ctx2.cachedFile.p then
				ctx2.cachedFile.p = nil
				aspectRatio = ctx2.saveFile
				aspectRatio(ctx2.cachedFile)
			end

			ctx3.field = function()
				tempValue8 = true
				password.Text = (tempValue14 and ctx3.sess) or string.rep("*", #ctx3.sess)
				password.CursorPosition = #ctx3.sess + 1
				tempValue8 = false
			end

			ctx3.field()

			trackConnection2(password:GetPropertyChangedSignal("Text"), function()
				if tempValue8 then
					return
				end
				local text = password.Text

				if tempValue14 then
					ctx3.sess = text
				elseif #text > #ctx3.sess then
					ctx3.sess ..= text:sub(#ctx3.sess + 1)
				elseif #text < #ctx3.sess then
					ctx3.sess = ctx3.sess:sub(1, #text)
				end

				if not (tempValue14) then
					text = ctx3.field
					text()
				end
			end)

			password.Size = UDim2.new(0.74, 0, 1, 0)
			local checkState8Result2 = checkState8(unequip:Clone())
			checkState8Result2.Button.AnchorPoint, checkState8Result2.Button.Position, checkState8Result2.Button.Size, checkState8Result2.Button.ZIndex, checkState8Result2.Button.Parent = Vector2.new(1,
				0.5), UDim2.new(0.985, 0, 0.5, 0), UDim2.new(0.19, 0, 0.78, 0), password.ZIndex, password.Parent
			checkState8Result2.Label.Size = UDim2.fromScale(0.84, 0.6)
			checkState10(checkState8Result2.Label, "Show")
			checkState9(checkState8Result2, stateFinder.Off)
			buildUIScale(checkState8Result2)

			tryCallFinder(checkState8Result2.Button, function()
				tempValue14 = not tempValue14
				checkState10(checkState8Result2.Label, (tempValue14 and "Hide") or "Show")
				checkState9(checkState8Result2, (tempValue14 and stateFinder.Blue) or stateFinder.Off)
				local field = ctx3.field
				field()
			end)

			local function checkState11(input)
				if ctx2.httpRequest then
					local tempValue7

					if input then
						tempValue7 = { rt = ctx2.cachedFile.rt }
					else
						local match = ctx3.usernameOrEmail.Text:match("^%s*(.-)%s*$")
						if match == "" then
							return ctx2.runUntilTimeout("Enter your username or email")
						end

						if ctx3.sess == "" then
							return ctx2.runUntilTimeout("Enter your password")
						end
						local entries5 = { u = match, p = ctx3.sess }
						ctx2.cachedFile.u = match
						tempValue7 = entries5
					end

					local tempValue15 = ctx2.tryCall2()
					local tempValue16 = ctx2.tryCall()
					local computed = math.floor(ctx2.getServerTimeNow() * 1000)
					tempValue7.hwid = tempValue15
					tempValue7.hw2 = tempValue16
					tempValue7.ts = computed

					if not input then
						ctx2.fieldValue2.acct = "Signing in..."
					end

					local function tryCall4()
						local callResult, result = pcall(ctx2.httpRequest, {
							Url = ctx2.robloxMcpUrl .. "joiner/login",
							Method = "POST",
							Headers = { ["Content-Type"] = "text/plain" },
							Body = ctx2.scanItems(ctx2.HttpService:JSONEncode(tempValue7), ctx2.fieldValue),
						})

						callResult = callResult and type(result) == "table" and ctx2.hasTimedOut(result.Body, ctx2.fieldValue)
						ctx2.fieldValue2.dirty = true

						if callResult then
							if callResult.rt == false then
								local fieldValue2 = ctx2.fieldValue2
								ctx2.cachedFile.rt = nil
								fieldValue2.who = nil
								ctx2.saveFile(ctx2.cachedFile)
							end

							if callResult.rt then
								ctx2.cachedFile.rt = callResult.rt
								ctx2.saveFile(ctx2.cachedFile)
							end

							if not input then
								ctx3.sess = ""
								ctx3.field()
							end

							if callResult.ok then
								local fieldValue2Finder = ctx2.fieldValue2
								fieldValue2Finder.who = callResult.username

								if not callResult.active then
									local booking = callResult.booking or {}
									local fieldValue22 = ctx2.fieldValue2
									local now2 = os.clock()
									local clamp = math.clamp
									local startsInMs = booking.startsInMs
									fieldValue22.whoAt = now2 + clamp((startsInMs or 60000) / 1000 + 2, 5, 30)

									if ctx2.fieldValue2.drawer == "sign" then
										ctx2.fieldValue2.drawer = nil
									end

									local fieldValue2 = ctx2.fieldValue2
									local acct

									if booking.state ~= "upcoming" then
										acct = ("Hi %s, no active booking. Book hours at chillihub.pro"):format(callResult.username)
									else
										acct = ("Hi %s, your %s booking starts in %d min"):format(callResult.username, booking.plan or "",
											(booking.startsInMs or 0) // 60000)

										if not acct then
											acct = ("Hi %s, no active booking. Book hours at chillihub.pro"):format(callResult.username)
											fieldValue2.acct = acct
											return
										end
									end

									fieldValue2.acct = acct
									return
								end

								ctx2.tryCall3()
								ctx2.genv.ChilliFinderOwner = ctx2.fieldValue2.me

								ctx2.fieldValue2.sess = {
									token = callResult.token,
									secret = callResult.secret,
									plan = callResult.plan,
									delayMs = callResult.delayMs,
									endTs = callResult.endTs,
									username = callResult.username,
								}

								table.clear(ctx2.fieldValue2.eggs)
								table.clear(ctx2.fieldValue2.seen)
								local fieldValue23 = ctx2.fieldValue2
								local fieldValue24 = ctx2.fieldValue2
								local fieldValue25 = ctx2.fieldValue2
								local fieldValue26 = ctx2.fieldValue2
								local fieldValue27 = ctx2.fieldValue2

								if fieldValue2Finder then
									fieldValue23.last = 0
									fieldValue24.wsAt = 0
									fieldValue25.acct = nil
									fieldValue26.view = nil
									fieldValue27.drawer = nil
									ctx2.field()
								end
							else
								ctx2.fieldValue2.acct = callResult.error or "Sign in failed"
								if not input then
									ctx2.fieldValue2.who = nil
									return
								end
							end
						elseif not input then
							ctx2.fieldValue2.acct = "Could not reach chillihub.pro, try again"
							return
						end
					end

					task.spawn(tryCall4)
					return
				end

				return ctx2.runUntilTimeout("This executor cannot send requests")
			end

			trackConnection2(ctx3.usernameOrEmail.FocusLost, function(enterPressed)
				if enterPressed then
					password:CaptureFocus()
				end
			end)

			trackConnection2(password.FocusLost, function(enterPressed)
				if enterPressed then
					checkState11()
				end
			end)

			doStep29(0.26, "Sign In", stateFinder.Join, checkState11)
			local signUp

			signUp = doStep29(0.74, "Sign Up", stateFinder.Gold, function()
				local callResult = pcall(setclipboard, chillihubUrl)
				checkState10(signUp.Label, (callResult and "Copied!") or "chillihub.pro")

				task.delay(2, function()
					checkState10(signUp.Label, "Sign Up")
				end)

				local runUntilTimeoutFinder = ctx2.runUntilTimeout
				runUntilTimeoutFinder((callResult and "Link copied, open chillihub.pro in your browser to sign up") or "Open chillihub.pro in your browser to sign up")
			end)

			listLayout5 = entries2
			listLayout5.user, listLayout5.sib = ctx3.usernameOrEmail, children
			local fieldValue28 = ctx2.fieldValue2

			fieldValue28.relogin = function()
				checkState11(true)
			end

			header = ctx2.fieldValue2

			if not (header.sess) then
				if ctx2.cachedFile.rt then
					task.defer(checkState11, true)
				elseif ctx3.sess ~= "" then
					task.defer(checkState11)
				end
			end

			entries2Ref = {ac = {}}
			entries2Ref.ac.head = destroyInstancesFinder(-1, 0.07, "")
			listLayout = spacer:Clone()

			for _, child in ipairs(listLayout:GetChildren()) do
				if not (child:IsA("UIStroke")) then
					if not (child:IsA("UICorner")) then
						if not (child:IsA("UIGradient")) then
							child:Destroy()
						end
					end
				end
			end

			listLayout.AnchorPoint, listLayout.Position, listLayout.Size = Vector2.zero, UDim2.new(), UDim2.new(1, 0,
				0.2, 0)
			listLayout.LayoutOrder = 0
			listLayout.ZIndex = 6
			listLayout.Visible = true
			listLayout.Parent = frame3
			listLayout:SetAttribute("ac", true)
			listLayout6 = Instance.new("UIGridLayout")
			listLayout6.CellSize, listLayout6.CellPadding, listLayout6.HorizontalAlignment, listLayout6.VerticalAlignment, listLayout6.SortOrder = UDim2.new(0.31,
				0, 0.42, 0), UDim2.new(0.02, 0, 0.06, 0), Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder
			listLayout6.Parent = listLayout
			entries2Ref.ac.info = {}
			listLayout6 = {"PLAN", "TIME LEFT", "ENDS AT", "FEED", "DELAY", "FINDER"}

			for index, item in ipairs(listLayout6) do
				listLayout3 = Instance.new("Frame")
				listLayout3.BackgroundTransparency = 1
				listLayout3.LayoutOrder = index
				listLayout3.ZIndex = 7
				listLayout3.Parent = listLayout
				frame2 = entries2.cards[1].val:Clone()
				frame2.RichText, frame2.TextScaled, frame2.AnchorPoint, frame2.Position, frame2.Size, frame2.TextXAlignment, frame2.ZIndex, frame2.Text = true, true, Vector2.new(0.5,
					0), UDim2.new(0.5, 0, 0, 0), UDim2.new(1, 0, 0.38, 0), Enum.TextXAlignment.Center, 8, "<font color=\"#C8C2DC\">" .. (item .. "</font>")
				frame2.Parent = listLayout3
				textLabel2 = entries2.cards[1].name:Clone()
				textLabel2.TextScaled, textLabel2.TextTruncate, textLabel2.AnchorPoint, textLabel2.Position, textLabel2.Size, textLabel2.TextXAlignment = true, Enum.TextTruncate.None, Vector2.new(0.5,
					1), UDim2.new(0.5, 0, 1, 0), UDim2.new(1, 0, 0.58, 0), Enum.TextXAlignment.Center
				textLabel2.ZIndex = 8
				textLabel2.Text = ""
				textLabel2.Parent = listLayout3
				entries2Ref.ac.info[item] = {l = textLabel2, g = textLabel2:FindFirstChildOfClass("UIGradient")}
			end

			local function doStep30(input, _, inputFinder, keyName, input2)
				local doStep27Result = doStep27(input, _, function()
				end)

				local label = doStep27Result.Label
				local textBox = Instance.new("TextBox")
				textBox.BackgroundTransparency, textBox.AnchorPoint, textBox.Position, textBox.Size, textBox.FontFace, textBox.TextScaled, textBox.TextColor3, textBox.TextTransparency, textBox.Text, textBox.PlaceholderText, textBox.ClearTextOnFocus, textBox.ZIndex, textBox.Parent = 1, label.AnchorPoint, label.Position, label.Size, fontFace, true, Color3.new(1,
					1, 1), 1, "", "0-" .. (inputFinder .. "s"), true, label.ZIndex + 1, label.Parent

				trackConnection2(textBox.Focused, function()
					textBox.TextTransparency = 0
					label.Visible = false
				end)

				trackConnection2(textBox.FocusLost, function()
					local tempValue7 = textBox.Text:lower():gsub("%s", "")
					local match, tempValue15 = tempValue7:match("^(%d*%.?%d+)([sm]?)$")
					local match2 = ((tempValue7 == "off") and 0)
						or (match and (tonumber(match) * (((tempValue15 == "m") and 60) or 1)))

					if match2 then
						jsonFile[keyName] = math.clamp(math.floor(match2 + 0.5), 0, inputFinder)
						hasTimedOutFinder()
						scanItems4()
					else
						tempValue7 = ctx2.runUntilTimeout
						tempValue7(input2)
					end

					match2 = ctx2.fieldValue2
					textBox.Text = ""
					textBox.TextTransparency = 1
					label.Visible = true
					match2.dirty = true
				end)

				return doStep27Result
			end

			entries2Ref.ac.age = doStep30(3, "Max egg age for Auto Join", 120, "age", "Type seconds from 0 to 120, like 45 or 1.5m (0 = Off)")
			entries2Ref.ac.night = doStep30(4, "Skip joins before night", 60, "night", "Type seconds from 0 to 60, like 15 (0 = Off)")

			entries2Ref.ac.hold = doStep27(5, "Wait if egg here matches filter", function()
				jsonFile.hold = not jsonFile.hold
				hasTimedOutFinder()
			end)

			entries2Ref.ac.rel = (if chilliFinderEmbedded then not chilliFinderEmbedded else doStep27(6,
				"Auto load after join", function()
				jsonFile.reload = not jsonFile.reload
				hasTimedOutFinder()
			end)) or nil

			entries2Ref.ac.out = doStep26(2, 0.31, "Sign Out", stateFinder.Stop, function()
				ctx2.cachedFile.rt = nil
				ctx3.sess = ""
				local field = ctx3.field
				field()
				doStep17("Signed out")
				local fieldValue2, fieldValue2Finder = ctx2.fieldValue2, ctx2.fieldValue2
				fieldValue2.who = nil
				fieldValue2Finder.view = nil
			end, frame4)

			entries2Ref.ac.back = doStep26(3, 0.31, "Back", stateFinder.Off, function()
				local fieldValue2 = ctx2.fieldValue2
				fieldValue2.view = nil
			end, frame4)

			entries2Ref.ac.list = doStep27(1, "Egg list", function()
				jsonFile.list = ((jsonFile.list or 0) + 1) % 3
				hasTimedOutFinder()
				scanItems4()
			end)

			do
				local frame5 = Instance.new("Frame")
				frame5.BackgroundTransparency, frame5.Size = 1, UDim2.new(1, 0, 0.99, 0)
				frame5.LayoutOrder = 20
				frame5.ZIndex = 6
				frame5.Visible = false
				frame5.Parent = frame3
				frame5:SetAttribute("eg", true)
				local _ = ""
				listLayout = checkState8(unequip:Clone())
				parent = listLayout.Button
				parent.AnchorPoint, parent.Position, parent.Size = Vector2.zero, UDim2.new(0.005, 0, 0, 0), UDim2.new(0.6,
					0, 0.07, 0)
				parent.Active = false
				parent.Parent = frame5
				checkState9(listLayout, stateFinder.Field)

				if listLayout.Label then
					listLayout.Label.Visible = false
				end

				local textBox = Instance.new("TextBox")
				textBox.BackgroundTransparency, textBox.AnchorPoint, textBox.Position, textBox.Size, textBox.FontFace, textBox.TextScaled, textBox.TextColor3, textBox.PlaceholderText, textBox.PlaceholderColor3, textBox.Text, textBox.ClearTextOnFocus, textBox.TextXAlignment, textBox.ZIndex = 1, Vector2.new(0,
					0.5), UDim2.new(0.06, 0, 0.5, 0), UDim2.new(0.88, 0, 1, 0), fontFace, true, Color3.new(1, 1, 1), "Search eggs", getColor(196, 190, 214), "", false, Enum.TextXAlignment.Left, ((listLayout.Label and listLayout.Label.ZIndex) or 8) + 1
				textBox.Parent = parent
				chilliStealPanelFrame = Instance.new("UIPadding", textBox)
				chilliStealPanelFrame.PaddingTop, chilliStealPanelFrame.PaddingBottom = UDim.new(0.24, 0), UDim.new(0.24, 0)
				textLabel2 = Instance.new("UIStroke", textBox)
				textLabel2:SetAttribute("own", true)
				textLabel2.Thickness = 1.2
				textLabel2.Transparency = 0.35
				local clone = entries2.cards[1].val:Clone()
				clone.RichText, clone.TextScaled, clone.AnchorPoint, clone.Position, clone.Size, clone.TextXAlignment = true, true, Vector2.new(1,
					0), UDim2.new(0.99, 0, 0.012, 0), UDim2.new(0.38, 0, 0.048, 0), Enum.TextXAlignment.Right
				clone.ZIndex = 8
				clone.Parent = frame5

				local function createFrame2(input, instance)
					local frame6 = Instance.new("Frame")
					frame6.BackgroundTransparency, frame6.Position, frame6.Size = 1, UDim2.new(0, 0, input, 0), UDim2.new(1,
						0, instance, 0)
					frame6.ZIndex = 6
					frame6.Parent = frame5
					instance = Instance.new("UIListLayout")
					instance.FillDirection, instance.HorizontalAlignment, instance.VerticalAlignment, instance.SortOrder, instance.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center, Enum.SortOrder.LayoutOrder, UDim.new(0.014, 0)
					instance.Parent = frame6
					return frame6
				end

				local frame6, frame7, scrollingFrame2 = createFrame2(0.085, 0.068), createFrame2(0.9,
					0.095), Instance.new("ScrollingFrame")
				scrollingFrame2.BackgroundTransparency, scrollingFrame2.BorderSizePixel, scrollingFrame2.Position, scrollingFrame2.Size, scrollingFrame2.ScrollBarThickness, scrollingFrame2.ScrollBarImageColor3, scrollingFrame2.CanvasSize, scrollingFrame2.AutomaticCanvasSize, scrollingFrame2.ScrollingDirection = 1, 0, UDim2.new(0,
					0, 0.168, 0), UDim2.new(1, 0, 0.72, 0), 4, getColor(200, 190, 230), UDim2.new(), Enum.AutomaticSize.Y, Enum.ScrollingDirection.Y
				scrollingFrame2.ZIndex = 7
				scrollingFrame2.Parent = frame5
				local uiGridLayout = Instance.new("UIGridLayout")
				uiGridLayout.SortOrder, uiGridLayout.HorizontalAlignment, uiGridLayout.CellPadding = Enum.SortOrder.LayoutOrder, Enum.HorizontalAlignment.Center, UDim2.fromOffset(6, 6)
				uiGridLayout.Parent = scrollingFrame2
				header = Instance.new("UIPadding", scrollingFrame2)
				header.PaddingTop, header.PaddingBottom, header.PaddingLeft, header.PaddingRight = UDim.new(0,
					4), UDim.new(0, 6), UDim.new(0, 4), UDim.new(0, 9)

				local function clampValue4()
					local tempValue7 = scrollingFrame2.AbsoluteSize.X - 13

					if tempValue7 > 40 then
						local computed = math.floor((tempValue7 - 18) / 4)
						uiGridLayout.CellSize = UDim2.fromOffset(computed, math.floor(computed * 1.02))
					end
				end

				trackConnection2(scrollingFrame2:GetPropertyChangedSignal("AbsoluteSize"), clampValue4)
				local list3, amount, tempValue15, items, iMap2 = {}, 0, false, {{"All", 0}, {"Divine", 10}, {"Eternal", 9},
					{"Secret", 8}, {"Picked", -1}}, {}

				local function scanTable6()
					local length = #(jsonFile.only or {})
					clone.Text = ((length > 0) and ("<font color=\"#7CF25A\">" .. (length .. " picked</font>")))
						or "<font color=\"#C8C2DC\">All eggs</font>"

					for index, item in ipairs(items) do
						local iEntry, amountRef = iMap2[index], amount
						checkState9(iEntry, ((amountRef == item[2]) and stateFinder.Gold) or stateFinder.Off)
					end

					for index, item in ipairs(list3) do
						length, index = tempValue10

						if length then
							local tempValue10Ref = tempValue10
							index = tempValue10Ref[item.n] == true
						else
							index = length
						end

						local fieldValue, tempValue7 = item.b, (amount == 0) or ((amount == -1) and index)
						local tempValue16 = (tempValue7 or (item.r == amount)) and ((_ == "") or (item.l:find(_, 1,
							true) ~= nil))
						fieldValue.Visible = tempValue16
						item.st.Color, item.st.Thickness, item.st.Transparency = (index and getColor(255, 204,
							64)) or item.c, (index and 2.5) or 1.5, (index and 0) or 0.6
						item.b.BackgroundColor3, item.dot.Visible = (index and getColor(48, 38, 22)) or getColor(24, 21,
							34), index == true
					end
				end

				for index, item in ipairs(items) do
					iMap2[index] = doStep26(index, 0.18, item[1], stateFinder.Off, function()
						amount = item[2]
						scanTable6()
						scrollingFrame2.CanvasPosition = Vector2.zero
					end, frame6)

					if iMap2[index].Label then
						iMap2[index].Label.Size = UDim2.fromScale(0.86, 0.58)
					end
				end

				trackConnection2(textBox:GetPropertyChangedSignal("Text"), function()
					_ = textBox.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
					scanTable6()
					scrollingFrame2.CanvasPosition = Vector2.zero
				end)

				local function doStep25(input)
					local only = ((type(jsonFile.only) == "table") and jsonFile.only) or {}
					local pos = table.find(only, input)

					if pos then
						table.remove(only, pos)
					else
						only[#only + 1] = input
					end

					jsonFile.only = only
					scanItems3()
					hasTimedOutFinder()
					scanItems4()
					scanTable6()
				end

				local function scanTable8()
					if tempValue15 then
						return
					end
					tempValue15 = true
					local list4 = {}

					pcall(function()
						local displayNameMap = {}

						for key, value in next, require(ReplicatedStorage2.Data.Assets).Directory, nil do
							key = (type(value) == "table") and value.Rarity
							local rarity = key and tonumber((key.Order or key.Index) or key.Rank)

							if value.DisplayName then
								if rarity then
									if rarity >= 8 then
										if not (displayNameMap[value.DisplayName]) then
											displayNameMap[value.DisplayName] = true
											list4[#list4 + 1] = {n = value.DisplayName, r = rarity,
												rn = tostring((key.DisplayName or key._id) or ""), v = tonumber(value.EarningRate) or 0}
										end
									end
								end
							end
						end
					end)

					table.sort(list4, function(input, inputFinder)
						if input.r ~= inputFinder.r then
							return input.r > inputFinder.r
						end
						return input.v > inputFinder.v
					end)

					for index, item in ipairs(list4) do
						local scanTable3Result, textButton = scanTable3(item.n), Instance.new("TextButton")
						textButton.Text, textButton.AutoButtonColor, textButton.BackgroundColor3 = "", false, getColor(24, 21, 34)
						textButton.BackgroundTransparency = 0.05
						textButton.LayoutOrder = index
						textButton.ZIndex = 8
						textButton.Parent = scrollingFrame2
						Instance.new("UICorner", textButton).CornerRadius = UDim.new(0.12, 0)
						index = Instance.new("UIStroke")
						index.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
						index.Parent = textButton
						index:SetAttribute("own", true)
						local uiElement = Instance.new("ImageLabel")
						uiElement.BackgroundTransparency, uiElement.Image, uiElement.ScaleType, uiElement.AnchorPoint, uiElement.Position, uiElement.Size = 1, scanTable3Result.icon, Enum.ScaleType.Fit, Vector2.new(0.5,
							0), UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.72, 0, 0.54, 0)
						uiElement.ZIndex = 9
						uiElement.Parent = textButton
						uiElement = Instance.new("TextLabel")
						uiElement.BackgroundTransparency, uiElement.FontFace, uiElement.Text, uiElement.TextScaled, uiElement.TextColor3, uiElement.TextStrokeTransparency, uiElement.AnchorPoint, uiElement.Position, uiElement.Size = 1, fontFace, item.n, true, Color3.new(1,
							1, 1), 0.35, Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0.61, 0), UDim2.new(0.92, 0, 0.19, 0)
						uiElement.ZIndex = 9
						uiElement.Parent = textButton
						local uiElement2 = Instance.new("UIGradient", uiElement)
						uiElement2.Rotation = 90

						if scanTable3Result.grad and (item.r ~= 8) then
							uiElement2.Color = scanTable3Result.grad.Color
						else
							uiElement2.Color = ColorSequence.new(((item.r == 8) and getColor(225, 230,
								240)) or scanTable3Result.color)
						end

						uiElement2 = uiElement:Clone()
						uiElement2.Text, uiElement2.Position, uiElement2.Size = item.rn:upper(), UDim2.new(0.5, 0, 0.82,
							0), UDim2.new(0.66, 0, 0.12, 0)
						uiElement2.TextStrokeTransparency = 0.6
						uiElement2.Parent = textButton
						uiElement = Instance.new("Frame")
						uiElement.BackgroundColor3, uiElement.AnchorPoint, uiElement.Position, uiElement.Size = Color3.new(1, 1,
							1), Vector2.new(1, 0), UDim2.new(0.95, 0, 0.05, 0), UDim2.new(0.2, 0, 0.2, 0)
						uiElement.ZIndex = 10
						uiElement.Visible = false
						uiElement.Parent = textButton
						Instance.new("UICorner", uiElement).CornerRadius = UDim.new(1, 0)
						Instance.new("UIAspectRatioConstraint", uiElement)
						uiElement2 = Instance.new("UIGradient", uiElement)
						uiElement2.Rotation, uiElement2.Color = 90, ColorSequence.new(getColor(255, 222, 90), getColor(255, 150, 20))
						uiElement2 = Instance.new("UIStroke", uiElement)
						uiElement2.Thickness, uiElement2.Color = 1.5, getColor(70, 40, 0)
						uiElement2:SetAttribute("own", true)
						uiElement2 = {{0.36, 0.58, 0.3, 45}, {0.58, 0.48, 0.56, -50}}

						for indexFinder, itemFinder in ipairs(uiElement2) do
							indexFinder = Instance.new("Frame")
							indexFinder.BorderSizePixel, indexFinder.BackgroundColor3, indexFinder.AnchorPoint, indexFinder.Position, indexFinder.Size, indexFinder.Rotation = 0, Color3.new(1,
								1, 1), Vector2.new(0.5, 0.5), UDim2.new(itemFinder[1], 0, itemFinder[2], 0), UDim2.new(itemFinder[3], 0, 0.14, 0), itemFinder[4]
							indexFinder.ZIndex = 11
							indexFinder.Parent = uiElement
							Instance.new("UICorner", indexFinder).CornerRadius = UDim.new(1, 0)
						end

						list3[#list3 + 1] = {b = textButton, st = index, dot = uiElement, n = item.n, l = item.n:lower(),
							r = item.r, c = scanTable3Result.color}

						tryCallFinder(textButton, function()
							doStep25(item.n)
						end)
					end

					clampValue4()
				end

				doStep26(1, 0.3, "Select all", stateFinder.Blue, function()
					local only = ((type(jsonFile.only) == "table") and jsonFile.only) or {}

					for _, item in ipairs(list3) do
						if item.b.Visible then
							if not (table.find(only, item.n)) then
								only[#only + 1] = item.n
							end
						end
					end

					jsonFile.only = only
					scanItems3()
					hasTimedOutFinder()
					scanItems4()
					scanTable6()
				end, frame7)

				doStep26(2, 0.3, "Clear", stateFinder.Off, function()
					jsonFile.only = {}
					scanItems3()
					hasTimedOutFinder()
					scanItems4()
					scanTable6()
				end, frame7)

				doStep26(3, 0.3, "Done", stateFinder.Join, function()
					local fieldValue2 = ctx2.fieldValue2
					fieldValue2.view = "ac"
				end, frame7)

				entries2Ref.ac.only = doStep27(2, "Only these eggs", function()
					scanTable8()
					amount = 0
					scanTable6()
					local fieldValue2 = ctx2.fieldValue2
					fieldValue2.view = "eg"
				end)
			end

			for _, value in next, entries2Ref.ac, nil do
				value = ((type(value) == "table") and value.Button) or value

				if typeof(value) == "Instance" then
					value:SetAttribute("ac", true)
				end
			end

			entries2.pk = entries2RefFinder

			local function doStep31(_)
				local fieldValue2Finder, fieldValue22, fieldValue2 = ctx2.fieldValue2, ctx2.fieldValue2, ctx2.fieldValue2
				fieldValue2Finder.drawer = ((fieldValue2.drawer ~= _) and _) or nil
				fieldValue22.view = nil
			end

			factor2 = {"force", "min", "rar"}

			for _, item in ipairs(factor2) do
				tryCallFinder(cacheFinder[item].Button, function()
					doStep31(item)
				end)
			end

			local function _()
				if checkState2() then
					local fieldValue2Finder, fieldValue22, fieldValue2 = ctx2.fieldValue2, ctx2.fieldValue2, ctx2.fieldValue2
					fieldValue2Finder.drawer, fieldValue22.view = nil, ((fieldValue2.view ~= "ac") and "ac") or nil
				else
					doStep31("sign")
				end
			end

			tryCallFinder(cacheFinder.acct.Button, _)

			if checkState8ResultFinder then
				chilliStealPanelFrame = checkState8(checkState8ResultFinder.Button:Clone())
				frame2 = chilliStealPanelFrame.Button

				for _, descendant in ipairs(frame2:GetDescendants()) do
					if descendant:IsA("Script") then
						descendant:Destroy()
					elseif descendant:IsA("LocalScript") then
						descendant:Destroy()
					end
				end

				frame2.Size, frame2.Position = UDim2.new(0.1, 0, 0.5, 0), UDim2.new(0.665, 0, 0.5, 0);
				(frame2:FindFirstChildOfClass("UIAspectRatioConstraint") or Instance.new("UIAspectRatioConstraint",
					frame2)).AspectRatio = 1

				if chilliStealPanelFrame.Label then
					chilliStealPanelFrame.Label.Visible = false
				end

				entries2RefFinder = Instance.new("ImageLabel")
				entries2RefFinder.BackgroundTransparency, entries2RefFinder.Image, entries2RefFinder.AnchorPoint, entries2RefFinder.Position, entries2RefFinder.Size, entries2RefFinder.ZIndex = 1, "rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png", Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.66, 0.66), ((chilliStealPanelFrame.Label and chilliStealPanelFrame.Label.ZIndex) or frame2.ZIndex) + 1
				entries2RefFinder.Parent = frame2
				Instance.new("UIAspectRatioConstraint", entries2RefFinder)
				entries2RefFinder.Size = UDim2.fromScale(0.74, 0.74)
				doStep30 = {{-2, 0}, {2, 0}, {0, -2}, {0, 2}, {-1.5, -1.5}, {1.5, 1.5}, {-1.5, 1.5}, {1.5, -1.5}}

				for _, item in ipairs(doStep30) do
					listLayout6 = entries2RefFinder:Clone()
					listLayout6.ImageColor3, listLayout6.ZIndex, listLayout6.Position = Color3.new(0, 0,
						0), entries2RefFinder.ZIndex - 1, UDim2.new(0.5, item[1], 0.5, item[2])
					listLayout6.Parent = frame2
				end

				checkState9(chilliStealPanelFrame, stateFinder.Blue)
				buildUIScale(chilliStealPanelFrame)
				tryCallFinder(frame2, _)
				frame2.Parent = checkState8ResultFinder.Button.Parent
				entries2.gear = chilliStealPanelFrame
			end

			frame2 = {"force", "min", "rar", "acct"}

			for _, item in ipairs(frame2) do
				buildUIScale(cacheFinder[item])
			end

			listLayout4, header, nameList2, doStep29, parent, listLayout2 = entries2, entries2, entries2, entries2, entries2, entries2
			entries2.B = cacheFinder
			listLayout4.V = entries2Ref
			header.ov = frame3
			nameList2.stat = mouseEnabled
			doStep29.scroll = scrollingFrame
			parent.title = hPat
			listLayout2.autoB = checkState8ResultFinder
			doStep28, _, entries2Ref = entries2, entries2, frame.Position
			doStep28.panel = cleanupResult
			_.home = entries2Ref
			cleanupResult.Position = entries2.home
			readAttribute3(cleanupResult, true, entries2.sbase)

			if chilliFinderEmbedded then
				entries2.cS = {}
				uiStroke, chilliStealPanelFrame = ipairs, table.pack(close:GetDescendants())

				for _, item in uiStroke(table.unpack(chilliStealPanelFrame, 1, chilliStealPanelFrame.n)) do
					if item:IsA("UIStroke") then
						setmetatableFnResult[item] = nil
						entries2.cS[#entries2.cS + 1] = item
					end
				end
			end

			collectDescendants(cleanupResult)
			doStep29 = entries2
			doStep29.gui = createScreenGui(tempValue12.ActivePets)
			entries2.gui.Enabled = false
			cleanupResult.Parent = entries2.gui
			entries2.gui.Parent = hui
			trackConnection2(cleanupResult:GetPropertyChangedSignal("AbsoluteSize"), scanTable5)
			_, header, listLayout = ipairs, {}, tempValue12.ActivePets
			header[1], header[2] = listLayout, tempValue12.Growing

			for _, item in _(header) do
				if item then
					trackConnection2(item:GetPropertyChangedSignal("Enabled"), function()
						if item.Enabled then
							if tempValue13 then
								chilliFinderPanelClose(true)
							end
						end
					end)
				end
			end

			return true
		end

		local function scanTable9(items, input, inputFinder)
			local iMap2 = {}

			for index, item in ipairs(items) do
				iMap2[index] = {item[1], index == input, function()
					inputFinder(index)
				end}
			end

			return iMap2
		end

		local handlers = {rar = function()
			local tempValue2

			for index, item in ipairs(itemsFinder) do
				tempValue2 = if item[2] == jsonFile.rar then index else tempValue2
			end

			return scanTable9(itemsFinder, tempValue2, function(keyName)
				jsonFile.rar = itemsFinder[keyName][2]
			end)
		end}

		local function checkState14()
			if not (entries2.panel) then
				return
			end
			local checkStateFinderResult = checkStateFinder()
			local tempValue2, sess = checkStateFinderResult and (hasTimedOut2()), checkState2()
			local view

			if sess then
				local fieldValue2Finder = ctx2.fieldValue2
				view = fieldValue2Finder.view
			else
				view = sess
			end

			local sess2 = view or nil
			entries2.ov.Visible = sess2 ~= nil
			entries2.scroll.Visible = sess2 == nil
			local size, size2 = not sess2

			if sess2 then
				size2 = size
			else
				view = ctx2.fieldValue2
				size2 = view.drawer ~= (sess and "sign")
			end

			view = nil

			if size2 then
				size = ctx2.fieldValue2
				view = size.drawer
			else
				view = size2
			end

			size2 = view or nil
			size = handlers[size2] and handlers[size2]()
			entries2.sib.Visible, entries2.pk.Visible, entries2.stat.Visible = size2 == "sign", size ~= nil, size2 == nil

			if size2 == "sign" then
				local fieldValue2Finder, startTimeFinder, tempValue5 = ctx2.fieldValue2, (os.clock() - ctx2.fieldValue2.msgAt) < 6

				if startTimeFinder then
					view = ctx2.fieldValue2
					tempValue5 = view.msg ~= ""
				else
					tempValue5 = startTimeFinder
				end

				startTimeFinder = nil

				if tempValue5 then
					local fieldValue22 = ctx2.fieldValue2
					startTimeFinder = fieldValue22.msg
				else
					startTimeFinder = tempValue5
				end

				tempValue5 = nil

				if startTimeFinder then
					tempValue5 = startTimeFinder
				else
					local fieldValue22 = ctx2.fieldValue2
					tempValue5 = fieldValue22.acct
				end

				checkState10(entries2.hint, (tempValue5 and ("<font color=\"#FFD24A\">" .. (tempValue5:gsub("[<>&]", ""):gsub("chillihub%.pro", "<font color=\"#FFFFFF\">chillihub.pro</font>") .. "</font>"))) or entries2.hint0)
			end

			view = entries2

			for key, value in pairs(view.sl) do
				value.f.Visible = size2 == key

				if size2 == key then
					value.sync()
				end
			end

			if size then
				view = #size
				entries2.gl.CellSize = UDim2.new((0.95 - (0.025 * (view - 1))) / view, 0, 0.64, 0)
				local maxTextSize, entries2Ref = math.max(8, math.floor(entries2.pk.AbsoluteSize.Y * 0.4)), entries2

				for _, item in ipairs(entries2Ref.tsc) do
					item.MaxTextSize = maxTextSize
				end
			end

			if size then
				view = entries2

				for index, opt in ipairs(view.opts) do
					local lookupValue = size[index]
					opt.Button.Visible = lookupValue ~= nil

					if lookupValue then
						checkState10(opt.Label, lookupValue[1])
						checkState9(opt, (lookupValue[2] and stateFinder.Join) or stateFinder.Blue)
						opt.pick = lookupValue[3]
					end
				end
			end

			local geo, tempValue7 = entries2.geo

			if checkStateFinderResult then
				view = nil
				view, tempValue7 = ctx2.fieldValue2, tostring(ctx2.fieldValue2.sess.plan or "")
			else
				tempValue7 = checkStateFinderResult
			end

			view = tempValue7 or false

			if entries2.vip ~= view then
				entries2.vip = view

				if entries2.hg then
					tempValue7 = (view and stateFinder.HeadVip) or stateFinder.Head
					entries2.hg.Color, entries2.hg.Rotation = tempValue7.Color, tempValue7.Rotation
				end

				local hPat = entries2.hPat

				if hPat then
					if hPat:IsA("ImageLabel") then
						local entries2Ref, entries2RefFinder, ptT, ptC = entries2, entries2, entries2.ptT
							or hPat.ImageTransparency, entries2.ptC or hPat.ImageColor3
						entries2Ref.ptT = ptT
						entries2RefFinder.ptC = ptC
						hPat.ImageTransparency, hPat.ImageColor3 = entries2.ptT, entries2.ptC
					end
				end

				if entries2.hp then
					checkState9(entries2.hp, (view and stateFinder.HudVip) or stateFinder.Hud)
				end

				hPat = entries2.title

				if hPat then
					local entries2Ref = entries2
					entries2Ref.t0 = entries2Ref.t0 or {f = hPat.FontFace, c = hPat.TextColor3}
					local uiGradient, uiStroke = hPat:FindFirstChildOfClass("UIGradient"), hPat:FindFirstChildOfClass("UIStroke")
					checkState10(hPat, "John Hub | Egg Finder")
					entries2.t0.sz, entries2.t0.ps = entries2.t0.sz or hPat.Size, entries2.t0.ps or hPat.Position
					hPat.Size, hPat.Position = entries2.t0.sz, entries2.t0.ps
					hPat.FontFace = (view and Font.new("rbxasset://fonts/families/GothamSSm.json",
						Enum.FontWeight.Heavy)) or entries2.t0.f
					hPat.TextColor3 = (view and Color3.new(1, 1, 1)) or entries2.t0.c

					if uiGradient then
						uiGradient.Enabled = not view
					end

					if uiStroke then
						entries2.t0.s = entries2.t0.s or uiStroke.Color
						uiStroke.Color = (view and Color3.new(0, 0, 0)) or entries2.t0.s
					end

					if Glitch then
						pcall(glitchDestroy)
						Glitch.Label = nil
					end
				end
			end

			if entries2.foot.Visible == sess then
				entries2.foot.Visible, geo.bottom = not sess, (sess and geo.bFull) or geo.bFoot
				view, tempValue7 = (sess and geo.cFull) or 0.2, entries2

				for _, card in ipairs(tempValue7.cards) do
					card.f.Size = UDim2.new(card.f.Size.X.Scale, card.f.Size.X.Offset, view, 0)
				end
			end

			tempValue7 = ((size2 == "sign") and entries2.sib.Size.Y.Scale) or (size and entries2.pk.Size.Y.Scale)
			view = tempValue7 or (entries2.sl[size2] and entries2.sl[size2].f.Size.Y.Scale)
			size = view or 0
			tempValue7 = ((size > 0) and ((geo.st + size) + geo.gap)) or geo.top
			size = UDim2.new(geo.sx.Scale, geo.sx.Offset, geo.bottom - tempValue7, 0)

			if entries2.scroll.Size ~= size then
				entries2.scroll.Size, entries2.scroll.Position = size, UDim2.new(geo.px.Scale, geo.px.Offset,
					tempValue7 + ((geo.bottom - tempValue7) * geo.aY), 0)
			end

			size, geo = ipairs, entries2.ov

			for _, child in size(geo:GetChildren()) do
				if child:IsA("GuiObject") then
					child.Visible = (sess2 ~= nil) and (child:GetAttribute(sess2) == true)
				end
			end

			local fieldValue2, fieldValue3 = entries2.B, entries2.V
			checkState10(fieldValue2.force.Cap, "FORCE JOIN")
			checkState10(fieldValue2.force.Label,
				((jsonFile.gap > 0) and (((((jsonFile.gap % 1) == 0) and ("%d"):format(jsonFile.gap)) or tostring(jsonFile.gap)) .. "s"))
				or "Off")
			view, size = fieldValue2.force, ((size2 == "force") and stateFinder.Gold)
				or ((jsonFile.gap > 0) and stateFinder.Join)
			checkState9(view, size or stateFinder.Off)
			checkState10(fieldValue2.min.Cap, "MIN VALUE")
			checkState10(fieldValue2.min.Label, scanTableFinder(jsonFile.min) .. "/s")
			checkState9(fieldValue2.min, ((size2 == "min") and stateFinder.Gold) or stateFinder.Blue)
			checkState10(fieldValue2.rar.Cap, "RARITY")
			checkState10(fieldValue2.rar.Label, itemsFinder[table.find({0, 8, 9, 10}, jsonFile.rar) or 1][1])
			checkState9(fieldValue2.rar, ((size2 == "rar") and stateFinder.Gold) or stateFinder.Blue)
			size = nil

			if checkStateFinderResult then
				tempValue7, geo = ctx2.fieldValue2
				geo, size = ctx2.getServerTimeNow, (tempValue7.sess.endTs / 1000) - ctx2.getServerTimeNow()
			else
				size = checkStateFinderResult
			end

			view, geo, tempValue7 = size or 0, fieldValue2.acct.Cap

			if checkStateFinderResult then
				size = nil
				size, tempValue7 = ctx2.fieldValue2, tostring(ctx2.fieldValue2.sess.plan):upper()
			else
				tempValue7 = checkStateFinderResult
			end

			checkState10(geo, tempValue7 or "ACCOUNT")
			size, tempValue7 = fieldValue2.acct.Label, (checkStateFinderResult and ("%dh%02dm"):format(view // 3600,
				(view % 3600) // 60)) or (sess and "No plan")
			checkState10(size, (tempValue7 or ((size2 == "sign") and "Hide")) or "Sign In")
			checkState9(fieldValue2.acct, (((size2 == "sign") or sess2) and stateFinder.Off) or stateFinder.Gold)

			if entries2.autoB then
				checkState10(entries2.autoB.Label, (ctx2.fieldValue2.auto and "AUTO ON") or "AUTO OFF")
				checkState9(entries2.autoB, (ctx2.fieldValue2.auto and stateFinder.Join) or stateFinder.Off)
			end

			if entries2.gear then
				checkState9(entries2.gear,
					(((sess2 == "ac") or (size2 == "sign")) and stateFinder.Join) or stateFinder.Blue)
			end

			geo = nil

			if tempValue9 then
				geo = ("%s %s  |  try %d  |  %ds%s"):format((tempValue9.force and "Force joining") or "Joining",
					tempValue9.e.name, tempValue9.tries, math.max(0,
					tempValue9.stop - os.clock()), ((tempValue9.why ~= "") and ("  |  " .. tempValue9.why)) or "")
			else
				size2, fieldValue2, tempValue7 = ctx2.fieldValue2, (os.clock() - ctx2.fieldValue2.msgAt) < 6

				if fieldValue2 then
					sess = ctx2.fieldValue2
					tempValue7 = sess.msg ~= ""
				else
					tempValue7 = fieldValue2
				end

				if tempValue7 then
					view = ctx2.fieldValue2
					geo = view.msg
				else
					if checkStateFinderResult then
						if tempValue2 then
							size = ctx2.fieldValue2

							if size.auto and readAttributeFinder() then
								geo = "Auto waits: night is close"
							else
								local fieldValue2Finder = ctx2.fieldValue2
								local hold, hold2 = fieldValue2Finder.auto and jsonFile.hold

								if hold then
									fieldValue2Finder = ctx2.fieldValue2
									hold2 = fieldValue2Finder.hold
								else
									hold2 = hold
								end

								if hold2 then
									geo = "Auto waits: an egg here matches your filter"
								else
									hold = ctx2.fieldValue2
									local tempValue5, fieldValue22 = (hold.ws and "Live") or "Connecting", ctx2.fieldValue2
									local length, fieldValue23 = #fieldValue22.top, ctx2.fieldValue2
									fieldValue2Finder, fieldValue22 = fieldValue23.auto

									if fieldValue2Finder then
										fieldValue23 = ctx2.fieldValue2
										fieldValue22 = ((#(fieldValue23.pick or {}) > 0) and "  |  Auto joining new eggs")
											or "  |  Auto waits for new eggs"
									else
										fieldValue22 = fieldValue2Finder
									end

									geo = (("%s  |  %d eggs%s"):format(tempValue5, length, fieldValue22 or "  |  Tap Join"))
								end
							end
						else
							geo = "Paused: Finder runs in another script"
						end
					else
						local fieldValue2Finder = ctx2.fieldValue2
						local acct = fieldValue2Finder.acct

						if acct then
							geo = acct
						else
							fieldValue2Finder = ctx2.fieldValue2
							geo = (((#fieldValue2Finder.top > 0)
								and "Top 5 recent eggs") or "No big eggs right now") .. "  |  Book at chillihub.pro"
						end
					end
				end
			end

			checkState10(entries2.stat, geo)
			entries2.stat.TextColor3 = (tempValue9 and getColor(255, 196, 77)) or getColor(255, 255, 255)

			if sess2 == "ac" then
				sess = nil

				if checkStateFinderResult then
					geo = ctx2.fieldValue2
					sess = geo.sess
				else
					sess = checkStateFinderResult
				end

				size = nil

				if sess then
					size = sess
				else
					fieldValue2, tempValue7 = {}, ctx2.fieldValue2
					fieldValue2.username = tempValue7.who
					view = ctx2.getServerTimeNow
					fieldValue2.endTs = view() * 1000
					size = fieldValue2
				end

				checkState10(fieldValue3.ac.head, "Signed in as " .. tostring(size.username or "?"))
				local getServerTimeNowFinder, computed = ctx2.getServerTimeNow, math.max(0,
					math.floor((size.endTs / 1000) - ctx2.getServerTimeNow()))

				local function checkState11(keyName, input, inputFinder)
					local tempValue5 = fieldValue3.ac.info[keyName]
					checkState10(tempValue5.l, input)

					if tempValue5.g then
						tempValue5.g.Color = ColorSequence.new(inputFinder)
						tempValue5.g.Rotation = 90
					end
				end

				checkState11("PLAN", (checkStateFinderResult and tostring(size.plan or "?"):upper()) or "NONE",
					(checkStateFinderResult and getColor(255, 214, 90)) or getColor(255, 120, 110))
				local isNegated = not checkStateFinderResult
				checkState11("TIME LEFT",
					((if checkStateFinderResult then isNegated else "-") or ((computed >= 3600) and ("%dh %02dm"):format(computed // 3600,
					(computed % 3600) // 60)))
					or ("%dm %02ds"):format(computed // 60, computed % 60), ((computed < 600) and getColor(255, 120,
					110)) or getColor(255, 255, 255))
				checkState11("ENDS AT", (checkStateFinderResult and os.date("%H:%M",
					math.floor(size.endTs / 1000))) or "-", getColor(255, 255, 255))
				local conditionalValue, tempValue8 = if checkStateFinderResult then isNegated else "Off"

				if conditionalValue then
					tempValue8 = conditionalValue
				else
					computed = ctx2.fieldValue2
					tempValue8 = computed.ws and "Live"
				end

				checkState11("FEED", tempValue8 or "Polling", (ctx2.fieldValue2.ws and getColor(124, 242,
					90)) or getColor(255, 200, 80))
				checkState11("DELAY",
					((if checkStateFinderResult then isNegated else "-") or (((size.delayMs or 0) > 0) and ("+" .. ((size.delayMs / 1000) .. "s"))))
					or "Instant", (((size.delayMs or 0) > 0) and getColor(255, 200, 80)) or getColor(124, 242, 90))
				checkState11("FINDER",
					((if checkStateFinderResult then isNegated else "-") or (tempValue2 and "Here"))
					or "Other", (tempValue2 and getColor(124, 242, 90)) or getColor(255, 120, 110))
				tempValue8 = #(jsonFile.only or {})
				checkState10(fieldValue3.ac.only.Label,
					((tempValue8 > 0) and (tempValue8 .. (((tempValue8 == 1) and " egg") or " eggs"))) or "All")
				checkState9(fieldValue3.ac.only, ((tempValue8 > 0) and stateFinder.Gold) or stateFinder.Blue)
				checkState10(fieldValue3.ac.list.Label, ({[0] = "Matching", "Top value", "Newest"})[jsonFile.list or 0])
				checkState9(fieldValue3.ac.list, (((jsonFile.list or 0) > 0) and stateFinder.Gold) or stateFinder.Blue)
				checkState10(fieldValue3.ac.hold.Label, (jsonFile.hold and "ON") or "OFF")
				checkState9(fieldValue3.ac.hold, (jsonFile.hold and stateFinder.Join) or stateFinder.Off)
				computed, isNegated = fieldValue3.ac.age.Label, (jsonFile.age > 0)
					and (((jsonFile.age < 60) and (jsonFile.age .. "s")) or ((jsonFile.age // 60) .. ("m" .. ((((jsonFile.age % 60) > 0) and (" " .. ((jsonFile.age % 60) .. "s"))) or ""))))
				checkState10(computed, isNegated or "Off")
				checkState9(fieldValue3.ac.age, ((jsonFile.age > 0) and stateFinder.Blue) or stateFinder.Off)
				checkState10(fieldValue3.ac.night.Label, ((jsonFile.night > 0) and (jsonFile.night .. "s")) or "Off")
				checkState9(fieldValue3.ac.night, ((jsonFile.night > 0) and stateFinder.Blue) or stateFinder.Off)

				if fieldValue3.ac.rel then
					checkState10(fieldValue3.ac.rel.Label, (jsonFile.reload and "ON") or "OFF")
					checkState9(fieldValue3.ac.rel, (jsonFile.reload and stateFinder.Join) or stateFinder.Off)
				end
			end

			sess, tempValue7, view = ipairs, entries2.cards, 0

			for index, item in sess(tempValue7) do
				fieldValue2, geo = tempValue13 and (sess2 == nil)

				if fieldValue2 then
					size = ctx2.fieldValue2
					geo = size.top[index]
				else
					geo = fieldValue2
				end

				index = geo or nil
				item.e = index

				if item.f.Visible ~= (index ~= nil) then
					item.f.Visible = index ~= nil
				end

				if index then
					view += 1
					local tempValue5 = item.f.AbsoluteSize.Y

					if (item.ek ~= index) or (item.eh ~= tempValue5) then
						item.ek = index
						item.eh = tempValue5
						local scanTable3Result = scanTable3(index.name)

						if item.icon then
							if item.icon.Image ~= scanTable3Result.icon then
								item.icon.Image = scanTable3Result.icon
							end
						end

						local match = tostring(index.mutation or ""):match("^%s*([^,]-)%s*,")
							or tostring(index.mutation or ""):match("^%s*(.-)%s*$")
						local configEntry, textSize = ((match ~= "") and (configMap[match] or {match, {225, 225,
							235}})) or nil, math.max(8, math.floor(tempValue5 * 0.33))

						if item.name.TextSize ~= textSize then
							item.name.TextSize = textSize
						end

						item.mh.Visible = configEntry ~= nil

						if configEntry then
							if item.mk ~= match then
								item.mk = match
								checkState10(item.mh, configEntry[1])
								item.mg.Color = (configEntry[2] and ColorSequence.new(Color3.fromRGB(unpack(configEntry[2]))))
									or colorSequence
							end
						end

						checkState10(item.name, tostring(index.name))
						textSize = math.max(7, math.floor(tempValue5 * 0.2))

						if item.mh.TextSize ~= textSize then
							item.mh.TextSize = textSize
						end

						if item.ng then
							if item.nk ~= index.name then
								item.nk = index.name
								match = index.rarity == 8
								item.ng.Color = ((scanTable3Result.grad and not match) and scanTable3Result.grad.Color)
									or ColorSequence.new((match and getColor(220, 226, 236)) or scanTable3Result.color)
								item.ng.Rotation = (scanTable3Result.grad and scanTable3Result.grad.Rotation) or 90
							end
						end
					end

					tempValue5 = tostring(index.valueText or "")
					checkState10(item.val,
						"<font color=\"#7CF25A\">$" .. ((((tempValue5 ~= "") and tempValue5) or tostring(index.value)) .. ("</font>" .. (((((tonumber(index.size) or 0) > 0) and ("  <font color=\"#FFD24A\">x%.2f</font>"):format(index.size)) or "") .. ((((checkStateFinderResult and ((index.pm or 0) > 0)) and ("  <font color=\"#9FD1FF\">%d/%d</font>"):format(index.pc or 0,
						index.pm)) or "") .. ("  <font color=\"#B8B4C8\">" .. (clampValueFinder(index) .. "</font>")))))))
					tempValue5 = tempValue9 and (tempValue9.e == index)
					local label, tempValue8 = item.b.Label, (tempValue5 and "Stop")
						or (if checkStateFinderResult then not checkStateFinderResult else "Join")
					checkState10(label, (tempValue8 or ((tempValue2 and index.jobId) and "Join")) or "Locked")
					local fieldValue, stop, stop2 = item.b, (tempValue5 and stateFinder.Stop)
						or (if checkStateFinderResult then not checkStateFinderResult else stateFinder.Gold)

					if stop then
						stop2 = stop
					else
						tempValue8 = tempValue2 and index.jobId

						if tempValue8 then
							label, tempValue5 = (jsonFile.list or 0) > 0

							if label then
								local fieldValue2Finder = ctx2.fieldValue2
								tempValue5 = not (fieldValue2Finder.pickSet or {})[index]
							else
								tempValue5 = label
							end

							stop2 = (tempValue5 and stateFinder.Blue) or stateFinder.Join
						else
							stop2 = tempValue8
						end
					end

					checkState9(fieldValue, stop2 or stateFinder.Off)
				else
				end
			end

			if entries2.badge then
				size = nil

				if checkStateFinderResult then
					tempValue2 = ctx2.fieldValue2
					size = #(tempValue2.pick or {})
				else
					size = checkStateFinderResult
				end

				sess2 = size or 0
				entries2.badge.Visible = sess2 > 0

				if entries2.bIcon then
					view = ctx2.fieldValue2
					sess, tempValue7 = view.top[1]

					if sess then
						geo = ctx2.fieldValue2
						tempValue7 = scanTable3(geo.top[1].name).icon
					else
						tempValue7 = sess
					end

					fieldValue2 = tempValue7 or entries2.bIcon0

					if entries2.bIcon.Image ~= fieldValue2 then
						entries2.bIcon.Image = fieldValue2
					end
				end

				checkState10(entries2.badgeT, ((sess2 > 99) and "99+") or tostring(sess2))
			end
		end

		local function hasTimedOut5()
			local fieldValue2Finder = ctx2.fieldValue2

			if fieldValue2Finder.ws then
				return
			else
				local fieldValue22 = ctx2.fieldValue2

				if fieldValue22.wsP then
					return
				else
					local fieldValue2 = ctx2.fieldValue2

					if os.clock() < fieldValue2.wsAt then
						return
					elseif checkStateFinder() then
						if not (hasTimedOut2()) then
							return
						end
					else
						return
					end
				end
			end

			fieldValue2Finder = ctx2.fieldValue2
			fieldValue2Finder.wsAt = os.clock() + 3
			local connect = (WebSocket and (WebSocket.connect or WebSocket.new))
				or ((syn and syn.websocket) and syn.websocket.connect)
			if not connect then
				return
			end

			task.spawn(function()
				local callResult, tempValue2 = pcall(connect, "wss://chillihub.pro/roblox-mcp/eggws")

				if callResult then
					if not tempValue2 then
						return
					end
				else
					return
				end

				callResult = ctx2.fieldValue2
				local sess = callResult.sess
				local onMessage, onClose = tempValue2.OnMessage or tempValue2.MessageReceived, tempValue2.OnClose
					or tempValue2.Closed

				if not (sess and onMessage) then
					pcall(function()
						tempValue2:Close()
					end)

					return
				end

				onMessage:Connect(function(input)
					local fieldValue22 = ctx2.fieldValue2
					fieldValue22.wsMsg = os.clock()
					fieldValue22 = ctx2.fieldValue2

					if fieldValue22.wsP == tempValue2 then
						local fieldValue23, fieldValue2, fieldValue24 = ctx2.fieldValue2, ctx2.fieldValue2, ctx2.fieldValue2
						fieldValue23.wsP = nil
						fieldValue2.ws = tempValue2
						fieldValue24.dirty = true
					end

					fieldValue22 = ctx2.fieldValue2

					if #fieldValue22.inbox < 200 then
						local fieldValue2, _ = ctx2.fieldValue2
						_, fieldValue2.inbox[#ctx2.fieldValue2.inbox + 1] = ctx2.fieldValue2, {input, sess.secret}
					end
				end)

				if onClose then
					onClose:Connect(function()
						local fieldValue22 = ctx2.fieldValue2

						if fieldValue22.wsP == tempValue2 then
							local fieldValue2 = ctx2.fieldValue2
							fieldValue2.wsP = nil
						end

						fieldValue22 = ctx2.fieldValue2

						if fieldValue22.ws == tempValue2 then
							local fieldValue2 = ctx2.fieldValue2
							fieldValue2.ws = nil
							fieldValue2 = ctx2.fieldValue2
							fieldValue2.dirty = true
						end
					end)
				end

				pcall(function()
					local scanItems9, HttpService3, _, tempValue5 = ctx2.scanItems, ctx2.HttpService, {session = sess.token}
					tempValue5, _.ts = ctx2.getServerTimeNow, math.floor(ctx2.getServerTimeNow() * 1000)
					tempValue5 = ctx2.fieldValue
					tempValue2:Send(scanItems9(HttpService3:JSONEncode(_), tempValue5))
				end)

				onClose = ctx2.fieldValue2
				onClose.wsP = tempValue2

				task.delay(6, function()
					local fieldValue22 = ctx2.fieldValue2

					if fieldValue22.wsP == tempValue2 then
						local fieldValue2 = ctx2.fieldValue2
						fieldValue2.wsP = nil

						pcall(function()
							tempValue2:Close()
						end)
					end
				end)
			end)
		end

		local function tryCall5(input, inputFinder)
			local callResult, result = pcall(gameRef2.HttpGet, gameRef2, input)
			if not (callResult) then
				return nil, (tostring(result):find("401") and "expired") or ""
			end
			input = ctx2.hasTimedOut
			return input(result, inputFinder, true), tostring(result)
		end

		local function hasTimedOut6()
			local fieldValue2, timestamp = ctx2.fieldValue2, os.clock() - ctx2.fieldValue2.arrived
			if timestamp < 8 then
				return true
			end
			local tempValue2 = false

			pcall(function()
				local directory, Mutations, _, records = require(ReplicatedStorage2.Data.Assets).Directory, require(ReplicatedStorage2.Shared.Modules.Mutations), pairs, require(ReplicatedStorage2.Client.EggState).ReadFieldEggs().Records

				for index, record in _(records) do
					index = ((((type(record) == "table") and (record.State ~= "Claimed")) and record.Uid) and not tostring(record.Uid):find("^FirstAreaEgg"))
						and directory[record.AssetCategory]
					local rarity, tempValue5 = index and index.Rarity

					if index then
						local tempValue10Ref = tempValue10
						local isNegated = not tempValue10Ref

						if tempValue10Ref then
							local tempValue10RefFinder = tempValue10
							tempValue5 = tempValue10RefFinder[index.DisplayName] == true
						else
							tempValue5 = isNegated
						end
					else
						tempValue5 = index
					end

					if tempValue5 and (((rarity and tonumber(rarity.RarityNumber or rarity.Rank)) or 0) >= jsonFile.rar) then
						local list3, cacheFinder = {}, {}

						local function checkState11(value)
							if type(value) == "string" then
								if value ~= "" then
									if value ~= "Normal" then
										if value ~= "None" then
											if not (cacheFinder[value]) then
												cacheFinder[value] = true
												list3[#list3 + 1] = value
											end
										end
									end
								end
							end
						end

						checkState11(record.BaseMutation)

						if type(record.Mutations) == "table" then
							for key, mutation in next, record.Mutations, nil do
								checkState11((((type(key) == "string") and (mutation == true)) and key) or mutation)
							end
						end

						local callResult, result = pcall(Mutations.EarningsFor, list3)
						checkState11 = tonumber(record.AssetScale) or 1
						if (((tonumber(index.EarningRate) or 0) * (((checkState11 > 5) and (((checkState11 / 5) ^ 1.2) * 19.637875755794113)) or (checkState11 ^ 1.85))) * ((callResult and tonumber(result)) or 1)) >= math.max(jsonFile.min, 1) then
							tempValue2 = true
							break
						end
					end
				end
			end)

			return tempValue2
		end

		do
			local tempValue2 = false

			pcall(function()
				tempValue2 = TeleportService2:GetTeleportSetting("__ChilliFinderAuto") == gameRef2.JobId
				TeleportService2:SetTeleportSetting("__ChilliFinderAuto", false)
			end)

			if tempValue2 then
				ctx2.fieldValue2.auto, ctx2.fieldValue2.autoAt = true, ctx2.getServerTimeNow() * 1000
			end
		end

		local tempValue17, amount5, amount6, amount7, amount8 = false, 0, 0, 0, 0

		local function _()
			tempValue12 = doStep20()
			if not (tempValue12) then
				return false
			end

			if not (destroyInstances() and doStep24()) then
				tryCall3()
				local guiList = {"hudGui", "gui"}

				for index, item in ipairs(guiList) do
					index = entries2[item]

					if index then
						index:Destroy()
					end
				end

				return false
			end

			tempValue17 = true
			ctx2.genv.JohnHubFinderReady = true
			if not ctx2.genv.JohnHubOpenedOnce then
				ctx2.genv.JohnHubOpenedOnce = true
				task.defer(function()
					if tempValueFinder and entries2.panel then
						chilliFinderPanelOpen(true)
					end
				end)
			end
			return true
		end

		local valueMap2 = {BurstMin = 1.4, BurstMax = 4, DurMin = 0.14, DurMax = 0.4, Tick = 0.03, JitterX = 4,
			JitterY = 3, RotJitter = 2, TearMin = 0.38, TearMax = 0.62, SlideMin = 3, SlideMax = 12, GapMax = 5, Seam = 2, SeamGlow = 10, GhostOffset = 3}
		valueMap2.GhostA = getColor(240, 183, 255)
		valueMap2.GhostB = getColor(191, 200, 255)
		valueMap2.GhostT = 0.3
		valueMap2.ScrambleChance = 0.6
		valueMap2.MaxScramble = 2
		valueMap2.Shards = 7
		valueMap2.ShardMin = 3
		valueMap2.ShardMax = 9
		valueMap2.Spread = 34
		valueMap2.Rise = 22
		valueMap2.Flicker = 0.1
		valueMap2.StrokeFlash = 0.5
		valueMap2.FlashColors = {getColor(217, 166, 255), getColor(168, 85, 247), getColor(255, 242, 255)}
		valueMap2.Core = getColor(255, 242, 255)
		valueMap2.Lilac = getColor(217, 166, 255)
		valueMap2.Bright = getColor(168, 85, 247)
		local nameList2, state3 = {"\226\151\162", "\226\151\163", "\226\151\164", "\226\151\165", "\226\150\178",
			"\226\150\188", "\226\151\134", "\226\150\147", "\226\150\146", "\226\150\145", "/", "\\", "X", "#", "%"}, {Parts = nil, NextBurst = 0, Burst = nil}
		state3.Rng = Random.new()
		local tempValue18

		local function destroyAll()
			if state3.Burst then
				if tempValue18 then
					pcall(tempValue18, state3.Burst)
				end
			end

			local parts2 = state3.Parts

			if parts2 then
				for _, item in ipairs(parts2.All) do
					pcall(function()
						item:Destroy()
					end)
				end
			end

			state3.Parts = nil
			state3.Burst = nil
		end

		local function destroyUIStroke(instance)
			destroyAll()
			local parent = instance.Parent
			local uiStroke, configMap2 = instance:FindFirstChildOfClass("UIStroke"), {All = {}, Ghosts = {},
				Shards = {}}

			local function doStep25(input)
				table.insert(configMap2.All, input)
				return input
			end

			local function parent2()
				local clone = instance:Clone()
				clone:ClearAllChildren()
				clone.Name = doStep18()
				clone.BackgroundTransparency = 1

				if uiStroke then
					uiStroke:Clone().Parent = clone
				end

				return clone
			end

			local function createInstanceFinder()
				local frame = Instance.new("Frame")
				frame.Name = doStep18()
				frame.BackgroundTransparency = 1
				frame.BorderSizePixel = 0
				frame.ClipsDescendants = true
				frame.AnchorPoint = instance.AnchorPoint
				frame.ZIndex = instance.ZIndex
				frame.Visible = false
				frame.Parent = parent
				return doStep25(frame)
			end

			configMap2.TearTop = createInstanceFinder()
			configMap2.TearBottom = createInstanceFinder()
			configMap2.TearTopText = doStep25((parent2()))
			configMap2.TearTopText.AnchorPoint = Vector2.new(0, 0)
			configMap2.TearTopText.Position = UDim2.fromScale(0, 0)
			configMap2.TearTopText.Parent = configMap2.TearTop
			configMap2.TearBottomText = doStep25((parent2()))
			configMap2.TearBottomText.AnchorPoint = Vector2.new(0, 0)
			configMap2.TearBottomText.Parent = configMap2.TearBottom

			local function uiCorner(backgroundColor3, backgroundTransparency, input)
				local frame = Instance.new("Frame")
				frame.Name = doStep18()
				frame.BorderSizePixel = 0
				frame.BackgroundColor3 = backgroundColor3
				frame.BackgroundTransparency = backgroundTransparency
				frame.AnchorPoint = Vector2.new(0.5, 0.5)
				frame.ZIndex = instance.ZIndex + input
				frame.Visible = false
				backgroundTransparency = Instance.new("UIGradient")
				backgroundTransparency.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1)})
				backgroundTransparency.Parent = frame
				frame.Parent = parent
				return doStep25(frame)
			end

			configMap2.SeamGlow = uiCorner(valueMap2.Bright, 0.72, 1)
			configMap2.SeamCore = uiCorner(valueMap2.Core, 0.05, 2)
			uiCorner, createInstanceFinder = ipairs, {valueMap2.GhostA, valueMap2.GhostB}

			for index, item in uiCorner(createInstanceFinder) do
				index = parent2()
				index.TextColor3 = item
				index.TextTransparency = 1
				index.ZIndex = math.max(instance.ZIndex - 1, 1)
				index.Parent = parent
				table.insert(configMap2.Ghosts, (doStep25(index)))
			end

			for index = 1, valueMap2.Shards, 1 do
				parent2 = Instance.new("Frame")
				parent2.Name = doStep18()
				parent2.BorderSizePixel = 0
				parent2.BackgroundColor3 = (((index % 2) == 0) and valueMap2.Lilac) or valueMap2.Core
				parent2.BackgroundTransparency = 1
				parent2.AnchorPoint = Vector2.new(0.5, 0.5)
				parent2.ZIndex = instance.ZIndex + 2
				uiCorner = Instance.new("UICorner")
				uiCorner.CornerRadius = UDim.new(0, 1)
				uiCorner.Parent = parent2
				parent2.Parent = parent
				table.insert(configMap2.Shards, (doStep25(parent2)))
			end

			state3.Parts = configMap2
			state3.NextBurst = os.clock() + state3.Rng:NextNumber(0.6, 1.6)
		end

		tempValue18 = function(data)
			local parts2, label = state3.Parts, state3.Label

			if label then
				if label.Parent then
					if data then
						if data.Orig then
							local orig = data.Orig
							label.Text = orig.Text
							label.Position = orig.Position
							label.Rotation = orig.Rotation
							label.TextTransparency = orig.TextTransparency
							local uiStroke = label:FindFirstChildOfClass("UIStroke")

							if uiStroke then
								if orig.Stroke then
									uiStroke.Color = orig.Stroke
								end
							end

							uiStroke = label:FindFirstChildOfClass("UIGradient")

							if uiStroke then
								if orig.Offset then
									uiStroke.Offset = orig.Offset
								end
							end
						end
					end
				end
			end

			if parts2 then
				for _, ghost in ipairs(parts2.Ghosts) do
					ghost.TextTransparency = 1
				end

				parts2.TearTop.Visible = false
				parts2.TearBottom.Visible = false
				parts2.SeamGlow.Visible = false
				parts2.SeamCore.Visible = false

				for _, shard in ipairs(parts2.Shards) do
					shard.BackgroundTransparency = 1
				end
			end
		end

		local function scanItems8(items)
			local parts2 = {}

			for index = 1, #items, 1 do
				parts2[index] = string.sub(items, index, index)
			end

			local rng, maxScramble = state3.Rng, valueMap2.MaxScramble

			for index = 1, rng:NextInteger(1, maxScramble), 1 do
				index = state3.Rng:NextInteger(1, #parts2)

				if parts2[index] ~= " " then
					parts2[index] = nameList2[state3.Rng:NextInteger(1, #nameList2)]
				end
			end

			return table.concat(parts2)
		end

		local function clampValue5(data, dataFinder, data2)
			local rng, orig, computed = state3.Rng, data.Orig, math.clamp(data.Elapsed / data.Duration, 0, 1)
			local tempValue2, tempValue5, rotation, text = rng:NextInteger(-valueMap2.JitterX,
				valueMap2.JitterX), rng:NextInteger(-valueMap2.JitterY, valueMap2.JitterY), orig.Rotation + rng:NextNumber(-valueMap2.RotJitter, valueMap2.RotJitter), ((rng:NextNumber() < valueMap2.ScrambleChance)
				and scanItems8(orig.Text)) or orig.Text
			dataFinder.Position = orig.Position + UDim2.fromOffset(tempValue2, tempValue5)
			dataFinder.Rotation = rotation
			dataFinder.Text = text
			local size, split, position, uiStroke = dataFinder.Size, data.Split, rng:NextInteger(valueMap2.SlideMin,
				valueMap2.SlideMax), rng:NextInteger(0, valueMap2.GapMax)
			dataFinder.TextTransparency = 1
			data2.TearTop.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale * split, size.Y.Offset * split)
			data2.TearTop.Position = orig.Position + UDim2.fromOffset(position, -uiStroke)
			data2.TearTop.Rotation = rotation
			data2.TearTopText.Size = UDim2.fromScale(1, 1 / split)
			data2.TearTopText.Text = text
			data = 1 - split
			data2.TearBottom.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale * data, size.Y.Offset * data)
			data2.TearBottom.Position = (orig.Position + UDim2.fromOffset(-position, uiStroke)) + UDim2.new(0, 0,
				size.Y.Scale * split, size.Y.Offset * split)
			data2.TearBottom.Rotation = rotation
			data2.TearBottomText.Size = UDim2.fromScale(1, 1 / data)
			data2.TearBottomText.Position = UDim2.fromScale(0, -split / data)
			data2.TearBottomText.Text = text
			data2.TearTop.Visible = true
			data2.TearBottom.Visible = true
			data, position = rng:NextNumber(), orig.Position + UDim2.new(size.X.Scale * 0.5, size.X.Offset * 0.5,
				size.Y.Scale * split, size.Y.Offset * split)
			data2.SeamGlow.Position = position
			data2.SeamGlow.Size = UDim2.new(size.X.Scale * 1.1, size.X.Offset * 1.1, 0, valueMap2.SeamGlow)
			data2.SeamGlow.BackgroundTransparency = ((1 - data) * 0.25) + 0.6
			data2.SeamGlow.BackgroundColor3 = ((data > 0.5) and valueMap2.Lilac) or valueMap2.Bright
			data2.SeamGlow.Visible = true
			data2.SeamCore.Position = position
			data2.SeamCore.Size = UDim2.new(size.X.Scale * ((data * 0.3) + 0.75), size.X.Offset, 0, valueMap2.Seam)
			data2.SeamCore.BackgroundTransparency = 0.05
			data2.SeamCore.Visible = true
			uiStroke = dataFinder:FindFirstChildOfClass("UIStroke")

			if uiStroke then
				if orig.Stroke then
					if rng:NextNumber() < valueMap2.StrokeFlash then
						uiStroke.Color = valueMap2.FlashColors[rng:NextInteger(1, #valueMap2.FlashColors)]
					else
						uiStroke.Color = orig.Stroke
					end
				end
			end

			position = dataFinder:FindFirstChildOfClass("UIGradient")

			if position then
				position.Offset = Vector2.new(rng:NextNumber(-0.5, 0.5), 0)
			end

			for index, ghost in ipairs(data2.Ghosts) do
				data = ((index ~= 1) and -1) or 1
				ghost.Text = text
				ghost.Rotation = rotation
				ghost.TextTransparency = valueMap2.GhostT
				ghost.Position = orig.Position + UDim2.fromOffset(tempValue2 + (data * valueMap2.GhostOffset),
					tempValue5 + (data * math.ceil(valueMap2.GhostOffset / 2)))
			end

			for index, shard in ipairs(data2.Shards) do
				tempValue2, uiStroke, rotation = ((index * 7919) % 97) / 97, (((index % 2) ~= 0) and -1)
					or 1, rng:NextInteger(valueMap2.ShardMin, valueMap2.ShardMax)
				shard.Size = UDim2.fromOffset(rotation, rotation)
				shard.Rotation = (tempValue2 * 360) + ((computed * 180) * uiStroke)
				shard.Position = (orig.Position + UDim2.new(size.X.Scale * 0.5, size.X.Offset * 0.5, size.Y.Scale * split,
					size.Y.Offset * split)) + UDim2.fromOffset((((tempValue2 - 0.5) * 2) * valueMap2.Spread) * computed, ((uiStroke * valueMap2.Rise) * computed) * (0.4 + (tempValue2 * 0.6)))
				shard.BackgroundTransparency = math.clamp(computed, 0, 1)
			end
		end

		local function checkState15(amount)
			local parts2, label = state3.Parts, state3.Label

			if parts2 then
				if label then
					if not (label.Parent) then
						return
					end
				else
					return
				end
			else
				return
			end

			local rng = state3.Rng

			if not (state3.Burst) then
				if amount < state3.NextBurst then
					return
				end

				if label.AbsoluteSize.X <= 0 then
					state3.NextBurst = amount + 1
					return
				end
				local uiStroke, uiGradient = label:FindFirstChildOfClass("UIStroke"), label:FindFirstChildOfClass("UIGradient")
				state3.Burst = {Start = amount, NextTick = 0, Elapsed = 0, Duration = rng:NextNumber(valueMap2.DurMin,
					valueMap2.DurMax), Split = rng:NextNumber(valueMap2.TearMin, valueMap2.TearMax), Orig = {Text = label.Text, Position = label.Position, Rotation = label.Rotation, TextTransparency = label.TextTransparency, Stroke = (uiStroke and uiStroke.Color)
					or nil, Offset = (uiGradient and uiGradient.Offset) or nil}}
				return
			end

			local burst = state3.Burst
			if amount < burst.NextTick then
				return
			end
			burst.NextTick = amount + valueMap2.Tick
			burst.Elapsed = amount - burst.Start

			if burst.Elapsed >= burst.Duration then
				tempValue18(burst)
				state3.Burst = nil
				state3.NextBurst = amount + rng:NextNumber(valueMap2.BurstMin, valueMap2.BurstMax)
				return
			end

			clampValue5(burst, label, parts2)
		end

		trackConnection2(RunService2.RenderStepped, function(deltaTime)
			local now2, glx, title = os.clock(), entries2.glx, entries2.title

			if glx then
				if title then
					deltaTime = ((entries2.vip and tempValue13) and true) or false

					if glx.ink.Visible ~= deltaTime then
						glx.ink.Visible = deltaTime
						glx.edge.Enabled = deltaTime
					end

					if deltaTime then
						glx.eg.Offset = Vector2.new(-1 + (2 * ((now2 % 3.2) / 3.2)), 0)
					end

					if deltaTime then
						local parent, computed = glx.ink.Parent, math.max(title.TextBounds.X, 1)

						if parent.AbsoluteSize.X > 0 then
							glx.ink.Position, glx.ink.Size = UDim2.fromScale(((title.AbsolutePosition.X - parent.AbsolutePosition.X) + (computed / 2)) / parent.AbsoluteSize.X,
								0.56), UDim2.fromScale(math.clamp((computed * 1.3) / parent.AbsoluteSize.X, 0.1, 0.9), 0.95)
						end
					end

					if entries2.vip and tempValue13 then
						if state3.Label ~= title then
							destroyAll()
							state3.Label = title
							destroyUIStroke(title)
						end

						checkState15(now2)
					elseif state3.Burst then
						tempValue18(state3.Burst)
						state3.Burst = nil
					end
				end
			end

			if not (tempValue17) then
				if now2 >= amount8 then
					amount8 = now2 + 2
					pcall(_)

					if tempValue17 then
						amount8 = 0
					end
				end

				return
			end

			if not (((tempValue12.Eggs:IsDescendantOf(gameRef2)
				and tempValue12.ActivePets:IsDescendantOf(gameRef2)) and entries2.btn) and entries2.btn:IsDescendantOf(gameRef2)) then
				tempValue17 = false
				tryCall3()
				glx = {"hudGui", "gui"}

				for _, item in ipairs(glx) do
					title = entries2[item]

					if title then
						title:Destroy()
					end
				end

				entries2, tempValue13 = {}, false
				return
			end

			if now2 >= amount8 then
				amount8 = now2 + 0.25
				checkState12()
				pcall(checkState13)

				if tempValue13 then
					title = ctx2.genv

					if title.ChilliFinderHidden then
						chilliFinderPanelClose()
					elseif not (hasTimedOut2()) then
						chilliFinderPanelClose()
					end
				end
			end

			if tempValue9 then
				if (now2 > tempValue9.stop) or not checkStateFinder() then
					glx = ctx2.fieldValue2
					glx.failed[tempValue9.e.jobId] = now2 + (((tempValue9.a and (jsonFile.gap > 0)) and 1) or 300)
					deltaTime = tempValue9.a
					title = if deltaTime then not deltaTime else ((tempValue9.tries > 1) and ("Gave up after %d tries"):format(tempValue9.tries))
						or "Could not join"
					checkState6(title or nil)
				end

				if tempValue9 then
					if not (tempValue9.fly) then
						if readAttributeFinder() then
							checkState6("Night is close, join stopped")
						end
					end
				end

				if tempValue9 then
					if now2 >= tempValue9.next then
						if not (tempValue9.fly and ((now2 - tempValue9.fly) < 10)) then
							if tempValue9.force then
								hasTimedOut3()
							elseif tempValue9.tries == 0 then
								hasTimedOut3()
							end
						end
					end
				end
			end

			title, glx = now2 >= amount7

			if title then
				deltaTime = ctx2.fieldValue2
				local dirty = deltaTime.dirty or tempValue9

				if dirty then
					glx = dirty
				else
					local fieldValue2 = ctx2.fieldValue2
					glx = (now2 - (fieldValue2.drawn or 0)) >= 1
				end
			else
				glx = title
			end

			if glx then
				deltaTime, title = ctx2.fieldValue2, ctx2.fieldValue2
				amount7 = now2 + 0.25
				deltaTime.drawn = now2
				title.dirty = false
				scanItems4()
				local callResult, result = pcall(checkState14)

				if not (callResult) then
					warn("[John Hub Finder] " .. tostring(result))
				end
			end

			if deadline then
				if now2 >= deadline then
					deadline = nil
					pcall(writefile, chilliFinderSettingsFile, ctx2.HttpService:JSONEncode(jsonFile))
				end
			end
		end)

		task.spawn(function()
			while true do
				local now2 = tempValueFinder
				if not now2 then
					break
				end
				now2 = os.clock()

				for index = 1, 20, 1 do
					local fieldValue2, inbox = ctx2.fieldValue2, table.remove(ctx2.fieldValue2.inbox, 1)
					if not (inbox) then
						break
					end
					index = ctx2.hasTimedOut
					local indexResult = index(inbox[1], inbox[2], true)

					if indexResult then
						if indexResult.eggs then
							scanItems5(indexResult.eggs)
						end
					end
				end

				if now2 >= amount5 then
					local checkStateFinderResult = checkStateFinder()
					local tempValue2

					if checkStateFinderResult then
						local fieldValue2 = ctx2.fieldValue2
						tempValue2 = (fieldValue2.ws and 15) or 2
					else
						tempValue2 = checkStateFinderResult
					end

					amount5 = now2 + (tempValue2 or 3)

					if checkStateFinder() then
						if hasTimedOut2() then
							tempValue2 = ctx2.fieldValue2

							if tempValue2.ws then
								local fieldValue2, timestamp = ctx2.fieldValue2, os.clock() - (ctx2.fieldValue2.wsMsg or 0)

								if timestamp > 50 then
									checkStateFinderResult = ctx2.tryCall3
									checkStateFinderResult()
								end
							end

							hasTimedOut5()
							local fieldValue2Finder = ctx2.fieldValue2

							if not (fieldValue2Finder.ws) then
								local robloxMcpUrlFinder, fieldValue22 = ctx2.robloxMcpUrl, ctx2.fieldValue2
								local fieldValue23, fieldValue2, tryCall5Result, tempValue5 = ctx2.fieldValue2, ctx2.fieldValue2, tryCall5(robloxMcpUrlFinder .. ("joiner/feed?s=" .. (fieldValue22.sess.token .. ("&since=" .. ctx2.fieldValue2.last))),
									ctx2.fieldValue2.sess.secret)

								if tryCall5Result then
									scanItems5(tryCall5Result.eggs)
								elseif tempValue5:find("expired") then
									fieldValue22 = toNumberOrDefault3()
									robloxMcpUrlFinder = nil

									if fieldValue22 then
										local tempValue7
										tempValue7, robloxMcpUrlFinder = ctx2.fieldValue2, fieldValue22.token ~= ctx2.fieldValue2.sess.token
									else
										robloxMcpUrlFinder = fieldValue22
									end

									if robloxMcpUrlFinder then
										local fieldValue24 = ctx2.fieldValue2
										fieldValue24.sess = fieldValue22
										fieldValue24 = ctx2.fieldValue2
										fieldValue24.wsAt = 0
									else
										local tempValue7, relogin = ctx2.cachedFile.rt

										if tempValue7 then
											local fieldValue24 = ctx2.fieldValue2
											relogin = fieldValue24.relogin
										else
											relogin = tempValue7
										end

										tempValue7 = nil

										if relogin then
											local tempValue8
											tempValue8, tempValue7 = ctx2.fieldValue2, (os.clock() - (ctx2.fieldValue2.rl or -10000)) > 20
										else
											tempValue7 = relogin
										end

										if tempValue7 then
											relogin = ctx2.fieldValue2
											relogin.rl = os.clock()
											local fieldValue24 = ctx2.fieldValue2
											fieldValue24.sess = nil
											fieldValue24 = ctx2.fieldValue2
											fieldValue24.relogin()
										else
											doStep17("Signed in somewhere else. Sign in again to use it here")
											local fieldValue24 = ctx2.fieldValue2
											fieldValue24.who = nil
										end
									end
								end
							end
						else
							local tryCall3Finder = ctx2.tryCall3
							tryCall3Finder()
						end
					else
						local fieldValue2Finder = ctx2.fieldValue2

						if fieldValue2Finder.sess then
							doStep17("Your booking ended. Book more hours at chillihub.pro")
							local fieldValue2 = ctx2.fieldValue2
							fieldValue2.whoAt = now2 + 30
						else
							local fieldValue22 = ctx2.fieldValue2
							local rt2, relogin = fieldValue22.who and ctx2.cachedFile.rt

							if rt2 then
								fieldValue22 = ctx2.fieldValue2
								relogin = fieldValue22.relogin
							else
								relogin = rt2
							end

							fieldValue22, rt2 = relogin and (hasTimedOut2())

							if fieldValue22 then
								relogin = ctx2.fieldValue2
								rt2 = now2 >= (relogin.whoAt or 0)
							else
								rt2 = fieldValue22
							end

							if rt2 then
								relogin = ctx2.fieldValue2
								relogin.whoAt = now2 + 30
								fieldValue22 = ctx2.fieldValue2
								fieldValue22.relogin()
							elseif tempValue13 then
								amount5 = (now2 + 2.5) + math.random()
								local robloxMcpUrlFinder, fieldValue = ctx2.robloxMcpUrl, ctx2.fieldValue
								local tryCall5Result = tryCall5(robloxMcpUrlFinder .. "eggtop.js", fieldValue)

								if tryCall5Result and (type(tryCall5Result.eggs) == "table") then
									for _, egg in ipairs(tryCall5Result.eggs) do
										egg.value = tonumber(egg.value) or 0
									end

									robloxMcpUrlFinder, fieldValue = ctx2.fieldValue2, ctx2.fieldValue2
									robloxMcpUrlFinder.sample = tryCall5Result.eggs
									fieldValue.dirty = true
								end
							else
								amount5 = now2 + 0.5
							end
						end
					end
				end

				if now2 >= amount6 then
					amount6 = now2 + 1

					if tempValue13 then
						local fieldValue2Finder = ctx2.fieldValue2

						if fieldValue2Finder.drawer == "sign" then
							local fieldValue2 = ctx2.fieldValue2
							fieldValue2.dirty = true
						else
							local fieldValue22 = ctx2.fieldValue2

							if fieldValue22.view == "ac" then
								local fieldValue2 = ctx2.fieldValue2
								fieldValue2.dirty = true
							end
						end
					end
				end

				local fieldValue25 = ctx2.fieldValue2
				local hold, fieldValue26 = ((fieldValue25.auto and jsonFile.hold) and hasTimedOut6())
					or false, ctx2.fieldValue2

				if hold ~= fieldValue26.hold then
					fieldValue25 = ctx2.fieldValue2

					if fieldValue25.hold then
						if not (hold) then
							local fieldValue2, getServerTimeNowFinder = ctx2.fieldValue2, ctx2.getServerTimeNow
							fieldValue2.autoAt = getServerTimeNowFinder() * 1000
							scanItems4()
						end
					end

					local fieldValue2Finder = ctx2.fieldValue2
					fieldValue2Finder.hold = hold
					fieldValue2Finder = ctx2.fieldValue2
					fieldValue2Finder.dirty = true
				end

				fieldValue26 = ctx2.fieldValue2
				fieldValue25, hold = (fieldValue26.auto and checkStateFinder()) and hasTimedOut2()

				if fieldValue25 then
					fieldValue26 = ctx2.fieldValue2
					hold = not fieldValue26.hold
				else
					hold = fieldValue25
				end

				fieldValue25 = nil

				if hold then
					fieldValue26 = ctx2.fieldValue2
					fieldValue25 = (now2 - fieldValue26.arrived) > 8
				else
					fieldValue25 = hold
				end

				if fieldValue25 then
					scanItems4()
					hold, fieldValue26 = ipairs, ctx2.fieldValue2
					local pick, tempValue2, tempValue5 = fieldValue26.pick or {}

					for index, item in hold(pick) do
						if item.jobId then
							index = ctx2.fieldValue2

							if (index.failed[item.jobId] or 0) <= now2 then
								local fieldValue2 = ctx2.fieldValue2
								local currentCount = fieldValue2.tried[item.jobId] or 0

								if tempValue2 then
									if currentCount < tempValue5 then
										tempValue2, tempValue5 = item, currentCount
									else
										if currentCount == 0 then
											if tempValue5 == 0 then
												if (item.at or 0) > (tempValue2.at or 0) then
													tempValue2, tempValue5 = item, currentCount
												else
												end
											else
											end
										else
										end
									end
								else
									tempValue2, tempValue5 = item, currentCount
								end
							else
							end
						else
						end
					end

					local fieldValue2Finder, hold3, gate = ctx2.fieldValue2, tempValue2 and jsonFile.hold

					if hold3 then
						pick = ctx2.getServerTimeNow
						gate = pick() < ((((tempValue2.at or 0) / 1000) + localPlayer2:GetNetworkPing()) + 0.1)
					else
						gate = hold3
					end

					fieldValue2Finder.gate = gate

					if tempValue2 then
						fieldValue2Finder = ctx2.fieldValue2

						if not (fieldValue2Finder.gate) then
							if not (readAttributeFinder()) then
								if tempValue2.placeId == gameRef2.PlaceId then
									if tempValue2.jobId then
										if tempValue9 then
											if tempValue9.a then
												if not (tempValue9.fly) then
													if tempValue2.jobId ~= tempValue9.e.jobId then
														hold3 = ctx2.fieldValue2

														if not (hold3.tried[tempValue2.jobId]) then
															if (tempValue2.at or 0) > (tempValue9.e.at or 0) then
																tempValue9 = nil
																checkState7(tempValue2, true)
															end
														end
													end
												end
											end
										else
											tempValue9 = nil
											checkState7(tempValue2, true)
										end
									end
								end
							end
						end
					end
				else
					local fieldValue2 = ctx2.fieldValue2
					fieldValue2.gate = nil
				end

				now2, fieldValue25 = task.wait, ctx2.fieldValue2
				hold, fieldValue26 = #fieldValue25.inbox > 0

				if hold then
					fieldValue26 = hold
				else
					fieldValue25 = ctx2.fieldValue2
					fieldValue26 = fieldValue25.gate
				end

				now2((fieldValue26 and 0) or 0.2)
			end
		end)

		ctx2.genv.ChilliFinderPanelCleanup = function()
			local genvFinder = ctx2.genv
			genvFinder.ChilliFinderHidden = nil
			pcall(destroyAll)
			tempValueFinder = false
			genvFinder = ctx2.tryCall3
			genvFinder()
			local guiList, fieldValue2 = ctx2.genv, ctx2.fieldValue2

			if guiList.ChilliFinderOwner == fieldValue2.me then
				genvFinder = ctx2.genv
				genvFinder.ChilliFinderOwner = nil
			end

			genvFinder = ctx2.genv

			if genvFinder.ChilliFinderPanelClose == chilliFinderPanelClose then
				guiList = ctx2.genv
				guiList.ChilliFinderPanelClose = nil
			end

			for _, item in ipairs(connections3) do
				pcall(item.Disconnect, item)
			end

			tryCall3()
			guiList = {"hudGui", "gui"}

			for _, item in ipairs(guiList) do
				fieldValue2 = entries2[item]

				if fieldValue2 then
					pcall(fieldValue2.Destroy, fieldValue2)
				end
			end

			if entries2.tpl then
				pcall(entries2.tpl.Destroy, entries2.tpl)
			end

			if deadline then
				pcall(writefile, chilliFinderSettingsFile, ctx2.HttpService:JSONEncode(jsonFile))
			end

			fieldValue2 = ctx2.genv
			fieldValue2.ChilliFinderPanelCleanup = nil
		end
end
local ok, err = xpcall(JohnHubRunSource, function(e)
    local detail = (debug and debug.traceback and debug.traceback()) or ""
    return tostring(e) .. " | " .. tostring(detail):sub(1, 500)
end)
if not ok then
    warn("[John Hub Finder] Initialization failed: " .. tostring(err))
end

]=======]
local TEMPLATE = [======[
-- John Hub standalone live egg finder (source-preserving bootstrap)
local CODE = %q
local TEMPLATE = %q
local ENV = ((type(getgenv) == "function") and getgenv()) or _G
ENV.JohnHubStandaloneSource = string.format(TEMPLATE, CODE, TEMPLATE)
ENV.JohnHubFinderReady = false
ENV.JohnHubOpenedOnce = false
ENV.ChilliFinderEmbedded = nil
local chunk, compileError = loadstring(CODE)
if not chunk then
    warn("[John Hub Finder] Source error: " .. tostring(compileError))
else
    chunk()
end

]======]
local ENV = ((type(getgenv) == "function") and getgenv()) or _G
ENV.JohnHubStandaloneSource = string.format(TEMPLATE, CODE, TEMPLATE)
ENV.JohnHubFinderReady = false
ENV.JohnHubOpenedOnce = false
ENV.ChilliFinderEmbedded = nil
local chunk, compileError = loadstring(CODE)
if not chunk then
    warn("[John Hub Finder] Source error: " .. tostring(compileError))
else
    chunk()
end
