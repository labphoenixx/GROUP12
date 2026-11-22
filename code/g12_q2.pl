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

%% ------------------------------------------------------------------
%% Equations
%% ------------------------------------------------------------------

%% generate_equation(+List, -Equation) is nondet.
%  Equation is a string "L=R" where L is the canonical form of an
%  expression over a non-empty prefix of List, R the canonical form of
%  an expression over the remaining non-empty suffix, and both sides
%  have the same integer value. Every number is used once, in order.
%  - Fails (no error, no loop) for [] and [_]: split/3 needs at least
%    two elements.
%  - Fails when no valid equation exists.
%  - On backtracking, enumerates every valid equation exactly once.
%    It is left nondet (not wrapped in once/1) so that a call with
%    Equation already bound checks it against all equations.
generate_equation(List, Equation) :-
    split(List, LeftNums, RightNums),
    build_expr(LeftNums, LVal, LTree),
    build_expr(RightNums, RVal, RTree),
    LVal =:= RVal,
    format_expr(LTree, LStr),
    format_expr(RTree, RStr),
    string_concat(LStr, "=", S1),
    string_concat(S1, RStr, Equation).

%% all_equations(+List, -Equations) is det.
%  Equations is the list of all valid equation strings for List,
%  without duplicates, in standard order of terms (sort/2 both sorts
%  and removes duplicates). Equations = [] when there is none,
%  including for [] and [_], because findall/3 then collects nothing.
all_equations(List, Equations) :-
    findall(Eq, generate_equation(List, Eq), Eqs),
    sort(Eqs, Equations).

%% count_equations(+List, -N) is det.
%  N is the number of equations in all_equations(List, _).
count_equations(List, N) :-
    all_equations(List, Equations),
    length(Equations, N).
