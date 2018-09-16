
-- Created for justtest server. Uses another mod (jtdb) instead of serialized file

ipnames = {}
ipnames.current_ip_tmp = {}
ipnames.name_per_ip_limit = tonumber(minetest.setting_get("max_names_per_ip")) or 5

ipnames.ip = jtdb:new(minetest.get_worldpath() .. "/names_per_ip_i")    -- find ip's by name
ipnames.ip.escape_value = true
-- ipnames.ip.use_cache = true
ipnames.ip.empty_value = {}
ipnames.ip.escape_v = function(value, key)
    assert(type(value) == "table",
        "Conversion from table to string will happen automatically!")
    local newvalue = minetest.serialize(value)
    return newvalue
end
ipnames.ip.unescape_v = function(value, key)
    -- minetest.log("action", "Hey name@ips? "..value.."@"..key);
    local newvalue = minetest.deserialize(value)
    if type(newvalue) ~= "table" then
        newvalue = {}
    end
    return newvalue
end

ipnames.names = jtdb:new(minetest.get_worldpath() .. "/names_per_ip_n") -- find names by ip
ipnames.names.escape_value = true
-- ipnames.names.use_cache = true
ipnames.names.empty_value = {}
ipnames.names.escape_v = function(value, key)
    assert(type(value) == "table",
        "Conversion from table to string will happen automatically!")
    local newvalue = minetest.serialize(value)
    return newvalue
end
ipnames.names.unescape_v = function(value, key)
    -- minetest.log("action", "Player "..value.."@"..key.." trying to join?");
    local newvalue = minetest.deserialize(value)
    if type(newvalue) ~= "table" then
        newvalue = {}
    end
    return newvalue
end

-- Get IP if player tries to join, cancel if there are too much names per IP:
minetest.register_on_prejoinplayer(function(name, ip)
    local names = ""
    local count = 0
    ipnames.current_ip_tmp[name] = ip
    -- Only stop new AND unknown to this mod accounts:
    if ipnames.ip.id[name] == nil and ipnames.names.id[ip] ~= nil then
        local names_list = ipnames.names:read(ip)
        local names = ""
        local count = 0
        for k, v in pairs(names_list) do
			names = names .. k .. ", "
            count = count + 1
		end
        -- local count = #names_list
        -- minetest.chat_send_all("Uh?" .. count);
        if count >= ipnames.name_per_ip_limit then
            -- minetest.log("action", "Player "..name.."@"..ip.." exceeded the limit of accounts.");
            return ("\nYou exceeded the limit of accounts (" .. ipnames.name_per_ip_limit ..
            ").\nYou already have the following accounts:\n" .. names)
        end
    end
end)

minetest.register_on_newplayer(function(player)
	local name = player:get_player_name()
    local current_ip = ipnames.current_ip_tmp[name]
    ipnames.current_ip_tmp[name] = nil
    assert(type(current_ip) == "string", "Player "..name.." has no IP???")
    local ip_list = ipnames.ip:read(name)
    ip_list[current_ip] = 1
    ipnames.ip:write(name, ip_list)
    local names_list = ipnames.names:read(current_ip)
    names_list[name] = 1
    ipnames.names:write(current_ip, names_list)
end)

minetest.register_on_shutdown(function()
    ipnames.ip:idfile_write()
    ipnames.names:idfile_write()
    minetest.log("action", "Mod names_per_ip did small maintenance on it's files names_per_ip-ip.jtid names_per_ip-names.jtid")
end)
