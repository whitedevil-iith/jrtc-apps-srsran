# Disaggregated RAN Architecture with JRTC/JBPF Support

This document explains the disaggregated RAN architecture support in this project, including all available components, deployment scenarios, and configuration examples.

## Table of Contents

- [1. Architecture Overview](#1-architecture-overview)
  - [1.1. O-RAN Disaggregated Architecture](#11-o-ran-disaggregated-architecture)
  - [1.2. Component Responsibilities](#12-component-responsibilities)
  - [1.3. Interfaces](#13-interfaces)
- [2. Available Components](#2-available-components)
- [3. JRTC/JBPF Support](#3-jrtcjbpf-support)
  - [3.1. JBPF Hooks by Component](#31-jbpf-hooks-by-component)
- [4. Component Deployment Architectures](#4-component-deployment-architectures)
  - [4.1. Scenario 1: Monolithic (Default)](#41-scenario-1-monolithic-default)
  - [4.2. Scenario 2: Disaggregated CU-DU Split](#42-scenario-2-disaggregated-cu-du-split)
  - [4.3. Scenario 3: Fully Disaggregated](#43-scenario-3-fully-disaggregated)
- [5. Configuration Examples](#5-configuration-examples)
  - [5.1. Monolithic gNB Configuration](#51-monolithic-gnb-configuration)
  - [5.2. CU-DU Split Configuration](#52-cu-du-split-configuration)
  - [5.3. Fully Disaggregated Configuration](#53-fully-disaggregated-configuration)
- [6. References](#6-references)

---

## 1. Architecture Overview

### 1.1. O-RAN Disaggregated Architecture

The O-RAN (Open Radio Access Network) alliance defines a disaggregated RAN architecture that splits the traditional monolithic base station into separate functional units. This disaggregation enables:

- **Flexibility**: Deploy components on different hardware platforms
- **Scalability**: Scale components independently based on load
- **Cost Optimization**: Use commercial off-the-shelf (COTS) hardware
- **Vendor Diversity**: Mix components from different vendors

The main functional split is between:
- **CU (Central Unit)**: Handles higher-layer protocols
- **DU (Distributed Unit)**: Handles lower-layer protocols and real-time processing
- **RU (Radio Unit)**: Handles RF signal processing (not part of this project)

The CU can be further split into:
- **CU-CP (Control Plane)**: Manages RRC and PDCP-C
- **CU-UP (User Plane)**: Manages SDAP and PDCP-U

### 1.2. Component Responsibilities

#### CU-CP (Control Plane)
- RRC (Radio Resource Control) protocol handling
- PDCP for control plane (SRBs - Signaling Radio Bearers)
- Connection to 5G Core (AMF) via NG interface
- UE context management
- Mobility management
- Bearer setup and management

#### CU-UP (User Plane)
- SDAP (Service Data Adaptation Protocol) layer
- PDCP for user plane (DRBs - Data Radio Bearers)
- Connection to 5G Core (UPF) for user data
- QoS flow management
- Header compression
- Security (ciphering and integrity protection)

#### DU (Distributed Unit)
- RLC (Radio Link Control) layer
- MAC (Medium Access Control) layer
- PHY (Physical) layer processing
- Scheduling decisions
- HARQ (Hybrid Automatic Repeat Request)
- Connection to RU via fronthaul

### 1.3. Interfaces

The disaggregated architecture defines standard interfaces between components:

```
                     ┌──────────┐
                     │ 5G Core  │
                     │ (AMF/UPF)│
                     └────┬─────┘
                          │ NG
                     ┌────┴─────┐
                     │  CU-CP   │
                     └────┬─────┘
                          │ E1
                     ┌────┴─────┐
                     │  CU-UP   │
                     └────┬─────┘
                          │ F1
                     ┌────┴─────┐
                     │    DU    │
                     └────┬─────┘
                          │ Fronthaul
                     ┌────┴─────┐
                     │    RU    │
                     └──────────┘
```

**NG Interface**: Connects CU-CP to 5G Core (AMF for control, UPF for data)
- Carries NAS messages
- Handles UE context management
- PDU session management

**E1 Interface**: Connects CU-CP and CU-UP
- Bearer context management
- QoS flow mapping
- User plane configuration

**F1 Interface**: Connects CU and DU
- F1-C (Control): RRC messages, UE context management
- F1-U (User): User plane data tunneling (GTP-U)

---

## 2. Available Components

All srsRAN components are built with JRTC/JBPF support enabled. The following binaries are available:

| Binary | Description | Components Included | Use Case |
|--------|-------------|---------------------|----------|
| **gnb** | Monolithic gNB | CU-CP + CU-UP + DU | Default deployment, all-in-one setup |
| **srscu** | Combined CU | CU-CP + CU-UP | CU-DU split deployments |
| **srscucp** | CU Control Plane | CU-CP only | Fully disaggregated deployments |
| **srscuup** | CU User Plane | CU-UP only | Fully disaggregated deployments |
| **srsdu** | Distributed Unit | DU only | All disaggregated deployments |

All binaries are installed to `/usr/local/bin/` in the Docker image.

---

## 3. JRTC/JBPF Support

All components are built with `-DENABLE_JBPF=ON`, which enables JBPF (Just-in-time BPF) hooks throughout the codebase. These hooks allow runtime instrumentation and telemetry collection without modifying the core srsRAN code.

### 3.1. JBPF Hooks by Component

#### Hooks Available in DU (`srsdu`, or DU part of `gnb`/`srscu`)
- **FAPI hooks**: PHY-MAC interface monitoring
  - `fapi_rx_data_indication`, `fapi_crc_indication`, `fapi_uci_indication`, etc.
- **MAC Scheduler hooks**: Resource allocation monitoring
  - `mac_sched_ue_creation`, `mac_sched_ul_bsr_indication`, etc.
- **MAC Scheduler Control hooks**: Dynamic resource allocation
  - `mac_sched_slice_mgmt` - Control hook for slice management
- **DU UE Context hooks**: UE lifecycle tracking
  - `du_ue_ctx_creation`, `du_ue_ctx_deletion`
- **RLC hooks**: Buffer management and throughput
  - `rlc_dl_creation`, `rlc_ul_rx_pdu`, `rlc_dl_sdu_delivered`, etc.
- **XRAN hooks**: Fronthaul packet capture
  - `capture_xran_packet`

#### Hooks Available in CU-CP (`srscucp`, or CU-CP part of `gnb`/`srscu`)
- **NGAP hooks**: 5G Core interface monitoring
  - `ngap_procedure_started`, `ngap_procedure_completed`
- **RRC hooks**: Radio resource control procedures
  - `rrc_ue_add`, `rrc_ue_procedure_started`, `rrc_ue_procedure_completed`
- **E1AP CU-CP hooks**: CU-CP to CU-UP interface
  - `e1_cucp_bearer_context_setup`, `e1_cucp_bearer_context_modification`
- **CU-CP UE Management hooks**: Control plane UE context
  - `cucp_uemgr_ue_add`, `cucp_uemgr_ue_update`, `cucp_uemgr_ue_remove`
- **PDU Session hooks**: Session management
  - `cucp_pdu_session_bearer_setup`, `cucp_pdu_session_remove`
- **PDCP hooks (SRBs)**: Control plane PDCP monitoring
  - `pdcp_dl_creation`, `pdcp_ul_rx_data_pdu` (for SRBs)

#### Hooks Available in CU-UP (`srscuup`, or CU-UP part of `gnb`/`srscu`)
- **E1AP CU-UP hooks**: CU-UP to CU-CP interface
  - `e1_cuup_bearer_context_setup`, `e1_cuup_bearer_context_modification`
- **PDCP hooks (DRBs)**: User plane PDCP monitoring
  - `pdcp_dl_creation`, `pdcp_dl_new_sdu`, `pdcp_dl_tx_data_pdu` (for DRBs)
  - `pdcp_ul_rx_data_pdu`, `pdcp_ul_deliver_sdu` (for DRBs)

#### Common Hooks (All Components)
- **Periodic Performance hook**: Regular statistics reporting
  - `report_stats` - Called every second

For detailed information about each hook and the context data they provide, see [srsran_hooks.md](./srsran_hooks.md).

For information about UE context tracking across components, see [codelets/ue_contexts/README.md](../codelets/ue_contexts/README.md).

---

## 4. Component Deployment Architectures

### 4.1. Scenario 1: Monolithic (Default)

**Description**: Single `gnb` binary running all functions on one host.

**Architecture**:
```
┌─────────────────────────────────────┐
│           Monolithic gNB            │
│  ┌──────────────────────────────┐  │
│  │ CU-CP (RRC, PDCP-C, NGAP)    │  │
│  ├──────────────────────────────┤  │
│  │ CU-UP (SDAP, PDCP-U)         │  │
│  ├──────────────────────────────┤  │
│  │ DU (RLC, MAC, PHY)           │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
         │                    │
         │ NG                 │ Fronthaul
         ▼                    ▼
    ┌────────┐           ┌────────┐
    │  Core  │           │   RU   │
    └────────┘           └────────┘
```

**Benefits**:
- Simplest deployment
- No inter-component communication overhead
- Easiest to debug and monitor
- Currently used in Helm deployments

**Binary**: `gnb`

**Use Case**: Development, testing, small-scale deployments, edge locations

---

### 4.2. Scenario 2: Disaggregated CU-DU Split

**Description**: Separate `srscu` (combined CU-CP + CU-UP) and `srsdu` components connected via F1 interface.

**Architecture**:
```
┌─────────────────────────────────┐
│         Combined CU             │
│  ┌───────────────────────────┐  │
│  │ CU-CP (RRC, PDCP-C, NGAP) │  │
│  ├───────────────────────────┤  │
│  │ CU-UP (SDAP, PDCP-U)      │  │
│  └───────────────────────────┘  │
└────────────────┬────────────────┘
                 │ F1
                 ▼
┌─────────────────────────────────┐
│              DU                 │
│  ┌───────────────────────────┐  │
│  │  RLC, MAC, PHY            │  │
│  └───────────────────────────┘  │
└────────────────┬────────────────┘
                 │ Fronthaul
                 ▼
            ┌────────┐
            │   RU   │
            └────────┘
```

**Benefits**:
- CU can be centralized (in a data center or cloud)
- DU remains close to RU for low latency
- One CU can serve multiple DUs
- Independent scaling of CU and DU

**Binaries**: `srscu` + `srsdu`

**Use Case**: Multi-site deployments, CU centralization, cloud RAN

---

### 4.3. Scenario 3: Fully Disaggregated

**Description**: Separate `srscucp`, `srscuup`, and `srsdu` components with E1 and F1 interfaces.

**Architecture**:
```
┌────────────────────────────┐
│          CU-CP             │
│  RRC, PDCP-C, NGAP         │
└──────────┬─────────────────┘
           │ E1
           ▼
┌────────────────────────────┐
│          CU-UP             │
│    SDAP, PDCP-U            │
└──────────┬─────────────────┘
           │ F1-U
           ▼
┌────────────────────────────┐
│            DU              │
│      RLC, MAC, PHY         │
└──────────┬─────────────────┘
           │ Fronthaul
           ▼
      ┌────────┐
      │   RU   │
      └────────┘

Note: CU-CP also connects to DU via F1-C (not shown)
```

**Benefits**:
- Maximum flexibility
- Independent scaling of control and user plane
- CU-UP can be placed closer to UPF/internet gateway
- Multiple CU-UPs can be controlled by one CU-CP
- Optimal resource utilization

**Binaries**: `srscucp` + `srscuup` + `srsdu`

**Use Case**: Large-scale deployments, cloud-native RAN, network slicing scenarios

---

## 5. Configuration Examples

### 5.1. Monolithic gNB Configuration

**Network Setup**: Single host

**Configuration**:
```yaml
# gnb.yaml - Monolithic gNB configuration
cu_cp:
  amf:
    addr: 192.168.101.50        # Core AMF address
    bind_addr: 192.168.101.10   # Local bind address

cu_up:
  upf:
    addr: 192.168.101.50        # Core UPF address
    bind_addr: 192.168.101.10   # Local bind address

cells:
  - pci: 1
    dl_arfcn: 632628
    band: 78
    common_scs: 30
    channel_bandwidth_MHz: 20
    nof_antennas_dl: 1
    nof_antennas_ul: 1
```

**Startup**:
```bash
gnb -c gnb.yaml
```

---

### 5.2. CU-DU Split Configuration

**Network Setup**: Two hosts connected via network

| Host | Component | IP Address | Interfaces |
|------|-----------|------------|------------|
| Host A | CU | 192.168.1.100 | NG (to Core), F1 (to DU) |
| Host B | DU | 192.168.1.101 | F1 (to CU), Fronthaul (to RU) |

**CU Configuration (srscu.yaml)**:
```yaml
# srscu.yaml - Combined CU configuration
cu_cp:
  amf:
    addr: 192.168.101.50        # Core AMF address
    bind_addr: 192.168.1.100    # CU IP address
    
  f1ap:
    bind_addr: 192.168.1.100    # F1-C interface address

cu_up:
  upf:
    addr: 192.168.101.50        # Core UPF address
    bind_addr: 192.168.1.100    # CU IP address
    
  f1u:
    bind_addr: 192.168.1.100    # F1-U interface address
```

**DU Configuration (srsdu.yaml)**:
```yaml
# srsdu.yaml - DU configuration
cu_cp_addr: 192.168.1.100       # CU-CP F1-C address
cu_up_addr: 192.168.1.100       # CU-UP F1-U address
bind_addr: 192.168.1.101        # DU IP address

cells:
  - pci: 1
    dl_arfcn: 632628
    band: 78
    common_scs: 30
    channel_bandwidth_MHz: 20
    nof_antennas_dl: 1
    nof_antennas_ul: 1
```

**Startup**:
```bash
# On Host A (CU)
srscu -c srscu.yaml

# On Host B (DU)
srsdu -c srsdu.yaml
```

---

### 5.3. Fully Disaggregated Configuration

**Network Setup**: Three hosts

| Host | Component | IP Address | Interfaces |
|------|-----------|------------|------------|
| Host A | CU-CP | 192.168.1.100 | NG (to Core), E1 (to CU-UP), F1-C (to DU) |
| Host B | CU-UP | 192.168.1.101 | E1 (to CU-CP), F1-U (to DU) |
| Host C | DU | 192.168.1.102 | F1 (to CU), Fronthaul (to RU) |

**CU-CP Configuration (srscucp.yaml)**:
```yaml
# srscucp.yaml - CU-CP configuration
amf:
  addr: 192.168.101.50          # Core AMF address
  bind_addr: 192.168.1.100      # CU-CP IP address

f1ap:
  bind_addr: 192.168.1.100      # F1-C interface

e1ap:
  bind_addr: 192.168.1.100      # E1 interface
  cu_up_list:
    - addr: 192.168.1.101       # CU-UP E1 address
```

**CU-UP Configuration (srscuup.yaml)**:
```yaml
# srscuup.yaml - CU-UP configuration
upf:
  addr: 192.168.101.50          # Core UPF address
  bind_addr: 192.168.1.101      # CU-UP IP address

e1ap:
  cu_cp_addr: 192.168.1.100     # CU-CP E1 address
  bind_addr: 192.168.1.101      # E1 interface

f1u:
  bind_addr: 192.168.1.101      # F1-U interface
```

**DU Configuration (srsdu.yaml)**:
```yaml
# srsdu.yaml - DU configuration
cu_cp_addr: 192.168.1.100       # CU-CP F1-C address
cu_up_addr: 192.168.1.101       # CU-UP F1-U address
bind_addr: 192.168.1.102        # DU IP address

cells:
  - pci: 1
    dl_arfcn: 632628
    band: 78
    common_scs: 30
    channel_bandwidth_MHz: 20
    nof_antennas_dl: 1
    nof_antennas_ul: 1
```

**Startup Sequence**:
```bash
# 1. Start CU-CP first (on Host A)
srscucp -c srscucp.yaml

# 2. Start CU-UP (on Host B)
srscuup -c srscuup.yaml

# 3. Start DU (on Host C)
srsdu -c srsdu.yaml
```

---

## 6. References

**Upstream srsRAN Documentation**:
- [srsRAN Project Documentation](https://docs.srsran.com/projects/project/)
- [CU-DU Split Configuration](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/running.html)
- [Configuration Reference](https://docs.srsran.com/projects/project/en/latest/user_manuals/source/config_ref.html)

**JRTC/JBPF Documentation**:
- [JBPF Hooks Reference](./srsran_hooks.md)
- [UE Context Management](../codelets/ue_contexts/README.md)
- [Codelets Documentation](./codelets.md)

**Standards**:
- [O-RAN Alliance Specifications](https://www.o-ran.org/specifications)
- [3GPP TS 38.401](https://www.3gpp.org/DynaReport/38401.htm) - NG-RAN Architecture
- [3GPP TS 38.470](https://www.3gpp.org/DynaReport/38470.htm) - F1 Interface
- [3GPP TS 38.460](https://www.3gpp.org/DynaReport/38460.htm) - E1 Interface
