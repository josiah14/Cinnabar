:- module stack.
:- interface.

% Abstract type: clients see that stack(T) exists, not how it is built.
:- type stack(T).

:- func empty = stack(T).
:- pred is_empty(stack(T)::in) is semidet.
:- func push(T, stack(T)) = stack(T).
:- pred pop(stack(T)::in, T::out, stack(T)::out) is semidet.

:- implementation.

% Internal representation: hidden from clients.
:- type stack(T) ---> empty_stack ; stack_node(T, stack(T)).

empty = empty_stack.
is_empty(empty_stack).
push(X, S) = stack_node(X, S).
pop(stack_node(Top, Rest), Top, Rest).
