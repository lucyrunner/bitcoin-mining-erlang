-module(bench).
-export([run/0]).

run() ->
    K = 5,
    DurationMs = 4000,
    WorkUnits = [200, 1000, 5000, 20000, 50000, 100000, 500000],
    Results = [bench_one(K, WU, DurationMs) || WU <- WorkUnits],
    io:format("~n~-12s ~-15s~n", ["WorkUnit", "Hashes/sec"]),
    [io:format("~-12w ~-15.2f~n", [WU, Rate]) || {WU, Rate} <- Results],
    halt().

bench_one(K, WorkUnit, DurationMs) ->
    BossPid = boss:start(K, WorkUnit),
    unregister(boss),
    register(list_to_atom("boss_bench_" ++ integer_to_list(WorkUnit)), BossPid),
    Workers = worker:start_local_workers(BossPid, "bench"),
    timer:sleep(DurationMs),
    BossPid ! {progress, self()},
    N = receive {progress, Count} -> Count after 2000 -> 0 end,
    [exit(W, kill) || W <- Workers],
    exit(BossPid, kill),
    {WorkUnit, N / (DurationMs / 1000)}.
