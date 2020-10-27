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
				{1,  1, "Ace of Clubs"},
				{2,  1, "Two of Clubs"},
				{3,  1, "Three of Clubs"},
				{4,  1, "Four of Clubs"},
				{5,  1, "Five of Clubs"},
				{6,  1, "Six of Clubs"},
				{7,  1, "Seven of Clubs"},
				{8,  1, "Eight of Clubs"},
				{9,  1, "Nine of Clubs"},
				{10, 1, "Ten of Clubs"},
				{11, 1, "Jack of Clubs"},
				{12, 1, "Queen of Clubs"},
				{13, 1, "King of Clubs"},

				{1,  2, "Ace of Diamonds"},
				{2,  2, "Two of Diamonds"},
				{3,  2, "Three of Diamonds"},
				{4,  2, "Four of Diamonds"},
				{5,  2, "Five of Diamonds"},
				{6,  2, "Six of Diamonds"},
				{7,  2, "Seven of Diamonds"},
				{8,  2, "Eight of Diamonds"},
				{9,  2, "Nine of Diamonds"},
				{10, 2, "Ten of Diamonds"},
				{11, 2, "Jack of Diamonds"},
				{12, 2, "Queen of Diamonds"},
				{13, 2, "King of Diamonds"},

				{1,  3, "Ace of Spades"},
				{2,  3, "Two of Spades"},
				{3,  3, "Three of Spades"},
				{4,  3, "Four of Spades"},
				{5,  3, "Five of Spades"},
				{6,  3, "Six of Spades"},
				{7,  3, "Seven of Spades"},
				{8,  3, "Eight of Spades"},
				{9,  3, "Nine of Spades"},
				{10, 3, "Ten of Spades"},
				{11, 3, "Jack of Spades"},
				{12, 3, "Queen of Spades"},
				{13, 3, "King of Spades"},

				{1,  4, "Ace of Hearts"},
				{2,  4, "Two of Hearts"},
				{3,  4, "Three of Hearts"},
				{4,  4, "Four of Hearts"},
				{5,  4, "Five of Hearts"},
				{6,  4, "Six of Hearts"},
				{7,  4, "Seven of Hearts"},
				{8,  4, "Eight of Hearts"},
				{9,  4, "Nine of Hearts"},
				{10, 4, "Ten of Hearts"},
				{11, 4, "Jack of Hearts"},
				{12, 4, "Queen of Hearts"},
				{13, 4, "King of Hearts"},
			}
		}
	}
}