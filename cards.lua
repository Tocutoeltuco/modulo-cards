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
				"**%s** (`%s`, **%s/%s**, %s)",
				discord.getMemberName(game.players[1]), -- 1st player (host)
				game.public and game.code or "private",
				#game.players, data.maxplayers,
				game.started and "playing" or "waiting"
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
	local is_host = game.players[1] == discord.authorId

	if game.started then
		local script = load(mod.script)
		script.initialChecks(user, game, mem, api.decks[mod.deck])
		script.command()

	else
		local cmd, args, length = api.get_command(parameters)

		if cmd == "leave" then
			if is_host then
				local game_deleted = {embed = {
					title = "Game deleted",
					description = string.format(
						"The game host (**%s** <@%s>) has left the game, so it has been deleted.",
						discord.authorName, discord.authorId
					)
				}}

				local player
				for index = 1, #game.players do
					player = game.players[index]
					mem.users[player] = nil

					discord.sendPrivateMessage(game_deleted, player)
				end
				for index = 1, #game.waiting do
					player = game.waiting[index]
					mem.users[player] = nil

					discord.sendPrivateMessage(game_deleted, player)
				end

				for index = 1, #mod.games do
					if mod.games[index] == game.code then
						table.remove(mod.games, index)
						break
					end
				end
				mem.games[game.code] = nil

				return
			end

			for index = 1, #game.players do
				if game.players[index] == discord.authorId then
					table.remove(game.players, index)
					break
				end
			end
			mem.users[discord.authorId] = nil

			discord.sendPrivateMessage({embed = {
				title = "Left the game",
				description = "You've left the game."
			}})

			local player_left = {embed = {
				title = "Player left",
				description = string.format(
					"**%s** (<@%s>) has left the game.",
					discord.authorName, discord.authorId
				)
			}}
			for index = 1, #game.players do
				discord.sendPrivateMessage(player_left, game.players[index])
			end

		elseif is_host then
			if cmd == "start" then
				local start_msg = {embed = {
					title = "Starting game",
					description = "The game is starting."
				}}
				for index = 1, #game.players do
					discord.sendPrivateMessage(start_msg, game.players[index])
				end

				game.started = true
				local script = load(mod.script)
				script.initialChecks(user, game, mem, api.decks[mod.deck])
				script.start()

			elseif cmd == "accept" or cmd == "deny" then
				if #game.waiting == 0 then
					discord.reply({embed = {
						title = "Error!",
						description = "Nobody is in your game's waiting list."
					}})
					return
				end

				local waiter = game.waiting[1]
				table.remove(game.waiting, 1)

				if cmd == "accept" then
					local players = #game.players + 1

					mem.users[waiter].ready = true
					game.players[players] = waiter

					local player_list = {}
					local new_player = {embed = {
						title = "New player",
						description = string.format(
							"**%s** has joined the game. **(%s/%s)**",
							discord.getMemberName(waiter),
							players, mod.maxplayers
						)
					}}
					local player
					for index = 1, players - 1 do
						player = game.players[index]

						discord.sendPrivateMessage(new_player, player)
						player_list[index] = "**" .. discord.getMemberName(player) .. "** <@" .. player .. ">"
					end

					discord.sendPrivateMessage({embed = {
						title = "Joined game",
						description = string.format(
							"You've joined the game `%s`. Players:\n- %s",
							game.code,
							table.concat(player_list, "\n- ")
						)
					}}, waiter)

					if players == mod.maxplayers then
						local rejection = {embed = {
							title = "Rejected",
							description = string.format(
								"The game `%s` is now full, so we removed you from the waiting list.",
								game.code
							)
						}}

						for index = 1, #game.waiting do
							waiter = game.waiting[index]
							mem.users[waiter] = nil

							discord.sendPrivateMessage(rejection, waiter)
						end

						game.waiting = {}

					elseif #game.waiting > 0 then
						discord.sendPrivateMessage({embed = {
							title = "Join request",
							description = string.format(
								"**%s** (<@%s>) wants to join your %s game. Type **!cards accept** or **!cards deny**.",
								discord.getMemberName(waiter), waiter,
								mod.name
							)
						}})
					end

				else
					mem.users[waiter] = nil

					discord.sendPrivateMessage({embed = {
						title = "Rejected",
						description = string.format(
							"You've been rejected to join the game `%s`.",
							game.code
						)
					}}, waiter)

					discord.sendPrivateMessage({embed = {
						title = "Rejection",
						description = string.format(
							"You've rejected **%s** (<@%s>).",
							discord.getMemberName(waiter), waiter
						)
					}})

					if #game.waiting > 0 then
						waiter = game.waiting[1]
						discord.sendPrivateMessage({embed = {
							title = "Join request",
							description = string.format(
								"**%s** (<@%s>) wants to join your %s game. Type **!cards accept** or **!cards deny**.",
								discord.getMemberName(waiter), waiter,
								mod.name
							)
						}})
					end
				end
			
			elseif cmd == "lock" then
				game.public = not game.public

				local change = {embed = {
					title = "Game Privacy",
					description = string.format(
						"The game is now `%s`.",
						game.public and "public" or "private"
					)
				}}

				for index = 1, #game.players do
					discord.sendPrivateMessage(change, game.players[index])
				end

			else
				discord.reply({embed = {
					title = "Unknown command",
					description = string.format(
						"Unknown command: `%s`.\n\n**Use `!cards help` to learn more.**",
						cmd
					)
				}})
			end

		else
			discord.reply({embed = {
				title = "Unknown command",
				description = string.format(
					"Unknown command: `%s`.\n\n**Use `!cards help` to learn more.**",
					cmd
				)
			}})
		end
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
				description = string.format(
					"The given code (`%s`) does not match any existent game.",
					code
				)
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
				description = string.format(
					"**%s** (<@%s>) wants to join your %s game. Type **!cards accept** or **!cards deny**.",
					discord.authorName, discord.authorId,
					mod.name
				)
			}}, game.players[1])
		end

		discord.reply({embed = {
			title = "Join request sent",
			description = string.format(
				"We sent your join request to **%s**. We'll notify you when they accept or deny.",
				discord.getMemberName(game.players[1])
			)
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
		local mod = mem.modules[ game.type ]
		mem.games[code] = game
		mod.games[#mod.games + 1] = code
		mem.users[discord.authorId] = {
			ready = true,
			game = code
		}

		discord.reply({embed = {
			title = "Game created",
			description = string.format(
				"You've created a %s game. Code: `%s`.\n\n" ..
				"Type **!cards lock** to make it public. " ..
				"We'll notify you when someone tries to join",
				mod.name, code
			)
		}})
	end
end