local function deep_clone(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deep_clone(value) -- Recursive call
		else
			copy[key] = value
		end
	end
	return copy
end

table.deep_clone = deep_clone

return {
	deep_clone = deep_clone,
}
