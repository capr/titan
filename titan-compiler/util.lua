local util = {}

function util.get_file_contents(filename)
    local f, err = io.open(filename, "r")
    if not f then
        return false, err
    end
    local s = f:read("a")
    f:close()
    if not s then
        return false, "unable to open file " .. filename
    else
        return s
    end
end

function util.set_file_contents(filename, contents)
    local f, err = io.open(filename, "w")
    if not f then
        return false, err
    end
    f:write(contents)
    f:close()
    return true
end


-- Barebones string-based template function for generating C/Lua code. Replaces
-- $VAR and ${VAR} placeholders in the `code` template by the corresponding
-- strings in the `substs` table.
function util.render(code, substs, ignore_missing)
    return (string.gsub(code, "%$({?)([A-Za-z_][A-Za-z_0-9]*)(}?)", function(a, k, b)
        if a == "{" and b == "" then
            error("unmatched ${ in template")
        end
        local v = substs[k]
        if not v then
            if ignore_missing then return nil end
            error("Internal compiler error: missing template variable " .. k .. "\n" .. code)
        end
        if a == "" and b == "}" then
            v = v .. b
        end
        return util.render(v, substs, ignore_missing)
    end))
end

function util.make_visitor(functions)
    return function(node, ...)
        assert(type(node) == "table")
        assert(node._tag)
        local f = assert(functions[node._tag])
        return f(node, ...)
    end
end

function util.to_set(array)
    local set = {}
    for _, v in ipairs(array) do
        set[v] = true
    end
    return set
end

function util.split_string(str, delim)
    local result = {}
    local n = 1
    local last_pos = 1
    for part, pos in string.gmatch(str, "(.-)" .. delim .. "()") do
        result[n] = part
        n = n + 1
        last_pos = pos
    end
    result[n] = string.sub(str, last_pos)
    return result
end

--
-- Functional
--

function util.curry(f, a)
    return function(...)
        return f(a, ...)
    end
end

function util.any(f, l)
    for _, elem in ipairs(l) do
        if f(elem) then
            return true
        end
    end
    return false
end

return util
