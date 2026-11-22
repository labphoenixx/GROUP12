:- use_module(library(lists)).

%% ------------------------------------------------------------------
%% Expression trees
%%   num(N)                 a single number N
%%   op(Op, Left, Right)    Op is one of +, -, *, /
%% ------------------------------------------------------------------

%% build_expr(+Nums, -Val, -Tree) is nondet.
%  Tree is an expression tree whose leaves are exactly the numbers in
%  Nums, in the same order, each used once; Val is its integer value.
%  - Fails for Nums = [] (an expression needs at least one number).
%  - No digit concatenation (each list element is one leaf) and no
%    unary minus (every op node has exactly two children).
%  - Every / node is exact: divisor non-zero and no remainder.
%  - Intermediate values may be negative.
%  On backtracking, each different tree is produced exactly once:
%  a tree is fixed by its split point and operator at the root and by
%  its two subtrees, and each of these is chosen once.
%  Terminates: Nums is bound, and both halves of a split are strictly
%  shorter non-empty lists.
build_expr([N], N, num(N)).
build_expr(Nums, Val, op(Op, LTree, RTree)) :-
    split(Nums, LNums, RNums),
    build_expr(LNums, LVal, LTree),
    build_expr(RNums, RVal, RTree),
    apply_op(Op, LVal, RVal, Val).

%% split(+Nums, -Left, -Right) is nondet.
%  Left and Right are non-empty lists with append(Left, Right, Nums).
%  Enumerates every split point from left to right. Fails when Nums
%  has fewer than two elements.
split(Nums, [L|Ls], [R|Rs]) :-
    append([L|Ls], [R|Rs], Nums).

%% apply_op(?Op, +A, +B, -Val) is nondet.
%  Val is the value of A Op B for Op in +, -, *, /.
%  For /, succeeds only when B =\= 0 and the division is exact
%  (A mod B =:= 0); then Val is A // B. A and B must be integers.
apply_op(+, A, B, Val) :- Val is A + B.
apply_op(-, A, B, Val) :- Val is A - B.
apply_op(*, A, B, Val) :- Val is A * B.
apply_op(/, A, B, Val) :-
    B =\= 0,
    0 =:= A mod B,
    Val is A // B.

%% ------------------------------------------------------------------
%% Canonical printing
%% ------------------------------------------------------------------

%% format_expr(+Tree, -Str) is det.
%  Str is the canonical string (an SWI-Prolog string, no spaces) of
%  Tree. Parentheses rule:
%  - * and / bind tighter than + and -; operators are left-associative.
%  - Left operand in parentheses only if its top operator has strictly
%    lower precedence than the parent's operator.
%  - Right operand in parentheses if its top operator has lower or
%    equal precedence to the parent's operator.
%  - A single number is never in parentheses.
%  Different trees always give different strings.
format_expr(num(N), Str) :-
    number_string(N, Str).
format_expr(op(Op, Left, Right), Str) :-
    prec(Op, P),
    format_expr(Left, LStr0),
    format_expr(Right, RStr0),
    (   tree_prec(Left, LP), LP < P
    ->  wrap(LStr0, LStr)
    ;   LStr = LStr0
    ),
    (   tree_prec(Right, RP), RP =< P
    ->  wrap(RStr0, RStr)
    ;   RStr = RStr0
    ),
    atom_string(Op, OpStr),
    string_concat(LStr, OpStr, S1),
    string_concat(S1, RStr, Str).

%% prec(?Op, ?P) is semidet.
%  P is the precedence level of Op: 1 for + and -, 2 for * and /.
prec(+, 1).
prec(-, 1).
prec(*, 2).
prec(/, 2).

%% tree_prec(+Tree, -P) is semidet.
%  P is the precedence of the top operator of Tree.
%  Fails for num(_), so a single number is never wrapped.
tree_prec(op(Op, _, _), P) :-
    prec(Op, P).

%% wrap(+S, -W) is det.
%  W is S surrounded by parentheses.
wrap(S, W) :-
    string_concat("(", S, S1),
    string_concat(S1, ")", W).
