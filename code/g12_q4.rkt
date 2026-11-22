#lang racket/base

;; ------------------------------------------------------------------
;; List helpers (built-in reverse, length and map are not allowed)
;; ------------------------------------------------------------------

;; my-reverse : list -> list
;; Purpose: returns the top-level elements of lst in reverse order.
;; Recursion: on lst. Base case () returns acc; each step moves
;;   (car lst) onto the front of acc.
;; Tail-recursive: yes.
(define my-reverse
  (lambda (lst)
    (let loop ((rest lst) (acc '()))
      (if (null? rest)
          acc
          (loop (cdr rest) (cons (car rest) acc))))))

;; my-length : list -> number
;; Purpose: number of top-level elements of lst (atoms and sublists
;;   each count as 1). (my-length '()) is 0.
;; Recursion: on lst. Base case () returns the count so far; each step
;;   adds 1 and moves to (cdr lst).
;; Tail-recursive: yes.
(define my-length
  (lambda (lst)
    (let loop ((rest lst) (count 0))
      (if (null? rest)
          count
          (loop (cdr rest) (+ count 1))))))

;; my-map : (any -> any) list -> list
;; Purpose: returns the list of (f e) for each top-level element e of
;;   lst, in the original order. (my-map f '()) is ().
;; Method: apply f left to right, consing each result onto acc (which
;;   builds the results in reverse), then reverse acc once at the end.
;; Recursion: on lst. Base case () returns (my-reverse acc).
;; Tail-recursive: yes (my-reverse is tail-recursive too).
(define my-map
  (lambda (f lst)
    (let loop ((rest lst) (acc '()))
      (if (null? rest)
          (my-reverse acc)
          (loop (cdr rest) (cons (f (car rest)) acc))))))

;; ------------------------------------------------------------------
;; S2.c: higher-order inserter
;; ------------------------------------------------------------------

;; list-like? : any -> boolean
;; Purpose: #t when e is a list: the empty list () or a pair.
;;   Everything else (numbers, symbols) is an atom. There are no
;;   dotted pairs in the input, so every pair is a proper list.
(define list-like?
  (lambda (e)
    (or (null? e) (pair? e))))

;; make-inserter : atom (number -> boolean) -> (list -> list)
;; Purpose: returns a function of one list. That function inserts x at
;;   the front of the list itself and of every list nested inside it,
;;   at every level, whose length satisfies len-ok?.
;; Length rule: the length of a list is its number of top-level
;;   elements, measured on the ORIGINAL list, before any insertion
;;   (my-length is applied to lst, not to the result). () has length 0.
;; Recursion (inside process): on the nesting structure. Each element
;;   that is a list is processed recursively (it is strictly smaller
;;   than its parent); atoms are kept as they are. Base case: () has no
;;   elements, so my-map returns () and only the length test remains.
;; Tail-recursive: the walk along each list is (my-map is); descending
;;   into sublists is not, so stack use grows with nesting depth
;;   (depth 100 is tiny), not with list length.
(define make-inserter
  (lambda (x len-ok?)
    (letrec ((process
              (lambda (lst)
                (let ((new-elems
                       (my-map (lambda (e)
                                 (if (list-like? e)
                                     (process e)
                                     e))
                               lst)))
                  (if (len-ok? (my-length lst))
                      (cons x new-elems)
                      new-elems)))))
      process)))

;; ------------------------------------------------------------------
;; S2.b / S2.c: insert-if-short (defined with make-inserter)
;; ------------------------------------------------------------------

;; insert-if-short : atom list number -> list
;; Purpose: inserts x at the front of lst and of every list nested in
;;   it, at every level, whose original length is less than n.
;;   () has length 0, so it becomes (x) whenever 0 < n.
;; Method: make-inserter with the length test (< len n). It uses
;;   my-length and my-map internally.
(define insert-if-short
  (lambda (x lst n)
    ((make-inserter x (lambda (len) (< len n))) lst)))

;; ------------------------------------------------------------------
;; S2.a: reading input and printing the result
;; ------------------------------------------------------------------

;; print-insert-result : -> (prints)
;; Purpose: reads x, then lst, then n from standard input with read,
;;   and prints (insert-if-short x lst n) with display, then a newline.
;;   No prompt or any other text is printed.
;; let* makes the reading order explicit: x first, lst second, n third.
(define print-insert-result
  (lambda ()
    (let* ((x (read))
           (lst (read))
           (n (read)))
      (display (insert-if-short x lst n))
      (newline))))
