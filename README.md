# Guile MQTT

Guile MQTT provides bindings for the libmosquitto MQTT client
library. The bindings are written in
[GOOPS](https://www.gnu.org/software/guile/manual/html_node/GOOPS.html)
and rely on lower-level bindings created by NYACC directly and
automatically from mosquitto.h.

The bindings align with GOOPS style, which means short method
names. (The specialization is done through the arguments.)

The user can extend the client class by inheritance.

# Dependencies

* [Guile Scheme](https://www.gnu.org/software/guile/)
* [NYACC](https://www.nongnu.org/nyacc/) by Matt Wette
* [libmosquitto](https://github.com/eclipse-mosquitto/mosquitto)

# Example

This example, as well as the Guile libmosquitto bindings themselves,
are inspired by the [Chicken Scheme mosquitto
bindings](http://wiki.call-cc.org/eggref/5/mosquitto) by Dmitrii
Kosenkov.

```
(use-modules (mosquitto client))

(let ((client (make-client #:on-connect
                          (lambda (client err)
                            (if (not (eq? err MOSQ_ERR_SUCCESS))
                                (abort err)
                                (display "Yay, we are connected!"))))))
  (set! (disconnect-callback client)
        (lambda (client err)
          (if (not (eq? err MOSQ_ERR_SUCCESS))
            (display "Unexpected disconnect..."))))

  (set! (message-callback client)
        (lambda (cl msg)
          (display (string->append "Topic: " (topic msg)
                                   "Payload:" payload msg))
          (publish client "topic2" "message received, thanks!")))
  (connect client "localhost" #:username "mqtt-admin" #:password "mypass")
  (subscribe client "topic1")
  (loop-forever client))
```

See further examples under the directory [examples](https://github.com/mdjurfeldt/guile-mqqt/tree/main/examples).

# API

```
(make-client #:key id (clean-session #t) user-data on-connect on-disconnect on-publish on-message on-subscribe on-unsubscribe on-log)
```

* id: String to use as the client id. If #f, a random client id will be generated. If id is #f, clean-session must be #t.
* clean-session: set to #t to instruct the broker to clean all messages and subscriptions on disconnect, #f to instruct it to keep them. Note that a client will never discard its own outgoing messages on disconnect. Calling connect or reconnect will cause the messages to be resent. Use reinitialise to reset a client to its original state. Must be set to #t if the id parameter is #f.
* user-data: user data that will be passed with cleint argument to any callbacks that are specified.
* on-connect: Connect callback. See connect-callback
* on-disconnect: Disconnect callback. See disconnect-callback
* on-publish: Publish callback. See publish-callback
* on-message: Message callback. See message-callback
* on-subscribe: Subscribe callback. See subscribe-callback
* on-unsubscribe: Unsubscribe callback. See unsubscribe-callback
* on-log: Logging callback. See log-callback

```
(connect client host #:key (port 1883) (keepalive 5) bind-address username password tls-cafile tls-capath tls-certfile tls-keyfile tls-insecure tls-ocsp-required tls-use-os-certs tls-alpn socks5-host (socks5-port 1080) socks5-username socks5-password (reconnect-delay 1) (reconnect-delay-max 10) reconnect-exp-backoff tcp-nodelay)
```

* host: the hostname or ip address of the broker to connect to.
* port: the network port to connect to. Default: 1883.
* keepalive: the number of seconds after which the broker should send a PING message to the client if no other messages have been exchanged in that time.
* bind-address: the hostname or ip address of the local network interface to bind to.
* username: the username to send as a string, or #f to disable authentication.
* password: the password to send as a string. Set to #f when username is valid in order to send just a username.
* tls-cafile: path to a file containing the PEM encoded trusted CA certificate files. Either cafile or capath must be set.
* tls-capath: path to a directory containing the PEM encoded trusted CA certificate files. See mosquitto.conf for more details on configuring this directory. Either cafile or capath must be set.
* tls-certfile: path to a file containing the PEM encoded certificate file for this client. If #f, keyfile must also be #f and no client certificate will be used.
* tls-keyfile: path to a file containing the PEM encoded private key for this client. If #f, certfile must also be #f and no client certificate will be used.
* tls-ocsp-required: Set whether OCSP checking on TLS connections is required. Set to #t to enable checking, or #f (the default) for no checking.
* tls-use-os-certs: Set to #t to instruct the client to load and trust OS provided CA certificates for use with TLS connections. Set to #f (the default) to only use manually specified CA certs.
* tls-alpn: If the broker being connected to has multiple services available on a single TLS port, such as both MQTT and WebSockets, use this option to configure the ALPN option for the connection.
* socks5-host: the SOCKS5 proxy host to connect to.
* socks5-port: the SOCKS5 proxy port to use.
* socks5-username: if set, use this username when authenticating with the proxy.
* socks5-password: if set and username is set, use this password when authenticating with the proxy.
* reconnect-delay: the number of seconds to wait between reconnects.
* reconnect-delay-max: the maximum number of seconds to wait between reconnects.
* reconnect-exp-backoff: use exponential backoff between reconnect attempts. Set to #t to enable exponential backoff.
* tcp-nodelay: Set to #t to disable Nagle’s algorithm on client sockets. This has the effect of reducing latency of individual messages at the potential cost of increasing the number of packets being sent. Defaults to #f, which means Nagle remains enabled.

```
(disconnect client)
```

Disconnect from the broker.

```
(loop client #:optional (timeout 1000))
```

The main network loop for the client. This must be called frequently to keep communications between the client and broker working. This is carried out by loop-forever, which are the recommended ways of handling the network loop. It must not be called inside a callback. If incoming data is present it will then be processed. Outgoing commands, from e.g. publish, are normally sent immediately that their function is called, but this is not always possible. loop will also attempt to send any remaining outgoing messages, which also includes commands that are part of the flow for messages with QoS>0.

    timeout: Maximum number of milliseconds to wait for network activity in the select() call before timing out. Set to 0 for instant return.

```
(loop-forever client #:optional (timeout 1000))
```

This function call loop for you in an infinite blocking loop. It is useful for the case where you only want to run the MQTT client loop in your program. It handles reconnecting in case server connection is lost. If you call disconnect in a callback it will return.

    timeout: Maximum number of milliseconds to wait for network activity in the select() call before timing out. Set to 0 for instant return.

```
(publish client topic payload #:key (qos 0) retain)
```

Publish a message on a given topic.

    topic: null terminated string of the topic to publish to.
    payload: blob or string of data to send.
    qos: integer value 0, 1 or 2 indicating the Quality of Service to be used for the message.
    retain: set to #t to make the message retained.

returns:

    mid: message id of sent message. Note that although the MQTT protocol doesn’t use message ids for messages with QoS=0, libmosquitto assigns them message ids so they can be tracked with this parameter.

```
(subscribe client sub #:key (qos 0))
```

Subscribe to a topic.

    sub: the subscription pattern.
    qos: the requested Quality of Service for this subscription.

```
(unsubscribe client sub)
```

Unsubscribe from a topic.

    sub: the unsubscription pattern.

* Callbacks
```
(set! (connect-callback client) (lambda (client err) ...))
```

Set the connect callback. This is called when the broker sends a CONNACK message in response to a connection.

    err: error condition, if #f - connection is success.

```
(set! (disconnect-callback client) (lambda (client unexpected?) ...))
```

Set the disconnect callback. This is called when the broker has received the DISCONNECT command and has disconnected the client.

    unexpected?: boolean value indicating the reason for the disconnect. A value of #f means the client has called disconnect. #t indicates that the disconnect is unexpected.

```
(set! (publish-callback client) (lambda (client mid) ...))
```

Set the publish callback. This is called when a message initiated with mosquitto_publish has been sent to the broker successfully.

    mid: the message id of the sent message.

```
(set! (message-callback client) (lambda (client message) ...))
```

Set the message callback. This is called when a message is received from the broker.

    message: the message record.

```
(set! (subscribe-callback client) (lambda (client mid) ...))
```

Set the subscribe callback. This is called when the broker responds to a subscription request.

    mid: the message id of the subscribe message.

```
(set! (unsubscribe-callback client) (lambda (client mid) ...))
```

Set the unsubscribe callback. This is called when the broker responds to a unsubscription request.

    mid: the message id of the unsubscribe message.

```
(set! (log-callback client) (lambda (client level str) ...))
```

Set the logging callback. This should be used if you want event logging information from the client library.

    level: the log message level from the values: 'log-info 'log-notice 'log-warning 'log-err 'log-debug
    str: the message string

* Caveats

MQTT v5 not supported yet.
