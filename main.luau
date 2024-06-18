local Memory = require("avm/memory")
local Stack = require("avm/stack")
local ram = Memory.create(1024)
local stack = Stack.create(ram, 0, 64)

local INST = table.freeze({
    PUSH_I8 = 0xA0,     -- push <i8>
    POP_I8 = 0xA1,      -- pop <register>
    ADD_I8 = 0xA2,      -- add <register>, <register>
    SUB_I8 = 0xA3,      -- sub <register>, <register>
    MOV_I8 = 0xA4,      -- mov <register>, <i8>
    PUSHR_I8 = 0xA5,    -- pushr <i8>

    HLT = 0xFF,         -- halt
})

local function inst_to_name(inst: number): string
    for k, v in pairs(INST) do
        if v == inst then
            return k
        end
    end
    error(`unknown instruction: {inst}`)
end

local function execute(program: Stack.Stack)
    local mem = Stack.create(Memory.create(32), 0, 32)
    local reg = { 0, 0, 0, 0 }

    local function rreg(i)
        assert(i >= 0 and i < 4, `register must be between 0 and 3, got {i}`)
        return reg[i]
    end

    local function wreg(i, x)
        assert(i >= 0 and i < 4, `register must be between 0 and 3, got {i}`)
        reg[i] = x
    end

    while not program:empty() do
        local inst = program:pop_u8()
        print(`instruction: {inst_to_name(inst)}`)
        if inst == INST.PUSH_I8 then
            mem:push_i8(program:pop_i8())
        elseif inst == INST.POP_I8 then
            wreg(program:pop_u8(), mem:pop_i8())
        elseif inst == INST.ADD_I8 then
            local acc = program:pop_u8()
            local r1 = rreg(acc)
            local r2 = rreg(program:pop_u8())
            wreg(acc, r1 + r2)
        elseif inst == INST.SUB_I8 then
            local acc = program:pop_u8()
            local r1 = rreg(acc)
            local r2 = rreg(program:pop_u8())
            wreg(acc, r1 - r2)
        elseif inst == INST.MOV_I8 then
            local v = program:pop_u8()
            local r = program:pop_u8()
            wreg(r, v)
        elseif inst == INST.PUSHR_I8 then
            mem:push_i8(rreg(program:pop_u8()))
        elseif inst == INST.HLT then
            break
        end
    end
    return mem
end

stack:push_u8(INST.HLT)
stack:push_u8(1)
stack:push_u8(INST.PUSHR_I8)
stack:push_u8(2)
stack:push_u8(1)
stack:push_u8(INST.ADD_I8)
stack:push_u8(2)
stack:push_u8(1)
stack:push_u8(INST.MOV_I8)
stack:push_u8(1)
stack:push_u8(3)
stack:push_u8(INST.MOV_I8)

print(execute(stack))