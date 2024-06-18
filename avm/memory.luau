--!native
local buffer = require("buffer")

local pow = math.pow

local function assert_virtual_memory_read(MEM_SIZE: number, mapped_memory: {}, address: number, offset: number, bytes: number)
    assert(type(address) == 'number', `address must be a number, got {type(address)}`)
    assert(type(offset) == 'number', `offset must be a number, got {type(offset)}`)
    assert(type(offset) == 'number', `value must be a number, got {type(offset)}`)
    local mapped_size = mapped_memory[address]
    assert(mapped_size ~= nil, `address {address} is not mapped`)
    assert(offset >= 0, `offset must start from 0, got {offset}`)
    assert(bytes > 0, `bytes must be greater than 0, got {bytes}`)
    assert(offset + (bytes - 1) < mapped_size, `offset must be less than {mapped_size}, got {offset}`)
end

local function assert_virtual_memory_write(MEM_SIZE: number, mapped_memory: {}, address: number, offset: number, value: number, bytes: number, signed: boolean, floating: boolean)
    assert(type(address) == 'number', `address must be a number, got {type(address)}`)
    assert(type(offset) == 'number', `offset must be a number, got {type(offset)}`)
    assert(type(offset) == 'number', `value must be a number, got {type(offset)}`)
    local mapped_size = mapped_memory[address]
    assert(mapped_size ~= nil, `address {address} is not mapped`)
    assert(offset >= 0, `offset must start from 0, got {offset}`)
    assert(bytes > 0, `bytes must be greater than 0, got {bytes}`)
    assert(offset + (bytes - 1) < mapped_size, `offset must be less than {mapped_size}, got {offset}`)
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
end


export type PointerRead<T> = {
    read_u8: (self: T, offset: number) -> number,
    read_i8: (self: T, offset: number) -> number,
    read_u16: (self: T, offset: number) -> number,
    read_i16: (self: T, offset: number) -> number,
    read_u32: (self: T, offset: number) -> number,
    read_i32: (self: T, offset: number) -> number,
    read_f32: (self: T, offset: number) -> number,
    read_f64: (self: T, offset: number) -> number,
}

export type PointerWrite<T> = {
    write_u8: (self: T, offset: number, value: number) -> (),
    write_i8: (self: T, offset: number, value: number) -> (),
    write_u16: (self: T, offset: number, value: number) -> (),
    write_i16: (self: T, offset: number, value: number) -> (),
    write_u32: (self: T, offset: number, value: number) -> (),
    write_i32: (self: T, offset: number, value: number) -> (),
    write_f32: (self: T, offset: number, value: number) -> (),
}

export type VirtualRead<T> = {
    read_u8: (self: T, address: number, offset: number) -> number,
    read_i8: (self: T, address: number, offset: number) -> number,
    read_u16: (self: T, address: number, offset: number) -> number,
    read_i16: (self: T, address: number, offset: number) -> number,
    read_u32: (self: T, address: number, offset: number) -> number,
    read_i32: (self: T, address: number, offset: number) -> number,
    read_f32: (self: T, address: number, offset: number) -> number,
    read_f64: (self: T, address: number, offset: number) -> number,
}

export type VirtualWrite<T> = {
    write_u8: (self: T, address: number, offset: number, value: number) -> (),
    write_i8: (self: T, address: number, offset: number, value: number) -> (),
    write_u16: (self: T, address: number, offset: number, value: number) -> (),
    write_i16: (self: T, address: number, offset: number, value: number) -> (),
    write_u32: (self: T, address: number, offset: number, value: number) -> (),
    write_i32: (self: T, address: number, offset: number, value: number) -> (),
    write_f32: (self: T, address: number, offset: number, value: number) -> (),
}

export type Pointer = PointerRead<Pointer> & PointerWrite<Pointer> & {
    get_address: (Pointer) -> number,
    get_size: (Pointer) -> number,
    free: (Pointer) -> (),
}

export type VirtualMemory = VirtualRead<VirtualMemory> & VirtualWrite<VirtualMemory> & {
    allocate: (VirtualMemory, size: number) -> Pointer,
    deallocate: (VirtualMemory, address: number) -> number,
}

export type Memory = buffer.Read<Memory> & buffer.Write<Memory> & {
    get_physical_memory: (Memory) -> buffer.Buffer,
}

local function _create_pointer(vmemory: VirtualMemory, address: number, size: number): Pointer
    local meta = {}
    local self = {}

    function self:get_address(): number
        return address
    end

    function self:get_size(): number
        return size
    end

    function self:free()
        vmemory:deallocate(address)
    end

    buffer.impl_custom_write(self, function(name, registry)
        return function(self, offset: number, value: number)
            (vmemory :: any)[`write_{name}`](vmemory, address, offset, value)
        end
    end)

    buffer.impl_custom_read(self, function(name, registry)
        return function(self, offset: number)
            return (vmemory :: any)[`read_{name}`](vmemory, address, offset)
        end
    end)

    return (setmetatable(self, meta) :: any) :: Pointer
end

local function _create_virutal_memory(memory: Memory): VirtualMemory
    local MEM_SIZE = #memory
    local mapped_memory = {}
    local virtual_memory_map = { last = 0 }

    local meta = {}
    local self = {}

    buffer.impl_custom_read(self, function(name, registry)
        return function(self, address: number, offset: number)
            assert_virtual_memory_read(MEM_SIZE, mapped_memory, address, offset, registry.b)
            return (memory :: any)[`read_{name}`](memory, address + offset)
        end
    end)

    buffer.impl_custom_write(self, function(name, registry)
        return function(self, address: number, offset: number, value: number)
            assert_virtual_memory_write(MEM_SIZE, mapped_memory, address, offset, value, registry.b, registry.s, registry.f)
            ;(memory :: any)[`write_{name}`](memory, address + offset, value)
        end
    end)

    function self:allocate(size: number): Pointer
        assert(type(size) == 'number', `size must be a number, got {type(size)}`)
        assert(size > 0, `size must be greater than 0, got {size}`)
        local address = virtual_memory_map.last
        mapped_memory[address] = size
        virtual_memory_map.last += size
        return _create_pointer(self, address, size)
    end

    function self:deallocate(address: number): number
        assert(type(address) == 'number', `address must be a number, got {type(address)}`)
        assert(address >= 0, `address must start from 0, got {address}`)
        assert(address < MEM_SIZE, `address must be less than {MEM_SIZE}, got {address}`)
        local size = mapped_memory[address]
        assert(size ~= nil, `address {address} is not mapped`)
        mapped_memory[address] = nil
        virtual_memory_map.last -= size
        assert(virtual_memory_map.last >= 0, `virtual memory map is not valid`)
        assert(virtual_memory_map.last <= MEM_SIZE, `virtual memory map is not valid, not enough memory`)
        return size
    end

    return (setmetatable(self, meta) :: any) :: VirtualMemory
end

local function _create_memory(MEM_SIZE): Memory
    local memory = buffer.create(MEM_SIZE)

    local meta = {}
    function meta:__tostring()
        local limit = math.min(#memory, 128)
        local result = memory:dump(0, limit)
        if #memory > limit then
            result ..= `... (+ {#memory - limit} bytes)`
        end
        return result
    end
    function meta:__len()
        return #memory
    end

    local self = {}

    function self:get_physical_memory(): buffer
        return memory
    end

    buffer.impl_custom_read(self, function(name, registry)
        return function(self, address: number)
            buffer.assert_read_memory(MEM_SIZE, address, registry.b)
            return memory[`read_{name}`](memory, address, registry.b)
        end
    end)

    buffer.impl_custom_write(self, function(name, registry)
        return function(self, address: number, value: number)
            buffer.assert_write_memory(MEM_SIZE, address, value, registry.b, registry.s, registry.f)
            memory[`write_{name}`](memory, address, value)
        end
    end)

    return (setmetatable(self, meta) :: any) :: Memory
end

return {
    create = _create_memory,
    create_virtual = _create_virutal_memory
}