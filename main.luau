local executor = require("avm/vm/executor")
local Codegen = require("avm/vm/codegen")
local Memory = require("avm/memory")
local Stack = require("avm/stack")

local ProgramMemory = Memory.create(16)
local Program = Stack.create(ProgramMemory, 0, #ProgramMemory)

Codegen.write_program(Program, {
    0xC2, 0x0, 1,   -- mov r1, 1
    0xC2, 0x1, 5,   -- mov r2, 1
    0xD0, 0x10,     -- add r2, r1
})

local exec = executor.create()
exec.run(Program)