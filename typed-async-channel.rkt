#lang typed/racket/base
(require/typed racket/async-channel
               [make-async-channel (All (A) (->* () (Integer) (Async-Channelof A)))]
               )

(provide make-async-channel
         )
