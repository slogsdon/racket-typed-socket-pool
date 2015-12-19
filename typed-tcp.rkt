#lang typed/racket/base
(require/typed racket/tcp
               [tcp-listen (->* (Integer) (Integer Any (U False String)) TCP-Listener)]
               [tcp-connect (-> String Integer (values Input-Port Output-Port))]
               [tcp-connect/enable-break (-> String Integer (values Input-Port Output-Port))]
               [tcp-accept (-> TCP-Listener (values Input-Port Output-Port))]
               [tcp-accept/enable-break (-> TCP-Listener (values Input-Port Output-Port))]
               [tcp-accept-ready? (-> TCP-Listener Boolean)]
               [tcp-close (-> TCP-Listener Void)]
               [tcp-listener? (-> Any Boolean)]
               [tcp-accept-evt (-> TCP-Listener Any)] ;;(-> TCP-Listener (Evtof (List Input-Port Output-Port)))
               [tcp-abandon-port (-> Port Void)]
               [tcp-addresses (case->
                               (-> Port (values String String)) ;;(->* (Port) (False) (values String String))
                               (-> Port True (values String Index String Index)))]
               [tcp-port? (-> Any Boolean)])

(provide tcp-listen
         tcp-connect
         tcp-connect/enable-break
         tcp-accept
         tcp-accept/enable-break
         tcp-accept-ready?
         tcp-close
         tcp-listener?
         tcp-accept-evt
         tcp-abandon-port
         tcp-addresses
         tcp-port?)