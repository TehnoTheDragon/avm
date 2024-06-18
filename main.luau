local executor = require("avm/vm/executor")
local Memory = require("avm/memory")
local Stack = require("avm/stack")

local ProgramMemory = Memory.create(1024)
local Program = Stack.create(ProgramMemory, 0, #ProgramMemory)
Program:push_u8(0x1)
Program:push_u8(0xB9)
Program:push_f64(10.3)
Program:push_u8(0xA4)

local exec = executor.create()
exec.run(Program)