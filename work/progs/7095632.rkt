(module f racket (provide (contract-out (f (-> any/c (and any/c (<=/c 37)))))) (define (f x) (+ x x)))