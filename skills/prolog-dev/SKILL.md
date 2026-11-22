---
name: prolog-dev
description: Conventions, run/test commands, hard constraints, a self-review checklist and known AI failure modes for writing SWI-Prolog 9.x code for the CS F301 assignment. Use for every Prolog predicate, test file or review.
---

# prolog-dev

## 1. Language and environment
- **SWI-Prolog 9.x** only. Write standard, portable SWI code; no other dialect's extensions.
- Each solution file (`id_q1.pl`, `id_q2.pl`) contains **only predicate definitions** (plus optional `:- use_module(library(...))` lines for the allowed libraries).
- Answer **one unit of work per request**: one predicate (with its helpers), one test file, or one review. Never write a whole problem in one answer.

## 2. Hard constraints (violating any of these is a bug)
1. **No initialization directives**: no `:- initialization(...)`, no `:- main.`, no top-level goals that run on load.
2. **Never call `halt/0` or `halt/1`** in the code. The grader adds `-t halt`.
3. **No dynamic state**: no `assert/1`, `asserta/1`, `assertz/1`, `retract/1`, `retractall/1`, `b_setval/2`, `nb_setval/2`, `b_getval/2`, `nb_getval/2`, or `:- dynamic`.
4. **Allowed libraries only:** `lists`, `apply`, `yall`, `aggregate`. No `clpfd`, `dcg/basics`, `strings`, `readutil` or any other library.
5. **No extra output.** Print only what the task specifies, in the exact format. No debug `print`/`write`/`format` left in the code.
6. **P2 only:** do not build a string or atom and parse it back (`term_to_atom/2`, `term_string/2`, `read_term_from_atom/3`, `number_codes` round trips) to evaluate an expression. Evaluate the expression **tree** directly.
7. Do not hard-code answers that are meant to be derived (for example, the P1 solution).

## 3. Coding conventions
- **Naming:** `snake_case` for predicates and atoms; `CamelCase` for variables; helpers get descriptive names (`split_list/3`, not `h/3`).
- **Header comment above every predicate**, in this form:
  ```prolog
  %% pred_name(+In, -Out) is det|semidet|nondet|multi.
  %  Declarative reading: "Out is ... of In" / "holds when ...".
  %  Arguments: In = ..., Out = ...
  %  Notes: termination argument, which arguments must be bound.
  ```
  Mode markers: `+` bound on entry, `-` unbound on entry, `?` either.
- **Determinism must match the comment.** If a predicate is `det`, it leaves no choice points on valid input. Add a cut or use `once/1` only where you can justify it in a comment (a "green" cut, or a "red" cut with an explanation).
- Put the base case / empty-list clause **first**, then the recursive clauses.
- Keep clauses short; extract helpers instead of deeply nested `( -> ; )`.
- Use `format/2` for output with an explicit `~n`. Check the output against the spec character by character.
- Strings vs atoms: `"abc"` is a **string** in SWI-Prolog 9 (double_quotes=codes is *not* the default). Use `string_concat/3`, `atomic_list_concat/3` + `atom_string/2`, or `format(string(S), ...)` when a string is required.

## 4. Running and testing
Run a file's `main/0`:
```bash
swipl -q -f id_q1.pl -g main -t halt
```
Run any other goal:
```bash
swipl -q -f id_q1.pl -g "count_solutions([1,2,3,4,5,6,7,8], N), print(N), nl" -t halt
swipl -q -f id_q2.pl -g "all_equations([4,2,5,3], Es), print(Es), nl" -t halt
```
Check that loading prints nothing and raises no warnings:
```bash
swipl -q -f id_q1.pl -g true -t halt     # output must be empty
```
**Test files** (`tests/`) use `plunit` **only inside the test file**, never in the solution file:
```prolog
:- use_module(library(plunit)).
:- consult('../code/id_q2.pl').

:- begin_tests(q2).
test(no_solution, [fail]) :- generate_equation([2,3,4], _).
test(example, Es == ["2*4=8"]) :- all_equations([2,4,8], Es).
:- end_tests(q2).
```
Run with: `swipl -q -g run_tests -t halt tests/test_q2.pl`
Include every example from the assignment, plus edge cases: `[]`, a single element, zeros, division by zero, inexact division, negative intermediate values, and duplicate trees.

## 5. Self-review checklist (apply before every answer)
- [ ] No `initialization`, `halt`, `assert`/`retract`, `b_setval`/`nb_setval`, or `:- dynamic` anywhere.
- [ ] Only `lists`, `apply`, `yall`, `aggregate` are used (check every built-in you call and the library it comes from).
- [ ] The file loads with **zero** warnings (singleton variables, discontiguous clauses, clauses not together).
- [ ] Every predicate has a mode/determinism comment and a declarative reading.
- [ ] Base cases are covered: empty list, single element, unbound vs bound arguments as documented.
- [ ] Predicates that should **fail** do fail: no exception, no infinite loop, including on `[]` and `[X]`.
- [ ] Termination: every recursive call works on a strictly smaller structure, or on a bounded, finite generator.
- [ ] Arithmetic: `is/2` only to compute, `=:=`/`=\=` to compare numbers, `==` for term identity, `=` for unification. No `is` evaluation of unbound or non-numeric terms.
- [ ] Division: `//` or a `0 =:= X mod Y` check for exactness, and test `Y =\= 0` **before** dividing.
- [ ] Generators are not placed after tests that need their bindings (generate-then-test order is correct; constraints are checked once variables are bound).
- [ ] Output matches the spec exactly (spacing, commas, quoting: `write` vs `print` vs `writeq`), and nothing else is printed.
- [ ] `findall`/`aggregate_all` results are deduplicated and sorted when the spec requires it (`sort/2` removes duplicates; `msort/2` does not).
- [ ] Strings returned where strings are required (`string/1` succeeds on the result).
- [ ] Tests were actually run, and the command and output are shown.

## 6. Known AI failure modes in Prolog (check for each)
1. **Infinite loops on backtracking:** left recursion (`expr(E) :- expr(L), ...`), generators over unbounded structures, `length(L, N)` with both unbound, or recursion that does not shrink its input. Asking for "the next solution" then never terminates.
2. **`is` vs `=:=` vs `=` confusion:** `X is Y` used to compare two bound numbers (works but fragile), `X = 3+4` expecting 7, or `=:=` on unbound variables (instantiation error).
3. **Instantiation errors** from calling arithmetic or `</2` before variables are bound, because tests are placed before generators.
4. **Empty and single-element lists not handled:** missing `[]` clause, or a predicate that throws instead of failing on `[]` or `[_]`.
5. **Spurious choice points / duplicate answers:** overlapping clauses that let the same solution succeed twice, which inflates `findall` counts. Missing `sort/2` dedup.
6. **Wrong cut placement:** a red cut that silently removes valid solutions, or a cut in a predicate that must enumerate (nondet).
7. **Using non-allowed libraries or predicates:** `clpfd` (`#=`, `all_different`), `between/3` is fine (built-in), but `sum_list` etc. must come from `lists`. `string_code` and other built-ins are fine; anything needing an extra `use_module` outside the allowed four is not.
8. **Strings vs atoms vs code lists:** returning `'4*2=5+3'` (atom) or a code list when a string is required. Assuming `"..."` is a code list.
9. **Output formatting drift:** `print/1` quoting atoms (`'AI'`, `'c++'`), missing or extra spaces after commas, missing final newline, stray `true.` or debug output.
10. **Hard-coding:** writing the known answer instead of deriving it, or special-casing the assignment's examples.
11. **Integer division bugs:** using `/` (which can give a float or rational in SWI 9) instead of checking `mod` and using `//`. Not checking division by zero in **every** sub-expression.
12. **Singleton-variable and discontiguous warnings** left in the file; clauses of one predicate split across the file.
13. **Claiming code was tested when it was not.** Always run it and show the actual output.
