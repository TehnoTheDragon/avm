local memory = require("avm/memory")
local storage = memory.create(256)
local vstorage = memory.create_virtual(storage)

local ptr = vstorage:allocate(1)
ptr:write_i8(0, 0x41)
local ptr2 = vstorage:allocate(1)
ptr2:write_i8(0, 0x42)
print(storage)