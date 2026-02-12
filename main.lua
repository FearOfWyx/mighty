--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.
repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local function getHWID()
    local hwid = nil
    
    if gethwid then
        hwid = gethwid()
    elseif getexecutorname then
        local executor_name = getexecutorname()
        local unique_str = executor_name .. tostring(game:GetService("UserInputService"):GetGamepadState(Enum.UserInputType.Gamepad1))
        
        if syn and syn.crypt and syn.crypt.hash then
            hwid = syn.crypt.hash(unique_str)
        elseif crypt and crypt.hash then
            hwid = crypt.hash(unique_str)
        else
            hwid = game:GetService("HttpService"):GenerateGUID(false)
        end
    end
    
    if not hwid and game:GetService("RbxAnalyticsService") then
        local success, result = pcall(function()
            return game:GetService("RbxAnalyticsService"):GetClientId()
        end)
        if success and result then
            hwid = result
        end
    end
    
    if not hwid then
        hwid = tostring(math.random(100000, 999999)) .. tostring(os.time())
    end
    
    return hwid
end

local function validateSecurity()
    local HttpService = game:GetService("HttpService")
    
    if not isfile('newvape/security/validated') then
        game.StarterGui:SetCore("SendNotification", {
            Title = "security error",
            Text = "please use right log in first",
            Duration = 5
        })
        return false, nil
    end
    
    local validationContent = readfile('newvape/security/validated')
    local success, validationData = pcall(function()
        return HttpService:JSONDecode(validationContent)
    end)
    
    if not success or not validationData then
        game.StarterGui:SetCore("SendNotification", {
            Title = "security error",
            Text = "corrupted validation file try to log in again",
            Duration = 5
        })
        return false, nil
    end
    
    if not validationData.username then
        game.StarterGui:SetCore("SendNotification", {
            Title = "security error",
            Text = "username missing from validation file",
            Duration = 5
        })
        return false, nil
    end
    
    if not validationData.hwid then
        game.StarterGui:SetCore("SendNotification", {
            Title = "security error",
            Text = "hwid missing from validation file",
            Duration = 5
        })
        return false, nil
    end
    
    local currentHWID = getHWID()
    if validationData.hwid ~= currentHWID then
        game.StarterGui:SetCore("SendNotification", {
            Title = "security error",
            Text = "hwid changed. your hwid doesnt match try to log in again",
            Duration = 5
        })
        return false, nil
    end
    
    local ACCOUNT_SYSTEM_URL = "https://raw.githubusercontent.com/poopparty/whitelistcheck/main/AccountSystem.lua"
    
    local function fetchAccounts()
        local success, response = pcall(function()
            return game:HttpGet(ACCOUNT_SYSTEM_URL)
        end)
        if success and response then
            local accountsTable = loadstring(response)()
            if accountsTable and accountsTable.Accounts then
                return accountsTable.Accounts
            end
        end
        return nil
    end
    
    local accounts = fetchAccounts()
    if not accounts then
        game.StarterGui:SetCore("SendNotification", {
            Title = "connection error",
            Text = "cant verify account status",
            Duration = 5
        })
        return false, nil
    end
    
    local accountValid = false
    local accountActive = false
    local accountHWID = nil
    for _, account in pairs(accounts) do
        if account.Username == validationData.username then
            accountValid = true
            accountActive = account.IsActive == true
            accountHWID = account.HWID
            break
        end
    end
    
    if not accountValid then
        game.StarterGui:SetCore("SendNotification", {
            Title = "access taken",
            Text = "your account is no longer authorized",
            Duration = 5
        })
        return false, nil
    end
    
    if not accountActive then
        game.StarterGui:SetCore("SendNotification", {
            Title = "account inactive",
            Text = "your account is currently inactive",
            Duration = 5
        })
        return false, nil
    end
    
    if accountHWID and currentHWID ~= accountHWID then
        game.StarterGui:SetCore("SendNotification", {
            Title = "security error",
            Text = "hwid mismatch detected",
            Duration = 5
        })
        return false, nil
    end
    
    return true, validationData.username
end

local securityPassed, validatedUsername = validateSecurity()
if not securityPassed then
    return
end

shared.ValidatedUsername = validatedUsername

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local queue_on_teleport = queue_on_teleport or function() end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/'..readfile('newvape/profiles/commit.txt')..'/'..select(1, path:gsub('newvape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function downloadPremadeProfiles()
    local httpService = game:GetService('HttpService')
    if not isfolder('newvape/profiles/premade') then
        makefolder('newvape/profiles/premade')
    end
    
    local commit = readfile('newvape/profiles/commit.txt')
    if not commit then
        commit = 'main'
    end
    
    local success, response = pcall(function()
        return game:HttpGet('https://api.github.com/repos/poopparty/poopparty/contents/profiles/premade?ref='..commit)
    end)
    
    if success and response then
        local files = httpService:JSONDecode(response)
        
        if type(files) == 'table' then
            for _, file in pairs(files) do
                if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                    local filePath = 'newvape/profiles/premade/'..file.name
                    
                    if not isfile(filePath) then
                        if file.download_url then
                            local downloadSuccess, fileContent = pcall(function()
                                return game:HttpGet(file.download_url, true)
                            end)
                            
                            if downloadSuccess and fileContent and fileContent ~= '404: Not Found' then
                                writefile(filePath, fileContent)
                            end
                        else
                            local downloadSuccess, fileContent = pcall(function()
                                return game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/'..commit..'/profiles/premade/'..file.name, true)
                            end)
                            
                            if downloadSuccess and fileContent ~= '404: Not Found' then
                                writefile(filePath, fileContent)
                            end
                        end
                    end
                end
            end
        end
    else
        local profiles = {
            'aero6872274481.txt',
            'aero6872265039.txt',
        }
        
        for _, profileName in ipairs(profiles) do
            local filePath = 'newvape/profiles/premade/'..profileName
            if not isfile(filePath) then
                local downloadSuccess, fileContent = pcall(function()
                    return game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/'..commit..'/profiles/premade/'..profileName, true)
                end)
                
                if downloadSuccess and fileContent ~= '404: Not Found' then
                    writefile(filePath, fileContent)
                end
            end
        end
    end
end

local function checkAccountActive()
    local ACCOUNT_SYSTEM_URL = "https://raw.githubusercontent.com/poopparty/whitelistcheck/main/AccountSystem.lua"
    
    local function fetchAccounts()
        local success, response = pcall(function()
            return game:HttpGet(ACCOUNT_SYSTEM_URL)
        end)
        if success and response then
            local accountsTable = loadstring(response)()
            if accountsTable and accountsTable.Accounts then
                return accountsTable.Accounts
            end
        end
        return nil
    end
    
    local accounts = fetchAccounts()
    if not accounts then 
        return true 
    end
    
    for _, account in pairs(accounts) do
        if account.Username == shared.ValidatedUsername then
            return account.IsActive == true
        end
    end
    return false
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleportedServers
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('newvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then
				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
			end
			if shared.VapeCustomProfile then
				teleportScript = 'shared.VapeCustomProfile = "'..shared.VapeCustomProfile..'"\n'..teleportScript
			end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Finished Loading', 'wsg, '..shared.ValidatedUsername..'! '..(vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI'), 5)
		end
	end
end

if not isfile('newvape/profiles/gui.txt') then
	writefile('newvape/profiles/gui.txt', 'new')
end
local gui = readfile('newvape/profiles/gui.txt')

if not isfolder('newvape/assets/'..gui) then
	makefolder('newvape/assets/'..gui)
end

downloadPremadeProfiles()

vape = loadstring(downloadFile('newvape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('newvape/games/universal.lua'), 'universal')()
	if isfile('newvape/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/poopparty/poopparty/'..readfile('newvape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('newvape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
