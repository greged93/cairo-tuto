%builtins output 
from starkware.cairo.common.serialize import serialize_word

func main{output_ptr: felt*}():
    alloc_locals
    local tile_list: felt*
    local n_steps

    %{
        tiles = program_input["tiles"]
        ids.tile_list = tile_list = segments.add()
        for i, tile in enumerate(tiles):
            memory[tile_list + i] = tile
        print(memory[tile_list + 2])
    %}
    return ()
end