-module(boss).
-export([start/2, loop/4]).

start(K, WorkUnit) ->
    Pid = spawn(?MODULE, loop, [K, WorkUnit, 0, {0, "", ""}]),
    register(boss, Pid),
    Pid.

loop(K, WorkUnit, NextStart, Best) ->
    receive
        {work_request, WorkerPid} ->
            WorkerPid ! {work, K, NextStart, NextStart + WorkUnit - 1},
            loop(K, WorkUnit, NextStart + WorkUnit, Best);

        {found, Input, Hash, Zeros} ->
            io:format("~s\t~s~n", [Input, Hash]),
            NewBest =
                case Zeros > element(1, Best) of
                    true  -> {Zeros, Input, Hash};
                    false -> Best
                end,
            loop(K, WorkUnit, NextStart, NewBest);

        {best, FromPid} ->
            FromPid ! {best, Best},
            loop(K, WorkUnit, NextStart, Best);

        {progress, FromPid} ->
            FromPid ! {progress, NextStart},
            loop(K, WorkUnit, NextStart, Best);

        stop ->
            ok
    end.