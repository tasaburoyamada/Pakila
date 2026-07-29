namespace Pakila

@[extern "lean_wasm_execute"]
opaque wasmExecute (modulePath : @& String) (funcName : @& String) : IO String

end Pakila
