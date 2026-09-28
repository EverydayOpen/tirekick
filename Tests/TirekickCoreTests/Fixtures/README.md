# Fixtures

Real command output published by other people, used by the Core parser and rule tests. Collected 2026-09-28.
Serial numbers, UUIDs and the battery serial are masked (`X`); nothing else was changed unless the table says so.

The `runner-*` folders come from the CI fixture-dump job (docs/BUILD_PLAN.md §2.4, below); beta testers' "Copy raw
data" adds real Macs. Until then, everything marked **VERIFY** has no verbatim sample here.

## GitHub runners (`runner-macos-26/`, `runner-macos-15-intel/`)

Captured by `.github/workflows/fixtures.yml` on GitHub-hosted runners, run 36430339928, 2026-09-28. These are virtual
machines, so no battery/NVMe/real serials. Each command has `<name>.stdout`, `.stderr` and `.status` (exit code)
exactly as the workflow wrote them (it had already replaced serials and UUIDs with `XXXX`); `about.txt` is `sw_vers`,
`uname -m` and the runner image. Only the empty `MobileMeAccounts_exists.stdout`/`.stderr` were left out.
`RunnerFixtureTests` builds RawData from them the way `Collector.collectAll()` does.

| Folder | Runner | Mac | Worth knowing |
|---|---|---|---|
| `runner-macos-26` | `macos-26`, image macos26 20260907.0351.1 | macOS 26.6.2 (25G83), arm64 VM: `VirtualMac2,1`, "Apple Virtual Machine 1", "Apple M1 (Virtual)" | `activation_lock_status` is `activation_lock_disabled`; `number_processors` is the Int `3`; SPDisplaysDataType and SPNVMeDataType are empty lists; SPStorageDataType lists Cryptex disk images (`is_internal_disk: "no"`) around the startup volume, which has no `device_name` or `smart_status` |
| `runner-macos-15-intel` | `macos-15-intel`, image macos15 20260824.0482.1 | macOS 15.7.9 (24G830), x86_64 VM reporting `Macmini6,2`, "Mac mini", i7-8700B | no `activation_lock_status` key; `cpu_type: "Unknown"`; drive "VEERTU ANKA", rotational, SATA, no `smart_status` |

What they settle (on these VMs, both macOS versions):

- `profiles status -type enrollment` and `fdesetup status` need no root: `sudo -u nobody` prints the same, exit 0.
- `sudo profiles show -type enrollment` on a Mac not in Apple Business prints `Error fetching Device Enrollment
  configuration: Client is not DEP enabled.` on stderr, exit 1. Without root it prints `Must be running as root`, exit 1.
- `ioreg -r -c AppleSmartBattery -a` with no battery prints nothing (not an empty array), exit 0.
- `sysctl` skips names it doesn't know (`hw.perflevel1.*` here) silently: no stderr, exit 0. Intel and VMs report
  `hw.nperflevels: 1` with `hw.perflevel0.name: Standard`.
- `~/Library/Preferences/MobileMeAccounts.plist` didn't exist on either runner (`test -f`, exit 1).

| File | Command | Mac | Provenance | Source |
|---|---|---|---|---|
| `SPHardwareDataType_AppleSilicon_M5Max_lockEnabled.json` | `system_profiler SPHardwareDataType -json` | MacBook Pro Mac17,6, M5 Max | verbatim (identifiers were already masked by the poster) | https://github.com/vladkens/macmon/issues/47 |
| `sysctl_AppleSilicon_M5Max_perflevels.txt` | `sysctl hw.perflevel*` (subset) | same Mac | verbatim | https://github.com/vladkens/macmon/issues/47 |
| `SPHardwareDataType_AppleSilicon_M1_lockDisabled.json` | `system_profiler SPHardwareDataType -json` from Terminal | MacBook Air MacBookAir10,1, M1 | verbatim, identifiers masked | https://forum.golangbridge.org/t/exec-command-return-different-values-between-go-and-commandline/26247 |
| `SPHardwareDataType_AppleSilicon_M1_underRosetta.json` | same command from an x86_64 (Rosetta) process on the same Mac | same Mac | verbatim, identifiers masked. Shows `cpu_type: "Unknown"`, `number_processors` as an Int | same thread |
| `SPHardwareDataType_Intel_iMacPro_lockDisabled.json` | `system_profiler SPHardwareDataType -json` | iMac Pro iMacPro1,1, Xeon W | verbatim (poster's own `*` masking) | https://github.com/kolide/launcher/issues/572 |
| `SPPowerDataType_AppleSilicon_excerpt_83pct.json` | `system_profiler SPPowerDataType -json` | Apple silicon MacBook | **excerpt** (the author cut other keys) | https://product.st.inc/entry/2024/11/28/163207 |
| `SPPowerDataType_Intel_excerpt_checkBattery.json` | same | Intel MacBook, text report "Service Recommended" | **excerpt**; one trailing comma removed so it parses | same article |
| `ioreg_AppleSmartBattery_Intel_excerpt.plist` | `ioreg -arlc AppleSmartBattery -w 0` | Intel MacBook | **excerpt** (3 keys) | same article |
| `ioreg_AppleSmartBattery_AppleSilicon_M1Max_text.txt` | `ioreg -r -c AppleSmartBattery -l -w0` (text, not `-a`) | MacBook Pro MacBookPro18,2, M1 Max | verbatim first block, battery serial masked | https://github.com/darrylmorley/whatcable/issues/95 |
| `ioreg_AppleSmartBattery_AppleSilicon_M1Max_converted.plist` | shape of `ioreg -r -c AppleSmartBattery -a` | same Mac | **converted by hand** from the text dump above: only the 7 keys Tirekick reads. VERIFY the real `-a` layout with the CI dump | same issue |
| `SPStorageDataType_AppleSilicon_1TB_withUSB.json` | `system_profiler SPStorageDataType -json` | Apple silicon, APPLE SSD AP1024Z + USB drive | verbatim | https://forum.bigfix.com/t/macos-spsoftwaredatatype-fun-with-json/51411 |
| `SPDisplaysDataType_AppleSilicon_M1Pro_builtinPlus2.json` | `system_profiler -json SPDisplaysDataType` | MacBook Pro M1 Pro + 2 Dell displays | verbatim | https://github.com/osquery/osquery/issues/7486 |
| `profiles_status_notEnrolled.txt`, `_mdm.txt`, `_mdmUserApproved.txt`, `_dep.txt` | `profiles status -type enrollment` (run without sudo) | macOS 10.13.4 | verbatim | https://derflounder.wordpress.com/2018/03/30/detecting-user-approved-mdm-using-the-profiles-command-line-tool-on-macos-10-13-4/ |
| `profiles_status_depWithServer.txt` | same, newer macOS: adds `MDM server:` | — | verbatim sample from a source comment | Chromium `base/enterprise_util_mac.mm` (runs `/usr/bin/profiles status -type enrollment` as the user) |
| `profiles_show_enrollment_assigned.txt` | `sudo profiles show -type enrollment` | Mac assigned in ABM | verbatim (the prompt and `Password:` lines dropped) | https://twocanoes.com/knowledge-base/troubleshooting-deployment-enrollment-dep-for-macos-by-viewing-the-activation-record/ |
| `profiles_show_enrollment_notDEP.txt` | same | Mac not in ABM/ASM | verbatim quote from a search snippet of an r/MacOS thread | https://www.reddit.com/r/MacOS/comments/1k7j8e3/buying_a_mdm_bypassed_macbook_pro_m1/ |
| `profiles_show_enrollment_error34006.txt` | same | Mac that couldn't reach Apple | verbatim | https://nwstrauss.com/posts/2020-08-11-mitigating-mac-enrollment-failures/ |
| `fdesetup_status_on.txt`, `fdesetup_status_off.txt` | `fdesetup status` | — | the two documented one-line outputs | https://apple.stackexchange.com/questions/359544/how-to-confirm-if-filevault-encryption-has-fully-completed |

## Not found yet (VERIFY with real Macs)

- **`system_profiler -json SPNVMeDataType`**: no verbatim sample with a drive (both runners print an empty list). Key names (`_items`, `device_model`, `size_in_bytes`
  as an integer, `smart_status`, `spnvme_trim_support`, `volumes`) come from gopsutil's struct that parses the real output:
  https://github.com/shirou/gopsutil/blob/master/disk/disk_darwin.go
- A full `SPPowerDataType` with the `_name: "spbattery_information"` item: seen only as `plutil -p` output
  (https://zenn.dev/ssk_ats/articles/ce657644540ee7), which confirms `sppower_battery_charge_info` and
  `sppower_battery_health_info` { cycle count 38, "Good", "88%" } sit in the same item.
- SMART `"Failing"`, battery health strings other than "Good"/"Check Battery", `activation_lock_status` on a real Intel Mac
  without a T2 chip (the Intel runner VM has no key), `profiles` output of "(null)".
