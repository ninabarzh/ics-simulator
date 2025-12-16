#!/bin/bash

################################################################################
# UU Power & Light - Full Attack Demonstration
#
# Orchestrated demonstration of OT/ICS attack scenarios against
# Unseen University Power & Light Co. turbine control systems
#
# Usage: ./examples/full_demo.sh [scenario]
#
# Scenarios:
#   all           - Run complete demonstration (default)
#   quick         - Quick demo (reconnaissance + one attack)
#   recon         - Reconnaissance only
#   disruption    - Disruption attacks
#   destruction   - Destruction attacks
#   exfiltration  - Data theft demonstrations
#   evasion       - Detection evasion techniques
#
# Requirements:
#   - Simulator must be running (python3 simulator/turbine_simulator.py)
#   - All dependencies installed (pip install -r requirements.txt)
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
SIMULATOR_IP="127.0.0.1"
SIMULATOR_PORT="502"
LOG_DIR="demo_logs"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="${LOG_DIR}/demo_${TIMESTAMP}.log"

################################################################################
# Helper Functions
################################################################################

print_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║        UU Power & Light - OT/ICS Attack Demonstration            ║"
    echo "║        Unseen University - Ankh-Morpork                          ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_header() {
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════════════${NC}\n"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_attack() {
    echo -e "${MAGENTA}[⚔]${NC} ${BOLD}$1${NC}"
}

pause_demo() {
    local message="${1:-Press Enter to continue}"
    echo -e "\n${YELLOW}${message}...${NC}"
    read -r
}

check_simulator() {
    print_info "Checking if simulator is running on ${SIMULATOR_IP}:${SIMULATOR_PORT}..."

    if timeout 2 bash -c "cat < /dev/null > /dev/tcp/${SIMULATOR_IP}/${SIMULATOR_PORT}" 2>/dev/null; then
        print_step "Simulator is running"
        return 0
    else
        print_error "Simulator not detected on ${SIMULATOR_IP}:${SIMULATOR_PORT}"
        echo ""
        echo "Please start the simulator first:"
        echo "  ${BOLD}python3 simulator/turbine_simulator.py${NC}"
        echo ""
        exit 1
    fi
}

check_dependencies() {
    print_info "Checking Python dependencies..."

    python3 -c "import pymodbus" 2>/dev/null || {
        print_error "pymodbus not installed"
        echo "Run: pip install -r requirements.txt"
        exit 1
    }

    print_step "All dependencies installed"
}

setup_logging() {
    mkdir -p "$LOG_DIR"
    print_info "Logging to: ${LOG_FILE}"
    echo "UU Power & Light Demo - $(date)" > "$LOG_FILE"
}

run_script() {
    local script=$1
    local description=$2
    local pause=${3:-true}

    print_attack "$description"
    echo ""

    if [ ! -f "$script" ]; then
        print_error "Script not found: $script"
        return 1
    fi

    # Run script and capture output
    python3 "$script" 2>&1 | tee -a "$LOG_FILE"

    local exit_code=${PIPESTATUS[0]}

    if [ "$exit_code" -eq 0 ]; then
        echo ""
        print_step "Attack demonstration completed successfully"
    else
        echo ""
        print_warning "Script exited with code: $exit_code"
    fi

    if [ "$pause" = true ]; then
        pause_demo
    fi

    return "$exit_code"
}

################################################################################
# Demo Scenarios
################################################################################

demo_reconnaissance() {
    print_header "PHASE 1: RECONNAISSANCE"

    echo "In this phase, we passively gather intelligence about the turbine"
    echo "control systems without disrupting operations."
    echo ""
    print_info "Objective: Map the system and identify attack opportunities"
    print_info "MITRE ATT&CK: T0840, T0842, T0888"
    pause_demo

    run_script "exploitation/turbine_reconnaissance.py" \
               "Reconnaissance: Reading turbine configuration data"
}

demo_disruption() {
    print_header "PHASE 2: DISRUPTION ATTACKS"

    echo "Demonstration of attacks that cause immediate operational disruption."
    echo ""
    print_info "Business Impact: Loss of power generation, emergency response costs"
    print_info "MITRE ATT&CK: T0816, T0881, T0809"
    pause_demo

    run_script "exploitation/turbine_emergency_stop.py" \
               "Disruption: Emergency shutdown of all turbines"
}

demo_destruction() {
    print_header "PHASE 3: DESTRUCTION ATTACKS"

    echo "Demonstration of attacks designed to cause physical equipment damage."
    echo ""
    print_warning "In a real scenario, this could destroy millions in equipment!"
    print_info "MITRE ATT&CK: T0836, T0806, T0831"
    pause_demo

    run_script "exploitation/turbine_overspeed_attack.py" \
               "Destruction: Gradual overspeed attack"
}

demo_exfiltration() {
    print_header "PHASE 4: DATA EXFILTRATION"

    echo "Demonstration of techniques to steal intellectual property and"
    echo "operational data without detection."
    echo ""
    print_info "Value: Years of engineering work, competitive intelligence"
    print_info "MITRE ATT&CK: T1048, T1041, T1030"
    pause_demo

    print_attack "Covert Exfiltration: DNS tunneling, HTTPS uploads, rate-limited theft"
    echo ""
    run_script "exfiltration/covert_exfiltration.py" \
               "Data Theft: Covert exfiltration techniques" \
               true

    print_attack "Intellectual Property: PLC ladder logic extraction"
    echo ""
    run_script "exfiltration/plc_logic_extraction.py" \
               "Data Theft: PLC configuration extraction" \
               true

    print_attack "Historical Data: Years of production metrics"
    echo ""
    run_script "exfiltration/historian_exfiltration.py" \
               "Data Theft: Historian database extraction"
}

demo_evasion() {
    print_header "PHASE 5: DETECTION EVASION"

    echo "Demonstration of techniques to bypass security monitoring systems."
    echo ""
    print_info "Strategy: Blend with normal traffic patterns"
    print_info "MITRE ATT&CK: T1562, T1070, T1027"
    pause_demo

    print_attack "Anomaly Detection Bypass: Traffic that appears normal"
    echo ""
    run_script "exploitation/anomaly_bypass_test.py" \
               "Evasion: Bypass anomaly detection" \
               true

    print_attack "SIEM Correlation Test: Multi-stage attack chain"
    echo ""
    print_warning "This demonstrates a complex, multi-stage attack"
    print_info "The SIEM should correlate these events into a kill chain alert"
    echo ""

    # SIEM test is interactive, so just mention it
    print_info "SIEM correlation test requires manual execution:"
    echo "  ${BOLD}python3 exploitation/siem_correlation_test.py${NC}"
    echo ""
    print_info "This test performs:"
    echo "  1. VPN login from unusual location"
    echo "  2. SSH brute force attack"
    echo "  3. RDP lateral movement"
    echo "  4. PLC configuration access"
    echo "  5. OT network scanning"
    echo "  6. Modbus connections"
    echo "  7. Modbus write commands"
}

demo_quick() {
    print_header "QUICK DEMONSTRATION"

    echo "Quick demonstration showing reconnaissance and one attack."
    echo ""

    demo_reconnaissance

    print_header "QUICK ATTACK: Emergency Stop"
    run_script "exploitation/turbine_emergency_stop.py" \
               "Quick Demo: Emergency shutdown attack" \
               false
}

demo_all() {
    print_header "COMPLETE DEMONSTRATION"

    echo "This demonstration will run through all attack scenarios:"
    echo ""
    echo "  1. ${GREEN}Reconnaissance${NC}    - Map the system"
    echo "  2. ${YELLOW}Disruption${NC}        - Emergency shutdowns"
    echo "  3. ${RED}Destruction${NC}       - Equipment damage"
    echo "  4. ${MAGENTA}Data Exfiltration${NC} - IP theft"
    echo "  5. ${CYAN}Detection Evasion${NC} - Bypass monitoring"
    echo ""
    print_warning "This will take approximately 10-15 minutes"
    pause_demo "Press Enter to begin full demonstration"

    demo_reconnaissance
    demo_disruption
    demo_destruction
    demo_exfiltration
    demo_evasion
}

show_summary() {
    print_header "DEMONSTRATION SUMMARY"

    echo "The demonstration has shown:"
    echo ""
    echo "✓ ${GREEN}Reconnaissance${NC}     - How attackers gather intelligence"
    echo "✓ ${YELLOW}Disruption${NC}         - Immediate operational impact"
    echo "✓ ${RED}Destruction${NC}        - Physical equipment damage"
    echo "✓ ${MAGENTA}Data Exfiltration${NC}  - Intellectual property theft"
    echo "✓ ${CYAN}Detection Evasion${NC}  - Bypassing security controls"
    echo ""

    print_header "KEY TAKEAWAYS"

    echo "1. ${BOLD}ICS protocols have no built-in security${NC}"
    echo "   • Modbus/TCP has no authentication or encryption"
    echo "   • Anyone with network access can read/write registers"
    echo ""

    echo "2. ${BOLD}Cyber attacks cause physical consequences${NC}"
    echo "   • Overspeed can destroy turbines (millions in damage)"
    echo "   • Emergency stops disrupt power generation"
    echo "   • Safety systems can be bypassed"
    echo ""

    echo "3. ${BOLD}Attackers can steal years of engineering work${NC}"
    echo "   • PLC configurations contain trade secrets"
    echo "   • Historical data reveals competitive intelligence"
    echo "   • Exfiltration can be covert and undetected"
    echo ""

    echo "4. ${BOLD}Detection is difficult but not impossible${NC}"
    echo "   • Network monitoring can detect anomalies"
    echo "   • Physics-based detection catches impossible values"
    echo "   • SIEM correlation identifies attack chains"
    echo ""

    print_header "DEFENSIVE RECOMMENDATIONS"

    echo "Critical Security Controls:"
    echo ""
    echo "  1. ${BOLD}Network Segmentation${NC}"
    echo "     • Isolate OT from IT networks"
    echo "     • Use firewalls and data diodes"
    echo "     • Implement zero-trust architecture"
    echo ""

    echo "  2. ${BOLD}Authentication & Access Control${NC}"
    echo "     • Deploy application-layer authentication"
    echo "     • Use VPNs with multi-factor authentication"
    echo "     • Implement role-based access control"
    echo ""

    echo "  3. ${BOLD}Monitoring & Detection${NC}"
    echo "     • Monitor all Modbus traffic"
    echo "     • Alert on write operations"
    echo "     • Use physics-based anomaly detection"
    echo "     • Correlate events in SIEM"
    echo ""

    echo "  4. ${BOLD}Incident Response${NC}"
    echo "     • Have OT-specific playbooks"
    echo "     • Practice incident response"
    echo "     • Coordinate with operations team"
    echo "     • Maintain offline backups"
    echo ""

    print_info "Log file saved to: ${LOG_FILE}"
    print_info "Attack artifacts saved to: demo_logs/"
    echo ""
}

show_usage() {
    echo "Usage: $0 [scenario]"
    echo ""
    echo "Scenarios:"
    echo "  all           - Run complete demonstration (default)"
    echo "  quick         - Quick demo (reconnaissance + one attack)"
    echo "  recon         - Reconnaissance only"
    echo "  disruption    - Disruption attacks"
    echo "  destruction   - Destruction attacks"
    echo "  exfiltration  - Data theft demonstrations"
    echo "  evasion       - Detection evasion techniques"
    echo ""
    echo "Example:"
    echo "  $0 quick"
    echo "  $0 recon"
    echo "  $0 all"
    echo ""
}

################################################################################
# Main Script
################################################################################

main() {
    local scenario="${1:-all}"

    # Setup
    print_banner
    setup_logging
    check_dependencies
    check_simulator

    echo ""
    print_info "Starting demonstration: ${BOLD}${scenario}${NC}"
    print_info "Target: ${SIMULATOR_IP}:${SIMULATOR_PORT}"
    echo ""

    # Run selected scenario
    case "$scenario" in
        all)
            demo_all
            ;;
        quick)
            demo_quick
            ;;
        recon|reconnaissance)
            demo_reconnaissance
            ;;
        disruption)
            demo_disruption
            ;;
        destruction)
            demo_destruction
            ;;
        exfiltration|exfil)
            demo_exfiltration
            ;;
        evasion)
            demo_evasion
            ;;
        help|-h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown scenario: $scenario"
            echo ""
            show_usage
            exit 1
            ;;
    esac

    # Show summary
    show_summary

    print_header "DEMONSTRATION COMPLETE"
    echo "Thank you for exploring OT/ICS security with UU Power & Light!"
    echo ""
    echo "For more information:"
    echo "  • Documentation: docs/"
    echo "  • Red Team Guide: https://red.tymyrddin.dev/docs/power/"
    echo "  • MITRE ATT&CK for ICS: https://attack.mitre.org/matrices/ics/"
    echo ""
    print_step "Demo completed successfully"
}

# Run main function
main "$@"
