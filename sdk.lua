-- This is a general sdk lib designed for any use with Kyber Plugins!
-- Recommended to copy total your /commmon/ folder to be included in to use.

--#region -- Default Lua Library Extensions --

table.contains = function(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

table.sub = function(table, startIndex, endIndex)
    local subArray = {}

    startIndex = math.max(1, startIndex or 1)
    endIndex = math.min(#arr, endIndex or #arr)

    for i = startIndex, endIndex do
        table.insert(subArray, arr[i])
    end
    return subArray
end

string.split = function(str, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

base64 = {}
do
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    base64.encode = function(data)
        return ((data:gsub('.', function(x)
            local r, b = '', x:byte()
            for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
            return r;
        end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c = 0
            for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
            return b:sub(c + 1, c + 1)
        end) .. ({ '', '==', '=' })[#data % 3 + 1])
    end

    base64.decode = function(data)
        data = string.gsub(data, '[^' .. b .. '=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r, f = '', (b:find(x) - 1)
            for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c = 0
            for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
            return string.char(c)
        end))
    end
end

json = {}
do
    json._version = "0.1.2"

    -------------------------------------------------------------------------------
    -- Encode
    -------------------------------------------------------------------------------

    local encode

    local escape_char_map = {
        ["\\"] = "\\",
        ["\""] = "\"",
        ["\b"] = "b",
        ["\f"] = "f",
        ["\n"] = "n",
        ["\r"] = "r",
        ["\t"] = "t",
    }

    local escape_char_map_inv = { ["/"] = "/" }
    for k, v in pairs(escape_char_map) do
        escape_char_map_inv[v] = k
    end


    local function escape_char(c)
        return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
    end


    local function encode_nil(val)
        return "null"
    end


    local function encode_table(val, stack)
        local res = {}
        stack = stack or {}

        -- Circular reference?
        if stack[val] then error("circular reference") end

        stack[val] = true

        if rawget(val, 1) ~= nil or next(val) == nil then
            -- Treat as array -- check keys are valid and it is not sparse
            local n = 0
            for k in pairs(val) do
                if type(k) ~= "number" then
                    error("invalid table: mixed or invalid key types")
                end
                n = n + 1
            end
            if n ~= #val then
                error("invalid table: sparse array")
            end
            -- Encode
            for i, v in ipairs(val) do
                table.insert(res, encode(v, stack))
            end
            stack[val] = nil
            return "[" .. table.concat(res, ",") .. "]"
        else
            -- Treat as an object
            for k, v in pairs(val) do
                if type(k) ~= "string" then
                    error("invalid table: mixed or invalid key types")
                end
                table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
            end
            stack[val] = nil
            return "{" .. table.concat(res, ",") .. "}"
        end
    end


    local function encode_string(val)
        return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
    end


    local function encode_number(val)
        -- Check for NaN, -inf and inf
        if val ~= val or val <= -math.huge or val >= math.huge then
            error("unexpected number value '" .. tostring(val) .. "'")
        end
        return string.format("%.14g", val)
    end


    local type_func_map = {
        ["nil"] = encode_nil,
        ["table"] = encode_table,
        ["string"] = encode_string,
        ["number"] = encode_number,
        ["boolean"] = tostring,
    }


    encode = function(val, stack)
        local t = type(val)
        local f = type_func_map[t]
        if f then
            return f(val, stack)
        end
        error("unexpected type '" .. t .. "'")
    end


    function json.encode(val)
        return (encode(val))
    end

    -------------------------------------------------------------------------------
    -- Decode
    -------------------------------------------------------------------------------

    local parse

    local function create_set(...)
        local res = {}
        for i = 1, select("#", ...) do
            res[select(i, ...)] = true
        end
        return res
    end

    local space_chars  = create_set(" ", "\t", "\r", "\n")
    local delim_chars  = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
    local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
    local literals     = create_set("true", "false", "null")

    local literal_map  = {
        ["true"] = true,
        ["false"] = false,
        ["null"] = nil,
    }


    local function next_char(str, idx, set, negate)
        for i = idx, #str do
            if set[str:sub(i, i)] ~= negate then
                return i
            end
        end
        return #str + 1
    end


    local function decode_error(str, idx, msg)
        local line_count = 1
        local col_count = 1
        for i = 1, idx - 1 do
            col_count = col_count + 1
            if str:sub(i, i) == "\n" then
                line_count = line_count + 1
                col_count = 1
            end
        end
        error(string.format("%s at line %d col %d", msg, line_count, col_count))
    end


    local function codepoint_to_utf8(n)
        -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
        local f = math.floor
        if n <= 0x7f then
            return string.char(n)
        elseif n <= 0x7ff then
            return string.char(f(n / 64) + 192, n % 64 + 128)
        elseif n <= 0xffff then
            return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
        elseif n <= 0x10ffff then
            return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                f(n % 4096 / 64) + 128, n % 64 + 128)
        end
        error(string.format("invalid unicode codepoint '%x'", n))
    end


    local function parse_unicode_escape(s)
        local n1 = tonumber(s:sub(1, 4), 16)
        local n2 = tonumber(s:sub(7, 10), 16)
        -- Surrogate pair?
        if n2 then
            return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
        else
            return codepoint_to_utf8(n1)
        end
    end


    local function parse_string(str, i)
        local res = ""
        local j = i + 1
        local k = j

        while j <= #str do
            local x = str:byte(j)

            if x < 32 then
                decode_error(str, j, "control character in string")
            elseif x == 92 then -- `\`: Escape
                res = res .. str:sub(k, j - 1)
                j = j + 1
                local c = str:sub(j, j)
                if c == "u" then
                    local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                        or str:match("^%x%x%x%x", j + 1)
                        or decode_error(str, j - 1, "invalid unicode escape in string")
                    res = res .. parse_unicode_escape(hex)
                    j = j + #hex
                else
                    if not escape_chars[c] then
                        decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                    end
                    res = res .. escape_char_map_inv[c]
                end
                k = j + 1
            elseif x == 34 then -- `"`: End of string
                res = res .. str:sub(k, j - 1)
                return res, j + 1
            end

            j = j + 1
        end

        decode_error(str, i, "expected closing quote for string")
    end


    local function parse_number(str, i)
        local x = next_char(str, i, delim_chars)
        local s = str:sub(i, x - 1)
        local n = tonumber(s)
        if not n then
            decode_error(str, i, "invalid number '" .. s .. "'")
        end
        return n, x
    end


    local function parse_literal(str, i)
        local x = next_char(str, i, delim_chars)
        local word = str:sub(i, x - 1)
        if not literals[word] then
            decode_error(str, i, "invalid literal '" .. word .. "'")
        end
        return literal_map[word], x
    end


    local function parse_array(str, i)
        local res = {}
        local n = 1
        i = i + 1
        while 1 do
            local x
            i = next_char(str, i, space_chars, true)
            -- Empty / end of array?
            if str:sub(i, i) == "]" then
                i = i + 1
                break
            end
            -- Read token
            x, i = parse(str, i)
            res[n] = x
            n = n + 1
            -- Next token
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "]" then break end
            if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
        end
        return res, i
    end


    local function parse_object(str, i)
        local res = {}
        i = i + 1
        while 1 do
            local key, val
            i = next_char(str, i, space_chars, true)
            -- Empty / end of object?
            if str:sub(i, i) == "}" then
                i = i + 1
                break
            end
            -- Read key
            if str:sub(i, i) ~= '"' then
                decode_error(str, i, "expected string for key")
            end
            key, i = parse(str, i)
            -- Read ':' delimiter
            i = next_char(str, i, space_chars, true)
            if str:sub(i, i) ~= ":" then
                decode_error(str, i, "expected ':' after key")
            end
            i = next_char(str, i + 1, space_chars, true)
            -- Read value
            val, i = parse(str, i)
            -- Set
            res[key] = val
            -- Next token
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "}" then break end
            if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
        end
        return res, i
    end


    local char_func_map = {
        ['"'] = parse_string,
        ["0"] = parse_number,
        ["1"] = parse_number,
        ["2"] = parse_number,
        ["3"] = parse_number,
        ["4"] = parse_number,
        ["5"] = parse_number,
        ["6"] = parse_number,
        ["7"] = parse_number,
        ["8"] = parse_number,
        ["9"] = parse_number,
        ["-"] = parse_number,
        ["t"] = parse_literal,
        ["f"] = parse_literal,
        ["n"] = parse_literal,
        ["["] = parse_array,
        ["{"] = parse_object,
    }


    parse = function(str, idx)
        local chr = str:sub(idx, idx)
        local f = char_func_map[chr]
        if f then
            return f(str, idx)
        end
        decode_error(str, idx, "unexpected character '" .. chr .. "'")
    end


    function json.decode(str)
        if type(str) ~= "string" then
            error("expected argument of type string, got " .. type(str))
        end
        local res, idx = parse(str, next_char(str, 1, space_chars, true))
        idx = next_char(str, idx, space_chars, true)
        if idx <= #str then
            decode_error(str, idx, "trailing garbage")
        end
        return res
    end
end


--#endregion

--#region -- General Utilities --

--#region Timer

TimerService = {
    timers = {},

    update = function(self, deltaSecs)
        for i = #self.timers, 1, -1 do
            local timer = self.timers[i]
            timer.elapsed = timer.elapsed + deltaSecs
            if timer.elapsed >= timer.interval then
                timer.elapsed = timer.elapsed - timer.interval
                timer.callback(timer)
                if not timer.running then
                    table.remove(self.timers, i)
                end
            end
        end
    end,
}

EventManager.Listen("Server:UpdatePre", TimerService.update, TimerService)

Timer = {}
Timer.__index = Timer

function Timer:new(interval, callback)
    local obj = setmetatable({}, self)
    obj.interval = interval
    obj.callback = callback
    obj.elapsed = 0
    obj.running = true
    table.insert(TimerService.timers, obj)
    return obj
end

function Timer:cancel()
    self.running = false
end

function SetTimeout(callback, delay)
    Timer:new(delay, function(timer)
        callback()
        timer:cancel()
    end)
end

--#endregion

--#endregion

--#region -- Frostbite Helper Commands --

hashString = function(s)
    local hash = 5381

    for i = 1, #s do
        local b = string.byte(s, i)
        hash = ((hash * 33) ~ b) & 0xFFFFFFFF
    end

    if hash >= 0x80000000 then
        hash = hash - 0x100000000
    end

    return hash
end

hashStringEx = function(s)
    if type(s) == "number" then
        return s
    end
    if s:sub(1, 2):lower() == "0x" then
        return tonumber(s, 16)
    end

    return hashString(s)
end

-- CODE BELOW IS NON FUNCTIONAL! WIP!

BlueprintUtils = {}

BlueprintUtils.createEventConnection = function(bp, dcA, portA, dcB, portB, targetType)
    local connection = EventConnection()
    connection.source = dcA;
    connection.target = dcB;
    connection.sourceEvent = hashStringEx(portA);
    connection.targetEvent = hashStringEx(portB);
    connection.fargetType = targetType;
    -- TODO: add connection to linkconnections array
end

BlueprintUtils.createPropertyConnection = function(bp, dcA, portA, dcB, portB, flags)
    local connection = PropertyConnection()
    connection.source = dcA;
    connection.target = dcB;
    connection.sourceEvent = hashStringEx(portA);
    connection.targetEvent = hashStringEx(portB);
    connection.flags = flags;
    -- TODO: add connection to linkconnections array
end

BlueprintUtils.createLinkConnection = function(bp, dcA, portA, dcB, portB)
    local connection = LinkConnection()
    connection.source = dcA;
    connection.target = dcB;
    connection.sourceEvent = hashStringEx(portA);
    connection.targetEvent = hashStringEx(portB);
    -- TODO: add connection to linkconnections array
end

--#endregion

--#region -- Frostbite Type Extensions --

local fbTypeOverrideRegistrations = {}

--#region Vec3

table.insert(fbTypeOverrideRegistrations, function()
    local globalVec = Vec3
    Vec3 = function(...)
        local args = { ... }

        local obj = globalVec()
        if #args == 1 then
            obj.x = args[1]
            obj.y = args[1]
            obj.z = args[1]
        elseif #args == 3 then
            obj.x = args[1]
            obj.y = args[2]
            obj.z = args[3]
        end

        return obj
    end

    local vec3Meta = getmetatable(globalVec())

    vec3Meta.__add = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x + other, self.y + other, self.z + other)
        elseif type(other) == "userdata" then
            return Vec3(self.x + other.x, self.y + other.y, self.z + other.z)
        end

        error("Invalid type for Vec3 addition " .. type(other))
    end

    vec3Meta.__sub = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x - other, self.y - other, self.z - other)
        elseif type(other) == "userdata" then
            return Vec3(self.x - other.x, self.y - other.y, self.z - other.z)
        end

        error("Invalid type for Vec3 subtraction " .. type(other))
    end

    vec3Meta.__mul = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x * other, self.y * other, self.z * other)
        elseif type(other) == "userdata" then
            return Vec3(self.x * other.x, self.y * other.y, self.z * other.z)
        end

        error("Invalid type for Vec3 multiplication " .. type(other))
    end

    vec3Meta.__div = function(self, other)
        if type(other) == "number" then
            return Vec3(self.x / other, self.y / other, self.z / other)
        elseif type(other) == "userdata" then
            return Vec3(self.x / other.x, self.y / other.y, self.z / other.z)
        end

        error("Invalid type for Vec3 division " .. type(other))
    end

    vec3Meta.__unm = function(self)
        return Vec3(-self.x, -self.y, -self.z)
    end

    vec3Meta.__eq = function(self, other)
        return self.x == other.x and self.y == other.y and self.z == other.z
    end
end)

--#endregion

for _, func in pairs(fbTypeOverrideRegistrations) do
    func()
end

--#endregion
