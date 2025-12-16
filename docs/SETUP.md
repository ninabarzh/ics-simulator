# Setup Guide - UU Power & Light ICS Simulator

Complete installation instructions for running the Unseen University Power & Light turbine simulator and attack demonstrations.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Simulator](#running-the-simulator)
- [Running Attack Scripts](#running-attack-scripts)
- [Network Configuration](#network-configuration)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software

Python 3.8 or higher
```bash
# Check your Python version
python3 --version

# Should output: Python 3.8.x or higher
```

pip (Python package manager)
```bash
# Check if pip is installed
python3 -m pip --version
```

### Operating System Support

- ✅ Linux (Ubuntu, Debian, Fedora, Arch) - Recommended
- ✅ macOS (10.15+, Intel or Apple Silicon)
- ✅ Windows (10/11 with Python installed)

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/yourusername/ics-simulator.git
cd ics-simulator
```

### Step 2: Create Virtual Environment (Recommended)

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
# On Linux/macOS:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### Step 3: Install Dependencies

```bash
# Install required packages
pip install -r requirements.txt
```

requirements.txt contents:
```
pymodbus==3.11.4
paramiko>=3.0.0
requests>=2.28.0
dnspython>=2.3.0
```

Optional dependencies (for advanced demos):
```bash
# For historian database simulation
pip install pyodbc>=4.0.39

# For Allen-Bradley PLC extraction
pip install pycomm3>=1.2.0
```

### Step 4: Verify Installation

```bash
# Test that pymodbus is installed correctly
python3 -c "import pymodbus; print('pymodbus version:', pymodbus.__version__)"

# Should output: pymodbus version: 3.11.4
```

## Running the Simulator

### Basic Usage

Terminal 1: Start the Turbine Simulator
```bash
python3 simulator/turbine_simulator.py
```

Expected output:
```
[*] UU P&L Turbine PLC simulator running
[*] Listening on 0.0.0.0:502
```

The simulator is now running and waiting for Modbus connections.

### Port Permissions

Port 502 requires elevated privileges on most systems:

#### Option 1: Run with sudo (Linux/macOS)
```bash
sudo python3 simulator/turbine_simulator.py
```

#### Option 2: Use a non-privileged port
Edit `turbine_simulator.py` to use port 5020 instead:

```
StartTcpServer(
    context=context,
    address=("0.0.0.0", 5020),  # Changed from 502
)
```

Then update attack scripts to use port 5020:

```
CONFIG = {
    'plc': {
        'ip': '127.0.0.1',
        'port': 5020  # Changed from 502
    }
}
```

#### Option 3: Grant Python port binding capability (Linux only)

```bash
# Allow Python to bind to privileged ports
sudo setcap 'cap_net_bind_service=+ep' $(which python3)

# Now you can run without sudo
python3 simulator/turbine_simulator.py
```

### Multiple Simulators

To simulate multiple turbines, run multiple instances on different ports:

Terminal 1:
```bash
python3 simulator/turbine_simulator.py 502
```

Terminal 2:
```bash
python3 simulator/turbine_simulator.py 5020
```

Terminal 3:
```bash
python3 simulator/turbine_simulator.py 5021
```

## Running Attack Scripts

### Basic Reconnaissance

Terminal 2 (while simulator runs in Terminal 1):
```bash
python3 exploitation/turbine_reconnaissance.py
```

This performs read-only reconnaissance, gathering:
- Current speed setpoints
- Temperature alarm thresholds
- Emergency stop status
- Current operational values

### Testing Different Attacks

```bash
# Emergency stop attack (immediate shutdown)
python3 exploitation/turbine_emergency_stop.py

# Gradual overspeed attack (stealthy manipulation)
python3 exploitation/turbine_overspeed_attack.py

# Anomaly detection bypass
python3 exploitation/anomaly_bypass_test.py

# Multi-stage attack chain (SIEM correlation test)
python3 exploitation/siem_correlation_test.py
```

### Data Exfiltration Demos

```bash
# Covert exfiltration techniques
python3 exfiltration/covert_exfiltration.py

# Historian data theft (simulated)
python3 exfiltration/historian_exfiltration.py

# PLC logic extraction (simulated)
python3 exfiltration/plc_logic_extraction.py
```

### Configuration Analysis

```bash
# Analyze ladder logic configurations
python3 analysis/ladder_logic_analysis.py
```

## Network Configuration

### Local Testing (Default)

All scripts default to `127.0.0.1` (localhost):
```python
CONFIG = {
    'plc': {
        'ip': '127.0.0.1',
        'port': 502
    }
}
```

This is perfect for learning and testing on a single machine.

### Multi-Machine Testing

To test across multiple machines on a network:

1. Configure the simulator to listen on all interfaces:

```
# turbine_simulator.py already listens on 0.0.0.0
StartTcpServer(
    context=context,
    address=("0.0.0.0", 502),  # Listens on all interfaces
)
```

2. Update attack scripts with the simulator's IP:

```python
CONFIG = {
    'plc': {
        'ip': '192.168.1.100',  # IP of machine running simulator
        'port': 502
    }
}
```

3. Configure firewall to allow connections:

```bash
# On simulator machine (Linux)
sudo ufw allow from 192.168.1.0/24 to any port 502

# Or allow specific IP
sudo ufw allow from 192.168.1.50 to any port 502
```

### Docker/VM Configuration

Running in Docker or VMs:

Docker:
```bash
# Map port 502
docker run -it -p 502:502 python:3.10 bash
```

VirtualBox:
- Use Bridged Network mode for cross-machine testing
- Use NAT with Port Forwarding for localhost testing:
  - Guest port 502 → Host port 502

VMware:
- Use Bridged mode for network testing
- Use NAT mode for localhost testing

## Troubleshooting

### "Permission denied" on port 502

Problem: Cannot bind to port 502 without root privileges

Solution 1: Run with sudo
```bash
sudo python3 simulator/turbine_simulator.py
```

Solution 2: Use non-privileged port (5020)
```bash
# Edit simulator and attack scripts to use port 5020
```

Solution 3: Grant capability (Linux)
```bash
sudo setcap 'cap_net_bind_service=+ep' $(which python3)
```

### "Connection refused" when running attacks

Problem: Simulator is not running or not accessible

Checklist:
1. ✅ Is the simulator running?
   ```bash
   ps aux | grep turbine_simulator
   ```

2. ✅ Is it listening on the correct port?
   ```bash
   netstat -tuln | grep 502
   # or
   ss -tuln | grep 502
   ```

3. ✅ Is firewall blocking connections?
   ```bash
   # Check firewall status (Linux)
   sudo ufw status
   
   # Allow Modbus traffic
   sudo ufw allow 502/tcp
   ```

4. ✅ Are you using the correct IP address?
   ```bash
   # For local testing, use:
   127.0.0.1
   
   # For network testing, find simulator IP:
   ip addr show  # Linux
   ifconfig      # macOS
   ipconfig      # Windows
   ```

### "ModuleNotFoundError: No module named 'pymodbus'"

Problem: Dependencies not installed

Solution: 

```bash
# Activate virtual environment if you created one
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Verify installation
python3 -c "import pymodbus; print(pymodbus.__version__)"
```

### Scripts fail with "Unresolved attribute reference"

Problem: IDE warnings about pymodbus 3.x API changes

Solution: These are just IDE warnings, not actual errors. The code runs correctly. To suppress:
- Ignore the warnings (code works fine)
- Add type hints to satisfy the IDE
- Disable specific inspections in your IDE

### Attacks don't seem to work

Problem: Simulator not responding or values not changing

Checklist:
1. ✅ Check simulator output for connection logs
2. ✅ Verify register addresses match:
   - Speed setpoint: register 1000
   - Temperature alarm: register 1050
   - E-stop: register 1100
3. ✅ Check if writes are successful (look for error messages)
4. ✅ Read back values to verify changes

Debug mode:
```python
# Add debug logging to attack scripts
import logging
logging.basicConfig(level=logging.DEBUG)
```

### Exfiltration scripts fail

Problem: Network tools not installed or unreachable

Expected behavior: Most exfiltration scripts are simulations:
- DNS exfiltration expects to fail (no attacker DNS server)
- HTTPS upload expects to fail (no attacker web server)
- Historian extraction expects to fail (no database)

These scripts demonstrate what would happen in a real attack, not actual data theft.

### Port already in use

Problem: Another process is using port 502

Find what's using the port:

```bash
# Linux/macOS
sudo lsof -i :502
sudo netstat -tulpn | grep 502

# Windows
netstat -ano | findstr :502
```

Solutions:

- Stop the other process
- Use a different port (5020)
- Kill the process:

  ```bash
  sudo kill -9 <PID>
  ```

## Next Steps

Once setup is complete:

1. Read [EXPLOITATION.md](EXPLOITATION.md) for detailed attack scenarios
2. Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system design

## Getting help

- [GitHub Issues](https://github.com/ninabarzh/ics-simulator/issues): Report bugs or ask questions
- Documentation: Check [other docs/ files](https://red.tymyrddin.dev/docs/power/)


Ready to start? Run the simulator and [exploit it](EXPLOITATION.md)!