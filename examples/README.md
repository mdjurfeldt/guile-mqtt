The three mosquitto client examples in this directory all contact the
test.mosquitto.org broker.

`client.scm` lists all topics and payloads.

`publish.scm` publishes one message under the topic
`guile-mqqt/test`and then exits.

`subscribe.scm`listens to topics under `guile-mqqt`.

You can run
```
guile subscribe.scm
```
in one terminal and then do
```
guile publish.scm
```
in another and see if the message propagates from `publish.scm`.
