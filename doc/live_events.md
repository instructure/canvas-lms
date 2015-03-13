# Live Events

Canvas includes the ability to push a subset of real-time events to a
Kinesis stream, which can then be consumed for various analytics
purposes. This is not a full-fidelity feed of all changes to the
database, but a targetted set of interesting actions such as
`grade_changed`, `login`, etc.

## Development and Testing

To enabled Live Events, you need to configure the plugin in the /plugins
interface. If using the docker-compose dev setup, there is already a
"fake kinesis" running that you can use. Make sure you have the `aws`
cli installed, and run the following command to create a stream (with
canvas running):

```bash
AWS_ACCESS_KEY_ID=key AWS_SECRET_ACCESS_KEY=secret aws --endpoint-url http://kinesis.docker/ kinesis create-stream --stream-name=mystream --shard-count=1
```

Once the stream is created, configure your Canvas (at /plugins) to use
it:

| Setting Name          | Value               |
| --------------------- | ------------------- |
| Kinesis Stream Name   | mystream            |
| AWS Region            | (leave blank)       |
| AWS Endpoint          | http://kinesis:4567 |
| AWS Access Key ID     | key                 |
| AWS Secret Access Key | secret              |

Restart Canvas, and events should start flowing to your kinesis stream.
You can view the stream with the `tail_kinesis` tool:

```bash
fig run --rm web script/tail_kinesis kinesis 4567 mystream
```
