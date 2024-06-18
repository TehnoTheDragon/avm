type INSTRUCTION = { id: number, size: number }
local INST: {[string]: INSTRUCTION} = {
    HLT = { id = 0xFF, size = 0 }, -- halt

    -- Stack

    PUSHCB = { id = 0xA0, size = 1 }, -- pushcb <u8:value>
    PUSHCS = { id = 0xA1, size = 2 }, -- pushcs <u16:value>
    PUSHCL = { id = 0xA2, size = 4 }, -- pushcl <u32:value>
    PUSHCF = { id = 0xA3, size = 4 }, -- pushcF <f32:value>
    PUSHCDF = { id = 0xA4, size = 8 }, -- pushcdf <f64:value>

    PUSHRB = { id = 0xB0, size = 1 }, -- pushrb <u8:register>
    PUSHRS = { id = 0xB1, size = 1 }, -- pushrs <u8:register>
    PUSHRL = { id = 0xB2, size = 1 }, -- pushrl <u8:register>
    PUSHRF = { id = 0xB3, size = 1 }, -- pushrf <u8:register>
    PUSHRDF = { id = 0xB4, size = 1 }, -- pushrdf <u8:register>

    POPB = { id = 0xB5, size = 2 }, -- popb <u8:signed> <u8:register>
    POPS = { id = 0xB6, size = 2 }, -- pops <u8:signed> <u8:register>
    POPL = { id = 0xB7, size = 2 }, -- popl <u8:signed> <u8:register>
    POPF = { id = 0xB7, size = 1 }, -- popf <u8:register>
    POPDF = { id = 0xB7, size = 1 }, -- popdf <u8:register>

    -- Registers

    MOV = { id = 0xC0, size = 2 }, -- mov <u8:register>, <u8:value>
    MOVS = { id = 0xC1, size = 3 }, -- movs <u8:register>, <u16:value>
    MOVL = { id = 0xC2, size = 5 }, -- movl <u8:register>, <u32:value>
    MOVF = { id = 0xC3, size = 5 }, -- movf <u8:register>, <f32:value>
    MOVDF = { id = 0xC4, size = 9 }, -- movdf <u8:register>, <f64:value>
}

local INST2NAME = {}
local function inst2name(inst: number): string
    return INST2NAME[inst]
end
for k, v in pairs(INST) do
    INST2NAME[v.id] = k
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
}
