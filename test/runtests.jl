using MarkElide
using Base.Test

using MarkElide

f(x) = @mark :a println("hi $x")

println("non elided call:")
f(2)

println("elided call:")
@elide :a f(3)
