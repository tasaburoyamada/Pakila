import struct

def create_mock_bert_gguf(path):
    # GGUF Magic "GGUF"
    magic = b"GGUF"
    version = struct.pack("<I", 2)
    tensor_count = struct.pack("<Q", 2 + 12 * 2) 
    
    # Metadata: tokenizer.ggml.tokens
    tokens = ["[CLS]", "[SEP]", "[UNK]", "hello", "native", "world", "##ly", "##ing"]
    
    metadata_count = 1
    
    header = magic + version + struct.pack("<Q", 2 + 12 * 2) + struct.pack("<Q", metadata_count)
    
    # tokenizer.ggml.tokens: array of strings
    key = "tokenizer.ggml.tokens"
    key_bytes = key.encode('utf-8')
    key_len = struct.pack("<Q", len(key_bytes))
    
    type_id = 9 # ARRAY
    val_type = 8 # STRING
    arr_len = struct.pack("<Q", len(tokens))
    
    kv_data = key_len + key_bytes + struct.pack("<I", type_id) + struct.pack("<I", val_type) + arr_len
    for t in tokens:
        t_bytes = t.encode('utf-8')
        kv_data += struct.pack("<Q", len(t_bytes)) + t_bytes

    tensors = []
    offset = 0
    
    def add_tensor(name, dims, type_id=0): # 0 = F32
        nonlocal offset
        name_bytes = name.encode('utf-8')
        name_len = struct.pack("<Q", len(name_bytes))
        n_dims = struct.pack("<I", len(dims))
        dim_bytes = b"".join(struct.pack("<Q", d) for d in dims)
        t_type = struct.pack("<I", type_id)
        t_off = struct.pack("<Q", offset)
        
        info = name_len + name_bytes + n_dims + dim_bytes + t_type + t_off
        
        prod = 1
        for d in dims: prod *= d
        # Using a small non-zero value (e.g. 0.01) for all weights
        data = struct.pack("<f", 0.01) * prod 
        
        tensors.append((info, data))
        offset += len(data)

    add_tensor("token_embd.weight", [30522, 384])
    add_tensor("position_embd.weight", [512, 384])
    for i in range(12):
        add_tensor(f"blk.{i}.attn_output.weight", [384, 384])
        add_tensor(f"blk.{i}.attn_output.bias", [384])
        
    with open(path, "wb") as f:
        f.write(header)
        f.write(kv_data)
        # Tensor infos
        for info, _ in tensors:
            f.write(info)
        # Tensor data
        for _, data in tensors:
            f.write(data)

if __name__ == "__main__":
    create_mock_bert_gguf("test/mock_bert.gguf")
    print("Mock BERT GGUF with Tokens created at test/mock_bert.gguf")
