import builtins;

import importlib;

import asyncio;

import json;

import re;

import shutil;

import from dataclasses { dataclass }

import from enum { Enum }

import from typing { Any }

import httpx;

import requests;

import from async_adbutils { AdbDevice, adb }

import from mobilerun_core_local.driver.android.portal {
    GITHUB_API_HOSTS,
    PORTAL_PACKAGE_NAME,
    REPO,
    check_portal_accessibility,
    enable_portal_accessibility,
    get_compatible_portal_version,
    portal_content_uri,
    portal_ime_id,
}

import from mobilerun_core_local.transport.android.portal_client { PortalClient }

import from rich.console { Console }

glob __version__: any = _PACKAGE_VERSION;

glob console: any = Console();

glob PORTAL_REMOTE_PORT: any = 8080;

class Status(Enum) {
    static has PASS: any = "pass";

    static has WARN: any = "warn";

    static has FAIL: any = "fail";
}

@dataclass
class CheckResult {
    has name: builtins.str;

    has status: Status;

    has message: builtins.str;

    has detail: builtins.str = "";
}

def _status_icon(status: Status) -> builtins.str {
    if status == Status.PASS {
        return "[green]✓[/]";
    } elif status == Status.WARN {
        return "[yellow]⚠[/]";
    } else {
        return "[red]✗[/]";
    }
}

def _print_result(result: CheckResult, debug: builtins.bool = False) -> None {
    icon: any = _status_icon(result.status);
    console.print(f"  {result.name:<22} {result.message:<42} {icon}");
    if debug and result.detail {
        console.print("  " + format("", "22") + " [dim]" + format(result.detail, "") + "[/]");
    }
}

def _parse_version_tuple(version_str: builtins.str) -> builtins.tuple {
    cleaned: any = version_str.lstrip("v").strip();
    parts: any = [];
    for p in cleaned.split(".") {
        try {
            parts.append(`int(p));
        } except ValueError {
            parts.append(0);
        }
    }
    return `tuple(parts);
}

def _parse_portal_version(version_str: builtins.str) -> builtins.tuple {
    cleaned: any = version_str.lstrip("v").strip();
    parts: any = [];
    for p in cleaned.split(".") {
        `match: any = re.match("\\d+", p);
        parts.append(`int(`match.group()) if `match else 0);
    }
    return `tuple(parts);
}

async def check_sdk_version(debug: builtins.bool) -> CheckResult {
    current: any = __version__;
    latest: any = None;

    for host in GITHUB_API_HOSTS {
        try {
            url: any = f"{host}/repos/droidrun/mobilerun/releases/latest";
            resp: any = requests.get(url, timeout=10);
            if resp.status_code == 200 {
                data: any = resp.json();
                if "release" in data {
                    tag: any = data["release"].get("tag", data["release"].get("tag_name", ""));
                } else {
                    tag = data.get("tag_name", "");
                }
                latest = tag.lstrip("v");
                break;
            }
        } except Exception {
            continue;
        }
    }

    if latest is None {
        return CheckResult(
            "SDK Version",
            Status.WARN,
            f"{current} (could not check latest)",
            detail="GitHub API unreachable",
        );
    }

    current_t: any = _parse_version_tuple(current);
    latest_t: any = _parse_version_tuple(latest);

    if current_t < latest_t {
        return CheckResult(
            "SDK Version",
            Status.WARN,
            f"{current} (latest: {latest})",
            detail="pip install --upgrade mobilerun",
        );
    }
    return CheckResult("SDK Version", Status.PASS, f"{current} (up to date)");
}

async def check_config(debug: builtins.bool) -> builtins.tuple[CheckResult, Any] {
    ConfigLoader: any = importlib.import_module("mobilerun.config_manager").ConfigLoader;
    OutdatedConfigError: any = importlib.import_module(
        "mobilerun.config_manager.loader"
    ).OutdatedConfigError;

    config_path: any = ConfigLoader.get_user_config_path();

    if not config_path.exists() {
        try {
            config: any = ConfigLoader.load();
            return (CheckResult("Config", Status.PASS, f"{config_path} (created)"), config);
        } except Exception as e {
            return (
                CheckResult(
                    "Config", Status.FAIL, "failed to create default config", detail=`str(e)
                ),
                None,
            );
        }
    }

    try {
        config = ConfigLoader.load();
        return (CheckResult("Config", Status.PASS, `str(config_path)), config);
    } except OutdatedConfigError {
        return (
            CheckResult(
                "Config",
                Status.FAIL,
                f"{config_path} (outdated, missing _version)",
                detail="See: mobilerun config_example.yaml",
            ),
            None,
        );
    } except Exception as e {
        return (
            CheckResult("Config", Status.FAIL, f"failed to load: {e}", detail=`str(config_path)),
            None,
        );
    }
}

async def check_adb(debug: builtins.bool) -> CheckResult {
    adb_path: any = shutil.which("adb");
    if not adb_path {
        return CheckResult(
            "ADB", Status.FAIL, "adb not found in PATH", detail="Install Android SDK Platform Tools"
        );
    }

    try {
        devices: any = await adb.list();
        count: any = len(devices);
        return CheckResult("ADB", Status.PASS, f"found, {count} device(s)", detail=adb_path);
    } except Exception as e {
        return CheckResult("ADB", Status.FAIL, f"adb found but server error: {e}", detail=adb_path);
    }
}

async def check_device(
    serial: builtins.str | None, debug: builtins.bool
) -> builtins.tuple[CheckResult, AdbDevice | None] {
    try {
        device: any = await adb.device(serial);
        state: any = await device.get_state();
        if state == "device" {
            return (CheckResult("Device", Status.PASS, f"{device.serial} (online)"), device);
        }
        return (CheckResult("Device", Status.FAIL, f"{device.serial} (state: {state})"), None);
    } except Exception as e {
        msg: any = `str(e);
        if "no devices" in msg.lower() or "not found" in msg.lower() {
            return (CheckResult("Device", Status.FAIL, "no device connected"), None);
        }
        return (CheckResult("Device", Status.FAIL, `str(e)), None);
    }
}

async def check_portal_installed(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.bool] {
    try {
        packages: any = await device.list_packages();
        if PORTAL_PACKAGE_NAME in packages {
            return (CheckResult("Portal", Status.PASS, "installed"), True);
        }
        return (CheckResult("Portal", Status.FAIL, "not installed"), False);
    } except Exception as e {
        return (CheckResult("Portal", Status.FAIL, f"error: {e}"), False);
    }
}

def _get_latest_portal_version -> builtins.str | None {
    for host in GITHUB_API_HOSTS {
        try {
            url: any = f"{host}/repos/{REPO}/releases/latest";
            resp: any = requests.get(url, timeout=10);
            if resp.status_code == 200 {
                data: any = resp.json();
                if "release" in data {
                    tag: any = data["release"].get("tag", data["release"].get("tag_name", ""));
                } else {
                    tag = data.get("tag_name", "");
                }
                return tag.lstrip("v").strip() if tag else None;
            }
        } except Exception {
            continue;
        }
    }
    return None;
}

async def check_portal_version(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.str | None, builtins.str | None, builtins.str | None] {
    installed: any = None;
    try {
        output: any = await device.shell(
            "content query --uri " + format(portal_content_uri(PORTAL_PACKAGE_NAME, "version"), "")
        );
        if "result=" in output {
            json_str: any = output.split("result=", 1)[1].strip();
            data: any = json.loads(json_str);
            if data.get("status") == "success" {
                installed = data.get("result") or data.get("data");
            }
        }
    } except Exception {}

    if not installed {
        return (
            CheckResult("Portal Version", Status.WARN, "could not read version"),
            None,
            None,
            None,
        );
    }
    latest_portal: any = _get_latest_portal_version();
    (expected, download_base, mapping_fetched) = get_compatible_portal_version(
        __version__, debug
    ) as any;

    installed_t: any = _parse_portal_version(installed);
    parts: any = [f"v{installed}"];

    if expected {
        expected_t: any = _parse_portal_version(expected);
        if installed_t != expected_t {
            parts.append(f"expected {expected}");
        }
    }

    if latest_portal {
        latest_t: any = _parse_portal_version(latest_portal);
        if installed_t < latest_t {
            parts.append(f"latest: {latest_portal}");
        }
    }

    msg: any = " → ".join(parts[:1])
        + (" (" + ", ".join(parts[1:]) + ")" if len(parts) > 1 else "");
    if expected {
        expected_t = _parse_portal_version(expected);
        if installed_t < expected_t {
            return (
                CheckResult("Portal Version", Status.WARN, msg),
                installed,
                expected,
                download_base,
            );
        }
        if installed_t > expected_t {
            return (
                CheckResult(
                    "Portal Version",
                    Status.PASS,
                    f"v{installed} (newer than {expected}, pinned for mobilerun {__version__})",
                ),
                installed,
                expected,
                download_base,
            );
        }
        return (
            CheckResult(
                "Portal Version", Status.PASS, f"v{installed} (pinned for mobilerun {__version__})"
            ),
            installed,
            expected,
            download_base,
        );
    }

    if latest_portal {
        latest_t = _parse_portal_version(latest_portal);
        if installed_t < latest_t {
            return (
                CheckResult(
                    "Portal Version",
                    Status.WARN,
                    msg,
                    detail="pip install --upgrade mobilerun, then mobilerun setup",
                ),
                installed,
                expected,
                download_base,
            );
        }
    }

    if not mapping_fetched and not latest_portal {
        return (
            CheckResult("Portal Version", Status.WARN, f"v{installed} (could not check latest)"),
            installed,
            None,
            None,
        );
    }

    return (
        CheckResult("Portal Version", Status.PASS, f"v{installed} (up to date)"),
        installed,
        expected,
        download_base,
    );
}

async def check_accessibility(
    device: AdbDevice, debug: builtins.bool
) -> builtins.tuple[CheckResult, builtins.bool] {
    try {
        enabled: any = await check_portal_accessibility(device, debug=debug);
        if enabled {
            return (CheckResult("Accessibility", Status.PASS, "enabled"), True);
        }
        return (CheckResult("Accessibility", Status.FAIL, "not enabled"), False);
    } except Exception as e {
        return (CheckResult("Accessibility", Status.FAIL, `str(e)), False);
    }
}

async def check_content_provider(device: AdbDevice, debug: builtins.bool) -> CheckResult {
    try {
        state: any = await device.shell(
            "content query --uri " + format(portal_content_uri(PORTAL_PACKAGE_NAME, "state"), "")
        );
        if "Row: 0 result=" in state {
            return CheckResult("Content Provider", Status.PASS, "reachable");
        }
        return CheckResult(
            "Content Provider", Status.FAIL, "invalid response", detail=state[:100] if debug else ""
        );
    } except Exception as e {
        return CheckResult("Content Provider", Status.FAIL, f"unreachable: {e}");
    }
}

async def check_tcp(device: AdbDevice, debug: builtins.bool) -> CheckResult {
    steps: any = [];
    try {
        toggle_uri: any = portal_content_uri(PORTAL_PACKAGE_NAME, "toggle_socket_server");
        await device.shell(f"content insert --uri {toggle_uri} --bind enabled:b:true");
        steps.append("server enabled");
    } except Exception as e {
        return CheckResult(
            "TCP Mode", Status.FAIL, "failed to enable socket server", detail=`str(e)
        );
    }
    await asyncio.sleep(1);
    auth_headers: builtins.dict[builtins.str, builtins.str] = {};
    try {
        portal: any = PortalClient(device, prefer_tcp=False);
        token: any = await portal._fetch_auth_token();
        if token {
            auth_headers["Authorization"] = f"Bearer {token}";
            steps.append("auth token ok");
        } else {
            steps.append("no auth token");
        }
    } except Exception as e {
        steps.append(f"auth token failed: {e}");
    }
    local_port: any = None;
    try {
        forwards: any = [];
        async for fwd in device.forward_list() {
            forwards.append(fwd);
        }
        for fwd in forwards {
            if fwd.serial == device.serial and fwd.remote == f"tcp:{PORTAL_REMOTE_PORT}" {
                `match: any = re.search("tcp:(\\d+)", fwd.local);
                if `match {
                    local_port = `int(`match.group(1));
                    steps.append(f"reusing forward :{local_port}");
                    break;
                }
            }
        }

        if local_port is None {
            local_port = await device.forward_port(PORTAL_REMOTE_PORT);
            steps.append(f"forwarded :{local_port}");
        }
    } except Exception as e {
        return CheckResult("TCP Mode", Status.FAIL, "port forward failed", detail=`str(e));
    }
    try {
        async with httpx.AsyncClient() as client {
            resp: any = await client.get(
                f"http://localhost:{local_port}/ping", headers=auth_headers, timeout=5
            );
            if resp.status_code == 200 {
                steps.append("ping ok");
                return CheckResult(
                    "TCP Mode", Status.PASS, f"localhost:{local_port}", detail=", ".join(steps)
                );
            }
            return CheckResult(
                "TCP Mode",
                Status.FAIL,
                f"ping returned {resp.status_code}",
                detail=", ".join(steps),
            );
        }
    } except Exception as e {
        return CheckResult("TCP Mode", Status.FAIL, f"ping failed: {e}", detail=", ".join(steps));
    }
}

async def check_portal_state(
    device: AdbDevice, use_tcp: builtins.bool, debug: builtins.bool
) -> builtins.tuple[CheckResult, Any] {
    import from mobilerun_core_local.transport.android.portal_client { PortalClient }

    try {
        portal: any = PortalClient(device, prefer_tcp=use_tcp);
        await portal.connect();
        method: any = "tcp" if portal.tcp_available else "content_provider";

        state: any = await portal.get_state();

        if isinstance(state, `dict) and state.get("error") {
            return (
                CheckResult(
                    "Portal State",
                    Status.FAIL,
                    "error: " + format(state.get("message", state.get("error")), ""),
                ),
                portal,
            );
        }

        required: any = ("a11y_tree", "phone_state", "device_context");
        present: any = [k for k in required if k in state];
        missing: any = [k for k in required if k not in state];

        if missing {
            return (
                CheckResult(
                    "Portal State",
                    Status.FAIL,
                    "missing: " + format(", ".join(missing), ""),
                    detail="present: "
                        + format(", ".join(present), "")
                        + " (via "
                        + format(method, "")
                        + ")",
                ),
                portal,
            );
        }
        return (
            CheckResult(
                "Portal State",
                Status.PASS,
                f"a11y_tree, phone_state, device_context (via {method})",
            ),
            portal,
        );
    } except Exception as e {
        return (CheckResult("Portal State", Status.FAIL, `str(e)), None);
    }
}

async def check_screenshot(portal: Any, debug: builtins.bool) -> CheckResult {
    try {
        data: any = await portal.take_screenshot(hide_overlay=True);
        if data and len(data) > 0 {
            size_kb: any = len(data) / 1024;
            return CheckResult("Screenshot", Status.PASS, f"ok ({size_kb:.0f} KB)");
        }
        return CheckResult("Screenshot", Status.FAIL, "empty response");
    } except Exception as e {
        return CheckResult("Screenshot", Status.FAIL, f"capture failed: {e}");
    }
}

async def check_keyboard(device: AdbDevice, debug: builtins.bool) -> CheckResult {
    try {
        output: any = await device.shell("ime list -s");
        ime_id: any = portal_ime_id(PORTAL_PACKAGE_NAME);
        if ime_id in output {
            return CheckResult("Keyboard", Status.PASS, "available");
        }
        return CheckResult(
            "Keyboard", Status.WARN, "not listed", detail="Will be set up automatically when needed"
        );
    } except Exception as e {
        return CheckResult("Keyboard", Status.WARN, f"could not check: {e}");
    }
}

async def fix_enable_accessibility(device: AdbDevice, debug: builtins.bool) -> builtins.bool {
    console.print("  [blue]→ Enabling accessibility service...[/]");
    try {
        await enable_portal_accessibility(device);
        enabled: any = await check_portal_accessibility(device, debug=debug);
        if enabled {
            console.print("  [green]  accessibility enabled[/]");
            return True;
        }
        console.print("  [yellow]  auto-enable may have failed, opening settings...[/]");
        await device.shell("am start -a android.settings.ACCESSIBILITY_SETTINGS");
        console.print(f"  [yellow]  please enable {PORTAL_PACKAGE_NAME} manually[/]");
        return False;
    } except Exception as e {
        console.print(f"  [red]  failed: {e}[/]");
        try {
            await device.shell("am start -a android.settings.ACCESSIBILITY_SETTINGS");
            console.print(f"  [yellow]  please enable {PORTAL_PACKAGE_NAME} manually[/]");
        } except Exception {}
        return False;
    }
}

async def run_doctor(
    device_serial: builtins.str | None = None, debug: builtins.bool = False
) -> None {
    debug = debug or False;

    console.print("\n[bold]Mobilerun Doctor[/]\n");

    results: builtins.list[CheckResult] = [];
    r: any = await check_sdk_version(debug);
    _print_result(r, debug);
    results.append(r);
    (r_config, config) = await check_config(debug) as any;
    _print_result(r_config, debug);
    results.append(r_config);
    if device_serial is None and config {
        device_serial = getattr(getattr(config, "device", None), "serial", None);
    }
    r = await check_adb(debug);
    _print_result(r, debug);
    results.append(r);
    if r.status == Status.FAIL {
        _print_summary(results);
        return;
    }
    (r_device, device) = await check_device(device_serial, debug) as any;
    _print_result(r_device, debug);
    results.append(r_device);
    if device is None {
        console.print("\n  [dim]Skipping device-dependent checks (no device)[/]");
        _print_summary(results);
        return;
    }
    (r_portal, is_installed) = await check_portal_installed(device, debug) as any;
    _print_result(r_portal, debug);
    if not is_installed {
        _setup_portal: any = importlib.import_module("mobilerun.cli.main")._setup_portal;

        await _setup_portal(path=None, device=device.serial, debug=debug);
        (r_portal, is_installed) = await check_portal_installed(device, debug) as any;
        if not is_installed {
            results.append(r_portal);
            _print_summary(results);
            return;
        }
    }
    results.append(r_portal);
    (r_version, installed_ver, _, _) = await check_portal_version(device, debug) as any;
    _print_result(r_version, debug);
    if r_version.status == Status.WARN and installed_ver {
        console.print("  [blue]→ Updating portal...[/]");
        _setup_portal = importlib.import_module("mobilerun.cli.main")._setup_portal;

        await _setup_portal(path=None, device=device.serial, debug=debug, in_place=True);
        console.print("  [dim]  waiting for portal to start...[/]");
        await asyncio.sleep(3);
        (r_version, _, _, _) = await check_portal_version(device, debug) as any;
        if r_version.status == Status.PASS {
            console.print("  [green]  portal updated[/]");
        } else {
            console.print("  [yellow]  update may not have resolved the version mismatch[/]");
        }
    }
    results.append(r_version);
    (r_a11y, a11y_enabled) = await check_accessibility(device, debug) as any;
    if not a11y_enabled {
        _print_result(r_a11y, debug);
        success: any = await fix_enable_accessibility(device, debug);
        if success {
            r_a11y = CheckResult("Accessibility", Status.PASS, "enabled (auto-fixed)");
            _print_result(r_a11y, debug);
        }
    } else {
        _print_result(r_a11y, debug);
    }
    results.append(r_a11y);
    r = await check_content_provider(device, debug);
    _print_result(r, debug);
    results.append(r);

    (r_cp_state, cp_portal) = await check_portal_state(device, False, debug) as any;
    r_cp_state.name = "State (content)";
    _print_result(r_cp_state, debug);
    results.append(r_cp_state);

    if cp_portal and r_cp_state.status == Status.PASS {
        r = await check_screenshot(cp_portal, debug);
        r.name = "Screenshot (content)";
        _print_result(r, debug);
        results.append(r);
    }
    r = await check_tcp(device, debug);
    _print_result(r, debug);
    results.append(r);

    if r.status == Status.PASS {
        (r_tcp_state, tcp_portal) = await check_portal_state(device, True, debug) as any;
        r_tcp_state.name = "State (tcp)";
        _print_result(r_tcp_state, debug);
        results.append(r_tcp_state);

        if tcp_portal and r_tcp_state.status == Status.PASS {
            r = await check_screenshot(tcp_portal, debug);
            r.name = "Screenshot (tcp)";
            _print_result(r, debug);
            results.append(r);
        }
    }
    r = await check_keyboard(device, debug);
    _print_result(r, debug);
    results.append(r);

    _print_summary(results);
}

def _print_summary(results: builtins.list[CheckResult]) -> None {
    fails: any = [r for r in results if r.status == Status.FAIL];
    warns: any = [r for r in results if r.status == Status.WARN];

    console.print();
    if not fails and not warns {
        console.print("  [bold green]All checks passed.[/]");
    } else {
        if fails {
            console.print(f"  [bold red]{len(fails)} issue(s):[/]");
            for r in fails {
                console.print(f"    [red]✗ {r.name}: {r.message}[/]");
                if r.detail {
                    console.print(f"      [dim]{r.detail}[/]");
                }
            }
        }
        if warns {
            console.print(f"  [bold yellow]{len(warns)} warning(s):[/]");
            for r in warns {
                console.print(f"    [yellow]⚠ {r.name}: {r.message}[/]");
                if r.detail {
                    console.print(f"      [dim]{r.detail}[/]");
                }
            }
        }
    }
    console.print();
}
