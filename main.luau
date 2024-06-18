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
print(Program)
print()

-- local ProgramMemory = Memory.create(16)
-- local Program = Stack.create(ProgramMemory, 0, #ProgramMemory)

-- add r1, r2
-- Program:push_u8(0x10)
-- Program:push_u8(0xD0)

-- mov r1, <>
-- Program:push_u32(2)
-- Program:push_u8(0x1)
-- Program:push_u8(0xC2)

-- mov r2, <>
-- Program:push_u32(1)
-- Program:push_u8(0x1)
-- Program:push_u8(0xC2)

-- print(Program)

local exec = executor.create()
exec.run(Program)