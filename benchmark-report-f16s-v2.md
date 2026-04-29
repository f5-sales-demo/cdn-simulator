# CDN Simulator — Load Test Report (F16s_v2 Baseline)

**CDN VM:** Standard_F16s_v2 (16 vCPU, 32 GiB RAM, 50 Gbps NIC)
**Target:** `http://20.65.90.112`
**Test Period:** April 26-27, 2026

## Aggregate Stats

| Metric | Value |
|---|---|
| **Total requests served** | **225,794,097** |
| **Cache HITs** | 224,672,073 (99.50%) |
| **Cache MISSes** | 1,119,619 (0.50%) |
| **STALE serves** | 301 |
| **UPDATING serves** | 2,089 |
| **5xx errors** | **0** |
| **Success rate** | **100.000%** |
| **Final cache size** | 492 MB |

## VM Sizing Journey

| Phase | CDN VM | vCPU | Monthly Cost | Outcome |
|---|---|---|---|---|
| Initial deploy | Standard_B2s | 2 | ~$35 | Burstable, inadequate |
| First upgrade | Standard_D4s_v5 | 4 | ~$125 | 100% CPU at 13K connections |
| Second upgrade | Standard_F8s_v2 | 8 | ~$194 | 100% CPU at 11K connections |
| **Current** | **Standard_F16s_v2** | **16** | **~$389** | **100% CPU at 28K connections, zero errors** |

## Cache Optimization Impact

| Fix | Before | After |
|---|---|---|
| `proxy_ignore_headers Vary` | Triple Vary fragmented cache | Single cache entry per URL |
| `proxy_hide_header X-Cache-Status` | Duplicate headers from origin | Clean single header |
| `proxy_hide_header Vary` | Origin's Vary passed through | gzip_vary handles it |
| Remove `proxy_cache_revalidate` | Origin roundtrip on expiry | Stale served, background refresh |
| **Juice Shop throughput** | **457 req/s** | **11,169 req/s (+2,343%)** |

## ABC Test Results — Traffic Generator Comparison

### Round 1: Non-keepalive

| Test | Traffic Gen VM | Gen vCPU | Peak Conn | CDN CPU | NGINX % | Kernel % | Errors |
|---|---|---|---|---|---|---|---|
| Baseline | D8s_v3 | 8 | 2.1K | 67% | 25% | 40% | 0 |
| Test B | F16s_v2 | 16 | 14K | 100% | 30% | 70% | 0 |
| Test C | F32s_v2 | 32 | 28.2K | 100% | 34% | 66% | 0 |
| Test D | D16s_v3 | 16 | 7.2K | 100% | 28% | 72% | 0 |

### Round 1: Keepalive (D16s_v3 pass)

| Test | Traffic Gen VM | Gen vCPU | Peak Conn | CDN CPU | NGINX % | Kernel % | Errors |
|---|---|---|---|---|---|---|---|
| Test D (KA) | D16s_v3 | 16 | 8.4K | 100% | **55%** | **45%** | 0 |

### Round 2: Keepalive A/B Comparison

| Test | Traffic Gen VM | Gen vCPU | Peak Conn | CDN CPU | NGINX % | Kernel % | Errors |
|---|---|---|---|---|---|---|---|
| A (KA) | F16s_v2 | 16 | 1.8K | 100% | 42% | 58% | 0 |
| B (KA) | F32s_v2 | 32 | 3.6K | 100% | 43% | 57% | 0 |

## Key Findings

1. **CDN is the ceiling, not the traffic gen.** F32s_v2 (32 vCPU) gen at 12% CPU produced the same CDN throughput as F16s_v2 (16 vCPU) gen.
2. **Keepalive improves NGINX share from 28% → 42-55%** but doesn't eliminate the ceiling.
3. **F16s_v2 = D16s_v3 performance.** Same Xeon 8272CL in eastus2.
4. **Zero errors under every test condition.** 225M requests without a single failure.
5. **RAM and disk massively over-provisioned.** 1.2 GB / 32 GB RAM (3.8%). 492 MB / 25 GB cache (2%).

## CPU Bottleneck Analysis

| Component | Without Keepalive | With Keepalive |
|---|---|---|
| **NGINX (usr)** | 28-34% | 42-55% |
| **Kernel (sys)** | 30-43% | 20-32% |
| **Softirq (si)** | 28-35% | 27-31% |
| **Idle** | 0% | 0% |

## Configuration at Time of Test

### Kernel Tuning

- somaxconn: 131072
- netdev_max_backlog: 131072
- tcp_max_syn_backlog: 131072
- tcp_tw_reuse: 1
- ip_local_port_range: 1024-65535
- rmem_max/wmem_max: 16777216
- tcp_max_tw_buckets: 4000000
- file-max: 4194304
- swappiness: 10

### NGINX

- workers: 16 (auto)
- worker_connections: 16384
- worker_rlimit_nofile: 131072
- upstream keepalive: 512
- keepalive_requests: 100000
- cache keys_zone: 64m
- cache max_size: 25g
- listen: 80 reuseport
- proxy_ignore_headers: Set-Cookie Cache-Control Expires Vary
- proxy_hide_header: X-Cache-Status, Vary

### OS Limits

- systemd LimitNOFILE: 131072
- www-data nofile: 131072
- irqbalance: active
- RFS: 65536 flow entries, 4096/queue
- NIC queues: 16 RX / 16 TX
