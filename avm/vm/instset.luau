--!native
local ELEMENTS_SIZE = table.freeze({
    [0x0] = 8,
    [0x1] = 16,
    [0x2] = 32,
    [0x3] = 32,
    [0x4] = 64,
})
local ELEMENTS_SYM = table.freeze({
    [0x0] = 'u',
    [0x1] = 'u',
    [0x2] = 'u',
    [0x3] = 'f',
    [0x4] = 'f',
})

type INSTRUCTION = {
    id: number,
    elements: { number },
    size: number?,
    count: number?,
    element_syms: { string }?,
    element_sizes: { number }?,
}
local INST: {[string]: INSTRUCTION} = {
    HLT = { id = 0xFF, elements = {} }, -- halt

    -- Stack

    PUSHCB = { id = 0xA0, elements = { 0x00 } }, -- pushcb <u8:value>
    PUSHCS = { id = 0xA1, elements = { 0x01 } }, -- pushcs <u16:value>
    PUSHCL = { id = 0xA2, elements = { 0x02 } }, -- pushcl <u32:value>
    PUSHCF = { id = 0xA3, elements = { 0x03 } }, -- pushcF <f32:value>
    PUSHCDF = { id = 0xA4, elements = { 0x04 } }, -- pushcdf <f64:value>

    PUSHRB = { id = 0xB0, elements = { 0x00 } }, -- pushrb <u8:register>
    PUSHRS = { id = 0xB1, elements = { 0x00 } }, -- pushrs <u8:register>
    PUSHRL = { id = 0xB2, elements = { 0x00 } }, -- pushrl <u8:register>
    PUSHRF = { id = 0xB3, elements = { 0x00 } }, -- pushrf <u8:register>
    PUSHRDF = { id = 0xB4, elements = { 0x00 } }, -- pushrdf <u8:register>

    POPB = { id = 0xB5, elements = { 0x00 } }, -- popb <u8:(sign: 1, register: 7)>
    POPS = { id = 0xB6, elements = { 0x00 } }, -- pops <u8:(sign: 1, register: 7)>
    POPL = { id = 0xB7, elements = { 0x00 } }, -- popl <u8:(sign: 1, register: 7)>
    POPF = { id = 0xB8, elements = { 0x00 } }, -- popf <u8:register>
    POPDF = { id = 0xB9, elements = { 0x00 } }, -- popdf <u8:register>

    -- Registers

    MOVB = { id = 0xC0, elements = { 0x00, 0x00 } }, -- mov <u8:register>, <u8:value>
    MOVS = { id = 0xC1, elements = { 0x00, 0x01 } }, -- movs <u8:register>, <u16:value>
    MOVL = { id = 0xC2, elements = { 0x00, 0x02 } }, -- movl <u8:register>, <u32:value>
    MOVF = { id = 0xC3, elements = { 0x00, 0x03 } }, -- movf <u8:register>, <f32:value>
    MOVDF = { id = 0xC4, elements = { 0x00, 0x04 } }, -- movdf <u8:register>, <f64:value>

    -- Math

    ADD = { id = 0xD0, elements = { 0x00 } }, -- add <u4:(left_register: 4, right_register: 4)>
    SUB = { id = 0xD1, elements = { 0x00 } }, -- sub <u4:(left_register: 4, right_register: 4)>
    MUL = { id = 0xD2, elements = { 0x00 } }, -- mul <u4:(left_register: 4, right_register: 4)>
    DIV = { id = 0xD3, elements = { 0x00 } }, -- div <u4:(left_register: 4, right_register: 4)>
}
local INST2NAME = {}
local INST2INST = {}
local function inst2name(inst: number): string
    return INST2NAME[inst]
end
local function inst2inst(inst: number): INSTRUCTION
    return INST2INST[inst]
end
for k, v in pairs(INST) do
    INST2NAME[v.id] = k
    INST2INST[v.id] = v
    v.element_syms = {}
    v.element_sizes = {}
    local size = 0
    for k, e in v.elements do
        size += ELEMENTS_SIZE[e]
        v.element_syms[k] = ELEMENTS_SYM[e]
        v.element_sizes[k] = ELEMENTS_SIZE[e]
    end
    v.size = size
    v.count = #v.elements
    setmetatable(v, {
        __tostring = function(self)
            return inst2name(self.id)
        end,
        __eq = function(self, other)
            print(self.id, other)
            return self.id == other
        end
    })
end

setmetatable(INST, {
    __index = function(self, key)
        assert(typeof(key) == "string", "key must be a string")
        local key = key:upper()
        local inst = rawget(self, key)
        if inst then
            return inst
        end
        error(`unknown instruction: {key}`)
    end,
    __tostring = function(self)
        local result = ""
        for k, v in pairs(self) do
            result ..= `{v}({v.id}, 0x{string.format("%X", v.size)})\n`
        end
        return result
    end,
})

table.freeze(INST2NAME)
table.freeze(INST)
return {
    INST = INST,
    inst2name = inst2name,
    inst2inst = inst2inst,
}
