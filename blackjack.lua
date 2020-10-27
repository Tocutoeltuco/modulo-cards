local user, game, mem, deck

return {
	initialChecks = function(_user, _game, _mem, _deck)
		user, game, mem, deck = _user, _game, _mem, _deck
	end,

	command = function()
		local cmd, args, length = api.get_command(parameters)
	end,

	start = function()
	end
}