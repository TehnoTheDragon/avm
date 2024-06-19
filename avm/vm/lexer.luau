local instset = require("instset")

local function is_in_instset(name: string): boolean
    return pcall(function() return instset.INST[name] end) == true
end

export type Token = {
    type: string,
    value: string,
    index_start: number,
    index_end: number,
}

local TokenMeta = {}
function TokenMeta:__tostring()
    return `{self.type}({self.index_start}, {self.index_end}): '{self.value}'`
end

local function _create_token(type: string, value: string, start_index: number, end_index: number): Token
    return (setmetatable({
        type = type,
        value = value,
        index_start = start_index,
        index_end = end_index
    }, TokenMeta) :: any) :: Token
end

local function _tokenize(source: string): {Token}
    local tokens: {Token} = {}
    local index = 1

    local function add_token(token: Token)
        table.insert(tokens, token)
    end

    local function char(): string
        return source:sub(index, index)
    end

    local function collect_whitespaces()
        local c = char()
        local begin = index
        while c == ' ' or c == '\t' or c == '\r' or c == '\n' do
            index += 1
            c = char()
        end
        if index - begin > 0 then
            add_token(_create_token('whitespace', ' ', begin, index - 1))
        end
    end

    local function is_alpha(c: string): boolean
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z')
    end

    local function is_digit(c: string): boolean
        return c >= '0' and c <= '9'
    end

    local function is_alphanum(c: string): boolean
        return is_alpha(c) or is_digit(c)
    end

    local function collect_name()
        local begin = index
        local c = char()
        while is_alphanum(c) do
            index += 1
            c = char()
        end
        local name = source:sub(begin, index - 1)
        add_token(_create_token(is_in_instset(name) and 'instruction' or 'name', name, begin, index - 1))
    end

    local function collect_number()
        local begin = index
        local c = char()
        while is_digit(c) do
            index += 1
            c = char()
        end
        if char() == '.' then
            index += 1
            c = char()
            while is_digit(c) do
                index += 1
                c = char()
            end
        end
        add_token(_create_token('number', source:sub(begin, index - 1), begin, index - 1))
    end

    while index <= #source do
        collect_whitespaces()
        local c = char()
        if is_alpha(c) then
            collect_name()
        elseif is_digit(c) then
            collect_number()
        else
            if c == ',' then
                add_token(_create_token('comma', ',', index, index))
            end
            index += 1
        end
    end

    return tokens
end

return {
    tokenize = _tokenize
}