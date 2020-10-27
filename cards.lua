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
			--	public = true,
			--	started = false
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

local REPO_LINK = "https://raw.githubusercontent.com/Tocutoeltuco/modulo-cards/" .. LATEST_MODULO_CARDS_COMMIT .. "/"
local mem = CARDS_MEMORY_TABLE
local function load(script)
	local head, body = discord.http(REPO_LINK .. "api.lua")
	local fnc, err = discord.load(body)
	if err then
		error("Syntax error in " .. script .. ": " .. err, 2)
	end
	local done, result = pcall(fnc)
	if not done then
		error("Runtime error in " .. script .. ": " .. result, 2)
	end
	return result
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

		fields[#fields + 1] = {
			name = data.name,
			value = table.concat(value, "\n")
		}
	end

	discord.reply({embed = {
		title = "Game List",
		description = "This is the list of available card games.\n\n**DM me `!cards help` to learn more.**",

		fields = fields
	}})
	return

elseif parameters == "help" then
	discord.reply({embed = {
		title = "Card Games Help",
		description = "to-do owo"
	}})
	return
end

if mem.users[ discord.authorId ] then
	local user = mem.users[ discord.authorId ]
	local game = mem.games[ user.game ]
	local mod = mem.modules[ game.type ]

	if game.started then
		local script = load(mod.script)
		script.initialChecks(user, game, mem)
		script.command()
	else
	end

elseif not parameters then
	discord.reply({embed = {
		title = "Error!",
		description = "You're not in any game. Create or join one!\n\n**Use `!cards help` to know how to.**"
	}})

else
	local cmd, args, length = api.get_command(parameters)

	if cmd == "join" then
		if length == 0 then
			discord.reply({embed = {
				title = "Invalid syntax",
				description = "You need to provide a code! Example: `!cards join AAAA`"
			}})
			return
		end

		local code = string.upper(args[1])
		local game = mem.games[code]
		if not game then
			discord.reply({embed = {
				title = "Unkown game",
				description = "The given code (`" .. code .. "`) does not match any existent game."
			}})
			return
		end
		local mod = mem.modules[ game.type ]
		if game.started or #game.players >= mod.maxplayers then
			discord.reply({embed = {
				title = "Can't join that game",
				description = "That game seems to be full or already started!"
			}})
			return
		end

		game.waiting[#game.waiting + 1] = discord.authorId
		mem.users[discord.authorId] = {
			ready = false,
			game = code
		}

		if #game.waiting == 1 then
			discord.sendPrivateMessage({embed = {
				title = "Join request",
				description = ("**" .. discord.authorName .. "** (<@" .. discord.authorId .. ">) wants to join your " ..
					mod.name .. " game. Type **!cards accept** or **!cards deny**.")
			}}, game.players[1])
		end

		discord.reply({embed = {
			title = "Join request sent",
			description = ("We sent your join request to **" .. discord.getMemberName(game.players[1]) ..
				"**. We'll notify you when they accept or deny.")
		}})

	elseif cmd == "create" then
		local available_characters = {
			"A", "B", "C", "D", "E", "F",
			"G", "H", "I", "J", "K", "L",
			"M", "N", "O", "P", "Q", "R",
			"S", "T", "U", "V", "W", "X",
			"Y", "Z"
		}
		local code = {}
		for i = 1, 4 do
			code[i] = available_characters[ math.random(26) ]
		end
		code = table.concat(code, "")

		local game = {
			code = code,
			type = "blackjack",
			players = {discord.authorId},
			waiting = {},
			public = false,
			started = false
		}
		mem.games[code] = game
		mem.users[discord.authorId] = {
			ready = true,
			game = code
		}

		discord.reply({embed = {
			title = "Game created",
			description = "You've created a " .. mem.modules[ game.type ].name .. " game. Code: `" .. code .. "`."
		}})

	else
		discord.reply({embed = {
			title = "Unknown command",
			description = "Unknown command: `" .. cmd .. "`.\n\n**Use `!cards help` to learn more.**"
		}})
	end
end