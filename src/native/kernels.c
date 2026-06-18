#define _GNU_SOURCE
#include <stdint.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <dlfcn.h>
#include <sched.h>
#include <sys/mount.h>
#include <signal.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <unistd.h>
#include <lean/lean.h>
#include "wasmtime.h"

/*
 * Pakila Native Kernels - Portable Version
 * Optimizing for current hardware (No AVX-512).
 * Mandate: Mathematical correctness and physical stability.
 */

LEAN_EXPORT uint8_t lean_cpu_has_avx512() { return 0; }

LEAN_EXPORT double lean_dot_product_native(lean_obj_arg a_arr, lean_obj_arg b_arr) {
    const double* A = lean_float_array_cptr(a_arr);
    const double* B = lean_float_array_cptr(b_arr);
    uint64_t n = lean_sarray_size(a_arr);
    double dot = 0.0;
    for (uint64_t i = 0; i < n; i++) {
        dot += A[i] * B[i];
    }
    return dot;
}

LEAN_EXPORT double lean_norm_native(lean_obj_arg a_arr) {
    const double* A = lean_float_array_cptr(a_arr);
    uint64_t n = lean_sarray_size(a_arr);
    double norm_sq = 0.0;
    for (uint64_t i = 0; i < n; i++) {
        norm_sq += A[i] * A[i];
    }
    return sqrt(norm_sq);
}

typedef struct {
    float d;       
    int8_t qs[32]; 
} block_q8_0;

LEAN_EXPORT double lean_dot_product_q8_0_native(lean_obj_arg a_obj, lean_obj_arg b_obj) {
    const block_q8_0* A = (const block_q8_0*)lean_sarray_cptr(a_obj);
    const block_q8_0* B = (const block_q8_0*)lean_sarray_cptr(b_obj);
    size_t n_blocks = lean_sarray_size(a_obj) / sizeof(block_q8_0);
    
    double total_sum = 0.0;
    for (size_t i = 0; i < n_blocks; i++) {
        double block_sum = 0;
        for (int j = 0; j < 32; j++) {
            block_sum += (double)A[i].qs[j] * (double)B[i].qs[j];
        }
        total_sum += block_sum * (double)(A[i].d * B[i].d);
    }
    return total_sum;
}

LEAN_EXPORT lean_obj_res lean_matmul_native(lean_obj_arg a_arr, lean_obj_arg b_arr, uint64_t m, uint64_t k, uint64_t n) {
    const double* A = lean_float_array_cptr(a_arr);
    const double* B = lean_float_array_cptr(b_arr);
    lean_object* res_arr = lean_mk_empty_float_array(lean_box(m * n));
    for (uint64_t i = 0; i < m * n; i++) lean_float_array_push(res_arr, 0.0);
    double* out = (double*)lean_float_array_cptr(res_arr);

    for (uint64_t i = 0; i < m; i++) {
        for (uint64_t l = 0; l < k; l++) {
            double va = A[i * k + l];
            for (uint64_t j = 0; j < n; j++) {
                out[i * n + j] += va * B[l * n + j];
            }
        }
    }
    return res_arr;
}

LEAN_EXPORT uint64_t lean_load_model_native(lean_obj_arg path_obj) {
    const char* path = lean_string_cstr(path_obj);
    void* handle = dlopen(path, RTLD_LAZY);
    if (!handle) return 0;
    return (uint64_t)handle;
}

LEAN_EXPORT void lean_unload_model_native(uint64_t addr) {
    void* handle = (void*)addr;
    if (handle) dlclose(handle);
}

#include <termios.h>
#include <unistd.h>

static struct termios orig_termios;
static int raw_mode_enabled = 0;

LEAN_EXPORT lean_obj_res lean_get_char(uint8_t dummy) {
    uint8_t c;
    ssize_t n = read(STDIN_FILENO, &c, 1);
    if (n <= 0) return lean_io_result_mk_ok(lean_box(0));
    return lean_io_result_mk_ok(lean_box(c));
}

LEAN_EXPORT lean_obj_res lean_enable_raw_mode(uint8_t dummy) {
    if (raw_mode_enabled) return lean_io_result_mk_ok(lean_box(0)); // Already enabled
    
    if (!isatty(STDIN_FILENO)) {
        return lean_io_result_mk_error(lean_mk_string("Not a TTY"));
    }

    if (tcgetattr(STDIN_FILENO, &orig_termios) == -1) {
        return lean_io_result_mk_error(lean_mk_string("tcgetattr failed"));
    }

    struct termios raw = orig_termios;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= ~(OPOST);
    raw.c_cflag |= (CS8);
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_cc[VMIN] = 1;
    raw.c_cc[VTIME] = 0;

    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) == -1) {
        return lean_io_result_mk_error(lean_mk_string("tcsetattr failed"));
    }

    raw_mode_enabled = 1;
    return lean_io_result_mk_ok(lean_box(1)); // Return 1 (true) for success
}

LEAN_EXPORT lean_obj_res lean_disable_raw_mode(uint8_t dummy) {
    if (!raw_mode_enabled) return lean_io_result_mk_ok(lean_box(0));

    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &orig_termios) == -1) {
        return lean_io_result_mk_error(lean_mk_string("tcsetattr failed to restore"));
    }

    raw_mode_enabled = 0;
    return lean_io_result_mk_ok(lean_box(0));
}

#include <sys/ioctl.h>

LEAN_EXPORT lean_obj_res lean_get_terminal_size(uint8_t dummy) {
    struct winsize w;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == -1) {
        // Fallback to 80x24
        lean_object* res = lean_alloc_ctor(0, 2, 0);
        lean_ctor_set(res, 0, lean_box(80));
        lean_ctor_set(res, 1, lean_box(24));
        return lean_io_result_mk_ok(res);
    }
    lean_object* res = lean_alloc_ctor(0, 2, 0);
    lean_ctor_set(res, 0, lean_box(w.ws_col));
    lean_ctor_set(res, 1, lean_box(w.ws_row));
    return lean_io_result_mk_ok(res);
}

#include <signal.h>
#include <sys/wait.h>
#include <stdlib.h>

static pid_t child_pid = 0;
void handle_alarm(int sig) {
    if (child_pid > 0) {
        kill(child_pid, SIGKILL);
    }
}

LEAN_EXPORT lean_obj_res lean_spawn_with_timeout(lean_obj_arg cmd_obj, lean_obj_arg args_obj, uint32_t timeout_sec) {
    const char* cmd = lean_string_cstr(cmd_obj);
    size_t args_size = lean_array_size(args_obj);
    char** argv = malloc(sizeof(char*) * (args_size + 2));
    if (!argv) return lean_io_result_mk_error(lean_mk_string("Memory allocation failed (argv)"));
    
    argv[0] = (char*)cmd;
    for (size_t i = 0; i < args_size; i++) {
        argv[i+1] = (char*)lean_string_cstr(lean_array_get_core(args_obj, i));
    }
    argv[args_size + 1] = NULL;

    int pipe_out[2];
    if (pipe(pipe_out) == -1) {
        free(argv);
        return lean_io_result_mk_error(lean_mk_string("Pipe failed"));
    }

    signal(SIGALRM, handle_alarm);
    alarm(timeout_sec);

    child_pid = fork();
    if (child_pid == 0) {
        // Child
        close(pipe_out[0]);
        dup2(pipe_out[1], STDOUT_FILENO);
        dup2(pipe_out[1], STDERR_FILENO);
        execvp(cmd, argv);
        exit(1);
    } else if (child_pid > 0) {
        // Parent
        close(pipe_out[1]);
        char buffer[4096];
        size_t total_size = 0;
        char* out_buf = NULL;
        ssize_t n;
        while ((n = read(pipe_out[0], buffer, sizeof(buffer))) > 0) {
            char* next_buf = realloc(out_buf, total_size + n + 1);
            if (!next_buf) {
                if (out_buf) free(out_buf);
                close(pipe_out[0]);
                free(argv);
                return lean_io_result_mk_error(lean_mk_string("Memory reallocation failed (out_buf)"));
            }
            out_buf = next_buf;
            memcpy(out_buf + total_size, buffer, n);
            total_size += n;
        }
        close(pipe_out[0]);
        if (out_buf) out_buf[total_size] = '\0';
        
        int status;
        waitpid(child_pid, &status, 0);
        alarm(0); // Cancel alarm
        child_pid = 0;
        
        lean_object* res_str = lean_mk_string(out_buf ? out_buf : "");
        if (out_buf) free(out_buf);
        free(argv);
        return lean_io_result_mk_ok(res_str);
    } else {
        close(pipe_out[0]);
        close(pipe_out[1]);
        free(argv);
        return lean_io_result_mk_error(lean_mk_string("Fork failed"));
    }
}

#define _GNU_SOURCE
#include <sched.h>
#include <sys/mount.h>

LEAN_EXPORT lean_obj_res lean_unshare_execute(lean_obj_arg cmd_obj, lean_obj_arg args_obj) {
    const char* cmd = lean_string_cstr(cmd_obj);
    size_t args_size = lean_array_size(args_obj);
    char** argv = malloc(sizeof(char*) * (args_size + 2));
    if (!argv) return lean_io_result_mk_error(lean_mk_string("Memory allocation failed (argv)"));
    
    argv[0] = (char*)cmd;
    for (size_t i = 0; i < args_size; i++) {
        argv[i+1] = (char*)lean_string_cstr(lean_array_get_core(args_obj, i));
    }
    argv[args_size + 1] = NULL;

    // Create pipe for capturing output
    int pipe_out[2];
    if (pipe(pipe_out) == -1) {
        free(argv);
        return lean_io_result_mk_error(lean_mk_string("Pipe failed"));
    }

    pid_t pid = fork();
    if (pid == 0) {
        // Child: Apply isolation
        // CLONE_NEWUSER is required for unprivileged unshare of other namespaces
        if (unshare(CLONE_NEWUSER | CLONE_NEWNS | CLONE_NEWPID) == -1) {
            perror("unshare failed");
            exit(1);
        }
        
        close(pipe_out[0]);
        dup2(pipe_out[1], STDOUT_FILENO);
        dup2(pipe_out[1], STDERR_FILENO);
        
        execvp(cmd, argv);
        exit(1);
    } else if (pid > 0) {
        // Parent
        close(pipe_out[1]);
        char buffer[4096];
        size_t total_size = 0;
        char* out_buf = NULL;
        ssize_t n;
        while ((n = read(pipe_out[0], buffer, sizeof(buffer))) > 0) {
            char* next_buf = realloc(out_buf, total_size + n + 1);
            if (!next_buf) {
                if (out_buf) free(out_buf);
                close(pipe_out[0]);
                free(argv);
                return lean_io_result_mk_error(lean_mk_string("Memory reallocation failed (out_buf)"));
            }
            out_buf = next_buf;
            memcpy(out_buf + total_size, buffer, n);
            total_size += n;
        }
        close(pipe_out[0]);
        if (out_buf) out_buf[total_size] = '\0';
        
        int status;
        waitpid(pid, &status, 0);
        
        lean_object* res_str = lean_mk_string(out_buf ? out_buf : "");
        if (out_buf) free(out_buf);
        free(argv);
        return lean_io_result_mk_ok(res_str);
    } else {
        close(pipe_out[0]);
        close(pipe_out[1]);
        free(argv);
        return lean_io_result_mk_error(lean_mk_string("Fork failed"));
    }
}

LEAN_EXPORT lean_obj_res lean_get_executable_path(uint8_t dummy) {
    char path[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", path, sizeof(path) - 1);
    if (len != -1) {
        path[len] = '\0';
        return lean_io_result_mk_ok(lean_mk_string(path));
    }
    return lean_io_result_mk_error(lean_mk_string("Failed to get executable path"));
}

#include <pwd.h>

static void* find_and_dlopen(const char* libname, const char* fallback) {
    void* handle = dlopen(libname, RTLD_LAZY);
    if (!handle && fallback) {
        handle = dlopen(fallback, RTLD_LAZY);
    }
    return handle;
}

LEAN_EXPORT lean_obj_res lean_get_home_directory(uint8_t dummy) {
    struct passwd *pw = getpwuid(getuid());
    if (pw) {
        return lean_io_result_mk_ok(lean_mk_string(pw->pw_dir));
    }
    return lean_io_result_mk_error(lean_mk_string("Failed to get home directory"));
}

/*
 * FFI Extensions: Python & HTTP (Curl) Dynamic Loading
 */

LEAN_EXPORT lean_obj_res lean_python_execute(lean_obj_arg script_obj) {
    const char* script = lean_string_cstr(script_obj);
    void* handle = find_and_dlopen("libpython3.10.so.1.0", "/usr/lib/x86_64-linux-gnu/libpython3.10.so.1.0");
    if (!handle) handle = find_and_dlopen("libpython3.so", NULL);
    if (!handle) return lean_io_result_mk_ok(lean_mk_string("Error: Cannot load libpython"));
    
    void (*Py_Initialize)(void) = dlsym(handle, "Py_Initialize");
    int (*PyRun_SimpleString)(const char*) = dlsym(handle, "PyRun_SimpleString");
    void (*Py_Finalize)(void) = dlsym(handle, "Py_Finalize");
    
    if (!Py_Initialize || !PyRun_SimpleString || !Py_Finalize) {
        dlclose(handle);
        return lean_io_result_mk_ok(lean_mk_string("Error: Cannot find Python symbols"));
    }
    
    Py_Initialize();
    int res = PyRun_SimpleString(script);
    Py_Finalize();
    dlclose(handle);
    
    if (res == 0) {
        return lean_io_result_mk_ok(lean_mk_string("Python execution succeeded"));
    } else {
        return lean_io_result_mk_ok(lean_mk_string("Python execution failed"));
    }
}

LEAN_EXPORT lean_obj_res lean_curl_execute(lean_obj_arg url_obj) {
    const char* url = lean_string_cstr(url_obj);
    void* handle = find_and_dlopen("libcurl.so.4", "/usr/lib/x86_64-linux-gnu/libcurl.so.4");
    if (!handle) handle = find_and_dlopen("libcurl.so", NULL);
    if (!handle) return lean_io_result_mk_ok(lean_mk_string("Error: Cannot load libcurl"));
    
    void* (*curl_easy_init)(void) = dlsym(handle, "curl_easy_init");
    int (*curl_easy_setopt)(void*, int, ...) = dlsym(handle, "curl_easy_setopt");
    int (*curl_easy_perform)(void*) = dlsym(handle, "curl_easy_perform");
    void (*curl_easy_cleanup)(void*) = dlsym(handle, "curl_easy_cleanup");
    
    if (!curl_easy_init || !curl_easy_setopt || !curl_easy_perform || !curl_easy_cleanup) {
        dlclose(handle);
        return lean_io_result_mk_ok(lean_mk_string("Error: Cannot find Curl symbols"));
    }
    
    void* curl = curl_easy_init();
    if (!curl) {
        dlclose(handle);
        return lean_io_result_mk_ok(lean_mk_string("Error: curl_easy_init failed"));
    }
    
    FILE* temp = tmpfile();
    if (!temp) {
        curl_easy_cleanup(curl);
        dlclose(handle);
        return lean_io_result_mk_ok(lean_mk_string("Error: tmpfile failed"));
    }
    
    curl_easy_setopt(curl, 10002, url); // CURLOPT_URL = 10002
    curl_easy_setopt(curl, 10001, temp); // CURLOPT_WRITEDATA = 10001
    
    int res = curl_easy_perform(curl);
    curl_easy_cleanup(curl);
    dlclose(handle);
    
    if (res != 0) {
        fclose(temp);
        return lean_io_result_mk_ok(lean_mk_string("Error: curl_easy_perform failed"));
    }
    
    fseek(temp, 0, SEEK_END);
    long size = ftell(temp);
    fseek(temp, 0, SEEK_SET);
    
    char* buffer = malloc(size + 1);
    if (!buffer) {
        fclose(temp);
        return lean_io_result_mk_error(lean_mk_string("Memory allocation failed (curl buffer)"));
    }
    
    if (fread(buffer, 1, size, temp) != (size_t)size) {
        free(buffer);
        fclose(temp);
        return lean_io_result_mk_error(lean_mk_string("Failed to read all data from temp file"));
    }
    buffer[size] = '\0';
    fclose(temp);
    
    lean_object* res_str = lean_mk_string(buffer);
    free(buffer);
    return lean_io_result_mk_ok(res_str);
}

LEAN_EXPORT lean_obj_res lean_decode_f32_native(lean_obj_arg bytes_obj, uint64_t count) {
    const float* src = (const float*)lean_sarray_cptr(bytes_obj);
    lean_object* res_arr = lean_mk_empty_float_array(lean_box(count));
    for (uint64_t i = 0; i < count; i++) {
        lean_float_array_push(res_arr, (double)src[i]);
    }
    return res_arr;
}

typedef struct {
    float d;
    uint8_t qs[16];
} block_q4_0;

LEAN_EXPORT lean_obj_res lean_decode_q4_0_native(lean_obj_arg bytes_obj, uint64_t count) {
    const block_q4_0* src = (const block_q4_0*)lean_sarray_cptr(bytes_obj);
    lean_object* res_arr = lean_mk_empty_float_array(lean_box(count));
    
    uint64_t decoded = 0;
    for (uint64_t i = 0; decoded < count; i++) {
        float d = src[i].d;
        for (int j = 0; j < 16 && decoded < count; j++) {
            uint8_t b = src[i].qs[j];
            float v1 = (float)(b & 0x0F) - 8.0f;
            float v2 = (float)(b >> 4) - 8.0f;
            lean_float_array_push(res_arr, (double)(v1 * d));
            decoded++;
            if (decoded < count) {
                lean_float_array_push(res_arr, (double)(v2 * d));
                decoded++;
            }
        }
    }
    return res_arr;
}

LEAN_EXPORT lean_obj_res lean_wasm_execute(lean_obj_arg module_path_obj, lean_obj_arg func_name_obj) {
    const char* module_path = lean_string_cstr(module_path_obj);
    const char* func_name = lean_string_cstr(func_name_obj);
    printf("[WASM] Loading module from: %s\n", module_path);

    wasm_engine_t* engine = wasm_engine_new();
    printf("[WASM] Engine created\n");
    wasmtime_store_t* store = wasmtime_store_new(engine, NULL, NULL);
    printf("[WASM] Store created\n");
    wasmtime_context_t* context = wasmtime_store_context(store);

    FILE* f = fopen(module_path, "rb");
    if (!f) return lean_io_result_mk_ok(lean_mk_string("Error: Cannot open WASM file"));
    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    fseek(f, 0, SEEK_SET);
    wasm_byte_vec_t binary;
    wasm_byte_vec_new_uninitialized(&binary, size);
    if (fread(binary.data, size, 1, f) != 1) {
        fclose(f);
        wasm_byte_vec_delete(&binary);
        wasmtime_store_delete(store);
        wasm_engine_delete(engine);
        return lean_io_result_mk_ok(lean_mk_string("Error: Failed to read WASM file"));
    }
    fclose(f);
    printf("[WASM] File read: %zu bytes\n", size);

    wasmtime_module_t* module = NULL;
    wasmtime_error_t* error = wasmtime_module_new(engine, (uint8_t*)binary.data, binary.size, &module);
    wasm_byte_vec_delete(&binary);

    if (error) {
        printf("[WASM] Compilation error\n");
        wasmtime_store_delete(store);
        wasm_engine_delete(engine);
        return lean_io_result_mk_ok(lean_mk_string("Error: Failed to compile WASM module"));
    }
    printf("[WASM] Module compiled\n");

    wasmtime_instance_t instance;
    wasm_trap_t* trap = NULL;
    error = wasmtime_instance_new(context, module, NULL, 0, &instance, &trap);
    
    if (error || trap) {
        printf("[WASM] Instantiation error\n");
        if (error) wasmtime_error_delete(error);
        if (trap) wasm_trap_delete(trap);
        wasmtime_module_delete(module);
        wasmtime_store_delete(store);
        wasm_engine_delete(engine);
        return lean_io_result_mk_ok(lean_mk_string("Error: Failed to instantiate WASM module"));
    }
    printf("[WASM] Instance created\n");

    wasmtime_extern_t func_extern;
    bool found = wasmtime_instance_export_get(context, &instance, func_name, strlen(func_name), &func_extern);
    
    if (!found || func_extern.kind != WASMTIME_EXTERN_FUNC) {
        printf("[WASM] Export not found: %s\n", func_name);
        wasmtime_module_delete(module);
        wasmtime_store_delete(store);
        wasm_engine_delete(engine);
        return lean_io_result_mk_ok(lean_mk_string("Error: Exported function not found"));
    }
    printf("[WASM] Function found: %s\n", func_name);

    wasmtime_val_t results[1];
    printf("[WASM] Calling function...\n");
    error = wasmtime_func_call(context, &func_extern.of.func, NULL, 0, results, 0, &trap);

    if (error || trap) {
        printf("[WASM] Execution error/trap\n");
        if (error) wasmtime_error_delete(error);
        if (trap) wasm_trap_delete(trap);
        wasmtime_module_delete(module);
        wasmtime_store_delete(store);
        wasm_engine_delete(engine);
        return lean_io_result_mk_ok(lean_mk_string("Error: WASM execution trap/error"));
    }
    printf("[WASM] Function call complete\n");

    wasmtime_module_delete(module);
    wasmtime_store_delete(store);
    wasm_engine_delete(engine);

    return lean_io_result_mk_ok(lean_mk_string("WASM Execution Successful (Void)"));
}
