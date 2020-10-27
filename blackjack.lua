local user, game, mem, deck

local function broadcast(content)
	for index = 1, #game.players do
		discord.sendPrivateMessage(content, game.players[index])
	end
end

local function pickRandomCard()
	local index
	repeat
		index = math.random(#deck)
	until not game.usedCards[index]

	game.blackjack.usedCards[index] = true
	return deck[index]
end

local function newDeck(cards)
	local deck = {}

	for index = 1, cards do
		deck[index] = pickRandomCard()
	end

	return deck
end

local function deckToString(deck)
	local str = {}

	for index = 1, #deck - 1 do
		str[index] = deck[index][3]
	end

	return string.format(
		"**%s** and **%s**",
		table.concat(str, "**, **"),
		deck[#deck][3]
	)
end

local function deckPoints(deck)
	local aces, total = 0, 0

	local card
	for index = 1, #deck do
		card = deck[index]

		if card[1] == 1 then -- ace
			aces = aces + 1
		else
			total = total + math.min(10, card[1])
		end
	end

	for index = 1, aces do
		total = total + (total + 11 > 21 and 1 or 11)
	end

	return total
end

local function sendDeck(player)
	local description = string.format(
		"Your deck is %s (%s points)",
		deckToString(game.blackjack.decks[player]),
		deckPoints(game.blackjack.decks[player])
	)

	if player == game.players[2] then
		description = description .. "\nThe dealer's second card is **" .. game.blackjack.decks[game.players[1]][2][3] .. "**"
	end

	discord.sendPrivateMessage({embed = {
		title = "Deck Information",
		description = description
	}}, player)
end

local function setTurn(player)
	game.blackjack.turn = game.players[player]
	game.blackjack.turnTimeout = os.time() + 60

	broadcast({embed = {
		title = string.format("It's the %s's turn!", player == 1 and "dealer" or "player"),
		description = string.format(
			"It's **%s**'s turn (<@%s>). They have **1 minute** or they'll automatically stand.",
			discord.getMemberName(game.players[player]), game.players[player]
		)
	}})
end

local function startNewRound()
	if game.blackjack.round > 0 then
		local dealer = game.blackjack.decks[game.players[1]]
		local player = game.blackjack.decks[game.players[2]]
		local dealer_points, player_points = deckPoints(dealer), deckPoints(player)

		local winner
		if player_points > 21 then
			winner = "dealer"
		elseif dealer_points > 21 then
			winner = "player"
		elseif player_points > dealer_points then
			winner = "player"
		else
			winner = "dealer"
		end

		broadcast({embed = {
			title = "Round ends!",
			description = string.format(
				"The dealer's deck was %s (%s points)\nThe player's deck was %s (%s points)\n\nThe %s wins the round!",
				deckToString(dealer), dealer_points,
				deckToString(player), player_points,
				winner
			)
		}})

		game.blackjack.rounds[game.blackjack.round] = winner
	end

	game.blackjack.round = game.blackjack.round + 1
	if game.blackjack.round > 2 then
		local winner
		if game.blackjack.round == 3 then
			if game.blackjack.rounds[1] == game.blackjack.rounds[2] then -- 2/3 victories
				winner = game.blackjack.rounds[1]
			end
		else
			local player_victories, dealer_victories = 0, 0
			for index = 1, #game.blackjack.rounds do
				if game.blackjack.rounds[index] == "player" then
					player_victories = player_victories + 1
				else
					dealer_victories = dealer_victories + 1
				end
			end

			winner = dealer_victories > player_victories and "dealer" or "player"
		end

		if winner then
			local player = game.players[winner == "dealer" and 1 or 2]

			broadcast({embed = {
				title = "The game ends!",
				description = string.format(
					"The %s (**%s** <@%s>) has won the game!\n\nTo leave, `!cards leave`. To play again, `!cards start`.",
					winner,
					discord.getMemberName(player), player
				)
			}})

			game.blackjack = nil
			game.started = false
		end
		return
	end

	game.blackjack.usedCards = {}
	setTurn(2)

	for index = 1, 2 do
		game.blackjack.decks[game.players[index]] = newDeck(2)
		sendDeck(game.players[index])
	end
end

local function stand(forced)
	if game.blackjack.turn == game.players[1] then -- dealer
		broadcast({embed = {
			title = "Dealer stood!",
			description = forced and "Time has ran out and the dealer stood." or nil
		}})

		startNewRound()

	else -- player
		broadcast({embed = {
			title = "Player stood!",
			description = forced and "Time has ran out and the player stood." or nil
		}})

		setTurn(1)
	end
end

local function hit()
	local card = pickRandomCard()
	local deck = game.blackjack.decks[game.blackjack.turn]
	deck[#deck + 1] = card
	local points = deckPoints(deck)
	local is_dealer = game.blackjack.turn == game.players[1]

	local content = {embed = {
		title = is_dealer and "Dealer hits!" or "Player hits!"
	}}

	if points > 21 then
		content.description = string.format(
			"The %s has got more than 21 points and has been busted!",
			is_dealer and "dealer" or "player"
		)
		broadcast(content)
		startNewRound()
		return
	end

	for index = 1, 2 do
		if (is_dealer and index == 1) or (not is_dealer and index == 2) then
			content.description = "You got a(n) **" .. card[3] .. "**. You have **" .. points .. "** points."
		else
			content.description = nil
		end

		discord.sendPrivateMessage(content, game.players[index])
	end
end

return {
	initialChecks = function(_user, _game, _mem, _deck)
		user, game, mem, deck = _user, _game, _mem, _deck

		if not game.blackjack then -- not initialized
			game.blackjack = {
				rounds = {}, -- round winners
				round = 0,
				turn = nil,
				turnTimeout = nil,
				decks = {},
				usedCards = {}
			}

			startNewRound()
		end

		if os.time() >= game.blackjack.turnTimeout then
			stand(true)
		end
	end,

	command = function()
		local cmd, args, length
		if parameters then
			cmd, args, length = api.get_command(parameters)
		end

		if cmd == "stand" or cmd == "hit" then
			if discord.authorId == game.blackjack.turn then
				discord.reply({embed = {
					title = "It's not your turn!",
					description = "Please wait for your turn."
				}})
				return
			end

			if cmd == "stand" then
				stand(false)
			else
				hit()
			end

		elseif not cmd then
			sendDeck(discord.authorId)

		else
			discord.reply({embed = {
				title = "Unkown command",
				description = (
					"You're in a blackjack game so you can only use blackjack commands: " ..
					"**!cards stand**, **!cards hit**, **!cards**"
				)
			}})
		end
	end
}