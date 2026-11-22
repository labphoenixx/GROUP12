# P1 Report: Department Assignment Puzzle, Reloaded (Group 12)

## 1. Value of N for clues 1 to 8

```
?- count_solutions([1,2,3,4,5,6,7,8], N).
N = 3.
```

**N = 3.** Clues 1 to 8 do not determine a unique answer: three different assignments satisfy all eight clues.

Command used:
```
swipl -q -f code/g12_q1.pl -g "count_solutions([1,2,3,4,5,6,7,8], N), print(N), nl" -t halt
```

## 2. The three solutions of clues 1 to 8

| Solution | Alex | Ben | Carla | Dana |
|---|---|---|---|---|
| 1 | design, java, AI | development, javascript, web | research, c++, data | testing, python, embedded |
| 2 | design, java, embedded | development, javascript, web | testing, python, AI | research, c++, data |
| 3 | testing, python, embedded | development, javascript, web | design, java, AI | research, c++, data |

`main/0` prints Solution 1, the first one found by generate-and-test.

## 3. What this tells us about the puzzle

- **The puzzle is under-constrained.** The clues remove 13,821 of the 13,824 candidate assignments (24 permutations for each of the three attributes, so 24³), but not the last 3.
- **Ben is fully determined.** He is (development, javascript, web) in every solution. The ambiguity is only among Alex, Carla and Dana.
- **Every clue does some work.** Dropping any one clue increases N, so no clue is redundant given the others:

| Clues used | N |
|---|---|
| 1–8 | 3 |
| all except clue 1 | 4 |
| all except clue 2 | 6 |
| all except clue 3 | 13 |
| all except clue 4 | 12 |
| all except clue 5 | 9 |
| all except clue 6 | 7 |
| all except clue 7 | 5 |
| all except clue 8 | 16 |

- **Solutions 1 and 3 have the same set of combinations.** If we ignore names and list each friend's (department, language, project) combination, Solutions 1 and 3 both contain exactly:
  (design, java, AI), (development, javascript, web), (research, c++, data), (testing, python, embedded).
  They differ only in *who* has which combination. Solution 2 has a different set: (design, java, embedded), (testing, python, AI).

  A clue that refers to friends only through attribute values (as P1.c requires) depends only on the set of combinations, not on the names. So any such clue is either true in both Solution 1 and Solution 3 or false in both. **It is impossible to keep Solution 1 alone or Solution 3 alone with a name-free clue. The only solution that can be made unique is Solution 2.**

## 4. Repair: clue 9 (P1.c)

```prolog
% CLUE 9: The friend who prefers the AI project works in the testing department.
clue(9, Solution) :-
    member(p(_, Dept, _, 'AI'), Solution),
    Dept == testing.
```

| Solution | Friend who prefers AI | Their department | Clue 9 |
|---|---|---|---|
| 1 | Alex | design | false |
| 2 | Carla | testing | **true** |
| 3 | Carla | design | false |

```
?- count_solutions([1,2,3,4,5,6,7,8,9], N).
N = 1.
```

The one remaining solution is Solution 2:

```
Alex  = [design, java, embedded]
Ben   = [development, javascript, web]
Carla = [testing, python, AI]
Dana  = [research, c++, data]
```

The clue mentions no friend by name. It refers to friends only through the attribute values `AI` and `testing`, in the same style as clue 5. This is checked by the test `clue9_mentions_no_name` in `tests/test_q1.pl`.

## 5. Verification

All tests in `tests/test_q1.pl` pass:
```
swipl -q -g run_tests -t halt tests/test_q1.pl
```
`swipl -q -g report -t halt tests/test_q1.pl` prints the values of N in section 3 and the three solutions in section 2.
