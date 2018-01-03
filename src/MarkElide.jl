module MarkElide
using Cassette
export @mark
export @elide

ismark_begin(x) = false
ismark_end(x) = false
function ismark_begin(ex::Expr)
    ex.head == :meta &&
    length(ex.args) == 3 &&
    ex.args[1] == :mark &&
    ex.args[3] == :begin
end
function ismark_end(ex::Expr)
    ex.head == :meta &&
    length(ex.args) == 3 &&
    ex.args[1] == :mark &&
    ex.args[3] == :end
end

Cassette.@context MarkElideCtx
function Cassette.getpass(::Type{MarkElideCtx})
    function inner(signature, method_body)::CodeInfo
        code = method_body.code
        ret = []
        elide = 0
        for ex in code
            if ismark_begin(ex)
                elide += 1
            elseif ismark_end(ex)
                @assert elide > 0
                elide -= 1
            elseif elide > 0
                nothing
            else
                push!(ret, ex)
            end
        end
        @assert elide == 0
        ret
        method_body.code = code
    end
end

# package code goes here

macro mark(symbol, code)
    @assert symbol isa QuoteNode
    @assert symbol.value isa Symbol
    Expr(:block,
         Expr(:meta, :mark, symbol.value, :begin),
         Expr(:(=), :ret, esc(code)),
         Expr(:meta, :mark, symbol.value, :end),
         :ret)
end

macro elide(symbol, code)
    @assert symbol isa QuoteNode
    @assert symbol.value isa Symbol
    @assert code isa Expr
    @assert code.head == :call
    f = esc(code.args[1])
    args = map(esc, code.args[2:end])
    :(Cassette.overdub(MarkElideCtx,$f)($(args...)))
end # module
end
