%% Tests for P1 (g12_q1.pl).
%% Run from the repo root:
%%   swipl -q -g run_tests -t halt tests/test_q1.pl
%% Print N for clues 1-8 and list every solution of clues 1-8:
%%   swipl -q -g report -t halt tests/test_q1.pl

:- use_module(library(plunit)).
:- use_module(library(lists)).
:- consult('../code/g12_q1.pl').   % resolved relative to this file

%% ------------------------------------------------------------------
%% Fixtures
%% ------------------------------------------------------------------

% One of the solutions of clues 1-8 (all eight clues hold).
good([p('Alex',design,java,'AI'),
      p('Ben',development,javascript,web),
      p('Carla',research,'c++',data),
      p('Dana',testing,python,embedded)]).

% Valid candidate that breaks clues 1, 3, 4, 5, 6 and 8
% (Dana prefers AI; testing likes javascript; Ben prefers data;
%  java is in development; Carla is embedded; data is in development).
bad_a([p('Alex',research,python,web),
       p('Ben',development,java,data),
       p('Carla',design,'c++',embedded),
       p('Dana',testing,javascript,'AI')]).

% Breaks clue 2 (Alex works in development).
bad_clue2_dept([p('Alex',development,python,web),
                p('Ben',research,java,data),
                p('Carla',design,'c++',embedded),
                p('Dana',testing,javascript,'AI')]).

% Breaks clue 2 (Alex prefers c++).
bad_clue2_lang([p('Alex',research,'c++',web),
                p('Ben',development,java,data),
                p('Carla',design,python,embedded),
                p('Dana',testing,javascript,'AI')]).

% Breaks clue 7 (Dana works in design).
bad_clue7_dept([p('Alex',research,python,web),
                p('Ben',development,java,data),
                p('Carla',testing,'c++',embedded),
                p('Dana',design,javascript,'AI')]).

% Breaks clue 7 (Dana's language is java), Dana still in testing.
bad_clue7_lang([p('Alex',research,python,web),
                p('Ben',development,javascript,data),
                p('Carla',design,'c++',embedded),
                p('Dana',testing,java,'AI')]).

% Breaks clue 1 (AI friend works in research), not Dana.
bad_clue1_research([p('Alex',research,python,'AI'),
                    p('Ben',development,java,web),
                    p('Carla',design,'c++',embedded),
                    p('Dana',testing,javascript,data)]).

% Breaks clue 4 (Ben prefers web but works in testing).
bad_clue4_testing([p('Alex',research,java,'AI'),
                   p('Ben',testing,python,web),
                   p('Carla',design,'c++',embedded),
                   p('Dana',development,javascript,data)]).

% Breaks clue 8 (data friend is in research but uses javascript).
bad_clue8_lang([p('Alex',design,java,'AI'),
                p('Ben',development,python,web),
                p('Carla',testing,'c++',embedded),
                p('Dana',research,javascript,data)]).

%% ------------------------------------------------------------------
%% valid_solution/1
%% ------------------------------------------------------------------
:- begin_tests(valid_solution).

test(count_all_candidates, N == 13824) :-
    aggregate_all(count, valid_solution(_), N).

test(names_in_order, Names == ['Alex','Ben','Carla','Dana']) :-
    once(valid_solution(S)),
    findall(Nm, member(p(Nm,_,_,_), S), Names).

test(fixtures_are_candidates, [forall(member(F, [good, bad_a, bad_clue2_dept,
        bad_clue2_lang, bad_clue7_dept, bad_clue7_lang, bad_clue1_research,
        bad_clue4_testing, bad_clue8_lang]))]) :-
    call(F, S),
    once(valid_solution(S)).

:- end_tests(valid_solution).

%% ------------------------------------------------------------------
%% clue/2: true cases
% (nondet: member/2 inside clue/2 can leave a harmless choice point)
%% ------------------------------------------------------------------
:- begin_tests(clue_true).

test(all_clues_hold_on_good, [forall(between(1, 8, K)), nondet]) :-
    good(S), clue(K, S).

test(clue2_true_on_bad_a, [nondet]) :- bad_a(S), clue(2, S).
test(clue7_true_on_bad_a, [nondet]) :- bad_a(S), clue(7, S).

:- end_tests(clue_true).

%% ------------------------------------------------------------------
%% clue/2: false cases
%% ------------------------------------------------------------------
:- begin_tests(clue_false).

test(clue1_dana_ai,            [fail]) :- bad_a(S), clue(1, S).
test(clue1_research_ai,        [fail]) :- bad_clue1_research(S), clue(1, S).
test(clue2_alex_development,   [fail]) :- bad_clue2_dept(S), clue(2, S).
test(clue2_alex_cpp,           [fail]) :- bad_clue2_lang(S), clue(2, S).
test(clue3_testing_not_python, [fail]) :- bad_a(S), clue(3, S).
test(clue4_ben_not_web,        [fail]) :- bad_a(S), clue(4, S).
test(clue4_ben_testing,        [fail]) :- bad_clue4_testing(S), clue(4, S).
test(clue5_java_not_design,    [fail]) :- bad_a(S), clue(5, S).
test(clue6_carla_embedded,     [fail]) :- bad_a(S), clue(6, S).
test(clue6_carla_development,  [fail]) :- bad_clue2_lang(S0),
    % same as bad_clue2_lang but Carla and Ben swap departments
    S0 = [A, p(B,BD,BL,BP), p(C,CD,CL,CP), D],
    S  = [A, p(B,CD,BL,BP), p(C,BD,CL,CP), D],
    clue(6, S).
test(clue7_dana_design,        [fail]) :- bad_clue7_dept(S), clue(7, S).
test(clue7_dana_java,          [fail]) :- bad_clue7_lang(S), clue(7, S).
test(clue8_data_development,   [fail]) :- bad_a(S), clue(8, S).
test(clue8_data_javascript,    [fail]) :- bad_clue8_lang(S), clue(8, S).

:- end_tests(clue_false).

%% ------------------------------------------------------------------
%% solve/1 and main/0
%% ------------------------------------------------------------------
:- begin_tests(solve_main).

test(solve_satisfies_all, [nondet]) :-
    solve(S),
    forall(between(1, 8, K), clue(K, S)).

test(solve_count, N == 3) :-
    aggregate_all(count, solve(_), N).

test(main_output_format) :-
    with_output_to(string(Out), main),
    split_string(Out, "\n", "", Lines),
    % 4 lines, each terminated by a newline, so the last piece is ""
    Lines = [L1, L2, L3, L4, ""],
    sub_string(L1, 0, _, _, "Alex = ["),
    sub_string(L2, 0, _, _, "Ben = ["),
    sub_string(L3, 0, _, _, "Carla = ["),
    sub_string(L4, 0, _, _, "Dana = ["),
    \+ sub_string(Out, _, _, _, "'").          % no quoted atoms

test(main_prints_a_solution) :-
    with_output_to(string(Out), main),
    once(solve(S)),
    with_output_to(string(Expected),
        forall(member(p(N,D,L,P), S),
               format("~w = [~w, ~w, ~w]~n", [N,D,L,P]))),
    Out == Expected.

:- end_tests(solve_main).

%% ------------------------------------------------------------------
%% count_solutions/2
%% ------------------------------------------------------------------
:- begin_tests(count_solutions).

test(all_eight, N == 3)      :- count_solutions([1,2,3,4,5,6,7,8], N).
test(no_clues, N == 13824)   :- count_solutions([], N).
test(clue3_only, N == 3456)  :- count_solutions([3], N).
test(clues_1_to_4, N == 208) :- count_solutions([1,2,3,4], N).
test(order_irrelevant, N1 == N2) :-
    count_solutions([8,7,6,5,4,3,2,1], N1),
    count_solutions([1,2,3,4,5,6,7,8], N2).
test(drop_each_clue_not_fewer, [forall(between(1, 8, K))]) :-
    numlist(1, 8, All),
    subtract(All, [K], Fewer),
    count_solutions(Fewer, NF),
    count_solutions(All, NA),
    NF >= NA.

:- end_tests(count_solutions).

%% ------------------------------------------------------------------
%% Report helper (not a test): prints N and every solution of clues 1-8
%% ------------------------------------------------------------------
report :-
    count_solutions([1,2,3,4,5,6,7,8], N),
    format("N for clues 1-8: ~w~n", [N]),
    forall(between(1, 8, K),
           ( numlist(1, 8, All), subtract(All, [K], Fewer),
             count_solutions(Fewer, NK),
             format("N without clue ~w: ~w~n", [K, NK]) )),
    format("~nAll solutions of clues 1-8:~n", []),
    findall(S, solve(S), Sols),
    forall(nth1(I, Sols, S),
           ( format("~nSolution ~w:~n", [I]),
             forall(member(p(Nm,D,L,P), S),
                    format("  ~w = [~w, ~w, ~w]~n", [Nm,D,L,P])) )).
