# Architecture - UU Power & Light ICS Simulator

Technical design documentation for the turbine control system simulator and attack demonstration framework.

## Table of Contents

- [System Overview](#system-overview)
- [Simulator Architecture](#simulator-architecture)
- [Modbus Protocol Implementation](#modbus-protocol-implementation)
- [Register Map](#register-map)
- [Attack Script Architecture](#attack-script-architecture)
- [Network Topology](#network-topology)
- [Data Flow](#data-flow)
- [Security Considerations](#security-considerations)

## System overview

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    Attack Machine                           │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Exploitation scripts                                  │ │
│  │  • turbine_overspeed_attack.py                         │ │
│  │  • turbine_emergency_stop.py                           │ │
│  │  • anomaly_bypass_test.py                              │ │
│  │  • siem_correlation_test.py                            │ │
│  │  • ...                                                 │ │
│  └────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Extraction scripts                                    │ │
│  │  • covert_exfiltration.py                              │ │
│  │  • historian_exfiltration.py                           │ │
│  │  • plc_logic_extraction.py                             │ │
│  │  • ...                                                 │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Modbus/TCP (Port 502)
                            │ TCP/IP Network
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                 Turbine PLC Simulator                       │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  turbine_simulator.py                                  │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │  Modbus server (pymodbus 3.11.4)                 │  │ │
│  │  │  • Listens on 0.0.0.0:502                        │  │ │
│  │  │  • Handles READ/WRITE requests                   │  │ │
│  │  │  • Maintains register state                      │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │  Register map                                    │  │ │
│  │  │  • Holding Registers (setpoints)                 │  │ │
│  │  │  • Input Registers (measurements)                │  │ │
│  │  │  • Coils (digital outputs)                       │  │ │
│  │  │  • Discrete Inputs (digital inputs)              │  │ │
│  │  └──────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

- Language: Python 3.12+
- Protocol library: pymodbus 3.11.4
- Network: TCP/IP, Modbus/TCP
- Supporting libraries:
  - paramiko (SSH operations)
  - requests (HTTPS)
  - dnspython (DNS operations)

## Simulator architecture

### turbine_simulator.py

Core implementation:

```python
from pymodbus.server import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock
from pymodbus.datastore import ModbusServerContext, ModbusDeviceContext

def create_turbine_simulator():
    # Define register blocks
    coils = ModbusSequentialDataBlock(0, [0] * 3000)
    discrete_inputs = ModbusSequentialDataBlock(0, [0] * 3000)
    holding_registers = ModbusSequentialDataBlock(0, [0] * 3000)
    input_registers = ModbusSequentialDataBlock(0, [0] * 3000)
    
    # Initialize with realistic values
    holding_registers.setValues(1000, [1500])  # Speed setpoint
    holding_registers.setValues(1050, [95])    # Temp alarm threshold
    holding_registers.setValues(1100, [0])     # E-stop status
    
    input_registers.setValues(2000, [1498])    # Current speed
    input_registers.setValues(2050, [72])      # Current temperature
    
    # Create device context (pymodbus 3.x API)
    device = ModbusDeviceContext(
        di=discrete_inputs,
        co=coils,
        hr=holding_registers,
        ir=input_registers,
    )
    
    return ModbusServerContext(devices=device, single=True)

if __name__ == "__main__":
    context = create_turbine_simulator()
    StartTcpServer(
        context=context,
        address=("0.0.0.0", 502),
    )
```

Key design decisions:

1. pymodbus 3.11.4: Latest stable version with modern API
2. ModbusDeviceContext: Replaces deprecated ModbusSlaveContext
3. Sequential DataBlocks: Simple addressing model (0-2999)
4. Persistent State: Values persist across connections
5. No Authentication: Realistic simulation of legacy ICS

### State Management

The simulator maintains state in memory:

- Volatile: State lost on restart (realistic for many PLCs)
- Persistent: Could be extended with SQLite/file storage
- Thread-safe: pymodbus handles concurrent connections

### Performance Characteristics

- Connections: Handles multiple simultaneous clients
- Throughput: ~1000 requests/second on modern hardware
- Latency: <1ms response time for local connections
- Memory: ~50MB RAM footprint

## Modbus protocol implementation

### Protocol stack

```
┌──────────────────────────────────┐
│   Application (Attack scripts)   │
├──────────────────────────────────┤
│   Modbus/TCP (ADU)               │
│   • Transaction ID               │
│   • Protocol ID (0x0000)         │
│   • Length                       │
│   • Unit ID (0x00)               │
├──────────────────────────────────┤
│   Modbus PDU                     │
│   • Function Code                │
│   • Data                         │
├──────────────────────────────────┤
│   TCP (Port 502)                 │
├──────────────────────────────────┤
│   IP                             │
├──────────────────────────────────┤
│   Ethernet                       │
└──────────────────────────────────┘
```

### Function codes used

| Code | Name                     | Purpose            | Used In        |
|------|--------------------------|--------------------|----------------|
| 0x03 | Read Holding Registers   | Read setpoints     | Reconnaissance |
| 0x04 | Read Input Registers     | Read measurements  | Reconnaissance |
| 0x06 | Write Single Register    | Modify setpoint    | All attacks    |
| 0x10 | Write Multiple Registers | Bulk modifications | (Not used)     |

### Modbus message format

Read Holding Registers (0x03):
```
Request:
[Transaction ID][Protocol ID][Length][Unit ID][Function][Start Addr][Quantity]
    2 bytes       2 bytes     2 bytes  1 byte   1 byte     2 bytes    2 bytes

Example: Read 10 registers starting at 1000
[0x0001][0x0000][0x0006][0x00][0x03][0x03E8][0x000A]

Response:
[Transaction ID][Protocol ID][Length][Unit ID][Function][Byte Count][Data...]
    2 bytes       2 bytes     2 bytes  1 byte   1 byte     1 byte     N bytes
```

Write Single Register (0x06):
```
Request:
[Transaction ID][Protocol ID][Length][Unit ID][Function][Address][Value]
    2 bytes       2 bytes     2 bytes  1 byte   1 byte   2 bytes  2 bytes

Example: Write 1490 to register 1000
[0x0001][0x0000][0x0006][0x00][0x06][0x03E8][0x05CA]

Response: (Echo of request for success)
[0x0001][0x0000][0x0006][0x00][0x06][0x03E8][0x05CA]
```

## Register map

### Complete register layout

#### Holding Registers (Setpoints - Read/Write)

| Address | Name                 | Type  | Units   | Range  | Default | Purpose                     |
|---------|----------------------|-------|---------|--------|---------|-----------------------------|
| 1000    | Speed Setpoint       | INT16 | RPM     | 0-2000 | 1500    | Target turbine speed        |
| 1050    | Temp Alarm Threshold | INT16 | °C      | 50-150 | 95      | Temperature alarm limit     |
| 1100    | Emergency Stop       | INT16 | Boolean | 0-1    | 0       | E-stop status (0=off, 1=on) |
| 1150    | Pressure Setpoint    | INT16 | PSI     | 0-200  | 130     | Hydraulic pressure target   |
| 1200    | Power Limit          | INT16 | MW      | 0-5    | 3       | Maximum power output        |

#### Input Registers (Measurements - Read Only)

| Address | Name                | Type  | Units | Range  | Typical | Purpose                  |
|---------|---------------------|-------|-------|--------|---------|--------------------------|
| 2000    | Current Speed       | INT16 | RPM   | 0-2000 | 1498    | Actual turbine speed     |
| 2050    | Current Temperature | INT16 | °C    | 0-150  | 72      | Bearing temperature      |
| 2100    | Current Pressure    | INT16 | PSI   | 0-200  | 128     | Hydraulic pressure       |
| 2150    | Power Output        | INT16 | kW    | 0-5000 | 2450    | Current power generation |
| 2200    | Vibration Level     | INT16 | mm/s  | 0-20   | 4       | Vibration measurement    |
| 2250    | Wind Speed          | INT16 | m/s   | 0-40   | 12      | Incoming wind speed      |

#### Coils (Digital Outputs - Read/Write)

| Address | Name           | Purpose                 |
|---------|----------------|-------------------------|
| 0       | Main Contactor | Enable/disable turbine  |
| 1       | Brake Engage   | Engage mechanical brake |
| 2       | Pitch Control  | Blade pitch adjustment  |
| 10      | Warning Light  | Status indicator        |
| 11      | Alarm Horn     | Audible alarm           |

#### Discrete Inputs (Digital Inputs - Read Only)

| Address | Name             | Purpose                      |
|---------|------------------|------------------------------|
| 0       | E-Stop Button    | Physical emergency stop      |
| 1       | Overspeed Sensor | Hardware overspeed detection |
| 2       | Overtemp Sensor  | Hardware overtemp detection  |
| 10      | Door Open        | Access door status           |
| 11      | Grid Connected   | Grid connection status       |

### Register access patterns

Normal HMI operation:

```
# HMI polls every 1 second
every 1s:
    read_input_registers(2000, 10)  # Read all measurements
    read_holding_registers(1000, 5)  # Read all setpoints
```

Engineering workstation:

```
# Periodic configuration checks
every 5min:
    read_holding_registers(1000, 200)  # Read config
    
# Configuration changes (rare)
when operator_modifies:
    write_register(1000, new_value)
    log_change(operator, timestamp, old, new)
```

Attack patterns:

```
# Reconnaissance
read_holding_registers(0, 3000)  # Read entire map
read_input_registers(0, 3000)    # Suspicious: too much data

# Targeted attack
write_register(1000, 0)          # Emergency stop
write_register(1000, 1650)       # Overspeed

# Stealthy attack
read_holding_registers(1000, 10) # Normal size
wait_random(0.5, 2.0)            # Variable timing
write_register(1000, 1495)       # Small change
```

## Attack script architecture

### Common pattern

All attack scripts follow this structure:

```python
#!/usr/bin/env python3
"""
Script description and purpose
"""

from pymodbus.client import ModbusTcpClient


# ============================================================================
# CONFIGURATION
# ============================================================================
CONFIG = {
    'plc': {
        'ip': '127.0.0.1',
        'port': 502
    },
    # Script-specific config
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================
def connect_safely(ip, port):
    """Safe connection with error handling"""
    try:
        client = ModbusTcpClient(ip, port=port)
        if client.connect():
            return client
        return None
    except Exception as e:
        print(f"Connection error: {e}")
        return None

def read_safely(client, address, count):
    """Safe read with error handling"""
    try:
        result = client.read_holding_registers(address, count)
        if not result.isError():
            return result.registers
        return None
    except Exception as e:
        print(f"Read error: {e}")
        return None

def write_safely(client, address, value):
    """Safe write with error handling"""
    try:
        result = client.write_register(address, value)
        return not result.isError()
    except Exception as e:
        print(f"Write error: {e}")
        return False

# ============================================================================
# ATTACK LOGIC
# ============================================================================
def perform_attack():
    """Main attack logic"""
    client = connect_safely(CONFIG['plc']['ip'], CONFIG['plc']['port'])
    if not client:
        return False
    
    try:
        # Attack implementation
        pass
    finally:
        client.close()
    
    return True

# ============================================================================
# MAIN EXECUTION
# ============================================================================
if __name__ == '__main__':
    print("[*] Attack script starting...")
    perform_attack()
```

### Error handling strategy

1. Connection Failures: Gracefully handle unreachable targets
2. Modbus Errors: Check `isError()` on all responses
3. Type Safety: Use type hints and Optional types
4. Resource Cleanup: Always close connections in `finally`
5. User Interruption: Handle Ctrl+C gracefully

### Logging & reporting

All scripts generate:
- Console output: Real-time progress
- JSON reports: Structured data for analysis
- Timestamps: ISO 8601 format for all events
- Impact assessment: Business and technical impact

## Network topology

### Simple (single machine)

```
┌─────────────────────────┐
│   Localhost (127.0.0.1) │
│                         │
│  ┌──────────────────┐   │
│  │  Simulator :502  │   │
│  └──────────────────┘   │
│           ↑             │
│           │ loopback    │
│  ┌──────────────────┐   │
│  │ Attack Scripts   │   │
│  └──────────────────┘   │
└─────────────────────────┘
```

### Multi-machine (realistic)

```
┌─────────────────────┐         ┌─────────────────────┐
│  Attack Machine     │         │  Target Machine     │
│  192.168.1.50       │         │  192.168.1.100      │
│                     │         │                     │
│  ┌──────────────┐   │         │  ┌──────────────┐   │
│  │Attack Scripts│   │         │  │Simulator:502 │   │
│  └──────────────┘   │         │  └──────────────┘   │
└─────────────────────┘         └─────────────────────┘
         │                               ↑
         │                               │
         └───────────TCP/IP──────────────┘
                 192.168.1.0/24
```

### Complex (Full OT Environment)

```
Internet
    │
    ↓
┌────────────────────────────────────────┐
│         Corporate Network              │
│  (IT Domain - 10.0.0.0/8)              │
└────────────────────────────────────────┘
    │ Firewall + DMZ
    ↓
┌────────────────────────────────────────┐
│         OT Network                     │
│  (192.168.0.0/16)                      │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │  SCADA Server                    │  │
│  │  192.168.1.10                    │  │
│  └──────────────────────────────────┘  │
│               │                        │
│  ┌────────────┼────────────┐           │
│  │            │            │           │
│  ↓            ↓            ↓           │
│ PLC 1       PLC 2       PLC 3          │
│ .10.10      .10.11      .10.12         │
│ :502        :502        :502           │
└────────────────────────────────────────┘
```

## Data Flow

### Normal operations

```
HMI/SCADA → [READ registers] → PLC
         ← [Register values] ←

Operator → [Modify setpoint] → HMI → [WRITE register] → PLC
                                          ← [Confirm] ←
```

### Attack sequence

```
1. Reconnaissance:
   Attacker → [READ 0-3000] → PLC
          ← [All registers] ←

2. Analysis:
   Attacker → [Identify targets]
   
3. Exploitation:
   Attacker → [WRITE critical register] → PLC
                      ← [Confirm write] ←
          
4. Impact:
   PLC → [Execute new setpoint] → Physical Process
   Physical Process → [Damage/disruption]
   
5. Exfiltration:
   Attacker → [READ configuration] → PLC
             ← [Ladder logic/data] ←
   Attacker → [DNS/HTTPS exfil] → C2 Server
```

## Security considerations

### Vulnerabilities by design

The simulator intentionally includes:
1. No authentication: Modbus/TCP has no built-in auth
2. No encryption: All traffic in plaintext
3. No access control: Any client can read/write
4. No audit logging: No built-in write attribution
5. No rate limiting: Allows brute force

These are realistic weaknesses in legacy ICS.

### Attack surface

```
Network Access
    ↓
Modbus/TCP (502)
    ├── Function Codes (03, 04, 06, 10)
    │   └── All enabled by default
    ├── Register Access
    │   ├── Read any register
    │   └── Write any register
    └── No Authentication Required
```

### Defense-in-depth required

Since protocol has no security:
1. Network segmentation: Isolate OT from IT
2. Firewalls: Whitelist allowed sources
3. IDS/IPS: Monitor Modbus traffic
4. Application whitelist: Only approved clients
5. Physical security: Secure access to PLCs

### Monitoring points

```
# What to monitor in production:
monitor_points = {
    'connections': {
        'new_connection': lambda src: log_and_alert_if_unknown(src),
        'connection_frequency': lambda: alert_if_excessive(),
    },
    'operations': {
        'write_operations': lambda: alert_always(),  # Rare in normal ops
        'read_size': lambda size: alert_if_size > normal_hmi_size,
        'function_codes': lambda fc: alert_if_fc not in [0x03, 0x04],
    },
    'values': {
        'setpoint_change': lambda old, new: alert_if_abs(new-old) > threshold,
        'rate_of_change': lambda: alert_if_cumulative_change_high(),
        'impossible_values': lambda v: alert_if_physics_violated(v),
    }
}
```

## Extending the simulator

### Adding new registers

```
# In create_turbine_simulator():
holding_registers.setValues(1300, [value])  # Add new setpoint
input_registers.setValues(2300, [value])     # Add new measurement
```

### Adding multiple turbines

```
# Create multiple contexts
turbine1 = create_turbine_simulator()
turbine2 = create_turbine_simulator()

# Run on different ports
StartTcpServer(context=turbine1, address=("0.0.0.0", 502))
StartTcpServer(context=turbine2, address=("0.0.0.0", 5020))
```

### Adding realistic behaviour

```
class RealisticTurbine:
    def __init__(self):
        self.speed_setpoint = 1500
        self.actual_speed = 1498
        
    def update(self):
        # Simulate inertia
        if self.actual_speed < self.speed_setpoint:
            self.actual_speed += 2  # Slow acceleration
        elif self.actual_speed > self.speed_setpoint:
            self.actual_speed -= 2  # Slow deceleration
            
        # Update input register
        input_registers.setValues(2000, [self.actual_speed])
```

## References

- [Modbus Application Protocol V1.1b3](https://modbus.org/docs/Modbus_Application_Protocol_V1_1b3.pdf)
- [Modbus TCP/IP Implementation Guide](https://modbus.org/docs/Modbus_Messaging_Implementation_Guide_V1_0b.pdf)
- [pymodbus Documentation](https://pymodbus.readthedocs.io/)
- [NIST SP 800-82 Rev. 3](https://csrc.nist.gov/publications/detail/sp/800-82/rev-3/final)


*Architecture designed for educational purposes. Always use in isolated environments.*