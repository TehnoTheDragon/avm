local memory = require("../memory")
local stack = require("../stack")
local instset = require("instset")
local regset = require("regset")

local function _execute(code: stack.Stack, stack: stack.Stack, registers: regset.REGSET)
    while not code:empty() do
        local inst = code:pop_u8()
        if instset.INST.HLT.id == inst then
            break
        -- ::: Stack ::: --
        -- Push Constants --
        elseif inst == instset.INST.PUSHCB.id then
            stack:push_u8(code:pop_u8())
        elseif inst == instset.INST.PUSHCS.id then
            stack:push_u16(code:pop_u16())
        elseif inst == instset.INST.PUSHCL.id then
            stack:push_u32(code:pop_u32())
        elseif inst == instset.INST.PUSHCF.id then
            stack:push_f32(code:pop_f32())
        elseif inst == instset.INST.PUSHCDF.id then
            stack:push_f64(code:pop_f64())
        -- Push Registers --
        elseif inst == instset.INST.PUSHRB.id then
            stack:push_u8(registers:get(code:pop_u8()))
        end
    end
end

local function _create_executor()
    local memory = memory.create(1024)
    local stack = stack.create(memory, 0, 64)

    local registers = regset.create(4)

    local self = {}

    function self.run(code: stack.Stack)
        _execute(code, stack, registers)
        print(stack)
    end

    return self
end

return {
    create = _create_executor
}