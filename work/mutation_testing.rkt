#lang racket

(require redex
         "interface.rkt")

(provide (all-defined-out))

(define p (read (open-input-file "fact.txt")))

(define f-name (box ""))

(define (get-contract t)
  (match t
    [(list 'provide (list 'contract-out (list _ more))) more]
    [_ "error"]))

(define (get-body t)
  (match t
    [(list 'define name more) (begin (set-box! f-name name) more)]
    [_ "error"]))

(define (parse-program p x)
  (cond
    [(empty? p) "error"]
    [(equal? "error" (x (first p))) (parse-program (rest p) x)]
    [else (x (first p))]))

(define (contract->type c)
  (let ([cpair (match c
                 [(cons '-> (cons a b)) (cons a b)])])
    (let ([cin (first cpair)] [cout (second cpair)])
      (cons (get-type-from-contract cin)
            (get-type-from-contract cout)))))

(define (get-type-from-contract c)
  (match c
    ['integer? 'num]
    ['real?    'num]
    [(cons '<=/c _) 'num]
    [(cons '>=/c _) 'num]
    [(cons '>/c _)  'num]
    [(cons '</c _)  'num]
    
    ['and      'bool]
    ['or       'bool]
    ['true?    'bool]
    
    [(cons '-> (cons a b)) 
     (cons '-> (list (get-type-from-contract a)
                     (get-type-from-contract (first b))))]))

(define (generate-new-function cpair)
  (gen-term (list (list (cadr (unbox f-name)) (car cpair)))
            'expression 
            (cdr cpair)
            0
            0
            1))

(define (build-new-program p f)
  (cond
    [(empty? p) p]
    [(equal? 
      (match (first p)
        [(list 'define _ more) #t]
        [_ "error"]) 
      #t)
     (cons (list 'define (unbox f-name) f) (build-new-program (rest p) f))]
    [else (cons (first p) (build-new-program (rest p) f))]))


(define (mutate-program path)
  (let ([p (read (open-input-file path))])
    (let ([cpair (contract->type (parse-program p get-contract))])
      (let ([body (parse-program p get-body)])
        (let ([f (generate-new-function cpair)])
          (build-new-program p f))))))




