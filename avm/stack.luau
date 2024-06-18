local buffer = require("buffer")
local memory = require("memory")

export type Pop<T> = {
    pop_u8: (T) -> number,
    pop_i8: (T) -> number,
    pop_u16: (T) -> number,
    pop_i16: (T) -> number,
    pop_u32: (T) -> number,
    pop_i32: (T) -> number,
    pop_f32: (T) -> number,
    pop_f64: (T) -> number,
}

export type Push<T> = {
    push_u8: (T, value: number) -> (),
    push_i8: (T, value: number) -> (),
    push_u16: (T, value: number) -> (),
    push_i16: (T, value: number) -> (),
    push_u32: (T, value: number) -> (),
    push_i32: (T, value: number) -> (),
    push_f32: (T, value: number) -> (),
}

export type Stack = Pop<Stack> & Push<Stack> & buffer.Read<Stack> & {
    
}

local function _create_stack(mem: memory.Memory, BEGIN: number, END: number): Stack
    local BUFFER = mem:get_physical_memory():get()
    local SIZE = END - BEGIN - 1
    assert(BEGIN < END, `Stack begin must be less than stack end`)
    assert(SIZE > 0, `Stack size must be greater than 0`)
    assert(SIZE < #mem, `Memory size is {#mem}, but trying allocate {SIZE}`)

    local cursor = END

    local meta = {}
    function meta:__tostring()
        local LIMIT = math.min(SIZE, 128)
        local result = ""
        for i = 0, LIMIT do
            result ..= string.format("%02X ", mem:read_u8(BEGIN + i))
            if i % 16 == 15 then
                result ..= "| "
                for j = 0, 15 do
                    local b = mem:read_u8(BEGIN + i - 15 + j)
                    if b < 32 then
                        result ..= "."
                    else
                        result ..= string.format("%c", b)
                    end
                end
                if i < SIZE then
                    result ..= "\n"
                end
            end
        end
        if SIZE > LIMIT then
            result ..= `... (+ {SIZE - LIMIT} bytes)`
        end
        return result
    end
    local self = {}

    buffer.impl_custom(self, function(self, name, registry)
        self[`pop_{name}`] = function(self)
            assert(cursor <= END, `stack overflow, {END - cursor} bytes left`)
            cursor += registry.b
            return registry.rw.r(BUFFER, BEGIN + cursor)
        end
        
        self[`push_{name}`] = function(self, value)
            assert(cursor > BEGIN, `stack underflow, {BEGIN - cursor} bytes left`)
            cursor -= registry.b
            registry.rw.w(BUFFER, BEGIN + cursor, value)
        end

        self[`read_{name}`] = function(self, index)
            assert(index <= SIZE, `index {index} out of range {SIZE}`)
            assert(index >= BEGIN, `index {index} out of range {BEGIN}`)
            return registry.rw.r(BUFFER, BEGIN + index)
        end
    end)

    return (setmetatable(self, meta) :: any) :: Stack
end

return {
    create = _create_stack
}