import struct

def create_mock_gemma_gguf(path):
    # GEMMA Constants matching Pakila/Core/Config.lean
    HIDDEN_SIZE = 3072
    NUM_LAYERS = 28
    VOCAB_SIZE = 3815

    # GGUF Magic "GGUF"
    magic = b"GGUF"
    version = struct.pack("<I", 2)
    
    # Calculate tensor count: token_embd + 28 layers * 11 tensors + output_norm
    tensor_count = 1 + (NUM_LAYERS * 11) + 1
    
    metadata_count = 1
    
    # Basic header structure
    header = magic + version + struct.pack("<Q", tensor_count) + struct.pack("<Q", metadata_count)
    
    # Placeholder Metadata
    key = "tokenizer.ggml.tokens"
    key_bytes = key.encode('utf-8')
    key_len = struct.pack("<Q", len(key_bytes))
    
    type_id = 9 # ARRAY
    val_type = 8 # STRING
    arr_len = struct.pack("<Q", VOCAB_SIZE)
    
    kv_data = key_len + key_bytes + struct.pack("<I", type_id) + struct.pack("<I", val_type) + arr_len
    for i in range(VOCAB_SIZE):
        t_bytes = f"token_{i}".encode('utf-8')
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
        data = struct.pack("<f", 0.01) * prod 
        
        tensors.append((info, data))
        offset += len(data)

    # 1. Token Embedding
    add_tensor("token_embd.weight", [VOCAB_SIZE, HIDDEN_SIZE])
    
    # 2. Layers
    for i in range(NUM_LAYERS):
        add_tensor(f"blk.{i}.attn_q.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.attn_k.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.attn_v.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.attn_output.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.ffn_gate.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.ffn_up.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.ffn_down.weight", [HIDDEN_SIZE, HIDDEN_SIZE])
        add_tensor(f"blk.{i}.attn_norm.weight", [HIDDEN_SIZE])
        add_tensor(f"blk.{i}.post_attention_norm.weight", [HIDDEN_SIZE])
        add_tensor(f"blk.{i}.ffn_norm.weight", [HIDDEN_SIZE])
        add_tensor(f"blk.{i}.post_ffw_norm.weight", [HIDDEN_SIZE])
        
    # 3. Output Norm
    add_tensor("output_norm.weight", [HIDDEN_SIZE])
        
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
    create_mock_gemma_gguf("test/mock_gemma.gguf")
    print("Mock Gemma GGUF created at test/mock_gemma.gguf")
