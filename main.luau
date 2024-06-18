local Memory = require("avm/memory")
local Stack = require("avm/stack")
local ram = Memory.create(1024)
local stack = Stack.create(ram, 0, 64)


stack:push_i8(40)
stack:push_i8(40)
stack:push_i8(40)
print(stack)
