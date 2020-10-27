local head, body = discord.http(
	"https://api.github.com/repos/Tocutoeltuco/modulo-cards/commits/master",
	{{"User-Agent", "Mozilla/5.0"}}
)
body = json.decode(body)
LATEST_MODULO_CARDS_COMMIT = body.sha

head, body = discord.http("https://raw.githubusercontent.com/Tocutoeltuco/modulo-cards/" .. LATEST_MODULO_CARDS_COMMIT .. "/cards.lua")
local fnc, err = discord.load(body)
if err then
	error(err)
end
return fnc()