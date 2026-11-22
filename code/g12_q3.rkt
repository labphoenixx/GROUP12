#lang racket/base

;; ------------------------------------------------------------------
;; List helpers (built-in reverse and append are not allowed)
;; ------------------------------------------------------------------

;; my-reverse : list -> list
;; Purpose: returns the top-level elements of lst in reverse order.
;; Recursion: on lst. Base case () returns the accumulator; each step
;;   moves (car lst) onto the front of acc, so the first element ends
;;   up last.
;; Tail-recursive: yes (the recursive call is the last thing done).
(define my-reverse
  (lambda (lst)
    (let loop ((rest lst) (acc '()))
      (if (null? rest)
          acc
          (loop (cdr rest) (cons (car rest) acc))))))

;; my-append : list list -> list
;; Purpose: returns the elements of a followed by the elements of b.
;; Method: reverse a once, then move its elements one by one onto the
;;   front of b. Reversing first puts them back in the original order.
;; Recursion: on the reversed a. Base case () returns acc (which
;;   starts as b).
;; Tail-recursive: yes; my-reverse is tail-recursive too, so the whole
;;   function runs in constant stack space. b is shared, not copied.
(define my-append
  (lambda (a b)
    (let loop ((rest (my-reverse a)) (acc b))
      (if (null? rest)
          acc
          (loop (cdr rest) (cons (car rest) acc))))))
