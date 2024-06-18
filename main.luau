local executor = require("avm/vm/executor")
local Memory = require("avm/memory")
local Stack = require("avm/stack")

local ProgramMemory = Memory.create(1024)
local Program = Stack.create(ProgramMemory, 0, #ProgramMemory)

-- add r1, r2
Program:push_u8(0x21)
Program:push_u8(0xD0)

-- mov r1, <>
Program:push_i32(2)
Program:push_u8(0x1)
Program:push_u8(0xC2)

-- mov r2, <>
Program:push_i32(1)
Program:push_u8(0x2)
Program:push_u8(0xC2)

local exec = executor.create()
exec.run(Program)