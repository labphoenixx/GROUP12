#lang racket/base
;; Tests for S2 (g12_q4.rkt).
;; Run from the repo root (or anywhere):
;;   racket tests/test_q4.rkt
;; Only the final summary line is printed when every check passes;
;; failures are shown as rackunit FAILURE blocks.
;;
;; The solution file has no `provide`, so it is loaded with
;; dynamic-require and its definitions are read from the module's
;; namespace (module->namespace). The solution file is not modified.

(require rackunit
         racket/port
         racket/runtime-path)

(define-runtime-path solution "../code/g12_q4.rkt")

(define ns (make-base-namespace))
(define load-output
  (parameterize ([current-namespace ns])
    (with-output-to-string
      (lambda () (dynamic-require solution #f)))))
(define sol-ns
  (parameterize ([current-namespace ns])
    (module->namespace solution)))
(define (get name) (eval name sol-ns))

(define my-length           (get 'my-length))
(define my-map              (get 'my-map))
(define make-inserter       (get 'make-inserter))
(define insert-if-short     (get 'insert-if-short))
(define print-insert-result (get 'print-insert-result))

;; run-with-input : string -> string
;; Runs (print-insert-result) with input as standard input and returns
;; everything it printed.
(define (run-with-input input)
  (parameterize ([current-input-port (open-input-string input)])
    (with-output-to-string (lambda () (print-insert-result)))))

;; Helpers for building big inputs (used only in the tests).
(define (nums n)                        ; (1 2 ... n)
  (let loop ((k n) (acc '()))
    (if (= k 0) acc (loop (- k 1) (cons k acc)))))
(define (nest d)                        ; d levels around (1)
  (let loop ((k d) (acc '(1)))
    (if (= k 0) acc (loop (- k 1) (list acc)))))
(define (nest-with x d)                 ; expected: x inserted at every level
  (let loop ((k d) (acc (list x 1)))
    (if (= k 0) acc (loop (- k 1) (list x acc)))))
(define (time-ms thunk)
  (define start (current-inexact-milliseconds))
  (thunk)
  (- (current-inexact-milliseconds) start))

;; ------------------------------------------------------------------
;; Loading
;; ------------------------------------------------------------------
(test-case "loading the file prints nothing"
  (check-equal? load-output ""))

;; ------------------------------------------------------------------
;; my-length
;; ------------------------------------------------------------------
(test-case "my-length"
  (check-equal? (my-length '()) 0)
  (check-equal? (my-length '(a)) 1)
  (check-equal? (my-length '(1 (2 3) () a)) 4)     ; sublists count as 1
  (check-equal? (my-length (nums 10000)) 10000))

;; ------------------------------------------------------------------
;; my-map
;; ------------------------------------------------------------------
(test-case "my-map"
  (check-equal? (my-map (lambda (v) (+ v 1)) '()) '())
  (check-equal? (my-map (lambda (v) (+ v 1)) '(1 2 3)) '(2 3 4))
  (check-equal? (my-map (lambda (v) v) '(a (b) ())) '(a (b) ()))   ; order kept
  (check-equal? (my-length (my-map (lambda (v) (* 2 v)) (nums 10000))) 10000)
  (check-equal? (car (my-map (lambda (v) (* 2 v)) (nums 10000))) 2))

;; ------------------------------------------------------------------
;; make-inserter
;; ------------------------------------------------------------------
(test-case "make-inserter returns a procedure"
  (check-true (procedure? (make-inserter 'x (lambda (len) #t)))))

(test-case "make-inserter with custom length tests"
  (check-equal? ((make-inserter 'z (lambda (len) (= len 2)))
                 '(a (b c) (d (e f)) ()))
                '(a (z b c) (z d (z e f)) ()))
  (check-equal? ((make-inserter 'x (lambda (len) #t)) '(() (()))) 
                '(x (x) (x (x))))
  (check-equal? ((make-inserter 'x (lambda (len) #f)) '(1 (2) ()))
                '(1 (2) ()))
  ;; length measured on the original list: (a) has length 1 before
  ;; insertion, so with "len = 1" it gets x even though it becomes (x a)
  (check-equal? ((make-inserter 'x (lambda (len) (= len 1))) '((a) b))
                '((x a) b)))

;; ------------------------------------------------------------------
;; insert-if-short: assignment examples and edge cases
;; ------------------------------------------------------------------
(test-case "insert-if-short: assignment examples"
  (check-equal? (insert-if-short 42 '((1 2) (3 4 5) (6) ()) 3)
                '((42 1 2) (3 4 5) (42 6) (42)))
  (check-equal? (insert-if-short 0 '(((1) 2) (3) ((4 5 6) ())) 3)
                '((0 (0 1) 2) (0 3) (0 (4 5 6) (0))))
  (check-equal? (insert-if-short 7 '() 3) '(7))
  (check-equal? (insert-if-short 7 '() 0) '()))

(test-case "insert-if-short: boundaries"
  (check-equal? (insert-if-short 'q '(a b) 2) '(a b))      ; 2 < 2 is false
  (check-equal? (insert-if-short 'q '(a b) 3) '(q a b))
  (check-equal? (insert-if-short 'q '(() ()) 1) '((q) (q)))
  (check-equal? (insert-if-short 'q '(a (b) c) 0) '(a (b) c)))

;; ------------------------------------------------------------------
;; Large inputs
;; ------------------------------------------------------------------
(test-case "nesting depth 100"
  (check-equal? (insert-if-short 'x (nest 100) 2) (nest-with 'x 100))
  (check-equal? (insert-if-short 'x (nest 100) 1) (nest 100)))

(test-case "flat list of 10,000 elements"
  (define big (nums 10000))
  (define ms
    (time-ms
     (lambda ()
       (check-equal? (insert-if-short 'x big 20000) (cons 'x big))
       (check-equal? (insert-if-short 'x big 3) big))))
  (check-true (< ms 2000) "10,000 elements should finish well under 2 s"))

(test-case "10,000 sublists, each short"
  (define big (my-map (lambda (v) (list v)) (nums 10000)))
  (define result (insert-if-short 'x big 2))
  (check-equal? (my-length result) 10000)              ; top not inserted
  (check-equal? (car result) '(x 1)))

;; ------------------------------------------------------------------
;; print-insert-result (stdin -> stdout)
;; ------------------------------------------------------------------
(test-case "print-insert-result: assignment examples"
  (check-equal? (run-with-input "42 ((1 2) (3 4 5) (6) ()) 3")
                "((42 1 2) (3 4 5) (42 6) (42))\n")
  (check-equal? (run-with-input "0 (((1) 2) (3) ((4 5 6) ())) 3")
                "((0 (0 1) 2) (0 3) (0 (4 5 6) (0)))\n")
  (check-equal? (run-with-input "7 () 3") "(7)\n")
  (check-equal? (run-with-input "7 () 0") "()\n"))

(test-case "print-insert-result: input over several lines"
  (check-equal? (run-with-input "z\n(a\n (b c))\n5\n") "(z a (z b c))\n"))

(test-case "print-insert-result: depth 100 from stdin"
  (define input (format "x ~a 2" (nest 100)))
  (check-equal? (run-with-input input)
                (string-append (format "~a" (nest-with 'x 100)) "\n")))

(display "test_q4: all checks run (failures, if any, are shown above)")
(newline)
