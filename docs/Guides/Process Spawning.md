# Process Spawning System

## Overview
The process spawning system provides functionality to execute script logic in background processes using named pipes for inter-process communication. This system spawns child processes and manages their lifecycle through PID tracking.

## Core Functions

### `memory_spawn_isolated()`
**Purpose:** Spawn background process using memory buffer communication  
**Type:** Core utility function  
**Languages:** Shell  

**Description:**
Creates background processes with named pipe communication channels. Despite the "isolated" name (legacy), this function explicitly spawns child processes and tracks their PIDs.

**Inputs:**
- `$1` - Buffer name (unique identifier)  
- `$2` - Command to execute in background process

**Outputs:**
- Returns 0 on success, 1 on error
- Creates background process with tracked PID
- Establishes named pipe communication

**Process Flow:**
1. Creates named pipe for process communication
2. Spawns background process using `eval "$command" 2>&1 > "${pipe_path}" &`
3. Captures and stores process PID: `local proc_pid=$!`
4. Writes PID to tracking file: `echo "$proc_pid" > "${pipe_path}.pid"`

**Example Usage:**
```bash
# Spawn background process
memory_spawn_isolated "worker_001" "security find-generic-password -g"

# Process runs in background with tracked PID
```

### `memory_create_buffer()`
**Purpose:** Create named pipe for inter-process communication  
**Type:** Core utility function  
**Languages:** Shell  

**Description:**
Creates named pipes (FIFOs) in `/tmp/mem_${JOB_ID}/` directory for communication between parent and spawned processes.

**Inputs:**
- `$1` - Buffer name (unique identifier)

**Outputs:**
- Returns 0 on success, 1 on error
- Creates named pipe at specified path

**Example Usage:**
```bash
# Create communication buffer
memory_create_buffer "main_worker"
# Creates: /tmp/mem_${JOB_ID}/main_worker.pipe
```

### `memory_read_buffer()`
**Purpose:** Read data from spawned process via named pipe  
**Type:** Core utility function  
**Languages:** Shell  

**Description:**
Reads output from background processes through named pipe communication with timeout handling.

**Inputs:**
- `$1` - Buffer name to read from

**Outputs:**
- Process output to stdout
- Returns 0 on success, 1 on error

**Example Usage:**
```bash
# Read from spawned process
result=$(memory_read_buffer "worker_001_proc")
echo "$result"
```

### `memory_cleanup_buffer()`
**Purpose:** Terminate spawned processes and cleanup resources  
**Type:** Core utility function  
**Languages:** Shell  

**Description:**
Kills tracked background processes and removes named pipes and PID files.

**Inputs:**
- `$1` - Buffer name to cleanup

**Process Flow:**
1. Reads PID from tracking file
2. Terminates process: `kill "$pid"`
3. Removes named pipe and PID files
4. Cleans up both main and process-specific buffers

**Example Usage:**
```bash
# Cleanup spawned processes
memory_cleanup_buffer "worker_001"
memory_cleanup_buffer "worker_001_proc"
```

## Command Line Interface

### `--spawn` Flag
**Purpose:** Enable background process spawning mode  
**Type:** Execution control flag  

**Description:**
When enabled, executes main script logic in background processes instead of the current process. Uses named pipe communication to retrieve results.

**Usage:**
```bash
./script.sh --spawn [other options]
```

**Behavior:**
1. Creates process spawning environment
2. Spawns `core_execute_main_logic` in background process
3. Reads results via named pipe communication
4. Cleans up spawned processes and resources

## Architecture

### Process Structure
```
Parent Process (main script)
├── Creates named pipes in /tmp/mem_${JOB_ID}/
├── Spawns background process via eval & 
├── Tracks child PID in .pid files
├── Communicates via named pipes
└── Cleanup: kills PIDs, removes pipes
```

### File System Layout
```
/tmp/mem_${JOB_ID}/
├── buffer_name.pipe          # Main communication pipe
├── buffer_name_proc.pipe     # Process-specific pipe  
├── buffer_name.pipe.pid      # Main process PID
└── buffer_name_proc.pipe.pid # Background process PID
```

## Implementation Details

### Process Spawning Method
The system uses shell background process spawning:
```bash
(
    eval "$command" 2>&1 > "${pipe_path}" &
) &
local proc_pid=$!  # Capture spawned process PID
```

### PID Tracking
Each spawned process has its PID stored for lifecycle management:
```bash
echo "$proc_pid" > "${pipe_path}.pid"
```

### Communication Protocol
- Named pipes (FIFOs) for inter-process communication
- Timeout-based reads to prevent hanging
- Background process output redirected to pipes

## Use Cases

### Parallel Execution
Execute multiple security functions in parallel background processes.

### Process Isolation
Separate script logic into distinct processes for better resource management.

### Asynchronous Operations
Allow long-running commands to execute without blocking main process.

## Error Handling

### Process Failure
- Checks process existence with `kill -0 "$pid"`
- Automatic cleanup on failure
- Fallback to synchronous execution

### Resource Cleanup
- Emergency cleanup function: `memory_cleanup_all()`
- Automatic PID termination on exit
- Named pipe removal

## Security Considerations

### File Permissions
- Named pipes created in `/tmp/` with standard permissions
- PID files contain process identifiers
- Cleanup prevents resource leaks

### Process Visibility
- Background processes visible in process tree
- PID tracking enables process monitoring
- Named pipes discoverable in filesystem

## Legacy Notes

The function names contain "isolated" for historical reasons, but the system actually:
- **DOES** spawn child processes
- **DOES** track PIDs  
- **DOES** create background processes
- **USES** named pipes for communication

This is a process spawning system, not a memory isolation system. 