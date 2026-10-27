# Motivation — engineering an alternate failure domain

## Starting situation

The original project had several Proxmox-capable hosts and a main fixed-line internet connection. That infrastructure is powerful, but a power failure, ISP incident, router outage or local network misconfiguration can make multiple nominally separate servers unreachable at the same time. **The goal was not a faster primary server; it was a different failure domain.**

A first-generation Surface Book was available but affected by a motherboard-related screen fault. The root cause of that display failure was **not established** during this project. Crucially, the machine could still boot an operating system and be managed remotely. That made it a candidate for repurposing.

## Research question

Can a mobile computer with a defective screen serve as a practical auxiliary application node by combining:

- a headless Debian Linux installation;
- remote SSH administration;
- lightweight container workloads;
- a battery-backed energy buffer;
- a network path through a smartphone's 4G/5G hotspot;
- optional private connectivity through Tailscale?

**Hypothesis:** for a limited selection of stateless or properly replicated services, a laptop-class edge node can improve resilience to failures shared by a main server room. This is a design hypothesis, *not a proven availability claim*.

## Why the Surface Book?

Its mobile architecture places CPU, SSD, networking and batteries in a compact platform with intrinsically low idle power relative to older rack servers. The detachable display and keyboard-base design adds complexity: battery visibility, NVIDIA base GPU power gating, firmware/ACPI and Linux driver compatibility may differ from conventional laptops.

Microsoft documents models with Intel HD 520 and optional 1 GB GDDR5 NVIDIA graphics. This project detects the Intel graphics device in Linux. The physically present NVIDIA device was not enumerated during the available inspection; it was not required for the core server goals.

## Engineering principles

1. **Resource extension:** retain useful portions of hardware instead of treating a display failure as total equipment loss.
2. **Service continuity:** design for specific recoverable services rather than an undefined promise of complete failover.
3. **Failure-domain diversity:** separate the secondary communication and backup-energy paths.
4. **Reproducibility:** retain install sources, exact assumptions and step-by-step diagnosis.
5. **Least operational complexity:** a headless Debian host and Docker containers are more direct for this role than a full nested virtualization stack.
6. **Responsible operations:** monitor aging batteries, thermal exposure, software security and data integrity.

## What the prototype does not prove

It does not prove a particular RTO, RPO, probability of failure, power uptime during a sitewide outage or online availability of the app. A local battery does not make upstream cellular infrastructure immune to outages. A Tailscale node is private-network access, not automatically a public ingress path for arbitrary users.

## Sustainability perspective

The sustainability claim is deliberately modest: **extending service life** can reduce demand for replacement equipment and defer disposal. Measuring actual energy and environmental benefit would also require considering charging efficiency, battery replacement, electricity mix and end-of-life recycling. No quantified carbon savings are claimed.
