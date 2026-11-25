# Performance: the Jac rewrite against the original Python

The original is commit `e34004270` (checked out at `../../base/mobilerun`). The Jac rewrite is the
`neojac-deslop` branch, built with neojac 0.5.1. This branch, `neojac-perf`, is that rewrite after
the speed work below.

## What runs where

`archwire.jac` has two spaces, both `cpython`:

```
space mobilerun: cpython { "."; }          # the wheel: every mobilerun/*.jac module
space mobilerun_dev: cpython { tests.*; }  # the pytest suite (Python)
```

None of the code is in a native space. neojac compiles each Jac module to a CPython 3.15 code
object (`.jac/build/pypi/top/site/mobilerun/**.pyc`), plus the runtime helper `_jac_mobilerun.py`.
So the Jac runs on the same interpreter as Python would, and only the code neojac emits differs.
No call crosses between spaces at run time (see blocker 1 for why none should).

## How it was measured

- **Machine:** shared, 20 cores. The load average was between 15 and 80 during the runs (each row
  below gives load at its start and end). Under that load, single samples swing by ±50%. So every
  number is a **median** of runs that alternate original and Jac (round-robin), and the minimums
  were checked as well.
- **Variants:**
  - `orig 3.15`: the original on neojac's CPython 3.15, with the same dependency pins as the Jac
    venv. This is the like-for-like baseline: same interpreter, same libraries.
  - `orig 3.12`: the original on CPython 3.12, which upstream supports (`requires-python <3.14`).
    It uses a separate venv pinned to the same versions.
  - `jac before`: a frozen copy of the `neojac-deslop` build.
  - `jac after`: a frozen copy of this branch's build.
- **Same inputs, same outputs:**
  - CLI commands give byte-identical stdout and exit codes, run in a sandboxed `HOME` with
    telemetry off.
  - Every workload prints a SHA-256 digest of its results, and all four variants agree on every
    run.
  - The test suites end identically: **15 failed, 1459 passed** in all four variants. The 15
    failures are environmental (langfuse not installed, a driver identity check, a loopback
    OAuth test, a MiniMax warning test) and fail the same way in the original.
- **Workloads:**
  - Start-up: `import mobilerun`, plus the offline CLI commands (`--version`, `--help`,
    `run --help`, `devices`, `doctor`, `whoami`).
  - The pytest suite.
  - In-process workloads for the code an agent step runs, built on synthetic but deterministic
    700-node accessibility trees:
    - `ui`: ConciseFilter and DetailedFilter → IndexedFormatter → UIState tap points.
    - `search`: element_search filters.
    - `macro`: compare_states.
    - `xml`: tool-call parsing.
    - `images`: screenshot resize with grid.
  - The workload timings are in-process; start-up is excluded.
- **Scripts:** in `~/neojac-deslop/perf/mobilerun/`: `work.py` (the workloads), `bench3.py` and
  `benchwork.py` (the runners), `env.sh` (the variants).

## Before / after

Medians; ×n is relative to `orig 3.15`.

| Workload | orig 3.15 | orig 3.12 | jac before | jac after | load |
|---|---:|---:|---:|---:|---|
| `ui` (filter, format, 59 tap points ×2, ×4 trees) | 237 ms | 344 ms | 1213 ms (×5.12) | **334 ms (×1.41)** | 39→37 |
| `search` (element_search ×30) | 264 ms | 228 ms | 609 ms (×2.30) | **518 ms (×1.96)** | 37→25 |
| `macro` (compare_states ×300) | 197 ms | 218 ms | 865 ms (×4.40) | **281 ms (×1.43)** | 25→30 |
| `xml` (parse 60 replies ×20) | 26.5 ms | 24.9 ms | 41.7 ms (×1.57) | 40.4 ms (×1.52) | 30→25 |
| `images` (resize + grid ×4) | 804 ms | 804 ms | 816 ms (×1.02) | 797 ms (×0.99) | 25→19 |
| `import mobilerun` | 1778 ms | 1511 ms | 1765 ms (×0.99) | 1842 ms (×1.04) | 19→18 |
| `mobilerun --version` | 3992 ms (min 1906) | 2816 ms (min 1642) | 3462 ms (min 1848) | 3095 ms (min 1932) | 18→33 |
| `mobilerun --help` | 3488 ms (min 1931) | 2619 ms (min 1691) | 3344 ms (min 1957) | 2796 ms (min 1988) | 33→29 |
| `mobilerun run --help` | 2233 ms | 2012 ms | 2200 ms (×0.98) | 2285 ms (×1.02) | 29→15 |
| `mobilerun devices` | 2271 ms | 2055 ms | 2382 ms (×1.05) | 2370 ms (×1.04) | 15→15 |
| `mobilerun doctor` | 3079 ms | 2724 ms | 3134 ms (×1.02) | 3118 ms (×1.01) | 15→36 |
| `mobilerun whoami` | 2631 ms | 2250 ms | 2603 ms (×0.99) | 2515 ms (×0.96) | 36→26 |
| pytest suite (1474 tests) | 33.5 s (min 28.7) | 44.2 s (min 30.5) | 39.7 s (min 26.8) | 41.7 s (min 27.8) | 26→20 |

The 11-run CLI and 5-run suite timings are in `~/neojac-deslop/perf/mobilerun/final_*.txt`. A load spike in the
middle of the `--version` and `--help` rows inflated their medians, so their minimums are given
too. By minimum, every CLI command is within ±5% of the original on the same interpreter. The
suite is mostly mock setup, asyncio and library code. Its five runs per variant spread by ±30%
under this load, and no variant is consistently faster: by minimum, the Jac is 3–6% faster than
the original.

**In short:** start-up and every CLI command were already at parity, and still are. The CPU paths
a device step runs were 2–5× slower than the original. They are now 1.4–2× slower: the UI
pipeline is 3.6× faster and macro matching 3.1× faster than before. Image handling is in Pillow
and was always at parity. In a real run, each step's time is dominated by the device round trip
and the LLM call, so the remaining gap is a few milliseconds per step.

## Where the time went, and what fixed it

**Start-up.** `python -X importtime` shows both builds import the same ~2,640 modules. The
mobilerun modules' own import time is the same in both (≈1.06 s vs 1.08 s of self time under
`-X importtime`). `_jac_mobilerun`, the only addition, costs 12 ms. Almost all of the 1.8–2.3 s is
dependencies, with llama_index ≈1.1 s (openai and sqlalchemy under it), posthog, opentelemetry and
mcp after it. They load because the package root, like the original's, imports the agent stack
eagerly. Deferring them would mean restructuring the package's import graph: `config_manager`
already imports the agent package, and an import cycle `config_manager ↔ executor_agent` only
resolves because of the eager root's order. That changes import-time behaviour, so it was left
alone (tested on a scratch copy; see "Not done").

**CPU paths.** All of the slowdown came from what neojac's CPython backend emits around values it
cannot type. The emitted code (`neojac emit-py mobilerun -o DIR`) showed four costs:

1. **`_jac.held(...)` around every read through an `any`.** This applies to a method call or an
   index on an `any` receiver. On this machine it adds ~170 ns to a 27 ns `dict.get`. The port
   made far more things `any` than necessary:
   - every `typing.Dict/List/Tuple[...]` annotation, which neojac treats as `any`;
   - 2,351 `x: any = ...` local declarations, so even `parts = []; parts.append(...)` went
     through `held`;
   - `glob Bounds: any = Tuple[int, int, int, int]`, which made every bounds tuple `any`.
2. **The port's `operator.le(a, b)` / `operator.ne(...)` calls**, written for chained
   comparisons, plus a `bool(...)` around every comparison of `any` operands.
3. **`_jac.convert(...)` wherever an `any` reaches a typed container**, which walks every item.
   That covers a `list[T]` or `dict[K, V]` parameter, `x as list[any]`, and `.extend(any)` on a
   typed list. Converting an 8-key dict to `dict[str, any]` costs ~6.4 µs.
4. **`import from __future__ { annotations }`** (kept in 36 modules) makes subscripted
   annotations such as `tuple[int, int]` `any` too. In `state.jac` it made even `index: int`
   `any`; that showed up as E2199 once the base class was retyped.

The changes, in commit order:

- `4a78570` **Typed tap-point geometry.** The hot path was `find_clear_point`, about 740
  recursive calls per tap, each scanning every blocker. It now takes `tuple[int, int, int, int]`
  boxes and uses chained comparisons, and its emitted Python is now line for line the original's.
  `UIState` parses bounds strings into typed boxes once, so no call converts. `state.jac` and
  `stealth_state.jac` lost their `__future__` import. The cold `find_uncovered_point`, used only
  when a tap is blocked, stays untyped on purpose: a float screen size from the device JSON must
  keep working as it did in Python. `ui` went from 1213 to ~430 ms.
- `ca26150` **Formatter, filters, element search, macro.**
  - `operator.*` calls are back to plain operators.
  - Fresh-literal locals (`x: any = []`, `""`, numbers) are typed.
  - The tree helpers return `list[any]`, so a typed list extended with them needs no
    per-element convert. A first attempt typed `all_nodes` but not `flatten_tree`; that added a
    `convert` per extend and made `search` slower, which this fixed.
  - `geometry.parse_bounds` is shared by the formatter's tap-blocker overlap test and `UIState`.
  - `node_semantic_key` is now `tuple(map(node.get, FIELDS))`: one dynamic read instead of seven
    `held` calls.
  - Result: `ui` ~290–330 ms, `macro` 865 → 281 ms.
- **`text_matches` / `has_text`** read the three text fields with `map(node.get, ...)`: no
  `held` per field. This made no measurable difference to `search` under this load. It is
  committed because it removes three dynamic reads per node and doesn't change behaviour. It
  came after the frozen `jac after` snapshot, so the table doesn't include it. Five alternating
  runs afterwards gave `search` 465–690 ms against the original's 260–307 ms, with the same digest.

- **`UIState._collect_all`** returns a `list[any]` built in a `list[any]`, so its append and
  extend are no longer `held` calls (they were typed `typing.List`). Seven alternating runs at
  load 12 gave `ui` 279 → 264 ms median, against the original's 202 ms, with the same digest.

- **`get_element_center` / `sort_by_position`** read the bounds edges with
  `map(bounds.get, EDGES, ZEROS)`: one `held` instead of five (or three). Seven alternating
  runs, with these and the `text_matches` change, gave `search` 481 → 404 ms median against
  the original's 287 ms. Load rose from 11 during the last two rounds; the digest was the same.

What is left of the gap is `held` on reads of the JSON nodes themselves. An accessibility node
is a dict whose values are of mixed types, so it is `any` by nature. Typing it means converting
it, which costs more than the `held`s it saves (see blocker 2).

Behaviour is unchanged: identical workload digests, identical CLI output, the same suite result
after every step, and no test edited.

## Blockers

1. **A native space can't be used from this package without an HTTP crossing.** The program's
   host is CPython: the wheel, `python -m mobilerun`, pytest, and users' `import mobilerun`. A
   call from a `cpython` space into a `native` space is a remote crossing, even inside one app.
   Minimal reproduction (`~/neojac-deslop/perf/mobilerun/scratch2/`):

   ```jac
   # archwire.jac
   graph spaces {
       space nat: native { geo; }
       space py: cpython { entry m; }
       app main { run py, nat; }
   }
   graph import { geo ++> m { clear_point } }
   ```

   ```
   $ neojac run main
     File ".../rt/stdjac/remote.jac", line 376, in crossing_request
   rt.stdjac.remote.RemoteUnavailable: no URL for space 'nat' (JAC_REMOTE_NAT)
   ```

   With a URL set, each call is an HTTP request with its arguments serialized. The work it would
   replace takes microseconds per call (a tap-point search, one tree node), so moving it native
   would be slower. The docs (`apps/crossings`) say only native-to-native calls inside one app are
   ordinary calls. `neojac build --lib` gives a C-ABI library, but the data here is nested Python
   dicts, which a C ABI can't carry without converting them.

2. **There is no unchecked way to treat an `any` as a typed value in a `cpython` space.** For
   data that is `any` by nature (JSON), the emitted code has two options, and both cost:
   - Every read is wrapped in `_jac.held(v)`. That is a Python call plus an `isinstance`, needed
     only for structs, which this program never uses.
   - Typing the value converts it, and `x as T` does the same as `x: T = ...`: it walks every
     item.

   Reproduction (`~/neojac-deslop/perf/mobilerun/repro_held_convert.txt`):

   ```jac
   def via_typing(nd: Dict[str, Any]) -> any { b = nd.get("bounds", {}); return b.get("left", 0); }
   def walk(elements: list[dict[str, any]], target: int) -> dict[str, any] | None {
       for item in elements {
           ...
           child = walk((item.get("children") or []) as list[any], target);
   ```

   emits

   ```python
   b = _jac.held(nd.get('bounds', {}))
   return _jac.held(b.get('left', 0))
   child = walk(_jac.convert(list(_jac.convert(item.get('children') or [], (list, None))), (list, (dict, str, None))), target)
   ```

   Measured: `d.get('a')` takes 27 ns and `_jac.held(d.get('a'))` takes 200 ns.
   `_jac.convert(d, (dict, str, None))` on an 8-key dict takes 6.4 µs.

3. **`from __future__ import annotations` silently makes typed annotations `any`.**
   (`~/neojac-deslop/perf/mobilerun/repro_future_annotations.txt`):

   ```jac
   import from __future__ { annotations }
   def first_lt(pair: tuple[int, int], v: int) -> bool { return pair[0] < v; }
   ```

   emits `return bool(_jac.held(pair[0]) < v)`. Without the import, it emits
   `return pair[0] < v`. In the repo, removing the import from `state.jac` alone gave
   `error[E2199]: StealthUIState.get_element_coords overrides UIState.get_element_coords with
   another signature: its parameter 'index' is any, and the method it overrides takes int there`.
   That means `index: int` had been read as `any` in the module that kept the import.

4. **Iterating a fixed-size tuple of typed elements yields `any`.**
   (`~/neojac-deslop/perf/mobilerun/repro_tuple_iter.txt`):
   `for p in (a, a) { total += p[0]; }` with `a: tuple[int, int, int, int]` emits
   `total += _jac.held(p[0])`. The workaround is a `list[T]` literal. It was used while typing
   `geometry.find_uncovered_point`, before that cold path was left untyped on purpose.

## Not done, and why

- **Lazy imports for start-up.** On a scratch copy of the original with a lazy package root,
  `import mobilerun` dropped from ~1.8 s to 65 ms. But `mobilerun.config_manager` then failed with
  `ImportError: cannot import name 'AgentConfig' from partially initialized module`, and every
  CLI module still pulled in llama_index through `mobilerun.agent`. Doing it means reordering the
  package's import graph, and it changes what `import mobilerun` loads. That isn't a behaviour-
  preserving speed-up of the rewrite, so the Jac matches the original's start-up instead.
- **Blanket removal of the remaining `x: any` locals and `__future__` imports.** In the 36
  modules with the import, retyping turns annotated parameters into checked places. An `any`
  argument there would then be converted (a bool becomes an int) or rejected (`None` for an
  `int`), where Python passed it through. That was done only in the modules on the measured hot
  path, with their call sites checked, and not repo-wide.
