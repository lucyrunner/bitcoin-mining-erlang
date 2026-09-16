-module(worker).
-export([start_local_workers/2, mine_loop/2]).

start_local_workers(BossRef, GatorId) ->
    N = erlang:system_info(schedulers),
    [spawn(?MODULE, mine_loop, [BossRef, GatorId]) || _ <- lists:seq(1, N)].

mine_loop(BossRef, GatorId) ->
    BossRef ! {work_request, self()},
    receive
        {work, K, Start, End} ->
            mine_range(BossRef, GatorId, K, Start, End),
            mine_loop(BossRef, GatorId)
    end.

mine_range(_BossRef, _GatorId, _K, Start, End) when Start > End ->
    ok;
mine_range(BossRef, GatorId, K, Start, End) ->
    Input = GatorId ++ ";" ++ integer_to_list(Start),
    Hash = sha256_hex(Input),
    Zeros = leading_zeros(Hash),
    case Zeros >= K of
        true  -> BossRef ! {found, Input, Hash, Zeros};
        false -> ok
    end,
    mine_range(BossRef, GatorId, K, Start + 1, End).

sha256_hex(Input) ->
    Digest = crypto:hash(sha256, list_to_binary(Input)),
    lists:flatten([io_lib:format("~2.16.0b", [B]) || <<B>> <= Digest]).

leading_zeros(Hash) -> leading_zeros(Hash, 0).
leading_zeros([$0 | Rest], N) -> leading_zeros(Rest, N + 1);
leading_zeros(_, N) -> N.