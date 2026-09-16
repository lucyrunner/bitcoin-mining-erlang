# 🪙 Bitcoin Mining with the Erlang Actor Model

## 👥 Group members
- Name: Lucy Liu
- Gator ID: "zifeiliu"


## 📁 Files
```
Bitcoin mining erlang/
  src/boss.erl      - the boss actor: hands out work, prints found coins
  src/worker.erl    - worker actors: pull work, hash candidates, report hits
  src/bitcoin.erl   - entry point (main/1): server mode or worker mode
  Makefile          - `make` compiles everything into ebin/
  project1          - launcher script (see Usage)
  README.md         - this file
```

## 🔨 Build
```
make
```

## ▶️ Usage
```
./project1 K              # run as the SERVER, mining locally for K
                           # leading-zero hashes and accepting remote workers
./project1 <ServerIP>      # run as a WORKER, joining the server at <ServerIP>
```
The two modes are distinguished exactly like the assignment's two examples:
a single numeric argument means "run as server with this difficulty"; a
non-numeric argument is treated as the server's address and this instance
joins as a worker.

Example:
```
# on the server machine
./project1 4

# on a worker machine, once the server is running
./project1 10.22.13.155
```
A worker prints nothing of its own — every coin found, by the server or by
any worker, is sent back to the boss actor and printed only there, as
required.

## 🎭 Actor model design
- **`boss` actor** (`boss.erl`) is the single owner of the mining state: the
  difficulty `K`, the next unassigned range of candidate integers, and the
  best coin seen so far. It only ever does two things: hand out a
  `{work, K, Start, End}` range when asked, and print a line when a
  `{found, Input, Hash, Zeros}` message arrives. It is registered locally
  under the name `boss` so that remote nodes can message it directly via
  `{boss, Node} ! Msg` without needing global registration.
- **`worker` actors** (`worker.erl`) do all the hashing. `start_local_workers/2`
  spawns one actor per `erlang:system_info(schedulers)` — i.e. one per usable
  core — whether it's running inside the server process or on a remote
  worker node. Each actor independently asks the boss for a range, computes
  `SHA-256(GatorID ++ ";" ++ N)` for every `N` in that range, and reports any
  hash whose hex representation has at least `K` leading zero digits. When a
  range is exhausted, the actor immediately asks for another — so the boss
  performs continuous, on-demand load balancing rather than a fixed
  up-front assignment.
- **Distribution** (`bitcoin.erl`) uses standard distributed Erlang
  (`net_kernel`, a shared cookie, `net_adm:ping/1`) to let a worker node join
  the server node over the network. No shared memory or locks are used
  anywhere — every core, local or remote, is just another actor that only
  ever talks to the boss (or to itself, recursively) via message passing.

## ⚙️ Work unit size
The size of the work unit is the number of consecutive candidate integers
(`Start..End`) the boss hands to a worker actor in one `{work, ...}`
response. We determined a good size empirically: pick a low difficulty
(so runs don't stall waiting for a rare hit), start the boss+workers with a
given `WORK_UNIT`, let them run for a fixed number of seconds, and measure
how many candidate integers were processed (hashes/sec) using the boss's
`NextStart` counter.

| Work unit | Hashes/sec (example run) |
|----------:|--------------------------:|
| 200       | ~75,000  |
| 1,000     | ~76,000  |
| 5,000     | ~74,000  |
| 20,000    | ~80,000  |
| 50,000    | ~87,500  |
| 100,000   | ~100,000 |
| 500,000   | ~125,000 |

Throughput climbs as the work unit grows because every hand-off costs a
message round trip (`work_request` → `work`) between a worker and the boss;
a bigger unit amortizes that fixed cost over more hashes. But too large a
work unit hurts **load balancing across a distributed cluster of
heterogeneous machines** — if one slow or late-joining machine is handed a
huge range, every other machine can end up idle waiting for it near the
end of a run.

We settled on **`WORK_UNIT = 50,000`** (already set in `bitcoin.erl`),
which is past the steep part of the throughput curve while still small
enough for the boss to keep re-balancing work every fraction of a second
per worker.

> 📝 TODO: replace the table above with numbers from your own run — start
> the server, let it run for e.g. 60 seconds at a couple of different
> `WORK_UNIT` values, and note the hashes/sec each time.

## 🎯 Result of running for input 4 (`./project1 4`)
> 📝 TODO: paste your own output here. Run:
> ```
> ./project1 4
> ```
> let it run for a while, then Ctrl+C, and paste the printed lines
> (GatorID;N \t hash) below.
```
TODO — paste coin output here
```

## ⏱️ Running time
> 📝 TODO: run the following and paste the result:
> ```
> time timeout 60 ./project1 4
> ```
> (times out after 60 seconds so it doesn't run forever)
```
real    TODOs
user    TODOs
sys     TODOs
```
CPU-time / real-time ratio ≈ `user / real` — this tells you roughly how
many cores were used. A ratio near 1.0 means almost no parallelism was
achieved (this can happen on a machine with few cores, or if something is
limiting concurrency); a ratio approaching your machine's core count means
the actor model is using your hardware well.

## 🏆 Best coin found
> 📝 TODO: from your run's output, find the line with the most leading
> zeros and paste it here:
```
TODO
```

## 🌐 Distributed test
> 📝 TODO: describe how many machines you tested with. At minimum, test
> with 2 (a server and one worker) using:
> ```
> # on the server
> ./project1 4
>
> # on the worker, once the server is running
> ./project1 <server's IP address>
> ```
> Confirm the worker prints nothing of its own, and that coins found by
> the worker still show up in the server's output. Report the largest
> number of machines you were able to test with.