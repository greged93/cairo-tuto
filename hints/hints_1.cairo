%builtins output

from starkware.cairo.common.serialize import serialize_word

func bar() -> (res):
    alloc_locals
    local x
    %{ ids.x = 5 %}  # Note this line.
    assert x * x = 25
    return (res=x)
end

func main {output_ptr: felt*}():
    serialize_word(1234)
    let (x) = bar()
    serialize_word(x)
    return ()
end