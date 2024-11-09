;;; examples/client.scm
;;;
;;; Copyright (C) 2024 Free Software Foundation, Inc.
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

(use-modules (mosquitto client))

(define broker "test.mosquitto.org")

(define (receive-message client message)
  (format #t "~40A: ~A\n" (topic message) (payload message)))

(define client (make-client #:on-message receive-message))

(connect client broker)
(subscribe client "#")
(loop-forever client)
