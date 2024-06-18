--!native
local instset = require("instset")
local memory = require("../memory")
local stack = require("../stack")

local BYTE = 0xFF
local SHORT = 0xFFFF
local LONG = 0xFFFFFFFF
local MAX_FLOAT_32 = 0x7FFFFFFF
local MAX_FLOAT_64 = 0x7FFFFFFFFFFFFFFF

local function _is_floating_point(value: number): boolean
    return value ~= math.floor(value)
end

local function _instruction_type(inst: number): {}?
    if instset.inst2name(inst) ~= nil then
        local instruction = instset.inst2inst(inst)
        local result = {}
        if instruction.count > 0 then
            for i = 1, instruction.count do
                table.insert(result, `push_{instruction.element_syms[i]}{instruction.element_sizes[i]}`)
            end
        end
        return result
    end
    --error(`({inst}) is not an instruction`)
    return nil
end

local function _write_program(stack: stack.Stack, code: {number})
    print(table.concat(code, ", "))
    local push_list = {}
    local function push(t: string, value: number)
        table.insert(push_list, {t, value})
    end

    local i = 1
    while i <= #code do
        local inst = code[i]
        push("push_u8", inst)
        i += 1
        local instruction = _instruction_type(inst)
        if instruction ~= nil then
            for _, v in instruction do
                push(v, code[i])
                i += 1
            end
        end
    end

    for i = #push_list, 1, -1 do
        stack[push_list[i][1]](stack, push_list[i][2])
    end
end

return {
    write_program = _write_program,
}