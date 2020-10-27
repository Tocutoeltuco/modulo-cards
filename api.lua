local function split_text(text, split_at, on_linebreak)
	local slices = {}
	
	if on_linebreak then
		local index = 1

		while #text - index + 1 > split_at do
			local slice = string.reverse(string.sub(text, index, index + split_at - 1))
			local slice = string.reverse(string.sub(slice, string.find(slice, "\n") + 1))
			slices[#slices + 1] = slice

			index = index + #slice + 1
		end

		if #text - index > 0 then
			slices[#slices + 1] = string.sub(text, index)
		end
	else
		for index = 1, #text, split_at do
			slices[#slices + 1] = text:sub(index, index + split_at - 1)
		end
	end

	return slices
end

local function get_command(text)
	local cmd, args, pointer = "", {}, -1

	for slice in string.gmatch(text, "%S+") do
		pointer = pointer + 1
		if pointer == 0 then
			cmd = string.lower(slice)
		else
			args[pointer] = slice
		end
	end

	return cmd, args, pointer
end

do
	local reply = discord.reply
	local privateMessage = discord.sendPrivateMessage

	local function sendContent(fnc, content, arg1)
		if type(content) == "table" and content.embed then
			-- UTC (!), year-month-dayThour:minute:secondZ
			content.embed.timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

			if not discord.message.isDM then
				content.embed.footer = {
					icon_url = discord.message.author.avatarURL,
					text = "Requested by " .. discord.authorName
				}
			end

			if not content.embed.color then
				content.embed.color = 0x665bf7
			end

			if content.embed.description and #content.embed.description > 2000 then
				for id, slice in next, split_text(content.embed.description, 2000, true) do
					content.embed.description = slice
					fnc(content, arg1)
				end
			else
				fnc(content, arg1)
			end
		elseif type(content) == "string" and #content > 2000 then
			for id, slice in next, split_text(content, 2000, true) do
				fnc(slice, arg1)
			end
		else
			fnc(content, arg1)
		end
	end

	function discord.reply(content)
		return sendContent(reply, content)
	end

	function discord.sendPrivateMessage(content, target)
		return sendContent(privateMessage, content, target)
	end
end

return {
	split_text = split_text,
	get_command = get_command,

	decks = {
		["standard-english"] = {
			name = "Standard 52-Card English Deck",
			cards = {
				"Ace of Clubs",
				"Two of Clubs",
				"Three of Clubs",
				"Four of Clubs",
				"Five of Clubs",
				"Six of Clubs",
				"Seven of Clubs",
				"Eight of Clubs",
				"Nine of Clubs",
				"Ten of Clubs",
				"Jack of Clubs",
				"Queen of Clubs",
				"King of Clubs",
				
				"Ace of Diamonds",
				"Two of Diamonds",
				"Three of Diamonds",
				"Four of Diamonds",
				"Five of Diamonds",
				"Six of Diamonds",
				"Seven of Diamonds",
				"Eight of Diamonds",
				"Nine of Diamonds",
				"Ten of Diamonds",
				"Jack of Diamonds",
				"Queen of Diamonds",
				"King of Diamonds",
				
				"Ace of Spades",
				"Two of Spades",
				"Three of Spades",
				"Four of Spades",
				"Five of Spades",
				"Six of Spades",
				"Seven of Spades",
				"Eight of Spades",
				"Nine of Spades",
				"Ten of Spades",
				"Jack of Spades",
				"Queen of Spades",
				"King of Spades",
				
				"Ace of Hearts",
				"Two of Hearts",
				"Three of Hearts",
				"Four of Hearts",
				"Five of Hearts",
				"Six of Hearts",
				"Seven of Hearts",
				"Eight of Hearts",
				"Nine of Hearts",
				"Ten of Hearts",
				"Jack of Hearts",
				"Queen of Hearts",
				"King of Hearts",
			}
		}
	}
}