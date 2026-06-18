=== 1. 上流依存分析: IO.FS 依存箇所 ===
Pakila/CLI/Terminal.lean:19:deriving instance Inhabited for IO.FS.DirEntry
Pakila/Core/Delegator.lean:61:  try IO.FS.removeFile tempFile catch _ => pure ()

=== 2. 下流波及分析: 影響を受ける UI コンポーネント ===
Pakila/CLI/App.lean
Pakila/CLI/AuthUI.lean
Pakila/CLI/Exporter.lean
Pakila/CLI/History.lean
Pakila/CLI/MemoryUI.lean
Pakila/CLI/Prompts.lean
Pakila/CLI/RewindUI.lean
Pakila/CLI/Session.lean
Pakila/CLI/SettingsUI.lean
Pakila/CLI/Terminal.lean
Pakila/CLI/TerminalBase.lean

=== 3. テストカバレッジ: 関連テスト ===
Base64Test.lean
Core
E2E
GgufTest.lean
Integration
JapaneseTokenizerTest.lean
MainLoopGapsTest.lean
Native
ParallelTest.lean
PortabilityTest.lean
RagGapsTest.lean
SandboxGapsTest.lean
SmokeTest.lean
SysInfoTest.lean
TestAll.lean
TestParallel.lean
TestPersistence.lean
TokenizerTest.lean
UiInteractiveTest.lean
Util
create_mock_bert_gguf.py
mock_bert.gguf
test.wasm
test_native_embedding.lean
test_rag_integration.lean
test_sandbox_hybrid.lean
