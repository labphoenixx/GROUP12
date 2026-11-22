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
