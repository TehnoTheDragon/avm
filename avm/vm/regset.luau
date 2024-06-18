export type REGSET = {
    set: (index: number, value: number) -> number,
    get: (index: number) -> (),

    add: (a: number, b: number) -> (),
    sub: (a: number, b: number) -> (),
    mul: (a: number, b: number) -> (),
    div: (a: number, b: number) -> (),
    inc: (index: number) -> (),
    dec: (index: number) -> (),
}

local function assert_register_index(index: number, count: number)
    assert(type(index) == 'number', `index must be a number, got {type(index)}`)
    assert(index > 0, `index must be greater than 0, got {index}`)
    assert(index <= count, `index must be less than {count}, got {index}`)
end

local function _create_regset(count: number): REGSET
    assert(type(count) == 'number', `count must be a number, got {type(count)}`)
    assert(count > 0, `count must be greater than 0, got {count}`)
    local registers = table.create(count, 0)
    local self = {}

    function self.get(index: number): number
        assert_register_index(index, count)
        return registers[index]
    end

    function self.set(index: number, value: number)
        assert_register_index(index, count)
        registers[index] = value
    end

    function self.add(a: number, b: number)
        self.set(a, self.get(a) + self.get(b))
    end

    function self.sub(a: number, b: number)
        self.set(a, self.get(a) - self.get(b))
    end

    function self.mul(a: number, b: number)
        self.set(a, self.get(a) * self.get(b))
    end

    function self.div(a: number, b: number)
        self.set(a, self.get(a) / self.get(b))
    end

    function self.inc(index: number)
        self.set(index, self.get(index) + 1)
    end

    function self.dec(index: number)
        self.set(index, self.get(index) - 1)
    end

    return self
end

return {
    create = _create_regset
}