# Docker Container Veth Mapper 🐳🔗

A Bash script to map Docker containers to their corresponding virtual Ethernet (veth) interfaces on the host, providing a clear overview of running containers and their networking details.

## Features 🚀

- Lists all running Docker containers along with their:
  - Container IDs
  - Container names
  - Host veth interface names
- Validates required dependencies (`docker`, `ip`, `nsenter`, and `jq`) before execution.
- Ensures the script runs with root or sudo privileges for accurate networking details.

## Requirements ✅

Make sure the following dependencies are installed and available on your system:

- `docker`: To interact with running containers.
- `ip`: For fetching veth interface details on the host.
- `nsenter`: To access the container's network namespace.
- `jq`: For parsing JSON outputs from `ip`.

## Usage 💻

### Run the Script

1. Clone or download this repository.
2. Open a terminal and navigate to the script location.
3. Run the script with root privileges:

   ```bash
   sudo ./dockerveth.sh
   ```

### Sample Output

```plaintext
CONTAINER ID   NAME           VETH       
b3e2a1c4f8d9   web-server     veth5d2a6d
c4e9b3a7e1f8   db-container   veth2b7c3f
e1f8c4a7b3e9   redis-cache    veth3f8a7b
```

### Error Handling

- If no containers are running:
  ```plaintext
  Error: no running Docker containers found.
  ```
- If a required command is missing:
  ```plaintext
  Error: the required command 'jq' is not installed. please install it and try again.
  ```
- If the script is not run as root:
  ```plaintext
  Error: this script requires root privileges. please run it as root or use sudo.
  ```

## How It Works ⚙️

1. **Prerequisite Check**: Ensures the script runs with root privileges and validates required commands.
2. **Container Discovery**: Fetches all running containers using `docker ps`.
3. **veth Interface Mapping**:
   - Retrieves veth details from the host using `ip` and `jq`.
   - Finds the container's `veth` name by inspecting its network namespace with `nsenter`.
4. **Tabular Output**: Displays container details along with their corresponding host veth interface in a neatly formatted table.

## File Structure 📂

- **`dockerveth.sh`**: The main script that maps Docker containers to host veth interfaces.

## License 📜

This project is licensed under the MIT License.