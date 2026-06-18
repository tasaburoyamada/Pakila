=== 1. Lean: Unsafe Option/Except Unwrapping (get!) ===
Pakila/Tokenizer/Normalizer.lean:31:          bytes := bytes.push (tokenBytes.get! i)

=== 2. Lean: Try-Catch Coverage ===
Pakila/CLI/Terminal.lean:20:deriving instance Inhabited for IO.FS.DirEntry
Pakila/CLI/Terminal.lean:49:      let res ← try
Pakila/CLI/RewindUI.lean:32:  let choice ← selectOption "Select entry:" options
Pakila/CLI/Session.lean:33:  try
Pakila/CLI/Exporter.lean:25:  try
Pakila/Memory/VectorDB.lean:23:structure VectorEntry where
Pakila/Memory/VectorDB.lean:34:  entries : Array VectorEntry := #[]
Pakila/Memory/VectorDB.lean:62:def VectorDB.search (self : VectorDB) (query : Vector) (topK : Nat) (threshold : Float := 0.5) : Array (VectorEntry × Float) :=
Pakila/Memory/VectorDB.lean:63:  let scored := self.entries.filterMap (fun entry =>
Pakila/Memory/VectorDB.lean:64:    let score := cosineSimilarity query entry.vector
Pakila/Memory/VectorDB.lean:65:    if score >= threshold then some (entry, score) else none
Pakila/Memory/VectorDB.lean:74:def VectorDB.insert (self : VectorDB) (entry : VectorEntry) : VectorDB :=
Pakila/Memory/VectorDB.lean:75:  { self with entries := self.entries.push entry }
Pakila/Governance/McpManager.lean:28:  for entry in entries do
Pakila/Governance/McpManager.lean:29:    if ← entry.path.isDir then
Pakila/Governance/McpManager.lean:30:      let subConfigs ← findMcpConfigs entry.path
Pakila/Governance/McpManager.lean:32:    else if entry.fileName == "mcp_config.json" then
Pakila/Governance/McpManager.lean:33:      configs := entry.path :: configs
Pakila/Governance/SkillManager.lean:42:      for entry in entries do
Pakila/Governance/SkillManager.lean:43:        if ← entry.path.isDir then
Pakila/Governance/SkillManager.lean:44:          let skillMd := entry.path / "SKILL.md"
Pakila/Governance/SkillManager.lean:48:              name := entry.fileName,
Pakila/Governance/SkillManager.lean:61:      try
Pakila/Governance/GitManager.lean:18:  try
Pakila/Governance/GitManager.lean:26:  try
Pakila/Governance/GitManager.lean:34:  try
Pakila/Governance/GitManager.lean:46:  try
Pakila/Plugins/Bash.lean:28:    try
Pakila/Plugins/LocalLeanTensor.lean:69:    let entries ← (try modelsDir.readDir catch _ => pure #[])
Pakila/Plugins/WasmLoader.lean:11:  entryPoint : String := "main"
Pakila/Plugins/WasmLoader.lean:18:  for entry in ← dir.readDir do
Pakila/Plugins/WasmLoader.lean:19:    let path := entry.path
Pakila/Plugins/WasmLoader.lean:27:  try
Pakila/Plugins/WasmLoader.lean:28:    let res ← Pakila.wasmExecute plugin.path plugin.entryPoint
Pakila/Plugins/Sandbox.lean:39:  try
Pakila/Plugins/Sandbox.lean:48:  try
Pakila/Plugins/Sandbox.lean:61:  try
Pakila/Plugins/Sandbox.lean:86:      try return .ok (← nativeGrep pat (System.FilePath.mk (dir.getD ".")))
Pakila/Plugins/Sandbox.lean:89:      try return .ok (← TerminalEnv.readFile path)
Pakila/Plugins/Sandbox.lean:92:      try 
Pakila/Plugins/Sandbox.lean:97:      try return .ok (← nativeGlob pat (System.FilePath.mk (dir.getD ".")))
Pakila/Diagnostics/SysInfo.lean:21:  try
Pakila/Diagnostics/SysInfo.lean:39:  try
Pakila/Core/ContextLoader.lean:23:    try TerminalEnv.readFile path catch _ => pure ""
Pakila/Core/FileInjector.lean:35:  try
Pakila/Core/ResourceManager.lean:44:  try
Pakila/Core/Search.lean:19:      try
Pakila/Core/Delegator.lean:61:  try IO.FS.removeFile tempFile catch _ => pure ()
Pakila/Core/Memory.lean:26:  let newEntry : VectorEntry := { id := s!"mem_{s.history.length}", text := text, vector := { data := #[] }, metadata := metadata }
Pakila/Core/Memory.lean:27:  let newDb := s.vectorDb.insert newEntry
Pakila/Core/Environment.lean:80:    try
Pakila/Core/Environment.lean:92:    try
Pakila/Core/Environment.lean:102:    try
Pakila/MainLoop.lean:29:      try
Pakila/MainLoop.lean:35:      try
Pakila/MainLoop.lean:41:      try
Pakila/MainLoop.lean:47:      try
Pakila/Config/Loader.lean:99:  try

=== 3. Lean: Error Propagation (Except.error) ===
Pakila/CLI/Session.lean:26:    | .error e => return Except.error (AppError.SerializationError e)
Pakila/CLI/Session.lean:27:  | .error e => return Except.error (AppError.SerializationError e)
Pakila/CLI/Session.lean:37:    return Except.error (AppError.IoError (s!"{repr e}"))
Pakila/CLI/Exporter.lean:29:    return Except.error (AppError.IoError (s!"{repr e}"))
Pakila/CLI/ArgParser.lean:41:        | none => Except.error (AppError.ConfigError s!"Invalid approval mode: {m}")
Pakila/CLI/ArgParser.lean:45:        | none => Except.error (AppError.ConfigError s!"Invalid output format: {f}")
Pakila/CLI/App.lean:37:    | Except.error e => TerminalEnv.println s!"[CLI Error]: {repr e}"; return
Pakila/CLI/App.lean:57:  let config ← match (← loadConfig configPath) with | Except.ok c => pure c | Except.error _ => pure ({} : AppConfig)
Pakila/CLI/App.lean:94:    let initialDb ← match (← Pakila.Memory.VectorDB.load dbPath.toString) with | Except.ok db => pure db | Except.error e => pure ∅
Pakila/CLI/App.lean:101:      | Except.error _ => pure ()
Pakila/Governance/SkillCreator.lean:23:    return Except.error (AppError.ExecutionError s!"Skill {name} already exists at {skillFile}")
Pakila/Governance/SkillManager.lean:65:        return Except.error (AppError.IoError s!"Failed to read skill file {s.path}: {e}")
Pakila/Governance/SkillManager.lean:66:  | none => return Except.error (AppError.ToolError s!"Skill '{name}' not found.")
Pakila/Governance/GitManager.lean:22:    return Except.error (AppError.ExecutionError s!"Git checkpoint failed: {e}")
Pakila/Governance/GitManager.lean:30:    return Except.error (AppError.ExecutionError s!"Git rewind failed: {e}")
Pakila/Governance/GitManager.lean:38:    return Except.error (AppError.ExecutionError s!"Git restore failed: {e}")
Pakila/Governance/GitManager.lean:50:    return Except.error (AppError.ExecutionError s!"Git worktree creation failed: {e}")
Pakila/Governance/PolicyEngine.lean:30:                   Except.error (AppError.ExecutionError s!"Policy Violation: scope {scope} is readonly. Bash command might mutate it.")
Pakila/Governance/PolicyEngine.lean:35:                   Except.error (AppError.ExecutionError s!"Policy Violation: {path} is in readonly scope {scope}.")
Pakila/Governance/PolicyEngine.lean:40:            | .ExecuteBash _ => if tool == "execute_bash" then Except.error (.ExecutionError s!"Policy Violation: {tool} is denied.") else check rest
Pakila/Governance/PolicyEngine.lean:41:            | .RunBackground .. => if tool == "run_shell_command" then Except.error (.ExecutionError s!"Policy Violation: {tool} is denied.") else check rest
Pakila/Plugins/Bash.lean:32:      return Except.error (AppError.ExecutionError s!"Native execution failed: {e}")
Pakila/Plugins/VisionTool.lean:27:    return Except.error (AppError.IoError "Image file not found.")
Pakila/Core/Persistence.lean:24:  return Except.error (AppError.ExecutionError "loadSession: NativeEmbeddingModel serialization pending")
Pakila/Core/Persistence.lean:55:    return Except.error (AppError.IoError s!"No backup file found for {path}")
Pakila/Core/LlmManager.lean:69:  | none => return Except.error (AppError.LlmError s!"Active backend '{self.activeBackend}' not found.")
Pakila/Core/LlmManager.lean:74:  | none => return Except.error (AppError.LlmError s!"Active backend '{self.activeBackend}' not found.")
Pakila/Core/LlmManager.lean:80:    return Except.error (AppError.ConfigError s!"Backend '{name}' not registered.")
Pakila/Core/ResourceManager.lean:49:    return Except.error (AppError.IoError s!"Failed to load model {name}: {repr e}")
Pakila/Core/ResourceManager.lean:62:  | none => return Except.error (AppError.ConfigError s!"Model {name} not found.")
Pakila/Core/Delegator.lean:66:    return Except.error (AppError.ExecutionError s!"Sub-agent failed with status {status}. Stderr: {err}")
Pakila/Core/Summarizer.lean:46:  | .error e => return Except.error e
Pakila/Config/Loader.lean:103:    return Except.error (AppError.IoError s!"Failed to save config: {e}")
Main.lean:41:    | Except.error e => IO.println s!"[CLI Error]: {repr e}"; return
Main.lean:120:  let config ← match (← loadConfig configPath) with | Except.ok c => pure c | Except.error _ => pure ({} : AppConfig)
Main.lean:163:      | Except.error e => IO.println s!"✖ Failed: {repr e}"; return
Main.lean:168:      | Except.error e => IO.println s!"[Memory Warning]: {e}"; pure ∅
Main.lean:177:      | Except.error e => IO.println s!"[Embedding Warning]: Failed to load BERT: {repr e}"

=== 4. C: Return Value & NULL Checks (kernels.c) ===
87:    if (!handle) return 0;
105:    if (!isatty(STDIN_FILENO)) {
109:    if (tcgetattr(STDIN_FILENO, &orig_termios) == -1) {
121:    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
130:    if (!raw_mode_enabled) return lean_io_result_mk_ok(lean_box(0));
132:    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios) == -1) {
144:    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == -1) {
179:    if (pipe(pipe_out) == -1) {
240:    if (pipe(pipe_out) == -1) {
249:        if (unshare(CLONE_NEWNS | CLONE_NEWPID) == -1) {
300:    if (!handle && fallback) {
321:    if (!handle) handle = find_and_dlopen("libpython3.so", NULL);
322:    if (!handle) return lean_io_result_mk_ok(lean_mk_string("Error: Cannot load libpython"));
328:    if (!Py_Initialize || !PyRun_SimpleString || !Py_Finalize) {
348:    if (!handle) handle = find_and_dlopen("libcurl.so", NULL);
349:    if (!handle) return lean_io_result_mk_ok(lean_mk_string("Error: Cannot load libcurl"));
356:    if (!curl_easy_init || !curl_easy_setopt || !curl_easy_perform || !curl_easy_cleanup) {
362:    if (!curl) {
368:    if (!temp) {
414:    if (!f) return lean_io_result_mk_ok(lean_mk_string("Error: Cannot open WASM file"));
460:    if (!found || func_extern.kind != WASMTIME_EXTERN_FUNC) {

=== 5. C: Memory Management Safety (malloc/realloc) ===
171:    char** argv = malloc(sizeof(char*) * (args_size + 2));
203:            out_buf = realloc(out_buf, total_size + n + 1);
231:    char** argv = malloc(sizeof(char*) * (args_size + 2));
267:            out_buf = realloc(out_buf, total_size + n + 1);
390:    char* buffer = malloc(size + 1);
