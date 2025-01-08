-- Made by qwertyui, qwertyui-is-back on GitHub
local function downloadFile(path, func)
	if not isfile(path) then
		createDownloader(path)
		local suc, res = pcall(function()
			return game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/"..readfile("newcatvape/profiles/commit.txt").."/"..select(1, path:gsub("newcatvape/", "")), true)
		end)
		if not suc or res == "404: Not Found" then
			error(res)
		end
		if path:find(".lua") then
			res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n"..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local cloneref = cloneref or function(obj)
	return obj
end
local httpService = cloneref(game:GetService("HttpService"))
local base64 = loadstring(downloadFile("newcatvape/libraries/base64.lua"), "base64")()

local round = function(number)
    return tonumber(string.format("%.2f", number))
end

local spotify = {
	token = "",
	PlaybackUpdate = Instance.new('BindableEvent')
}

function spotify:ConvertTime(ms)
    local z = round(ms / 1000)
    local m = math.floor(z / 60)
    z = math.floor(z - (m * 60))
    if #tostring(z) < 2 then
        z = string.format("0%d", z)
    end
    return string.format("%s:%s", m, z)
end

function spotify:Request(url)
	local data = http.request({
        Url = "https://api.spotify.com/v1/"..url,
        Method = "GET",
        Headers = {
            Authorization = "Bearer "..spotify.token
        },
    })

    local body = data.Body and cloneref(game:GetService("HttpService")):JSONDecode(data.Body) or ""
    if body and body.error then
        return error(body.error.message)
    end
    return (data and body) or ""
end

function spotify:UpdateToken(refreshToken, clientId, clientSecret)
	if not refreshToken then
		error("string expected, got nil")
	end
	
	spotify.token = ""
	
	local data = http.request({
		Url = "https://api.catvape.info/spotify/updateToken",
		Method = "GET",
		Headers = {
			Token = refreshToken,
			Id = clientId,
			Secret = clientSecret
		}
	})

	local body = data.Body and httpService:JSONDecode(data.Body) or {}
	if body and body.error then
		return error(body.error.message)
	end
	
	spotify.token = body.access_token
	return body.access_token
end

local song = ""
function spotify:GetData()
	local data = spotify:Request("me/player/currently-playing")
    if not data or not data.item then return end

    local names = {}
    if data.item.artists then
        for i, v in ipairs(data.item.artists) do
            table.insert(names, v.name)
        end
    end

    local artist = table.concat(names, ", ")
    if song ~= data.item.name then
		song = data.item.name
		spotify.PlaybackUpdate:Fire(artist, data.item.name, data.item.album.images[2].url)
    end

    return {
        song = {
            name = data.item.name,
            cover = data.item.album.images[2].url,
            artist = artist
        },
        playback = {
            current = data.progress_ms,
            total = data.item.duration_ms,
            playing = data.is_playing
        }
    }
end

return spotify