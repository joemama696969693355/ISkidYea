if not shared.vape then
    repeat task.wait() until shared.vape
end
local vape = shared.vape
local httpService = game:GetService('HttpService')
local catauth = getgenv().CAK
if not isfile('newcatvape/updateTime.json') then
	writefile('newcatvape/updateTime.json', [[{"CAK": "none", "User": "None", "Minute": "0"}]])
end
local updateData = httpService:JSONDecode(readfile('newcatvape/updateTime.json'))
if catauth or isfile('cak') then
	if not catauth then 
		getgenv().CAK = readfile('cak')
		if getgenv().CAK:find('\n') then
			getgenv().CAK = getgenv().CAK:split('\n')[1]
		end
	end
	catauth = getgenv().CAK
	writefile('cak', catauth)
	if updateData.CAK ~= catauth or updateData.User ~= game.Players.LocalPlayer.Name or updateData.Minute <= 0 then
		local suc, res = pcall(function()
			local result = request({
				Url = 'https://api.catvape.info/auth/whitelist/updateWhitelist?key='..catauth..'&name='..game.Players.LocalPlayer.Name,
				Method = 'GET'
			})
			local body = httpService:JSONDecode(result.Body)
			if body and body.Rank then
				return 'Failed'
			else
				error('Failed')
			end
		end)
		if not suc then
			task.spawn(error, 'Cat Login | '.. res)
			vape:CreateNotification('Cat', 'Failed to update whitelist data', 10, 'alert')
		else
			vape:CreateNotification('Cat', 'Updated whitelist data', 10, 'alert')
			updateData.CAK = catauth
			updateData.User = game.Players.LocalPlayer.Name
			updateData.Minute = tonumber(updateData.Minute) <= 0 and 30 or updateData.Minute - 1
			writefile('newcatvape/updateTime.json', httpService:JSONEncode(updateData))
		end
	end
else
	vape:CreateNotification('Cat', 'Failed to login: CAK is not valid, please generate a new one.', 10, 'alert')
	task.delay(11, function()
		vape:Uninject()
	end)
	error('Cat | Failed to login: CAK is not valid, please generate a new one')
end

local success, res = pcall(function()
	local req = request({
		Url = 'https://api.catvape.info/auth/authorization/key/discord?key='..catauth,
		Method = 'GET'
	})
	print(req.StatusCode)
	print(req.Body)
	if tostring(req.Body) == '404' or tostring(req.Body):find('502 Bad Gateway') then
		return 'Down'
	end
	local API
	local a2, v2 = pcall(function()
		API = httpService:JSONDecode(req.Body)
	end)
	if not a2 then
		return "Down"
	end
	assert(API.userid)
	vape:CreateNotification('Cat', 'Logged in as '.. API.name.. ' ('.. API.userid.. ')', 7)
	task.spawn(function()
		request({
			Url = 'https://api.catvape.info/auth/authorization/key/successLogin?key='..catauth,
			Method = 'GET'
		})
	end)
end)

if not success or success and res == 'Down' then
	if res == 'Down' then
		print('cat down')
		return true
	elseif not success then
		task.delay(7, function()
			vape:Uninject()
		end)
		task.spawn(warn, res)
		vape:CreateNotification('Cat', 'Invalid api result, Please report this problem to qwertyui or fuzzy.', 7, 'alert')
		error('CatVape | Invalid api result, Please report this problem to qwertyui or fuzzy.')
	end
end
task.spawn(function()
	local suc, err = pcall(function()
		loadfile('newcatvape/libraries/whitelist.lua')()
	end)
	if not suc then
		task.spawn(error, 'Cat Whitelist | '.. err)
		vape:CreateNotification('Cat', 'Whitelist is currently down, Please report this problem to qwertyui or fuzzy.', 20, 'alert')
	else
		task.spawn(function()
			local updateTick = tick()
			repeat
				if (tick() - updateTick) >= 59 then
					updateTick = tick()
					updateData.CAK = readfile('cak')
					updateData.User = game.Players.LocalPlayer.Name
					updateData.Minute = updateData.Minute - 1
					writefile('newcatvape/updateTime.json', httpService:JSONEncode(updateData))
				end
				task.wait(15)
			until not shared.vape
		end)
	end
end)
