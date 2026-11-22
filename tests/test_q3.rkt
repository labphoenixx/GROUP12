#lang racket/base
;; Tests for S1 (g12_q3.rkt).
;; Run from the repo root (or anywhere):
;;   racket tests/test_q3.rkt
;; No output from rackunit means every check passed; a summary line is
;; printed at the end.
;;
;; The solution file has no `provide`, so it is loaded with
;; dynamic-require and its definitions are read from the module's
;; namespace (module->namespace). The solution file is not modified.

(require rackunit
         racket/port
         racket/runtime-path)

(define-runtime-path solution "../code/g12_q3.rkt")

;; Load the module, capturing anything printed while loading.
(define ns (make-base-namespace))
(define load-output
  (parameterize ([current-namespace ns])
    (with-output-to-string
      (lambda () (dynamic-require solution #f)))))
(define sol-ns
  (parameterize ([current-namespace ns])
    (module->namespace solution)))

;; get : symbol -> value defined in g12_q3.rkt
(define (get name) (eval name sol-ns))

(define print-inorder           (get 'print-inorder))
(define print-all-traversals    (get 'print-all-traversals))
(define print-height-and-leaves (get 'print-height-and-leaves))

;; out : procedure tree -> string printed by (proc tree)
(define (out proc tree)
  (with-output-to-string (lambda () (proc tree))))

;; ------------------------------------------------------------------
;; Trees
;; ------------------------------------------------------------------
(define t1 '(4 (2 (1 () ()) (3 () ()))
               (6 (5 () ()) (7 () ()))))
(define t2 '(1 () (2 () (3 () ()))))           ; right-skewed
(define t3 '(a (b () ()) (c () ())))           ; symbols
(define empty '())
(define single '(9 () ()))
(define left-skewed '(3 (2 (1 () ()) ()) ()))
(define zigzag '(1 (2 () (3 (4 () ()) ())) ())) ; left, right, left
(define one-child '(5 (4 () ()) ()))            ; root is not a leaf

;; Large skewed trees (built here, not in the solution file).
(define (left-chain n)          ; root 1, left child 2, ..., n deepest
  (let loop ((k n) (acc '()))
    (if (= k 0) acc (loop (- k 1) (list k acc '())))))
(define (right-chain n)         ; root 1, right child 2, ..., n deepest
  (let loop ((k n) (acc '()))
    (if (= k 0) acc (loop (- k 1) (list k '() acc)))))
(define (nums from to)          ; (from from+1 ... to)
  (let loop ((k to) (acc '()))
    (if (< k from) acc (loop (- k 1) (cons k acc)))))
(define (as-line lst) (string-append (format "~a" lst) "\n"))

;; ------------------------------------------------------------------
;; Loading
;; ------------------------------------------------------------------
(test-case "loading the file prints nothing"
  (check-equal? load-output ""))

;; ------------------------------------------------------------------
;; S1.a print-inorder
;; ------------------------------------------------------------------
(test-case "print-inorder: assignment examples"
  (check-equal? (out print-inorder t1) "(1 2 3 4 5 6 7)\n")
  (check-equal? (out print-inorder t2) "(1 2 3)\n")
  (check-equal? (out print-inorder t3) "(b a c)\n")
  (check-equal? (out print-inorder empty) "()\n"))

(test-case "print-inorder: edge cases"
  (check-equal? (out print-inorder single) "(9)\n")
  (check-equal? (out print-inorder left-skewed) "(1 2 3)\n")
  (check-equal? (out print-inorder zigzag) "(2 4 3 1)\n")
  (check-equal? (out print-inorder one-child) "(4 5)\n"))

;; ------------------------------------------------------------------
;; S1.b print-all-traversals
;; ------------------------------------------------------------------
(test-case "print-all-traversals: assignment examples"
  (check-equal? (out print-all-traversals t1)
                "(1 2 3 4 5 6 7)\n(4 2 1 3 6 5 7)\n(1 3 2 5 7 6 4)\n")
  (check-equal? (out print-all-traversals t2)
                "(1 2 3)\n(1 2 3)\n(3 2 1)\n")
  (check-equal? (out print-all-traversals t3)
                "(b a c)\n(a b c)\n(b c a)\n")
  (check-equal? (out print-all-traversals empty)
                "()\n()\n()\n"))

(test-case "print-all-traversals: edge cases"
  (check-equal? (out print-all-traversals single)
                "(9)\n(9)\n(9)\n")
  (check-equal? (out print-all-traversals left-skewed)
                "(1 2 3)\n(3 2 1)\n(1 2 3)\n")
  (check-equal? (out print-all-traversals zigzag)
                "(2 4 3 1)\n(1 2 3 4)\n(4 3 2 1)\n")
  (check-equal? (out print-all-traversals one-child)
                "(4 5)\n(5 4)\n(4 5)\n"))

;; ------------------------------------------------------------------
;; S1.c print-height-and-leaves
;; ------------------------------------------------------------------
(test-case "print-height-and-leaves: assignment examples"
  (check-equal? (out print-height-and-leaves t1) "(3 4)\n")
  (check-equal? (out print-height-and-leaves t2) "(3 1)\n")
  (check-equal? (out print-height-and-leaves t3) "(2 2)\n")
  (check-equal? (out print-height-and-leaves empty) "(0 0)\n"))

(test-case "print-height-and-leaves: edge cases"
  (check-equal? (out print-height-and-leaves single) "(1 1)\n")
  (check-equal? (out print-height-and-leaves left-skewed) "(3 1)\n")
  (check-equal? (out print-height-and-leaves zigzag) "(4 1)\n")
  (check-equal? (out print-height-and-leaves one-child) "(2 1)\n"))

;; ------------------------------------------------------------------
;; Large skewed trees (1000 nodes)
;; ------------------------------------------------------------------
(test-case "large left-skewed tree"
  (define t (left-chain 1000))
  (check-equal? (out print-inorder t) (as-line (reverse (nums 1 1000))))
  (check-equal? (out print-height-and-leaves t) "(1000 1)\n"))

(test-case "large right-skewed tree"
  (define t (right-chain 1000))
  (check-equal? (out print-all-traversals t)
                (string-append (as-line (nums 1 1000))
                               (as-line (nums 1 1000))
                               (as-line (reverse (nums 1 1000)))))
  (check-equal? (out print-height-and-leaves t) "(1000 1)\n"))

(display "test_q3: all checks run (failures, if any, are shown above)")
(newline)
