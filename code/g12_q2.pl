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
