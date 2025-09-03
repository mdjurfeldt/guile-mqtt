;;; mosquitto/client.scm --- Guile API to libmosquitto
;;;
;;; Copyright (C) 2024, 2025 Free Software Foundation, Inc.
;;;
;;; This library is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU Lesser General Public License as
;;; published by the Free Software Foundation, either version 3 of the
;;; License, or (at your option) any later version.
;;;
;;; This library is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;; Lesser General Public License for more details.
;;;
;;; You should have received a copy of the GNU Lesser General Public
;;; License along with this program.  If not, see
;;; <http://www.gnu.org/licenses/>.

;;; Commentary:
;;;
;;; Code:

(define-module (mosquitto client)
  #:use-module (oop goops)
  #:use-module (ffi mosquitto)
  #:use-module (system foreign)
  #:use-module (mosquitto foreign cdata)
  #:use-module ((guile) #:select (connect) #:prefix guile:)
  #:use-module (rnrs bytevectors)
  #:export (<mosquitto-client>
            make-client user-data client
            connect disconnect
            publish subscribe unsubscribe
            loop loop-forever
            connect-callback disconnect-callback publish-callback
            message message-callback topic payload
            subscribe-callback unsubscribe-callback log-callback
            )
  #:replace (connect)
  )

(define (bool->int b)
  (if b 1 0))

;;; Class <mosquitto-client>

(define mosq-guardian (make-guardian))

(add-hook! after-gc-hook
           (lambda ()
             (let loop ((obj (mosq-guardian)))
               (if obj
                   (begin
                     (mosquitto_destroy mosq)
                     (loop (mosq-guardian)))))))

(define-class <mosquitto-client> ()
  (mosq #:accessor mosq)
  (user-data #:accessor user-data #:init-keyword #:user-data))

(define-method (initialize (client <mosquitto-client>) initargs)
  (let ((id             (get-keyword #:id initargs #f))
        (clean-session  (get-keyword #:clean-session initargs #t))
        (on-connect     (get-keyword #:on-connect initargs #f))
        (on-disconnect  (get-keyword #:on-disconnect initargs #f))
        (on-publish     (get-keyword #:on-publish initargs #f))
        (on-message     (get-keyword #:on-message initargs #f))
        (on-subscribe   (get-keyword #:on-subscribe initargs #f))
        (on-unsubscribe (get-keyword #:on-unsubscribe initargs #f))
        (on-log         (get-keyword #:on-log initargs #f))
        )
    (if (not id)
        (set! id (string-append "client-"
                                (number->string (random (expt 2 32) (random-state-from-platform)) 16))))
    (let ((obj (mosquitto_new id (bool->int clean-session) (scm->pointer client))))
      (mosq-guardian obj)
      (set! (mosq client) obj)
      (if on-connect
          (set! (connect-callback client) on-connect))
      (if on-disconnect
          (set! (disconnect-callback client) on-disconnect))
      (if on-publish
          (set! (publish-callback client) on-publish))
      (if on-message
          (set! (message-callback client) on-message))
      (if on-subscribe
          (set! (subscribe-callback client) on-subscribe))
      (if on-unsubscribe
          (set! (unsubscribe-callback client) on-unsubscribe))
      (if on-log
          (set! (log-callback client) on-log))))
  (next-method))

(define (make-client . args)
  (apply make <mosquitto-client> args))

;;; Connecting, reconnecting, disconnecting

(define connect guile:connect)

;;; This will pickup the old definition of connect as a default method
(define-generic connect)

(define-method (connect (client <mosquitto-client>) (host <string>) . args)
  (define* (connect #:key (port 1883) (keepalive 60) bind-address
                    username password tls-cafile tls-capath
                    tls-certfile tls-keyfile tls-ocsp-required
                    tls-use-os-certs tls-alpn socks5-host socks5-port
                    socks5-username socks5-password reconnect-delay
                    reconnect-delay-max reconnect-exp-backoff tcp-nodelay)
    (if username
        (begin
          (if (not password)
              (error "connect: must supply password"))
          (mosquitto_username_pw_set (mosq client) username password)))
    (if (or tls-cafile tls-capath tls-certfile tls-keyfile)
        (begin
          (if (not (or tls-cafile tls-capath))
              (error "connect: either tls-cafile or tls-capth must be given"))
          (if (not (and tls-certfile tls-keyfile))
              (error "connect: both tls-certfile amd tls-keyfile mustbe given"))
          (mosquitto_tls_set (mosq client)
                             (or tls-cafile %null-pointer)
                             (or tls-capath %null-pointer)
                             tls-certfile
                             tls-keyfile
                             %null-pointer)
          (if tls-ocsp-required
              (mosquitto_int_option (mosq client)
                                    'MOSQ_OPT_TLS_OCSP_REQUIRED
                                    1))
          (if tls-use-os-certs
              (mosquitto_int_option (mosq client)
                                    'MOSQ_OPT_TLS_USE_OS_CERTS
                                    1))
          (if tls-alpn
              (mosquitto_string_option (mosq client)
                                       'MOSQ_OPT_TLS_ALPN
                                       tls-alpn))))
    (if socks5-host
        (mosquitto_socks5_set (mosq client)
                              socks5-host
                              (or socks5-port 1080)
                              (or socks5-username %null-pointer)
                              (or socks5-password %null-pointer)))
    (if (or reconnect-delay reconnect-delay-max reconnect-exp-backoff)
        (mosquitto_reconnect_delay_set (mosq client)
                                       (or reconnect-delay 1)
                                       (or reconnect-delay-max 10)
                                       reconnect-exp-backoff))
    (if tcp-nodelay
        (mosquitto_int_option (mosq client)
                              'MOSQ_OPT_TCP_NODELAY
                              1))
    (if bind-address
        (mosquitto_connect_bind (mosq client) host port keepalive bind-address)
        (mosquitto_connect (mosq client) host port keepalive)))
  (apply connect args))

(define-method (disconnect (client <mosquitto-client>))
  (mosquitto_disconnect (mosq client)))

;;; Publishing, subscribing, unsubscribing

(define-method (publish (client <mosquitto-client>) (topic <string>) (payload <string>) . args)
  (define* (publish #:key (qos 0) retain)
    (let ((mid (make-cdata (cbase 'int))))
      (mosquitto_publish (mosq client)
                         (cdata& mid)
                         topic
                         (bytevector-length (string->utf8 payload))
                         payload
                         qos
                         (bool->int retain))
      (cdata-ref mid))) ; return message id
  (apply publish args))

(define-method (subscribe (client <mosquitto-client>) (topic <string>) . args)
  (define* (subscribe #:key (qos 0))
    (mosquitto_subscribe (mosq client) %null-pointer topic qos))
  (apply subscribe args))

(define-method (unsubscribe (client <mosquitto-client>) (topic <string>))
  (mosquitto_unsubscribe (mosq client) %null-pointer topic))

;;; Network loop

(define-method (loop-forever (client <mosquitto-client>) . args)
  (define* (loop-forever #:key (timeout -1))
    (mosquitto_loop_forever (mosq client) timeout 1))
  (apply loop-forever args))

(define-method (loop (client <mosquitto-client>) . args)
  (define* (loop #:key (timeout -1))
    (mosquitto_loop (mosq client) timeout 1))
  (apply loop args))

;;; Callbacks

(define (make-int-callback callback)
  (lambda (mosq client int)
    (callback (pointer->scm client) int)))

(define-method ((setter connect-callback) (client <mosquitto-client>) callback)
  (mosquitto_connect_callback_set (mosq client) (make-int-callback callback)))

(define-method ((setter disconnect-callback) (client <mosquitto-client>) callback)
  (mosquitto_disconnect_callback_set (mosq client) (make-int-callback callback)))

(define-method ((setter publish-callback) (client <mosquitto-client>) callback)
  (mosquitto_publish_callback_set (mosq client) (make-int-callback callback)))

(define-class <message> ()
  (message #:getter message #:init-keyword #:message))

(define-method (topic (m <message>))
  (pointer->string (cdata*-ref (message m) 'topic)))

(define-method (payload (m <message>))
  (let ((len (cdata*-ref (message m) 'payloadlen)))
    (pointer->string (cdata*-ref (message m) 'payload) len)))

(define (make-message-callback callback)
  (lambda (mosq obj message)
    (callback (pointer->scm obj) (make <message> #:message message))))

(define-method ((setter message-callback) (client <mosquitto-client>) callback)
  (mosquitto_message_callback_set (mosq client) (make-message-callback callback)))

(define (make-subscribe-callback callback)
  (lambda (mosq obj mid qos-count granted-qos)
    (callback (pointer->scm obj) mid)))

(define-method ((setter subscribe-callback) (client <mosquitto-client>) callback)
  (mosquitto_subscribe_callback_set (mosq client) (make-subscribe-callback callback)))

(define-method ((setter unsubscribe-callback) (client <mosquitto-client>) callback)
  (mosquitto_unsubscribe_callback_set (mosq client) (make-int-callback callback)))

(define (make-log-callback callback)
  (lambda (mosq obj level str)
    (callback (pointer->scm obj) level (pointer->string str))))

(define-method ((setter log-callback) (client <mosquitto-client>) callback)
  (mosquitto_log_callback_set (mosq client) (make-log-callback callback)))

;;; Error codes

(define (publish-enum-type! enum-type)
  (let* ((type-info (ctype-info enum-type))
         (unwrap (cenum-numf type-info))
         (interface (module-public-interface (current-module))))
    (for-each (lambda (name)
                (module-define! interface name (unwrap name)))
              (cenum-syml type-info))))

(publish-enum-type! enum-mosq_err_t)

;;; Initialize libmosquitto

(mosquitto_lib_init)
