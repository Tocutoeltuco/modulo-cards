local memory_version = 1
if not CARDS_MEMORY_TABLE or CARDS_MEMORY_TABLE.version ~= memory_version then
	CARDS_MEMORY_TABLE = {
		version = memory_version,
		users = {
			-- id = {
			--	ready = true,
			--	game = "AAAA"
			-- }
		},
		games = {
			-- code = {
			--	code = "AAAA",
			--	type = "blackjack",
			--	players = {},
			--	waiting = {},
			--	public = true
			-- }
		},
		modules = {
			blackjack = {
				name = "Blackjack",
				script = "blackjack.lua",
				deck = "standard-english",
				games = {},
				maxplayers = 2
			}
		}
	}
end

local REPO_LINK = "https://raw.githubusercontent.com/Tocutoeltuco/modulo-cards/master/"
local mem = CARDS_MEMORY_TABLE
local function load(script)
	local head, body = discord.http(REPO_LINK .. "api.lua")
	local fnc, err = discord.load(body)
	if err then
		error("Syntax error in " .. script .. ": " .. err, 2)
	end
	return fnc()
end
local api = load("api.lua")

if not discord.message.isDM or parameters == "list" then
	-- request game list

	local fields = {}
	local game, value
	for name, data in next, mem.modules do
		value = {}
		for index = 1, #data.games do
			game = mem.games[ data.games[index] ]

			value[index] = string.format(
				"**%s** (`%s`, **%s/%s**)",
				discord.getMemberName(game.players[1]), -- 1st player (host)
				game.public and game.code or "private",
				#game.players, data.maxplayers
			)
		end

		if #value == 0 then
			value[1] = "Nobody is playing right now."
		end

		fields[index] = {
			name = data.name,
			value = table.concat(value, "\n")
		}
	end

	discord.reply({embed = {
		title = "Game List",
		description = "This is the list of available card games.\n\n**DM me `!cards help` to learn more.**",
		color = 0x665bf7,

		fields = fields
	}})
	return

elseif parameters == "help" then
	discord.reply({embed = {
		title = "Card Games Help",
		description = "to-do owo",
		color = 0x665bf7
	}})
	return
end

if mem.users[ discord.authorId ] then
	local user = mem.users[ discord.authorId ]
	local game = mem.games[ user.game ]
	local mod = mem.modules[ game.type ]

	local script = load(mod.script)
	script.initialChecks(user, game, mem)
	script.command()
else
	discord.reply({embed = {
		title = "you're not in any game owo",
		description = "to-do"
	}})
end