#lang typed/racket/base
(require "typed-tcp.rkt"
         "typed-async-channel.rkt")

(define-type Handler (-> Input-Port Output-Port Void))
(define-type Timeout-Thread Thread)
(define-type Worker-Thread Thread)
(define-type Request-Channel (Async-Channelof request))

(struct: pool ([workers : (List Worker-Thread)]
               [requests : Request-Channel]))

(struct: request ([in : Input-Port]
                  [out : Output-Port]))

(: request-channel Request-Channel)
(define request-channel (make-async-channel))

(: serve (->* () (#:port Integer
                  #:handler Handler
                  #:num-workers Nonnegative-Integer
                  #:worker-timeout Nonnegative-Integer
                  #:worker-memory-limit Nonnegative-Integer) (-> Void)))
(define (serve #:port [port-number 3000]
               #:handler [handler handle]
               #:num-workers [num-workers 10]
               #:worker-timeout [worker-timeout 10]
               #:worker-memory-limit [worker-memory-limit (* 50 1024 1024)])
  (define custodian (make-custodian))
  (parameterize ([current-custodian custodian])
    (define listener (tcp-listen port-number (* 4 num-workers)))
    (for ([i (in-range 0 num-workers)])
      (thread (serve-loop listener handler num-workers worker-timeout worker-memory-limit))))
  ;; Return a Procedure to shutdown the custodian
  ;; and its children.
  (lambda ()
    (custodian-shutdown-all custodian)))

(: serve-loop (-> TCP-Listener Handler Nonnegative-Integer Nonnegative-Integer Nonnegative-Integer (-> Void)))
(define (serve-loop listener handler num-workers worker-timeout worker-memory-limit)
  (define i (random num-workers))
  (: inner (-> Void))
  (define (inner)
    (define run (lambda ()
                  (display (string-append "id: " (number->string i) "\n"))
                  (accept listener handler worker-timeout worker-memory-limit)))
    (if (tcp-accept-ready? listener)
        (run)
        (void))
    (inner))
  inner)

;; Simple TCP worker
(: accept (-> TCP-Listener (-> Input-Port Output-Port Void) Nonnegative-Integer Nonnegative-Integer Thread))
(define (accept listener handler timeout memory-limit)
  (define custodian (make-custodian))
  (custodian-limit-memory custodian memory-limit)
  (parameterize ([current-custodian custodian])
    (define-values (in out) (tcp-accept listener))
    (thread (lambda ()
              (handler in out)
              (close-input-port in)
              (close-output-port out))))
  (thread (lambda ()
            (sleep timeout)
            (custodian-shutdown-all custodian))))

;; Dummy Handler
(: handle Handler)
(define (handle in out)
  (define req
    (let ([request-line
      (let ([line (read-line in)])
        (if (eof-object? line)
            ""
            line))])
    ;; Match the first line to extract the request:
    (regexp-match #rx"^GET (.+) HTTP/[0-9]+\\.[0-9]+" request-line)))
  (when req
    ;; Discard the rest of the header (up to blank line):
    (regexp-match #rx"(\r\n|^)\r\n" in)
    ;; Send reply:
    (display "HTTP/1.0 200 Okay\r\n" out)
    (display "Server: k\r\nContent-Type: text/html\r\n\r\n" out)
    (display "Hello" out)))
