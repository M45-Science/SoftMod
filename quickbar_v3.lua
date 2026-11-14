-- M45 Quickbar Exchange V3. The catalog size and order are part of the wire format.
-- slots[1..100] = {name = "transport-belt", quality = "normal"} or nil.
local M = {}
local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
local floor = math.floor
local catalog = require("quickbar_v3_items")
local function field(value, width)
    local bits = {}
    for i = width, 1, -1 do
        bits[i] = value % 2 == 0 and "0" or "1"
        value = floor(value / 2)
    end
    assert(value == 0)
    return table.concat(bits)
end

local function reader(bits)
    local cursor = 1
    return function(width)
        assert(cursor + width - 1 <= #bits, "truncated field")
        local value = 0
        for i = cursor, cursor + width - 1 do
            value = value * 2 + bits:byte(i) - 48
        end
        cursor = cursor + width
        return value
    end
end

local function count(n)
    if n < 16 then return field(n, 5) end
    return field(16 + n % 16, 5) .. count(floor(n / 16))
end

local function read_count(get)
    local n = 0
    for shift = 0, 12, 4 do
        local digit = get(5)
        n = n + digit % 16 * 2^shift
        if digit < 16 then return n end
    end
    error("oversize count")
end

local function repeated(n, value)
    local result = {}
    for i = 1, n do result[i] = value end
    return result
end

-- Encoder and decoder partition the digits into identical exact-integer groups.
local function radix(bases, digits, get)
    local output = {}
    local start = 1
    while start <= #bases do
        local size, stop = 1, start
        while stop <= #bases and size <= floor(2^48 / bases[stop]) do
            size = size * bases[stop]
            stop = stop + 1
        end
        local width = 0
        while 2^width < size do width = width + 1 end
        if get then
            local value = get(width)
            assert(value < size, "unused item or quality code")
            for i = stop - 1, start, -1 do
                output[i] = value % bases[i]
                value = floor(value / bases[i])
            end
        else
            local value = 0
            for i = start, stop - 1 do value = value * bases[i] + digits[i] end
            output[#output + 1] = field(value, width)
        end
        start = stop
    end
    if get then return output end
    return table.concat(output)
end

local function choice(candidates)
    local best
    for mode = 0, 3 do
        local bits = candidates[mode]
        if bits and (not best or #bits + 2 < #best) then best = field(mode, 2) .. bits end
    end
    return assert(best)
end

local function positions(pos)
    local options, mask = {}, repeated(100, "0")
    local prefix, stride = true, #pos >= 2
    local step = stride and pos[2] - pos[1]
    for i, p in ipairs(pos) do
        mask[p + 1] = "1"
        prefix = prefix and p == i - 1
        stride = stride and p == pos[1] + (i - 1) * step
    end
    if prefix then options[0] = "" end
    if stride then options[1] = field(pos[1], 7) .. count(step - 1) end
    options[2] = table.concat(mask)
    for k = 0, 4 do
        local parts, last = {field(k, 3)}, -1
        for _, p in ipairs(pos) do
            local gap = p - last - 1
            parts[#parts + 1] = ("0"):rep(floor(gap / 2^k)) .. "1" .. field(gap % 2^k, k)
            last = p
        end
        local bits = table.concat(parts)
        if not options[3] or #bits < #options[3] then options[3] = bits end
    end
    return choice(options)
end

local function read_positions(get, n, limit)
    local mode, pos = get(2), {}
    if mode == 0 or mode == 1 then
        local first, step = 0, 1
        if mode == 1 then first = get(7); step = read_count(get) + 1 end
        for i = 1, n do pos[i] = first + (i - 1) * step end
    elseif mode == 2 then
        for i = 0, 99 do
            if get(1) == 1 then pos[#pos + 1] = i end
        end
    else
        local k, last = get(3), -1
        assert(k <= 4)
        for i = 1, n do
            local gap = 0
            while get(1) == 0 do
                gap = gap + 2^k
                assert(gap < limit)
            end
            last = last + 1 + gap + get(k)
            pos[i] = last
        end
    end
    assert(#pos == n and (n == 0 or pos[n] < limit), "invalid positions")
    return pos
end

local function index_of(list, value)
    for i, v in ipairs(list) do if v == value then return i end end
end

local function remember(list, value)
    local i = index_of(list, value)
    if i then return i - 1 end
    list[#list + 1] = value
    return #list - 1
end

local function range(n)
    local list = {}
    for i = 1, n do list[i] = i - 1 end
    return list
end

local function sequence(ids, size)
    local options = {[0] = radix(repeated(#ids, size), ids)}
    local unique, refs = {}, {}
    for i, id in ipairs(ids) do refs[i] = remember(unique, id) end
    if #unique == #ids then
        local left, bases, ranks = range(size), {}, {}
        for i, id in ipairs(ids) do
            local rank = index_of(left, id)
            bases[i], ranks[i] = #left, rank - 1
            table.remove(left, rank)
        end
        options[1] = radix(bases, ranks)
    else
        options[2] = count(#unique - 1) .. radix(repeated(#unique, size), unique)
                     .. radix(repeated(#ids, #unique), refs)
    end
    return choice(options)
end

local function read_sequence(get, n, size)
    local mode = get(2)
    if mode == 0 then return radix(repeated(n, size), nil, get) end
    if mode == 1 then
        assert(n <= size)
        local bases, left = {}, range(size)
        for i = 1, n do bases[i] = size - i + 1 end
        local ids = radix(bases, nil, get)
        for i, rank in ipairs(ids) do ids[i] = table.remove(left, rank + 1) end
        return ids
    end
    assert(mode == 2)
    local k = read_count(get) + 1
    assert(k <= n and k <= size)
    local palette = radix(repeated(k, size), nil, get)
    local ids = radix(repeated(n, k), nil, get)
    for i, id in ipairs(ids) do ids[i] = palette[id + 1] end
    return ids
end

local function quality_bits(q, size)
    local pos, exceptions, uniform = {}, {}, true
    for i, value in ipairs(q) do
        uniform = uniform and value == q[1]
        if value ~= 0 then
            pos[#pos + 1] = i - 1
            exceptions[#exceptions + 1] = value - 1
        end
    end
    if #pos == 0 then return field(0, 2) end
    local options = {[2] = radix(repeated(#q, size), q)}
    if uniform then options[1] = radix({size}, {q[1]}) end
    options[3] = count(#pos) .. positions(pos) .. radix(repeated(#pos, size - 1), exceptions)
    return choice(options)
end

local function read_qualities(get, n, size)
    local mode = get(2)
    if mode == 0 then return repeated(n, 0) end
    if mode == 1 then return repeated(n, radix({size}, nil, get)[1]) end
    if mode == 2 then return radix(repeated(n, size), nil, get) end
    local k = read_count(get)
    assert(k <= n)
    local pos = read_positions(get, k, n)
    local exceptions = radix(repeated(k, size - 1), nil, get)
    local q = repeated(n, 0)
    for i, p in ipairs(pos) do q[p + 1] = exceptions[i] + 1 end
    return q
end

local function qualities()
    return {"normal", "uncommon", "rare", "epic", "legendary"}
end

local function extensions(list, first)
    local parts = {count(#list - first + 1)}
    for i = first, #list do
        local name = list[i]
        if #name > 10240 then return nil end
        parts[#parts + 1] = count(#name)
        for j = 1, #name do parts[#parts + 1] = field(name:byte(j), 8) end
    end
    return table.concat(parts)
end

function M.encode(slots)
    local pos, special = {}, false
    for i = 1, 100 do
        if slots[i] then
            pos[#pos + 1] = i - 1
            special = special or slots[i].quality == "quality-unknown"
        end
    end
    local bits = field(#pos, 7)
    if #pos > 0 then
        local items, qs = {table.unpack(catalog)}, qualities()
        if special then qs[6] = "quality-unknown" end
        local known = #qs
        local ids, q = {}, {}
        for i, p in ipairs(pos) do
            ids[i] = remember(items, slots[p + 1].name)
            q[i] = remember(qs, slots[p + 1].quality or "normal")
        end
        bits = bits .. positions(pos)
        if special or #items > #catalog or #qs > known then
            local item_names = extensions(items, #catalog + 1)
            local quality_names = extensions(qs, known + 1)
            if not item_names or not quality_names then return nil end
            bits = bits .. "1" .. (special and "1" or "0") .. item_names .. quality_names
        else
            bits = bits .. "0"
        end
        bits = bits .. sequence(ids, #items) .. quality_bits(q, #qs)
    end
    if #bits > (10240 - 3) * 6 then return nil end
    bits = bits .. ("0"):rep(-#bits % 6)
    local get, chars = reader(bits), {"Q3:"}
    for i = 1, #bits, 6 do
        local index = get(6) + 1
        chars[#chars + 1] = alphabet:sub(index, index)
    end
    return table.concat(chars)
end

local function read_extensions(get, list, slots)
    local n = read_count(get)
    assert(n <= slots)
    for i = 1, n do
        local len, chars = read_count(get), {}
        assert(len > 0 and len <= 10240)
        for j = 1, len do chars[j] = string.char(get(8)) end
        local name = table.concat(chars)
        assert(not index_of(list, name), "duplicate extension")
        list[#list + 1] = name
    end
end

local function decode(export)
    assert(#export <= 10240 and export:sub(1, 3) == "Q3:")
    local chunks = {}
    for i = 4, #export do
        local index = alphabet:find(export:sub(i, i), 1, true)
        assert(index, "invalid alphabet")
        chunks[#chunks + 1] = field(index - 1, 6)
    end
    local bits = table.concat(chunks)
    local left, read = #bits, reader(bits)
    local function get(width)
        left = left - width
        return read(width)
    end
    local slots, n = {}, get(7)
    assert(n <= 100)
    if n > 0 then
        local pos = read_positions(get, n, 100)
        local items, qs = {table.unpack(catalog)}, qualities()
        if get(1) == 1 then
            if get(1) == 1 then qs[6] = "quality-unknown" end
            read_extensions(get, items, n)
            read_extensions(get, qs, n)
        end
        local ids = read_sequence(get, n, #items)
        local q = read_qualities(get, n, #qs)
        for i, p in ipairs(pos) do
            slots[p + 1] = {name = items[ids[i] + 1], quality = qs[q[i] + 1]}
        end
    end
    assert(left < 6 and get(left) == 0, "invalid padding")
    return slots
end

function M.decode(export)
    local ok, slots = pcall(decode, export)
    if ok then return slots end
    return nil, "Invalid Q3 quickbar export."
end

return M
