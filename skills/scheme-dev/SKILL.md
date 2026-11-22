---
name: scheme-dev
description: Conventions, run/test commands, the exact allowed built-ins, a self-review checklist and known AI failure modes for writing Racket 8.x (#lang racket/base) code for the CS F301 assignment. Use for every Scheme function, test file or review.
---

# scheme-dev

## 1. Language and environment
- **Racket 8.x**. Every solution file (`id_q3.rkt`, `id_q4.rkt`) starts with exactly:
  ```racket
  #lang racket/base
  ```
- Files contain **only definitions**. The grader appends its own calls to the end of the file.
- Answer **one unit of work per request**: one function (with its helpers), one test file, or one review. Never write a whole problem in one answer.

## 2. Allowed built-ins (the complete list)
Anything not on this list is forbidden, even if it is in `racket/base`.

| Category | Allowed |
|---|---|
| Definition / binding | `define`, `lambda`, `let`, `let*`, `letrec`, named `let` |
| Control | `if`, `cond` (with `else`), `and`, `or`, `not`, `begin` |
| Data | `quote` (written `'`), `cons`, `car`, `cdr`, `list` |
| c...r compositions | up to 4 levels: `caar` `cadr` `cdar` `cddr`, `caaar` … `cdddr`, `caaaar` … `cddddr` |
| Predicates | `null?`, `pair?`, `eq?` |
| Association lists | `assq`, `assoc` |
| Arithmetic / comparison | `+` `-` `*` `<` `>` `<=` `>=` `=`, `max` |
| Output | `display`, `newline` |
| Input | `read`: **only in Q4 (`id_q4.rkt`)** |

## 3. Explicitly banned
- **List library functions:** `length`, `append`, `reverse`, `map`, `filter`, `member`, `memq`, `list-ref`, `list-tail`, `foldl`, `foldr`, `apply`, `for-each`, `andmap`, `ormap`. Write your own helper instead (`my-length`, `my-reverse`, `my-map`, ...).
- **Mutation:** `set!`, `set-car!`, `set-cdr!`, `set-box!`, any `!` procedure.
- **Other data types:** strings (`string-append`, `"..."` literals, `number->string`), vectors, hash tables, boxes, structs.
- **Loops:** `do`, `for`, `for/list`, `for/fold`, and every other `for` form. Use recursion.
- **Other predicates and helpers that look harmless but are NOT allowed:** `equal?`, `eqv?`, `list?`, `symbol?`, `number?`, `zero?`, `add1`, `sub1`, `when`, `unless`, `case`, `error`, `printf`, `write`, `print`, `void`, `quasiquote`/`` ` ``.
- **`read` in Q3.**
- **Top-level calls or prints:** no `(print-inorder t1)`, no test trees with display calls, and no `(display ...)` at the top level. Loading the file must print nothing.
- `require`, `provide`, `module+ test` in solution files (keep the file self-contained).

## 4. Coding conventions
- **Naming:** `kebab-case` (`print-inorder`, `my-reverse`, `count-leaves`). Predicates end in `?` (`leaf?`), helpers carrying accumulators end in `-acc` or `-iter`.
- **Contract comment above every function:**
  ```racket
  ;; my-reverse : list -> list
  ;; Purpose: returns the elements of lst in reverse order.
  ;; Recursion: on lst; base case () returns acc; each step moves (car lst) onto acc.
  ;; Tail-recursive: yes.
  ```
  State the type, the purpose, the base case(s), what shrinks on each call, and whether the function is tail-recursive.
- **Prefer tail recursion with accumulators** where it is natural (list walks, counting, building results). Build in reverse with `cons` onto an accumulator, then `my-reverse` once at the end. Tree recursion (two subtrees) cannot be fully tail-recursive: say so in the comment, and keep the accumulator style where it removes the need for `append`.
- **All state goes through arguments.** No global mutable variables.
- Distinguish atoms from lists using only `pair?` and `null?`: an element is a list if `(or (null? e) (pair? e))`, otherwise it is an atom.
- Output: `display` the whole list in one call, then `newline`. `display` of `'()` prints `()`.
- Keep each `define` small; extract helpers rather than nesting deep `cond`s.

## 5. Running and testing
Run a file:
```bash
racket id_q3.rkt          # must print nothing (definitions only)
```
Test the way the grader does: **append calls to a copy** of the solution file, never to the solution itself:
```bash
cat code/id_q3.rkt tests/q3_calls.rkt > /tmp/run_q3.rkt
racket /tmp/run_q3.rkt
```
where `tests/q3_calls.rkt` contains only calls, for example:
```racket
(define t1 '(4 (2 (1 () ()) (3 () ())) (6 (5 () ()) (7 () ()))))
(print-inorder t1)              ; expected: (1 2 3 4 5 6 7)
(print-height-and-leaves '())   ; expected: (0 0)
```
For Q4 (reads stdin):
```bash
cat code/id_q4.rkt tests/q4_calls.rkt > /tmp/run_q4.rkt   # q4_calls.rkt: (print-insert-result)
echo "42 ((1 2) (3 4 5) (6) ()) 3" | racket /tmp/run_q4.rkt
# expected: ((42 1 2) (3 4 5) (42 6) (42))
```
Compare actual output with expected output using `diff`. Include every example in the assignment plus edge cases: empty tree / empty list, single node, skewed trees, `n = 0`, symbols as values, nesting depth 100, and a list of 10,000 elements.

**Banned-identifier scan** (must print nothing):
```bash
grep -nwE 'length|append|reverse|map|filter|member|memq|list-ref|list-tail|set!|equal\?|list\?|symbol\?|number\?|zero\?|add1|sub1|when|unless|for|do|vector|string|printf|write|apply|foldl|foldr' code/id_q3.rkt code/id_q4.rkt
```
(Names you define yourself, like `my-length`, contain these words; `-w` only matches whole identifiers, but review any hit by hand.)

## 6. Self-review checklist (apply before every answer)
- [ ] First line is `#lang racket/base`.
- [ ] Every identifier used is either defined in the file or on the allowed list (section 2). Checked one by one.
- [ ] No `length`/`append`/`reverse`/`map`/`filter`/`member`, no `set!`, no strings/vectors/loops, no `equal?`/`list?`/`symbol?`/`zero?`/`add1`.
- [ ] `read` appears only in `id_q4.rkt`.
- [ ] No top-level calls, no top-level `display`, no test data that prints. `racket file.rkt` prints nothing.
- [ ] Every function has a contract comment with base case, shrinking argument, and tail-recursion status.
- [ ] Base cases: `'()` handled first in every recursive function.
- [ ] Accumulator-built lists are reversed exactly once (not zero, not twice), so order is correct.
- [ ] Every printing function ends its output with exactly one `newline`, and prints no extra spaces or text.
- [ ] Parentheses balanced; `cond` has an `else` branch where needed.
- [ ] Deep/large inputs: no `append` chains inside recursion (quadratic) and no recursion that grows unnecessarily; tested with depth 100 and 10,000 elements.
- [ ] Tests were actually run with the grader-style command, and the real output is shown.

## 7. Known AI failure modes in Scheme (check for each)
1. **Reaching for banned built-ins by habit:** `length`, `append`, `reverse`, `map`, `equal?`, `list?`, `symbol?`, `zero?`, `add1`, `when`, `for-each`, `apply`, `foldl`. These run fine in Racket, so the error is silent; only the grader catches it.
2. **Quasiquote / unquote** (`` `(,a ,b) ``) used to build lists. Not allowed; use `list` / `cons`.
3. **Top-level test calls left in the file**, or `(module+ test ...)` / `(provide ...)` added.
4. **Accumulator order bugs:** forgetting to reverse, reversing twice, or pre-order/post-order accumulated in the wrong order.
5. **Using `append` to concatenate traversal results.** It is banned and quadratic; thread an accumulator through the tree instead (visit right subtree first when consing onto an accumulator to get left-to-right order).
6. **Treating `'()` as an atom** or treating every non-pair as a list. In S2, `()` is a list of length 0 and must get `x` inserted when `0 < n`.
7. **Measuring length after insertion** instead of on the original list.
8. **Leaf/height confusion:** height of `()` is 0, single node is 1. A node with one empty child is not a leaf.
9. **Output format drift:** using `write`/`print` instead of `display`, printing each element separately with spaces, missing or doubled `newline`, printing `'(1 2)` with a quote.
10. **Mutation via `set!`** to keep counters or results.
11. **`read` misuse in Q4:** reading in the wrong order (must be `x`, then `lst`, then `n`), or printing a prompt.
12. **Using `else` outside `cond`** or `if` with only one branch where a value is printed.
13. **Strings sneaking in** via `"\n"` in `display` (use `newline`) or `number->string`.
14. **Claiming code was tested when it was not.** Always run it and show the actual output.
