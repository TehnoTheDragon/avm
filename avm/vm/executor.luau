local memory = require("../memory")
local stack = require("../stack")
local instset = require("instset")
local regset = require("regset")

local BYTE = 8
local SHORT = 16
local LONG = 32

local pow = math.pow
local extract = bit32.extract
local band = bit32.band

local function _integer_to_bits(value: number, bits: number, signed: boolean): number
    if not signed then
        return bit32.extract(value, 0, bits)
    end
    return band(value, pow(2, bits) - 1)
end

local function _extract_sign_reg(operand: number): (number, number)
    return extract(operand, 0, 1), extract(operand, 1, 7)
end

local function _extract_reg_reg(operand: number): (number, number)
    return extract(operand, 0, 4), extract(operand, 4, 4)
end

local function _execute(code: stack.Stack, stack: stack.Stack, registers: regset.REGSET)
    while not code:empty() do
        local inst = code:pop_u8()
        print(`instruction: {instset.inst2name(inst)}`)
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
        elseif inst == instset.INST.PUSHRS.id then
            stack:push_u16(registers:get(code:pop_u8()))
        elseif inst == instset.INST.PUSHRL.id then
            stack:push_u32(registers:get(code:pop_u8()))
        elseif inst == instset.INST.PUSHRF.id then
            stack:push_f32(registers:get(code:pop_u8()))
        elseif inst == instset.INST.PUSHRDF.id then
            stack:push_f64(registers:get(code:pop_u8()))
        -- Pop --
        elseif inst == instset.INST.POPB.id then
            local sign, reg = _extract_sign_reg(code:pop_u8())
            local value = _integer_to_bits(stack:pop_u8(), BYTE, sign == 1)
            registers:set(reg, value)
        elseif inst == instset.INST.POPS.id then
            local sign, reg = _extract_sign_reg(code:pop_u8())
            local value = _integer_to_bits(stack:pop_u16(), SHORT, sign == 1)
            registers:set(reg, value)
        elseif inst == instset.INST.POPL.id then
            local sign, reg = _extract_sign_reg(code:pop_u8())
            local value = _integer_to_bits(stack:pop_u32(), LONG, sign == 1)
            registers:set(reg, value)
        elseif inst == instset.INST.POPF.id then
            local reg = code:pop_u8()
            local value = stack:pop_f32()
            registers:set(reg, value)
        elseif inst == instset.INST.POPDF.id then
            local reg = code:pop_u8()
            local value = stack:pop_f64()
            registers:set(reg, value)
        -- ::: Immediate Register ::: --
        elseif inst == instset.INST.MOVB.id then
            local reg = code:pop_u8()
            registers:set(reg, code:pop_u8())
        elseif inst == instset.INST.MOVS.id then
            local reg = code:pop_u8()
            registers:set(reg, code:pop_u16())
        elseif inst == instset.INST.MOVL.id then
            local reg = code:pop_u8()
            registers:set(reg, code:pop_u32())
        elseif inst == instset.INST.MOVF.id then
            local reg = code:pop_u8()
            registers:set(reg, code:pop_f32())
        elseif inst == instset.INST.MOVDF.id then
            local reg = code:pop_u8()
            registers:set(reg, code:pop_f64())
        -- ::: Math Operations ::: --
        elseif inst == instset.INST.ADD.id then
            local regA, regB = _extract_reg_reg(code:pop_u8())
            registers:add(regA, regB)
        end
        print(registers)
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
        print(registers)
    end

    return self
end

return {
    create = _create_executor
}