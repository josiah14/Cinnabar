:- module stats_pipeline.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module int.
:- import_module list.
:- import_module maybe.
:- import_module string.
:- import_module thread.
:- import_module thread.channel.

%---------------------------------------------------------------------------%
% Types

:- type stats ---> stats(count :: int, total :: int, maximum :: int).

%---------------------------------------------------------------------------%
% Stage 1: Producer — sends 1..N, then sentinel

:- pred producer(int::in, channel(maybe(int))::in, io::di, io::uo) is cc_multi.
producer(N, Chan, !IO) :-
    ( N =< 0 ->
        channel.put(Chan, no, !IO)
    ;
        channel.put(Chan, yes(N), !IO),
        producer(N - 1, Chan, !IO)
    ).

%---------------------------------------------------------------------------%
% Stage 2: Accumulator — threads count/sum/max as explicit state parameters.
% No IO output here — all printing is Stage 3's job.
%
% The Count0/Sum0/Max0 triple is passed linearly: each recursive call
% receives the updated values, and the old bindings are never used again.
% The structural pattern resembles array_di/array_uo threading, but these
% are ordinary immutable values — no di/uo mode enforcement applies here.

:- pred acc_loop(channel(maybe(int))::in, channel(stats)::in,
                 int::in, int::in, int::in,
                 io::di, io::uo) is cc_multi.
acc_loop(In, Out, Count0, Sum0, Max0, !IO) :-
    channel.take(In, Item, !IO),
    (
        Item = no,
        channel.put(Out, stats(Count0, Sum0, Max0), !IO)
    ;
        Item = yes(V),
        Count1 = Count0 + 1,
        Sum1   = Sum0 + V,
        Max1   = ( V > Max0 -> V ; Max0 ),
        acc_loop(In, Out, Count1, Sum1, Max1, !IO)
    ).

%---------------------------------------------------------------------------%
% Stage 3: Reporter — receives one stats record, prints results

:- pred reporter(channel(stats)::in, io::di, io::uo) is det.
reporter(Chan, !IO) :-
    channel.take(Chan, stats(Count, Total, Maximum), !IO),
    io.format("count:   %d\n", [i(Count)], !IO),
    io.format("total:   %d\n", [i(Total)], !IO),
    io.format("maximum: %d\n", [i(Maximum)], !IO),
    ( Count > 0 ->
        io.format("average: %d\n", [i(Total / Count)], !IO)
    ;
        io.write_string("average: (none)\n", !IO)
    ).

%---------------------------------------------------------------------------%

main(!IO) :-
    N = 20,
    channel.init(DataChan, !IO),
    channel.init(StatsChan, !IO),
    io.format("=== stats pipeline: 1..%d ===\n", [i(N)], !IO),
    promise_equivalent_solutions [!:IO]
        thread.spawn(producer(N, DataChan), !IO),
    promise_equivalent_solutions [!:IO]
        thread.spawn(acc_loop(DataChan, StatsChan, 0, 0, 0), !IO),
    reporter(StatsChan, !IO).
