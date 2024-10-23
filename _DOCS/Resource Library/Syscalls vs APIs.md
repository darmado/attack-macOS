
# Syscalls vs Foundation APIs 
<p>
  <span style="display: inline-block; padding: 5px 10px; background-color: #007bff; color: white; border-radius: 5px; font-size: 0.8em;">Good Stuff</span>
</p>

This document compares low-level system calls (syscalls) with their corresponding high-level Foundation APIs in macOS. The comparison is organized by category, showing how Foundation abstracts and simplifies many low-level operations.

## User Account Management

| Syscall | Description | Corresponding Foundation API | API Description |
|---------|-------------|------------------------------|-----------------|
| getpwuid() | Retrieves password file entry for a user ID. | NSFileManager with homeDirectoryForCurrentUser | Gets the home directory for the current user. |
| getpwnam() | Retrieves password file entry for a username. | NSUserDefaults | Manages user preferences in a higher-level manner. |
| setpwent() | Rewinds the password file to the beginning. | - | Not applicable; directly accessing user accounts. |
| endpwent() | Closes the password file. | - | Not applicable; directly accessing user accounts. |
| useradd() | Adds a new user to the system. | SMJobBless | Grants permissions for managing system services. |
| userdel() | Deletes a user from the system. | SMJobBless | Similar to useradd but for removing users. |

## Security

| Syscall | Description | Corresponding Foundation API | API Description |
|---------|-------------|------------------------------|-----------------|
| setuid() | Sets the user ID of the calling process. | Authorization framework | Manages permissions and user authentication. |
| setgid() | Sets the group ID of the calling process. | - | Not directly applicable; relates to user groups. |
| getuid() | Gets the effective user ID of the calling process. | NSUser | Represents the current user in a higher-level context. |
| getgid() | Gets the effective group ID of the calling process. | - | Not directly applicable; relates to user groups. |
| seteuid() | Sets the effective user ID. | - | Not directly applicable; used for privilege management. |
| setegid() | Sets the effective group ID. | - | Not directly applicable; used for privilege management. |

## Networking

| Syscall | Description | Corresponding Foundation API | API Description |
|---------|-------------|------------------------------|-----------------|
| socket() | Creates a socket for communication. | NSStream | Provides stream-based APIs for network communication. |
| connect() | Connects a socket to a remote address. | NSURLSession | Manages network requests and sessions. |
| send() | Sends data over a socket. | NSOutputStream | Facilitates sending data through network streams. |
| recv() | Receives data from a socket. | NSInputStream | Handles incoming data from network streams. |
| bind() | Binds a socket to an address. | - | Not directly available through Foundation APIs. |
| listen() | Listens for incoming connections on a socket. | - | Not directly available through Foundation APIs. |

## Inter-Process Communication

| Syscall | Description | Corresponding Foundation API | API Description |
|---------|-------------|------------------------------|-----------------|
| pipe() | Creates a unidirectional data channel (pipe). | NSPipe | Represents a pipe for inter-process communication. |
| socket() | Creates an endpoint for communication. | NSStream (with NSInputStream and NSOutputStream) | High-level interface for data streaming over sockets. |
| bind() | Associates a socket with a specific address. | CFSocket | Provides a higher-level interface for socket communication. |
| listen() | Marks a socket as a passive socket for accepting connections. | - | Not directly applicable; socket management is more abstracted. |
| accept() | Accepts a connection on a socket. | - | Not directly applicable; typically handled at a lower level. |
| send() | Sends a message on a socket. | NSStream | Provides methods to write data to a socket. |
| recv() | Receives a message from a socket. | NSInputStream | Provides methods to read data from a socket. |
| shutdown() | Shuts down part of a full-duplex connection. | - | Not directly applicable; lower-level socket operations. |
| msgget() | Creates or accesses a message queue. | dispatch_queue | Provides higher-level concurrency control. |
| msgsnd() | Sends a message to a message queue. | - | Not directly applicable; lower-level message handling. |
| msgrcv() | Receives a message from a message queue. | - | Not directly applicable; lower-level message handling. |
| shmget() | Creates or accesses a shared memory segment. | NSFileHandle with memory-mapped files | High-level interface for file handling with shared memory. |
| shmat() | Attaches a shared memory segment to the process's address space. | - | Not directly applicable; lower-level shared memory handling. |
| shmdt() | Detaches a shared memory segment from the process. | - | Not directly applicable; lower-level shared memory handling. |

