local Executor = require("avm/vm/executor")
local Codegen = require("avm/vm/codegen")
local Memory = require("avm/memory")
local Stack = require("avm/stack")
local Lexer = require("avm/vm/lexer")
local Parser = require("avm/vm/parser")

local ProgramMemory = Memory.create(32)
local Program = Stack.create(ProgramMemory, 0, #ProgramMemory)

local source = [[
movf r1, 4.3
movf r2, 5.7
add r1, r2
]]

local tokens = Lexer.tokenize(source)
local ast = Parser.parse(tokens)

Codegen.build_with_ast(Program, ast)

print(Program)

local executor = Executor.create(64, 64)
executor.run(Program)