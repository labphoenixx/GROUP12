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

;; ------------------------------------------------------------------
;; Tree access
;; A tree is either '() or a three-element list (value left right).
;; ------------------------------------------------------------------

;; node-value : tree -> value      (the tree must not be empty)
(define node-value (lambda (tree) (car tree)))

;; node-left : tree -> tree        (the tree must not be empty)
(define node-left (lambda (tree) (cadr tree)))

;; node-right : tree -> tree       (the tree must not be empty)
(define node-right (lambda (tree) (caddr tree)))

;; ------------------------------------------------------------------
;; S1.a: inorder
;; ------------------------------------------------------------------

;; inorder : tree -> list
;; Purpose: returns the values of tree in inorder
;;   (left subtree, node, right subtree).
;; Recursion: on the tree. Base case '() returns '(). Otherwise the
;;   result is (inorder left) followed by the node value consed onto
;;   (inorder right). Both subtrees are strictly smaller.
;; Tail-recursive: no (a tree has two subtrees, so at most one call
;;   can be in tail position).
(define inorder
  (lambda (tree)
    (if (null? tree)
        '()
        (my-append (inorder (node-left tree))
                   (cons (node-value tree)
                         (inorder (node-right tree)))))))

;; print-inorder : tree -> (prints)
;; Purpose: prints the inorder list of tree on one line with display,
;;   then a newline. The empty tree prints ().
(define print-inorder
  (lambda (tree)
    (display (inorder tree))
    (newline)))

;; ------------------------------------------------------------------
;; S1.b: preorder, postorder, all traversals
;; ------------------------------------------------------------------

;; preorder : tree -> list
;; Purpose: returns the values of tree in preorder
;;   (node, left subtree, right subtree).
;; Recursion: on the tree. Base case '() returns '(). Otherwise the
;;   node value is consed onto (preorder left) followed by
;;   (preorder right).
;; Tail-recursive: no (two subtrees).
(define preorder
  (lambda (tree)
    (if (null? tree)
        '()
        (cons (node-value tree)
              (my-append (preorder (node-left tree))
                         (preorder (node-right tree)))))))

;; postorder : tree -> list
;; Purpose: returns the values of tree in postorder
;;   (left subtree, right subtree, node).
;; Recursion: on the tree. Base case '() returns '(). Otherwise
;;   (postorder left) followed by (postorder right) followed by the
;;   one-element list of the node value.
;; Tail-recursive: no (two subtrees).
(define postorder
  (lambda (tree)
    (if (null? tree)
        '()
        (my-append (postorder (node-left tree))
                   (my-append (postorder (node-right tree))
                              (list (node-value tree)))))))

;; print-all-traversals : tree -> (prints)
;; Purpose: prints three lines with display: the inorder list, the
;;   preorder list and the postorder list, each followed by a newline.
;;   The empty tree prints () on all three lines.
(define print-all-traversals
  (lambda (tree)
    (display (inorder tree))
    (newline)
    (display (preorder tree))
    (newline)
    (display (postorder tree))
    (newline)))

;; ------------------------------------------------------------------
;; S1.c: height and leaf count
;; ------------------------------------------------------------------

;; height : tree -> number
;; Purpose: height of tree. '() has height 0; a node has height
;;   1 + the larger of its two subtree heights (a single node is 1).
;; Recursion: on the tree; both subtrees are strictly smaller.
;; Tail-recursive: no (two subtrees).
(define height
  (lambda (tree)
    (if (null? tree)
        0
        (+ 1 (max (height (node-left tree))
                  (height (node-right tree)))))))

;; leaf? : tree -> boolean        (the tree must not be empty)
;; Purpose: #t when both subtrees of the node are '().
(define leaf?
  (lambda (tree)
    (and (null? (node-left tree))
         (null? (node-right tree)))))

;; count-leaves : tree -> number
;; Purpose: number of leaves in tree. '() has 0 leaves; a leaf counts
;;   as 1; any other node has the sum of its subtrees' leaves.
;;   A node with exactly one empty child is not a leaf.
;; Recursion: on the tree; both subtrees are strictly smaller.
;; Tail-recursive: no (two subtrees).
(define count-leaves
  (lambda (tree)
    (cond ((null? tree) 0)
          ((leaf? tree) 1)
          (else (+ (count-leaves (node-left tree))
                   (count-leaves (node-right tree)))))))

;; print-height-and-leaves : tree -> (prints)
;; Purpose: prints the list (height leaf-count) on one line with
;;   display, then a newline. The empty tree prints (0 0).
(define print-height-and-leaves
  (lambda (tree)
    (display (list (height tree) (count-leaves tree)))
    (newline)))
