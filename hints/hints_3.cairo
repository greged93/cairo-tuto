%builtins output range_check
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.squash_dict import squash_dict
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.serialize import serialize_word

struct KeyValue:
    member key : felt
    member value : felt
end

# Builds a DictAccess list for the computation of the cumulative
# sum for each key.
func build_dict(list : KeyValue*, size, dict : DictAccess*) -> (
        dict:DictAccess*):
    if size == 0:
        return (dict=dict)
    end

    %{
        # Populate ids.dict.prev_value using cumulative_sums...
        # Add list.value to cumulative_sums[list.key]...
        ids.dict.prev_value = cumulative_sums.get(ids.list.key, 0)
        cumulative_sums[ids.list.key] = ids.dict.new_value =  cumulative_sums.get(ids.list.key, 0) + ids.list.value
        print(cumulative_sums)
    %}
    # Copy list.key to dict.key...
    # Verify that dict.new_value = dict.prev_value + list.value...
    # Call recursively to build_dict()...
    assert dict.key = list.key
    assert dict.new_value = dict.prev_value + list.value
    return build_dict(list=list + KeyValue.SIZE, size=size-1, dict=dict + DictAccess.SIZE)
end

# Verifies that the initial values were 0, and writes the final
# values to result.
func verify_and_output_squashed_dict(
        squashed_dict : DictAccess*,
        squashed_dict_end : DictAccess*, result : KeyValue*) -> (
        result: KeyValue*):
    tempvar diff = squashed_dict_end - squashed_dict
    if diff == 0:
        return (result=result)
    end

    # Verify prev_value is 0...
    assert squashed_dict.prev_value = 0
    # Copy key to result.key...
    assert result.key = squashed_dict.key
    # Copy new_value to result.value...
    assert result.value = squashed_dict.new_value
    # Call recursively to verify_and_output_squashed_dict...
    return verify_and_output_squashed_dict(squashed_dict=squashed_dict+DictAccess.SIZE, squashed_dict_end=squashed_dict_end, result=result+KeyValue.SIZE)
end

# Given a list of KeyValue, sums the values, grouped by key,
# and returns a list of pairs (key, sum_of_values).
func sum_by_key{output_ptr: felt*, range_check_ptr}(list : KeyValue*, size) -> (
        result:KeyValue*, result_size):
    %{
        # Initialize cumulative_sums with an empty dictionary.
        # This variable will be used by ``build_dict`` to hold
        # the current sum for each key.
        cumulative_sums = {}
    %}
    # Allocate memory for dict, squashed_dict and res...
    # Call build_dict()...
    # Call squash_dict()...
    # Call verify_and_output_squashed_dict()...
    alloc_locals
    let (local dict_start: DictAccess*) = alloc() 
    let (local squashed_dict: DictAccess*) = alloc() 
    let (local res: KeyValue*) = alloc() 


    let (local dict_end: DictAccess*) = build_dict(list=list, size=size, dict=dict_start)
    let (local squashed_dict_end : DictAccess*) = squash_dict(
        dict_accesses=dict_start,
        dict_accesses_end=dict_end,
        squashed_dict=squashed_dict)
    local range_check_ptr = range_check_ptr
    verify_and_output_squashed_dict(squashed_dict=squashed_dict, squashed_dict_end=squashed_dict_end, result=res) # Attention!!! Here res points to the beginning of the result, 
                                                                                                                  # so no need to try to get the beginning, I'm already there
    tempvar result_size = (squashed_dict_end-squashed_dict)/DictAccess.SIZE
    return (res, result_size)
end

func print_dict{output_ptr: felt*, range_check_ptr}(dict: DictAccess*, size) :
    if size == 0:
        return ()
    end
    serialize_word(dict.key)
    serialize_word(dict.prev_value)
    serialize_word(dict.new_value)
    print_dict(dict=dict+DictAccess.SIZE, size=size-1)
    return()
end

func print_key_val{output_ptr: felt*, range_check_ptr}(res: KeyValue*, size) :
    if size == 0:
        return ()
    end
    serialize_word(res.key)
    serialize_word(res.value)
    print_key_val(res=res+KeyValue.SIZE, size=size-1)
    return()
end

func main{output_ptr: felt*, range_check_ptr}():
    alloc_locals
    local list: (KeyValue, KeyValue, KeyValue, KeyValue, KeyValue, KeyValue) = (
        KeyValue(key=3, value=5), 
        KeyValue(key=1, value=10), 
        KeyValue(key=3, value=1), 
        KeyValue(key=3, value=8), 
        KeyValue(key=1, value=20),
        KeyValue(key=5, value=20),
        )

    
    const LIST_SIZE = 6
    let (__fp__, _) = get_fp_and_pc()
    let (local result: KeyValue*, size) = sum_by_key(list=cast(&list, KeyValue*), size=LIST_SIZE)
    print_key_val(res=result,size=size)
    return()
end