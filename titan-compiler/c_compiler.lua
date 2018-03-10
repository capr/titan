local coder = require "titan-compiler.coder"
local util = require "titan-compiler.util"

local c_compiler = {}

c_compiler.LUA_SOURCE_PATH = "lua/src/"
c_compiler.CFLAGS = "--std=c99 -O2 -Wall -fPIC"
c_compiler.CC = "cc"

local function shell(cmd)
    local p = io.popen(cmd)
    out = p:read("*a")
    p:close()
    return out
end

local UNAME = shell("uname -s")

local SHARED
if UNAME == "Darwin" then
    SHARED = "-shared -undefined dynamic_lookup"
else
    SHARED = "-shared"
end

function c_compiler.compile(filename, input)
    local code, errors = coder.generate(filename, input)
    if not code then return false, errors end

    local basename = assert(string.match(filename, "^(.*)%.titan$"))
    local c_filename = basename .. ".c"
    local so_filename = basename .. ".so"

    local ok, err = util.set_file_contents(c_filename, code)
    if not ok then return nil, {err} end

    local args = {c_compiler.CC, c_compiler.CFLAGS, SHARED, c_filename,
                  "-I", c_compiler.LUA_SOURCE_PATH, "-o", so_filename}
    return os.execute(table.concat(args, " "))
end

return c_compiler