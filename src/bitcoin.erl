-module(bitcoin).
-export([main/1]).

-define(GATORID, "gatorlinkid").
-define(WORK_UNIT, 50000).
-define(COOKIE, bitcoin_mining_cookie).

main([Arg]) ->
    case parse_integer(Arg) of
        {ok, K} -> run_server(K);
        error    -> run_worker(Arg)
    end;
main(_) ->
    io:format("Usage:~n  project1 <K>            (run as server)~n"
              "  project1 <ServerAddress> (run as worker)~n"),
    halt(1).

run_server(K) ->
    ok = start_distribution(boss),
    BossPid = boss:start(K, ?WORK_UNIT),
    _Workers = worker:start_local_workers(BossPid, ?GATORID),
    io:format("Server node ~s up, mining locally with K=~p (work unit=~p)~n",
              [node(), K, ?WORK_UNIT]),
    io:format("Remote workers can join with: project1 ~s~n", [my_host()]),
    wait_forever().

run_worker(ServerAddr) ->
    ok = start_distribution(worker_name()),
    ServerNode = list_to_atom("boss@" ++ ServerAddr),
    case net_adm:ping(ServerNode) of
        pong ->
            _Workers = worker:start_local_workers({boss, ServerNode}, ?GATORID),
            io:format("Worker node ~s joined server ~s~n", [node(), ServerNode]),
            wait_forever();
        pang ->
            io:format("Could not reach server node ~s~n", [ServerNode]),
            halt(1)
    end.

start_distribution(Name) ->
    case net_kernel:start([Name, shortnames]) of
        {ok, _}                       -> ok;
        {error, {already_started, _}} -> ok
    end,
    erlang:set_cookie(node(), ?COOKIE),
    ok.

worker_name() ->
    list_to_atom("worker" ++ integer_to_list(erlang:unique_integer([positive, monotonic]))).

my_host() ->
    {ok, Host} = inet:gethostname(),
    Host.

parse_integer(S) ->
    case string:to_integer(S) of
        {Int, ""} when is_integer(Int) -> {ok, Int};
        _                              -> error
    end.

wait_forever() ->
    receive
    after infinity -> ok
    end.