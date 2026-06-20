:- module anagrams.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.

:- implementation.
:- import_module list.
:- import_module map.
:- import_module string.

% Two words are anagrams iff their sorted, lowercased character sequences are equal.
:- func canonical(string) = string.
canonical(Word) = string.from_char_list(Sorted) :-
    Chars = string.to_char_list(string.to_lower(Word)),
    list.sort(Chars, Sorted).

:- pred group_anagrams(list(string)::in, list(list(string))::out) is det.
group_anagrams(Words, Groups) :-
    list.foldl(insert_word, Words, map.init, GroupMap),
    map.values(GroupMap, Groups).

:- pred insert_word(string::in,
                    map(string, list(string))::in,
                    map(string, list(string))::out) is det.
insert_word(Word, !Map) :-
    Key = canonical(Word),
    ( map.search(!.Map, Key, Existing) ->
        map.set(Key, [Word | Existing], !Map)
    ;
        map.set(Key, [Word], !Map)
    ).

main(!IO) :-
    Words = ["eat", "tea", "tan", "ate", "nat", "bat"],
    group_anagrams(Words, Groups),
    list.foldl(
        (pred(G::in, !.IO::di, !:IO::uo) is det :-
            io.write_line(G, !IO)),
        Groups, !IO).
