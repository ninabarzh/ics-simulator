# UU Power & Light ICS Simulator (under construction)

A realistic Industrial Control System (ICS) simulator for demonstrating OT/ICS penetration testing techniques against 
a fictional wind turbine farm operated by the Unseen University in Ankh-Morpork. Part of the 
[UU Power & Light penetration testing project](https://red.tymyrddin.dev/docs/power/).

> "Making consequences feel real without making it actually real, which is considerably harder than it sounds but infinitely preferable to the alternative."

[![License: CC0-1.0](https://img.shields.io/badge/License-CC0_1.0-lightgrey.svg)](http://creativecommons.org/publicdomain/zero/1.0/)
[![Python 3.12+](https://img.shields.io/badge/python-3.12+-blue.svg)](https://www.python.org/downloads/)

## Educational project

This is a fictional scenario for cybersecurity education. The "Unseen University Power & Light Co." is based on 
Terry Pratchett's Discworld series. All systems, attacks, and vulnerabilities demonstrated here are for authorised 
testing and learning purposes only.

## Background story

Unseen University Power & Light Co. operates a wind turbine farm in Ankh-Morpork. As a penetration tester, you've been 
hired to assess the security of their industrial control systems. The facility includes:

- 3 Wind Turbines: Controlled via Modbus/TCP PLCs
- SCADA System: Centralized monitoring and control
- Engineering Workstations: For configuration and maintenance
- Historian Database: Storing years of operational data
- Corporate Network: Connected to the OT network (unfortunately)

Your goal: Demonstrate what an attacker could achieve with network access to their systems.

## What this simulator demonstrates

### Attack scenarios we built together

1. Basic Reconnaissance - Reading turbine parameters without detection
2. Emergency Stop Attack - Immediate shutdown of all turbines
3. Overspeed Attack - Gradual manipulation to cause equipment damage
4. Data Exfiltration - Stealing IP via covert channels (DNS, HTTPS)
5. Historian Theft - Extracting years of production data
6. Ladder Logic Extraction - Stealing PLC configuration
7. Anomaly Detection Bypass - Blending attacks with normal traffic
8. SIEM Correlation Testing - Multi-stage attack chain detection

## Quick start

```bash
# Terminal 1: Start the UU P&L turbine simulator
python3 simulator/turbine_simulator.py

# Terminal 2: Run reconnaissance
python3 exploitation/turbine_reconnaissance.py
```

Output from simulator:
```
[*] UU P&L Turbine PLC simulator running
[*] Listening on 0.0.0.0:502
```

Output from reconnaissance:
```
[*] Reading configuration from Turbine 1 (Demo) (127.0.0.1)...
    Speed Setpoint: 1500 RPM
    Current Speed: 1498 RPM
    Temperature Alarm: 95°C
    Current Temperature: 72°C
```

## Repository structure

```
ics-simulator/
├── README.md                           # This file
├── requirements.txt                    # Python dependencies
├── simulator/
│   └── turbine_simulator.py           # UU P&L turbine PLC simulator
├── exploitation/
│   ├── turbine_reconnaissance.py      # Read-only reconnaissance
│   ├── turbine_overspeed_attack.py   # Gradual overspeed attack
│   ├── turbine_emergency_stop.py     # Mass shutdown attack
│   ├── anomaly_bypass_test.py        # Detection evasion testing
│   ├── siem_correlation_test.py      # Multi-stage attack chain
|   └── ...
├── exfiltration/
│   ├── covert_exfiltration.py        # DNS/HTTPS/slow exfiltration
│   ├── historian_exfiltration.py     # Database extraction demo
│   ├── plc_logic_extraction.py       # Ladder logic theft demo
|   └── ...
├── analysis/
│   └── ladder_logic_analysis.py      # Configuration analysis demo
├── docs/
│   ├── SETUP.md                       # Installation instructions
│   ├── EXPLOITATION.md                # How to use attack scripts
│   └── ARCHITECTURE.md                # System design details
└── examples/
    ├── attack_script.py               # Attack template (adopt and adapt)
    └── demo.sh                        # Orchestrated demonstration
```

## The penetration test story

### Phase 1: Initial access

You've gained VPN access to UU P&L's network (simulated in our scripts). Now you need to understand what you're dealing with.

### Phase 2: Reconnaissance

Use `turbine_reconnaissance.py` to passively gather intelligence:

- Turbine operational parameters
- Safety thresholds and alarm levels
- Network topology and device addresses
- Normal operational patterns

### Phase 3: Exploitation

Demonstrate various attack impacts:

- Disruption: `turbine_emergency_stop.py` - Immediate loss of power generation
- Destruction: `turbine_overspeed_attack.py` - Equipment damage from overspeed
- Evasion: `anomaly_bypass_test.py` - Attacks that bypass detection

### Phase 4: Data theft

Show what attackers can steal:

- IP Theft: `plc_logic_extraction.py` - Years of engineering work
- Business Intelligence: `historian_exfiltration.py` - Production data
- Covert Channels: `covert_exfiltration.py` - Exfiltration without detection

### Phase 5: Persistence & Impact

Demonstrate the full kill chain with `siem_correlation_test.py`.

## Key components

### The turbine simulator

Emulates a Siemens/Allen-Bradley style PLC with:
- Modbus/TCP on port 502
- Holding Registers: Setpoints (speed, temperature alarms, e-stop)
- Input Registers: Current measurements (speed, temperature)
- Realistic values: 1500 RPM nominal speed, 95°C alarm threshold

### Attack scripts

All scripts we developed in our conversation:
- Configured for `127.0.0.1` (local testing)
- Safe by default (restore original values)
- Detailed logging and reporting
- Educational output explaining impact

### The "UU P&L" scenario

Based on [documentation](https://red.tymyrddin.dev/docs/power/) showing:

- Network architecture
- System components
- Attack surface
- Business impact

## Documentation

- [SETUP.md](docs/SETUP.md) - How to install and run the simulator
- [EXPLOITATION.md](docs/EXPLOITATION.md) - Detailed attack script usage
- [ARCHITECTURE.md](docs/ARCHITECTURE.md) - Technical design and Modbus register map

## Example: Full attack demonstration

```bash
# 1. Start the victim system (Terminal 1)
python3 simulator/turbine_simulator.py

# 2. Reconnaissance phase (Terminal 2)
python3 exploitation/turbine_reconnaissance.py

# 3. Demonstrate impact - Overspeed attack
python3 exploitation/turbine_overspeed_attack.py

# 4. Show data theft capability
python3 exfiltration/covert_exfiltration.py

# 5. Multi-stage attack for SIEM testing
python3 exploitation/siem_correlation_test.py
```

## Requirements

```
pymodbus==3.11.4      # Modbus/TCP communication
paramiko>=3.0.0       # SSH (for brute force demo)
requests>=2.28.0      # HTTPS exfiltration
dnspython>=2.3.0      # DNS tunneling
```

Optional for advanced demos:

```
pyodbc>=4.0.39        # Historian database (if available)
pycomm3>=1.2.0        # Allen-Bradley PLC (if available)
```

Install with:

```bash
pip install -r requirements.txt
```

## Learning objectives

After working through this simulator, you'll understand:

1. ICS protocol vulnerabilities: Why Modbus/TCP has no authentication
2. Physical consequences: How cyberattacks cause real-world damage
3. Attack lifecycle: From reconnaissance to impact
4. Detection evasion: How attackers blend with normal traffic
5. Data exfiltration: Techniques to steal industrial IP
6. Defense strategies: What works (and what doesn't) in OT security

## Safe practice environment

This simulator is designed to be:

- Isolated: Runs locally, no external dependencies
- Safe: All attacks are reversible
- Educational: Detailed output explains each action
- Realistic: Based on real ICS protocols and vulnerabilities

## Related Projects

- [Main Repo](https://github.com/ninabarzh/power-and-light): Some more scripts and files
- [Unseen University Power & Light Co.](https://red.tymyrddin.dev/docs/power/): Complete scenario documentation

## References

- [MITRE ATT&CK for ICS](https://attack.mitre.org/matrices/ics/)
- [Modbus Protocol Specification](https://modbus.org/specs.php)
- [NIST ICS Security Guide](https://csrc.nist.gov/publications/detail/sp/800-82/rev-2/final)

## License

CC0 1.0 Universal - Public Domain Dedication

## Acknowledgments

Inspired by Terry Pratchett's Discworld and built to improve ICS security awareness through hands-on learning.

*"The Wizards of Unseen University would like to assure you that all magical and mundane security measures are in place. Mostly."*
