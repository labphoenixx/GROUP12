:- use_module(library(lists)).

%% ------------------------------------------------------------------
%% Domain facts
%% ------------------------------------------------------------------

%% friends(-Names) is det.
%  Names is the list of the four friends, in the fixed order
%  Alex, Ben, Carla, Dana.
friends(['Alex', 'Ben', 'Carla', 'Dana']).

%% departments(-Depts) is det.
%  Depts is the list of the four departments.
departments([research, development, design, testing]).

%% languages(-Langs) is det.
%  Langs is the list of the four favorite languages.
languages([python, java, 'c++', javascript]).

%% projects(-Projects) is det.
%  Projects is the list of the four project preferences.
projects(['AI', web, embedded, data]).

%% ------------------------------------------------------------------
%% Candidate generator
%% ------------------------------------------------------------------

%% valid_solution(-Solution) is nondet.
%  Solution is a list [p('Alex',D1,L1,P1), p('Ben',D2,L2,P2),
%  p('Carla',D3,L3,P3), p('Dana',D4,L4,P4)] in which the departments,
%  languages and projects are each a permutation of their domain, so
%  every value of every attribute is used exactly once.
%  On backtracking it enumerates all 24 * 24 * 24 = 13824 candidates.
%  No clue is checked here; clues are applied separately.
%  Terminates: permutation/2 of a fixed 4-element list has finitely
%  many solutions.
valid_solution(Solution) :-
    friends(Names),
    departments(Depts),
    languages(Langs),
    projects(Projects),
    permutation(Depts, DeptPerm),
    permutation(Langs, LangPerm),
    permutation(Projects, ProjPerm),
    build_people(Names, DeptPerm, LangPerm, ProjPerm, Solution).

%% build_people(+Names, +Depts, +Langs, +Projects, -People) is det.
%  People is the list of p(Name, Dept, Lang, Project) terms formed by
%  zipping the four lists position by position.
%  Base case: all four lists empty gives [].
%  Recursion: on the lists, which shrink by one element per call.
build_people([], [], [], [], []).
build_people([N|Ns], [D|Ds], [L|Ls], [P|Ps], [p(N, D, L, P)|People]) :-
    build_people(Ns, Ds, Ls, Ps, People).

%% ------------------------------------------------------------------
%% Clues (each clue(N, Solution) assumes Solution is fully filled in)
%% ------------------------------------------------------------------

%% clue(+N, +Solution) is semidet.
%  Succeeds exactly when clue number N holds in Solution.
%  Each attribute value occurs exactly once in a candidate, so every
%  member/2 lookup below matches exactly one friend (no duplicates).

% Clue 1: The friend who prefers the AI project does not work in
% research and is not Dana.
clue(1, Solution) :-
    member(p(Name, Dept, _, 'AI'), Solution),
    Dept \== research,
    Name \== 'Dana'.

% Clue 2: Alex does not work in development and does not prefer C++.
clue(2, Solution) :-
    member(p('Alex', Dept, Lang, _), Solution),
    Dept \== development,
    Lang \== 'c++'.

% Clue 3: The friend working in the testing department likes Python.
clue(3, Solution) :-
    member(p(_, testing, Lang, _), Solution),
    Lang == python.

% Clue 4: Ben prefers web projects and does not work in testing.
clue(4, Solution) :-
    member(p('Ben', Dept, _, Project), Solution),
    Project == web,
    Dept \== testing.

% Clue 5: The friend whose favorite language is Java works in the
% design department.
clue(5, Solution) :-
    member(p(_, Dept, java, _), Solution),
    Dept == design.

% Clue 6: Carla's project preference is not embedded, and her
% department is not development.
clue(6, Solution) :-
    member(p('Carla', Dept, _, Project), Solution),
    Project \== embedded,
    Dept \== development.

% Clue 7: Dana's favorite language is not Java, and she works in
% research or testing.
clue(7, Solution) :-
    member(p('Dana', Dept, Lang, _), Solution),
    Lang \== java,
    memberchk(Dept, [research, testing]).

% Clue 8: The friend who prefers data projects works in research and
% does not use JavaScript.
clue(8, Solution) :-
    member(p(_, Dept, Lang, data), Solution),
    Dept == research,
    Lang \== javascript.

%% ------------------------------------------------------------------
%% Solving and printing
%% ------------------------------------------------------------------

%% solve(-Solution) is nondet.
%  Solution is a candidate from valid_solution/1 that satisfies every
%  clue from 1 to 8. Generate-then-test: the candidate is fully bound
%  before any clue is checked.
solve(Solution) :-
    valid_solution(Solution),
    clue(1, Solution),
    clue(2, Solution),
    clue(3, Solution),
    clue(4, Solution),
    clue(5, Solution),
    clue(6, Solution),
    clue(7, Solution),
    clue(8, Solution).

%% main is det.
%  Prints the first solution of solve/1 as four lines, one per friend
%  in the order Alex, Ben, Carla, Dana, in the form
%  Name = [Dept, Lang, Project]
%  once/1 keeps only the first solution, so main prints exactly once.
main :-
    once(solve(Solution)),
    print_people(Solution).

%% print_people(+People) is det.
%  Prints each p(Name, Dept, Lang, Project) in People on its own line.
%  ~w writes atoms without quotes, so 'AI' prints as AI and 'c++' as c++.
%  Base case: [] prints nothing. Recursion: on the list.
print_people([]).
print_people([p(Name, Dept, Lang, Project)|People]) :-
    format("~w = [~w, ~w, ~w]~n", [Name, Dept, Lang, Project]),
    print_people(People).
