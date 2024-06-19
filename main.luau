-- local executor = require("avm/vm/executor")
-- local Codegen = require("avm/vm/codegen")
-- local Memory = require("avm/memory")
-- local Stack = require("avm/stack")

-- local ProgramMemory = Memory.create(32)
-- local Program = Stack.create(ProgramMemory, 0, #ProgramMemory)

-- Codegen.write_program(Program, {
--     0xC2, 0x0, 1,   -- mov r1, 1
--     0xC2, 0x1, 5,   -- mov r2, 1
--     0xD0, 0x10,     -- add r2, r1
-- })

-- local exec = executor.create(1024, 32)
-- exec.run(Program)
local lexer = require("avm/vm/lexer")
local parser = require("avm/vm/parser")

local source = [[
movb r1, 4.5
movb r2, 5
add r1, r2
]]

local tokens = lexer.tokenize(source)
local ast = parser.parse(tokens)