%% Tests for P2 (g12_q2.pl).
%% Run from the repo root:
%%   swipl -q -g run_tests -t halt tests/test_q2.pl

:- use_module(library(plunit)).
:- use_module(library(lists)).
:- consult('../code/g12_q2.pl').   % resolved relative to this file

%% ------------------------------------------------------------------
%% Assignment examples
%% ------------------------------------------------------------------
:- begin_tests(assignment_examples).

test(all_4253, Es == ["4*2-5=3", "4*2=5+3", "4-2=5-3", "4/2=5-3",
                      "4=2*(5-3)", "4=2+(5-3)", "4=2+5-3"]) :-
    all_equations([4,2,5,3], Es).

test(generate_4253_is_one_of_seven, [nondet]) :-
    generate_equation([4,2,5,3], E),
    all_equations([4,2,5,3], Es),
    memberchk(E, Es).

test(generate_234_fails, [fail]) :-
    generate_equation([2,3,4], _).

test(all_234_empty, Es == []) :-
    all_equations([2,3,4], Es).

test(all_248, Es == ["2*4=8"]) :-
    all_equations([2,4,8], Es).

test(count_4253, N == 7) :- count_equations([4,2,5,3], N).
test(count_234,  N == 0) :- count_equations([2,3,4], N).
test(count_248,  N == 1) :- count_equations([2,4,8], N).

:- end_tests(assignment_examples).

%% ------------------------------------------------------------------
%% Short lists
%% ------------------------------------------------------------------
:- begin_tests(short_lists).

test(generate_empty_fails,  [fail]) :- generate_equation([], _).
test(generate_single_fails, [fail]) :- generate_equation([5], _).
test(all_empty,  Es == []) :- all_equations([], Es).
test(all_single, Es == []) :- all_equations([5], Es).
test(count_empty,  N == 0) :- count_equations([], N).
test(count_single, N == 0) :- count_equations([5], N).
test(two_equal, Es == ["7=7"]) :- all_equations([7,7], Es).
test(two_unequal, Es == []) :- all_equations([7,8], Es).

:- end_tests(short_lists).

%% ------------------------------------------------------------------
%% Division rules
%% ------------------------------------------------------------------
:- begin_tests(division).

% 0/0 is rejected, so only "0=0" remains.
test(zeros_pair, Es == ["0=0"]) :-
    all_equations([0,0], Es).

% 5/0 must never appear; 0/5 is fine.
test(no_division_by_zero, [fail]) :-
    generate_equation([5,0,5], "5/0=5").

test(zero_dividend_ok, [nondet]) :-
    generate_equation([0,5,0], "0/5=0").

% Division by zero hidden inside a sub-expression: 6/(0*2) is rejected.
test(nested_division_by_zero, [fail]) :-
    build_expr([6,0,2], _, op(/, num(6), op(*, num(0), num(2)))).

% 7/2 is not exact (7//2 would give 3), so "7/2=3" must not appear.
test(non_exact_rejected, [fail]) :-
    generate_equation([7,2,3], "7/2=3").

test(non_exact_not_listed) :-
    all_equations([7,2,3], Es),
    \+ memberchk("7/2=3", Es).

% Non-exact division inside a sub-expression: (3/2)*2 is rejected.
test(nested_non_exact, [fail]) :-
    build_expr([3,2,2], _, op(*, op(/, num(3), num(2)), num(2))).

% Exact division in a sub-expression is allowed.
test(nested_exact_ok, [true(V == 4), nondet]) :-
    build_expr([8,4,2], V, op(*, op(/, num(8), num(4)), num(2))).

:- end_tests(division).

%% ------------------------------------------------------------------
%% Negative intermediate values
%% ------------------------------------------------------------------
:- begin_tests(negatives).

% Both sides equal -2.
test(negative_both_sides, [nondet]) :-
    generate_equation([3,5,1,3], "3-5=1-3").

% A negative intermediate (2-3 = -1) inside a larger expression.
test(negative_intermediate, [nondet]) :-
    generate_equation([1,2,3,2], "1-(2-3)=2").

% Negative exact division: (2-6)/2 = -2.
test(negative_division, [true(V == -2), nondet]) :-
    build_expr([2,6,2], V, op(/, op(-, num(2), num(6)), num(2))).

:- end_tests(negatives).

%% ------------------------------------------------------------------
%% Canonical form / parenthesization
%% ------------------------------------------------------------------
:- begin_tests(canonical_form).

t(op(*, op(+, num(4), num(2)), num(3)), "(4+2)*3").
t(op(+, num(4), op(*, num(2), num(3))), "4+2*3").
t(op(*, op(/, num(8), num(4)), num(2)), "8/4*2").
t(op(/, num(8), op(*, num(4), num(2))), "8/(4*2)").
t(op(-, op(-, num(1), num(2)), num(3)), "1-2-3").
t(op(-, num(1), op(-, num(2), num(3))), "1-(2-3)").
t(op(+, num(1), op(+, num(2), num(3))), "1+(2+3)").
t(op(+, op(+, num(1), num(2)), num(3)), "1+2+3").
t(op(-, num(1), op(+, num(2), num(3))), "1-(2+3)").
t(op(/, num(8), op(/, num(4), num(2))), "8/(4/2)").
t(num(42), "42").

test(examples, [forall(t(Tree, Expected)), true(S == Expected)]) :-
    format_expr(Tree, S).

test(result_is_string, [nondet]) :-
    generate_equation([4,2,5,3], E),
    string(E).

test(no_spaces) :-
    all_equations([4,2,5,3], Es),
    forall(member(E, Es), \+ sub_string(E, _, _, _, " ")).

% 1-(2-3) and 1-2-3 are different trees with different values.
test(right_minus_parenthesized) :-
    all_equations([1,2,3,2], Es),
    memberchk("1-(2-3)=2", Es),
    \+ memberchk("1-2-3=2", Es).

% 1+(2+3) and 1+2+3 have the same value but are different trees:
% both must be listed.
test(both_plus_trees_listed) :-
    all_equations([1,2,3,6], Es),
    memberchk("1+(2+3)=6", Es),
    memberchk("1+2+3=6", Es).

% Every tree gives a different string.
test(distinct_trees_distinct_strings, N == M) :-
    findall(S, (build_expr([1,2,3,4], _, T), format_expr(T, S)), Ss),
    length(Ss, N),
    sort(Ss, Sorted),
    length(Sorted, M).

:- end_tests(canonical_form).

%% ------------------------------------------------------------------
%% all_equations/2 and count_equations/2 properties
%% ------------------------------------------------------------------
:- begin_tests(all_and_count).

test(sorted_no_duplicates) :-
    all_equations([1,1,1,1], Es),
    sort(Es, Es).

test(all_strings) :-
    all_equations([1,1,1,1], Es),
    forall(member(E, Es), string(E)).

test(count_matches_length, N == L) :-
    all_equations([1,1,1,1], Es),
    length(Es, L),
    count_equations([1,1,1,1], N).

test(count_1111, N == 30) :-
    count_equations([1,1,1,1], N).

test(generate_finds_every_listed, [nondet]) :-
    all_equations([4,2,5,3], Es),
    forall(member(E, Es), generate_equation([4,2,5,3], E)).

test(no_output) :-
    with_output_to(string(Out),
                   ( all_equations([4,2,5,3], _),
                     count_equations([2,3,4], _),
                     ignore(generate_equation([2,4,8], _)) )),
    Out == "".

:- end_tests(all_and_count).
