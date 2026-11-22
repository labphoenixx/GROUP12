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
