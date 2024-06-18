--!native
local buffer_create = buffer.create
local buffer_tostring = buffer.tostring
local buffer_fill = buffer.fill
local buffer_length = buffer.len

local buffer_ru8 = buffer.readu8
local buffer_wu8 = buffer.writeu8
local buffer_ru16 = buffer.readu16
local buffer_wu16 = buffer.writeu16
local buffer_ru32 = buffer.readu32
local buffer_wu32 = buffer.writeu32

local buffer_ri8 = buffer.readi8
local buffer_wi8 = buffer.writei8
local buffer_ri16 = buffer.readi16
local buffer_wi16 = buffer.writei16
local buffer_ri32 = buffer.readi32
local buffer_wi32 = buffer.writei32

local buffer_rf32 = buffer.readf32
local buffer_wf32 = buffer.writef32
local buffer_rf64 = buffer.readf64
local buffer_wf64 = buffer.writef64

local buffer_rstr = buffer.readstring
local buffer_wstr = buffer.writestring

local buffer_copy = buffer.copy

local pow = math.pow
local strlen = string.len

local function assert_read_memory(MEM_SIZE: number, address: number, bytes: number)
    assert(type(address) == 'number', `address must be a number, got {type(address)}`)
    assert(type(bytes) == 'number', `bytes must be a number, got {type(bytes)}`)
    assert(address >= 0, `address must start from 0, got {address}`)
    assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
    assert(bytes > 0, `bytes must be greater than 0, got {bytes}`)
    assert(address + bytes <= MEM_SIZE, `address + bytes must be less than {MEM_SIZE}, got {address + bytes}`)
    assert(bytes <= MEM_SIZE - address, `bytes must be less than {MEM_SIZE - address}, got {bytes}`)
end

local function assert_write_memory(MEM_SIZE: number, address: number, value: number, bytes: number, signed: boolean, floating: boolean)
    assert(type(address) == 'number', `address must be a number, got {type(address)}`)
    assert(type(value) == 'number', `value must be a number, got {type(value)}`)
    assert(type(bytes) == 'number', `bytes must be a number, got {type(bytes)}`)
    assert(address >= 0, `address must start from 0, got {address}`)
    assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
    assert(bytes > 0, `bytes must be greater than 0, got {bytes}`)
    if not floating then
        local sign = (signed and 1 or 0)
        local max = pow(2, bytes * (8 - sign))
        local min = (signed and -1 * max or 0)
        assert(value >= min, `value must be greater than {min}, got {value}`)
        assert(value < max, `value must be less than {max}, got {value}`)
    else
        assert(value >= -math.huge, `value must be greater than -math.huge, got {value}`)
        assert(value <= math.huge, `value must be less than math.huge, got {value}`)
    end
    assert(address + bytes <= MEM_SIZE, `address + bytes must be less than {MEM_SIZE}, got {address + bytes}`)
    assert(bytes <= MEM_SIZE - address, `bytes must be less than {MEM_SIZE - address}, got {bytes}`)
end

local function assert_read_string(MEM_SIZE: number, address: number, length: number)
    assert(type(address) == 'number', `address must be a number, got {type(address)}`)
    assert(type(length) == 'number', `length must be a number, got {type(length)}`)
    assert(address >= 0, `address must start from 0, got {address}`)
    assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
    assert(length > 0, `length must be greater than 0, got {length}`)
    assert(address + length <= MEM_SIZE, `address + length must be less than {MEM_SIZE}, got {address + length}`)
    assert(length <= MEM_SIZE - address, `length must be less than {MEM_SIZE - address}, got {length}`)
end

local function assert_write_string(MEM_SIZE: number, address: number, value: string)
    assert(type(address) == 'number', `address must be a number, got {type(address)}`)
    assert(type(value) == 'string', `value must be a string, got {type(value)}`)
    local length = strlen(value)
    assert(address >= 0, `address must start from 0, got {address}`)
    assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
    assert(length > 0, `length must be greater than 0, got {length}`)
    assert(address + length <= MEM_SIZE, `address + length must be less than {MEM_SIZE}, got {address + length}`)
    assert(length <= MEM_SIZE - address, `length must be less than {MEM_SIZE - address}, got {length}`)
end

type REGISTRY = { f: boolean, s: boolean, b: number, rw: { r: (buffer, number) -> number, w: (buffer, number, number) -> any } }
local REGISTRY_MAP: {[string]: REGISTRY} = table.freeze({
    ["u8"] = { f = false, s = false, b = 1, rw = { r = buffer_ru8, w = buffer_wu8 } },
    ["i8"] = { f = false, s = true, b = 1, rw = { r = buffer_ri8, w = buffer_wi8 } },
    ["u16"] = { f = false, s = false, b = 2, rw = { r = buffer_ru16, w = buffer_wu16 } },
    ["i16"] = { f = false, s = true, b = 2, rw = { r = buffer_ri16, w = buffer_wi16 } },
    ["u32"] = { f = false, s = false, b = 4, rw = { r = buffer_ru32, w = buffer_wu32 } },
    ["i32"] = { f = false, s = true, b = 4, rw = { r = buffer_ri32, w = buffer_wi32 } },
    ["f32"] = { f = true, s = true, b = 4, rw = { r = buffer_rf32, w = buffer_wf32 } },
    ["f64"] = { f = true, s = true, b = 8, rw = { r = buffer_rf64, w = buffer_wf64 } },
})

export type Read<T> = {
    read_u8: (T, address: number) -> number,
    read_i8: (T, address: number) -> number,
    read_u16: (T, address: number) -> number,
    read_i16: (T, address: number) -> number,
    read_u32: (T, address: number) -> number,
    read_i32: (T, address: number) -> number,
    read_f32: (T, address: number) -> number,
    read_f64: (T, address: number) -> number,
}

export type Write<T> = {
    write_u8: (T, address: number, value: number) -> (),
    write_i8: (T, address: number, value: number) -> (),
    write_u16: (T, address: number, value: number) -> (),
    write_i16: (T, address: number, value: number) -> (),
    write_u32: (T, address: number, value: number) -> (),
    write_i32: (T, address: number, value: number) -> (),
    write_f32: (T, address: number, value: number) -> (),
}

export type Buffer = Write<Buffer> & Read<Buffer> & {
    dump: (Buffer) -> string,
    fill: (Buffer, address: number, size: number, value: number) -> (),
    copy: (Buffer, from: number, to: number, size: number) -> (),
    read: (Buffer, address: number, size: number) -> string,
    write: (Buffer, address: number, value: string) -> (),
    get: (Buffer) -> buffer,
}

local function implement_custom_read(self: any, builder: (name: string, registry: REGISTRY) -> any)
    for name, registry in REGISTRY_MAP do
        self[`read_{name}`] = builder(name, registry)
    end
end

local function implement_read(self: any, buf: buffer, MEM_SIZE: number)
    for name, registry in REGISTRY_MAP do
        self[`read_{name}`] = function(self, address: number)
            assert_read_memory(MEM_SIZE, address, registry.b)
            return registry.rw.r(buf, address)
        end
    end
end

local function implement_custom_write(self: any, builder: (name: string, registry: REGISTRY) -> any)
    for name, registry in REGISTRY_MAP do
        self[`write_{name}`] = builder(name, registry)
    end
end

local function implement_write(self: any, buf: buffer, MEM_SIZE: number)
    for name, registry in REGISTRY_MAP do
        self[`write_{name}`] = function(self, address: number, value: number)
            assert_write_memory(MEM_SIZE, address, value, registry.b, registry.s, registry.f)
            registry.rw.w(buf, address, value)
        end
    end
end

local function implement_custom(self: any, builder: (self: any, name: string, registry: REGISTRY) -> any)
    for name, registry in REGISTRY_MAP do
        builder(self, name, registry)
    end
end

local function _create_buffer(MEM_SIZE: number): Buffer
    assert(MEM_SIZE > 0, `size must be greater than 0, got {MEM_SIZE}`)
    local buffer = buffer_create(MEM_SIZE)

    local meta = {}
    function meta:__tostring()
        return buffer_tostring(buffer)
    end
    function meta:__len()
        return buffer_length(buffer)
    end
    function meta:__index(index)
        assert(type(index) == 'number', `index must be a number, got {type(index)}`)
        assert(index >= 0, `index must start from 0, got {index}`)
        assert(index < MEM_SIZE, `index must be less than {MEM_SIZE}, got {index}`)
        return buffer_ru8(buffer, index)
    end
    function meta:__newindex(index, value)
        assert(type(index) == 'number', `index must be a number, got {type(index)}`)
        assert(index >= 0, `index must start from 0, got {index}`)
        assert(index < MEM_SIZE, `index must be less than {MEM_SIZE}, got {index}`)
        assert(type(value) == 'number', `value must be a number, got {type(value)}`)
        assert(value >= 0, `value must be greater than 0, got {value}`)
        assert(value < 256, `value must be less than 256, got {value}`)
        buffer_wu8(buffer, index, value)
    end

    local self = {}

    function self:dump(address: number, length: number)
        assert(type(address) == 'number', `address must be a number, got {type(address)}`)
        assert(address >= 0, `address must start from 0, got {address}`)
        assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
        assert(type(length) == 'number', `length must be a number, got {type(length)}`)
        assert(length > 0, `length must be greater than 0, got {length}`)
        assert(address + length <= MEM_SIZE, `address + length must be less than {MEM_SIZE}, got {address + length}`)
        local dump = ""
        for i = 0, length - 1 do
            dump ..= string.format("%02X ", buffer_ru8(buffer, address + i))
            if i % 16 == 15 then
                dump ..= "| "
                for j = 0, 15 do
                    local b = buffer_ru8(buffer, address + i - 15 + j)
                    if b < 32 then
                        dump ..= "."
                    else
                        dump ..= string.format("%c", b)
                    end
                end
                dump ..= "\n"
            end
        end
        return dump
    end

    function self:fill(address: number, size: number, value: number)
        assert(type(address) == 'number', `address must be a number, got {type(address)}`)
        assert(address >= 0, `address must start from 0, got {address}`)
        assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
        assert(type(size) == 'number', `size must be a number, got {type(size)}`)
        assert(size > 0, `size must be greater than 0, got {size}`)
        assert(type(value) == 'number', `value must be a number, got {type(value)}`)
        assert(value >= 0, `value must be greater than 0, got {value}`)
        assert(value < 256, `value must be less than 256, got {value}`)
        buffer_fill(buffer, address, size, value)
    end

    function self:copy(from: number, to: number, length: number)
        assert(type(from) == 'number', `from must be a number, got {type(from)}`)
        assert(from >= 0, `from must start from 0, got {from}`)
        assert(from < MEM_SIZE, `from must be less than {MEM_SIZE}, got {from}`)
        assert(type(to) == 'number', `to must be a number, got {type(to)}`)
        assert(to >= 0, `to must start from 0, got {to}`)
        assert(to < MEM_SIZE, `to must be less than {MEM_SIZE}, got {to}`)
        assert(type(length) == 'number', `length must be a number, got {type(length)}`)
        assert(length > 0, `length must be greater than 0, got {length}`)
        assert(from + length <= MEM_SIZE, `from + length must be less than {MEM_SIZE}, got {from + length}`)
        buffer_copy(buffer, from, to, length)
    end

    function self:read(address: number, length: number)
        assert_read_string(MEM_SIZE, address, length)
        return buffer_rstr(buffer, address, length)
    end

    function self:write(address: number, value: string)
        assert_write_string(MEM_SIZE, address, value)
        buffer_wstr(buffer, address, value)
    end

    function self:get(): buffer
        return buffer
    end

    function self:read_u8(address: number)end
    function self:write_u8(address: number, value: number)end
    function self:read_i8(address: number)end
    function self:write_i8(address: number, value: number)end
    function self:read_u16(address: number)end
    function self:write_u16(address: number, value: number)end
    function self:read_i16(address: number)end
    function self:write_i16(address: number, value: number)end
    function self:read_u32(address: number)end
    function self:write_u32(address: number, value: number)end
    function self:read_i32(address: number)end
    function self:write_i32(address: number, value: number)end
    function self:read_f32(address: number)end
    function self:write_f32(address: number, value: number)end
    function self:read_f64(address: number)end
    function self:write_f64(address: number, value: number)end

    implement_read(self, buffer, MEM_SIZE)
    implement_write(self, buffer, MEM_SIZE)

    return (setmetatable(self, meta) :: any) :: Buffer
end

return {
    create = _create_buffer,
    
    impl_custom_read = implement_custom_read,
    impl_read = implement_read,
    impl_custom_write = implement_custom_write,
    impl_write = implement_write,
    impl_custom = implement_custom,

    assert_read_memory = assert_read_memory,
    assert_write_memory = assert_write_memory,
    assert_read_string = assert_read_string,
    assert_write_string = assert_write_string,
}