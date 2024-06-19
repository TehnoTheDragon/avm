local lexer = require("lexer")
local instset = require("instset")

local function _parse(tokens: {lexer.Token})
    local ast = {}
    local index = 1

    local function get_instruction_node(instruction: string, inst: number)
        local node = {}
        node.kind = 'instruction'
        node.instruction = instruction
        node.inst = inst
        node.elements = {}
        node.meta = {}
        table.insert(ast, node)
        return setmetatable(node, {
            __tostring = function(self)
                return `{instruction}({string.format('%02X', inst)}) \{{table.concat(self.elements, ', ')}}`
            end,
        })
    end

    local function current(): lexer.Token
        return tokens[index]
    end

    local function skip()
        index += 1
    end

    local function eat(type: string): lexer.Token
        local token = current()
        assert(token.type == type, `expected {type}, got {token.type}`)
        skip()
        return current()
    end

    local function expect(type: string): lexer.Token
        local token = current()
        assert(token.type == type, `expected {type}, got {token.type}`)
        index += 1
        return token
    end

    local function skip_whitespace(): lexer.Token
        while current().type == 'whitespace' do
            skip()
        end
        return current()
    end

    local function parse_instruction()
        local instruction_token = expect('instruction')
        local instruction_type = instset.INST[instruction_token.value]
        local instruction_node = get_instruction_node(instruction_token.value, instruction_type.id)
        instruction_node.meta = { token = instruction_token, type = instruction_type }
        while true do
            local t = skip_whitespace()
            if t.type == "number" then
                table.insert(instruction_node.elements, tonumber(t.value))
            elseif t.type == "name" then
                eat(t.type)
                local prefix = t.value:sub(1, 1)
                if prefix == 'r' then
                    table.insert(instruction_node.elements, tonumber(t.value:sub(2) - 1))
                else
                    error(`expected register 'r', got '{prefix}'`)
                end
            else
                error(`expected number or name, got {t.type}`)
            end

            if current().type == 'comma' then
                eat('comma')
            else
                break
            end
        end
    end

    while index <= #tokens do
        local token = current()
        if token.type == 'instruction' then
            parse_instruction()
        end
        index += 1
    end

    return ast
end

local function _analyzer(ast: {})
    local function analyze_instruction_operands(node)
        local node_elements_count = #node.elements
        local inst_elements_count = node.meta.type.count
        if node_elements_count == inst_elements_count then
            return
        end
        local inst_element_sizes = node.meta.type.element_sizes

        -- not best solution, but I need fix it for now
        local low = bit32.band(node.elements[1], 0xF)
        local high = bit32.band(node.elements[2], 0xF)
        local combine = bit32.lshift(high, 4) + low
        node.elements = { combine }
    end

    for i, node in ast do
        if node.kind == 'instruction' then
            analyze_instruction_operands(node)
        end
        -- print(`[{i}]: {node}`)
    end
end

return {
    parse = function(tokens: {lexer.Token}): {}
        local ast = _parse(tokens)
        _analyzer(ast)
        return ast
    end,
}