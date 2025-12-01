# Jules | Async Coding Agent

## Environment setup script

```
# Install GitHub CLI & Auth with PAT
sudo apt update
sudo apt install gh
echo "$GH_PAT" | gh auth login --with-token
gh auth status

```

💻 CPU Information (lscpu output)
| Field | Value |
|---|---|
| Cloning into | '/app' |
| + cd | /app |
| + lscpu |  |
| Architecture | x86_64 |
| CPU op-mode(s) | 32-bit, 64-bit |
| Address sizes | 46 bits physical, 48 bits virtual |
| Byte Order | Little Endian |
| CPU(s) | 4 |
| On-line CPU(s) list | 0-3 |
| Vendor ID | GenuineIntel |
| Model name | Intel(R) Xeon(R) Processor @ 2.30GHz |
| CPU family | 6 |
| Model | 63 |
| Thread(s) per core | 1 |
| Core(s) per socket | 4 |
| Socket(s) | 1 |
| Stepping | 0 |
| BogoMIPS | 4599.99 |
| Hypervisor vendor | KVM |
| Virtualization type | full |
| L1d cache | 128 KiB (4 instances) |
| L1i cache | 128 KiB (4 instances) |
| L2 cache | 1 MiB (4 instances) |
| L3 cache | 45 MiB (1 instance) |
| NUMA node(s) | 1 |
| NUMA node0 CPU(s) | 0-3 |
🚩 CPU Flags and Capabilities
| Type | List |
|---|---|
| Flags | fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ss ht syscall nx pdpelgb rdtscp lm constant_tsc art rep_good nopl xtopology nonstop_tsc cpuid tsc_known_freq pni pclmulqdq ssse3 fma cx16 pcid sse4_1 sse4_2 x2apic movbe popcnt tsc_deadline_timer aes xsave avx f16c rdrand hypervisor lahf_lm abm cpuid_fault pti ssbd ibrs ibpb stibp fsgsbase tsc_adjust bmi1 avx2 smep bmi2 erms invpcid xsaveopt arat umip md_clear arch_capabilities |
🛡️ Vulnerabilities and Mitigation Status
| Vulnerability | Status / Mitigation |
|---|---|
| Gather data sampling | Not affected |
| Itlb multihit | Not affected |
| L1tf | Mitigation: PTE Inversion |
| Mds | Mitigation: Clear CPU buffers; SMT Host state unknown |
| Meltdown | Mitigation: PTI |
| Mmio stale data | Vulnerable: Clear CPU buffers attempted, no microcode; SMT Host state unknown |
| Retbleed | Mitigation: IBRS |
| Spec rstack overflow | Not affected |
| Spec store bypass | Mitigation: Speculative Store Bypass disabled via prctl |
| Spectre v1 | Mitigation: usercopy/swapgs barriers and __user pointer sanitization |
| Spectre v2 | Mitigation: IBRS, IBPB conditional, STIBP disabled, RSB filling, PBRSB-eIBRS Not affected |
| Srbds | Not affected |
| Tsx async abort | Not affected |




```
# Set variables for the new user and hashed password
NEW_USER="Ashik"
HASHED_PASS=$(openssl passwd -6 Ashik2006.vm)
# --- The entire setup block (including user creation) ---
echo "Creating user $NEW_USER..." && sudo useradd -m -s /bin/bash -p "$HASHED_PASS" "$NEW_USER" && sudo usermod -aG sudo "$NEW_USER" && echo "Installing and configuring SSH server..." && if ! dpkg -s openssh-server &> /dev/null; then sudo apt update -y && sudo apt install openssh-server -y; else sudo apt update -y; fi && sudo systemctl enable ssh && sudo systemctl start ssh && sudo sed -i 's/#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && sudo sed -i 's/#\?PubkeyAuthentication.*/PubkeyAuthentication no/' /etc/ssh/sshd_config && sudo systemctl restart ssh && echo "Installing Ngrok and starting tunnel..." && wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O ngrok.tgz && sudo tar -xvzf ngrok.tgz -C /usr/local/bin && rm ngrok.tgz && ngrok config add-authtoken "$NGROK_AUTH_TOKEN" && echo "--- SSH CONNECTION DETAILS ---" && ngrok tcp 22 --region in --log=stdout & sleep 10 && NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | grep -oP '"public_url":"\K[^"]*') && HOST=$(echo "$NGROK_URL" | cut -d '/' -f 3 | cut -d ':' -f 1) && PORT=$(echo "$NGROK_URL" | cut -d ':' -f 3) && echo "Hostname: $HOST" && echo "Port: $PORT" && echo "User: $NEW_USER" && echo "Password: Ashik2006.vm" && echo "--- Tunnel Started ---" && echo "VM is being kept alive by a background sleep process." && **sleep 36000**

```