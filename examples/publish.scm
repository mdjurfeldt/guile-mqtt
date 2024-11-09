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

(define is-published #f)

(define client (make-client #:on-publish (lambda (client mid)
					   (set! is-published #t))))

(connect client broker)
(publish client "guile-mqtt/test" "Hello world!")

;; Loop until published
(while (not is-published)
  (loop client))
