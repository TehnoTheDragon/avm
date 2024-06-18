--!native
export type REGSET = {
    get: (REGSET, index: number) -> number,
    set: (REGSET, index: number, value: number) -> (),

    add: (REGSET, a: number, b: number) -> (),
    sub: (REGSET, a: number, b: number) -> (),
    mul: (REGSET, a: number, b: number) -> (),
    div: (REGSET, a: number, b: number) -> (),
    inc: (REGSET, index: number) -> (),
    dec: (REGSET, index: number) -> (),
}

local function assert_register_index(index: number, count: number)
    assert(type(index) == 'number', `index must be a number, got {type(index)}`)
    assert(index >= 0, `index must be greater or equal 0, got {index}`)
    assert(index <= count, `index must be less than {count}, got {index}`)
end

local function _create_regset(count: number): REGSET
    assert(type(count) == 'number', `count must be a number, got {type(count)}`)
    assert(count > 0, `count must be greater than 0, got {count}`)
    local registers = {}
    for i = 0, count - 1 do
        registers[i] = 0
    end

    local meta = {}
    function meta:__tostring()
        local result = ""
        for i = 0, count - 1 do
            local value = registers[i]
            result ..= `r{i}: {string.format("%08X", value)}({string.format("%.4f", value)}); `
            if i % 2 == 1 and i < count then
                result ..= "\n"
            end
        end
        return result
    end
    local self = {}

    function meta:__index(key)
        if type(key) == 'number' then
            return self:get(key)
        end
        return rawget(self, key)
    end

    function self:get(index: number): number
        assert_register_index(index, count)
        return registers[index]
    end

    function self:set(index: number, value: number)
        assert_register_index(index, count)
        registers[index] = value
    end

    function self:add(a: number, b: number)
        self:set(a, self:get(a) + self:get(b))
    end

    function self:sub(a: number, b: number)
        self:set(a, self:get(a) - self:get(b))
    end

    function self:mul(a: number, b: number)
        self:set(a, self:get(a) * self:get(b))
    end

    function self:div(a: number, b: number)
        self:set(a, self:get(a) / self:get(b))
    end

    function self:inc(index: number)
        self:set(index, self:get(index) + 1)
    end

    function self:dec(index: number)
        self:set(index, self:get(index) - 1)
    end

    return (setmetatable(self, meta) :: any) :: REGSET
end

return {
    create = _create_regset
}