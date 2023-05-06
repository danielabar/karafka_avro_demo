# Karafka Avro Demo

This project sets up a standalone Ruby application using the [Karafka](https://github.com/karafka/karafka) gem to demonstrate how to use the [Avro](https://avro.apache.org/) serialization format together with a [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/index.html) to validate Kafka message format. The [avro_turf](https://github.com/dasch/avro_turf/) gem is used for working with the Avro serialization format from Ruby.

In a production setup, the producer application would likely be separate from the consumer application, but for this simple demo, the consumers are in `app/consumers`, and a console is used to produce messages.

There are actually two ways to use an Avro (or any other) schema, this project demonstrates both:

**1. Local File System**

Use a schema file from the local file system. In this case, all producer and consumer applications must have access to a copy of the file so that they can serialize and deserialize messages respectively. This avoids the complexity of using a registry, but the drawback is if a change is needed to the schema file, need to manually update all producer and consumer applications with the latest copy of the file. The `person` topic in this project demonstrates this.

**2. Schema Registry**

Use a centralized schema registry to persist the schema. This is a separate server that needs to be running, and all producers/consumers must be able to connect to it. A schema file can be uploaded to the registry, then all producers and consumers can retrieve it and use it for serializing/deserializing messages. The `greeting` topic in this project demonstrates this.

## Prerequisites

In order to run this project, make sure you have installed:

* [Docker](https://www.docker.com/products/docker-desktop/)
* A Ruby version manager of your choice, for example [rbenv](https://github.com/rbenv/rbenv)
* The Ruby language version specified in [.ruby-version](.ruby-version)

## Setup

Install dependencies:

```
bundle install
```

Start Kafka broker, Zookeeper, and Confluent Schema Registry in Docker containers:

```
docker-compose up
```

In another terminal, start Karafka server, this will start the consumers in `app/consumers/*.rb` polling for messages:

```
bundle exec karafka server
```

## Produce Messages

In another terminal, start a Karafka console, here you can produce messages (and run any Ruby commands), then watch the server tab for message consumption:

```
bundle exec karafka console
```

### Local File Schema

Example of producing a message using a local file schema, this does not use a registry:

```ruby
# Producer
avro = AvroTurf.new(schemas_path: "app/schemas/")
message = avro.encode({ "full_name" => "Jane Doe", "age" => 28 }, schema_name: "person", validate: true)
# message_type header contains the schema name
headers = { "message_type" => "person" }
Karafka.producer.produce_async(topic: 'person', payload: message, headers: headers)
```

In the server terminal, this message should get consumed by `PersonConsumer`.

Also try to produce an invalid message:

```ruby
message_bad = avro.encode({ "full_name" => "Jane Doe", "age" => "blue" }, schema_name: "person", validate: true)
```

### Schema Registry

Now let's use a registry to retrieve the schema.

Still in the karafka console, run these commands to register the `greeting.avsc` schema:

```ruby
# One time code to register the schema in the registry
registry = AvroTurf::ConfluentSchemaRegistry.new("http://0.0.0.0:8081/")
registry.register("greeting", File.read("app/schemas/greeting.avsc"))
# => 1 (returns the schema ID)
# List the schemas
registry.subjects
#=> ["greeting"]
```

You can also use the schema registry REST API, for example, use a browser and navigate to `http://0.0.0.0:8081/subjects/greeting/versions/1`, the schema is persisted as escaped JSON:

```json
{
  "subject": "greeting",
  "version": 1,
  "id": 1,
  "schema": "{\"type\":\"record\",\"name\":\"greeting\",\"fields\":[{\"name\":\"title\",\"type\":\"string\"}]}"
}
```

**NOTE:** A real registry schema will require authentication to connect to. See [AvroTurf::Messaging](https://github.com/dasch/avro_turf/blob/master/lib/avro_turf/messaging.rb) `initialize` method for how to specify credentials.

Produce a message that conforms to this schema:

```ruby
# Producer
avro = AvroTurf::Messaging.new(registry_url: "http://0.0.0.0:8081")
message = avro.encode({ "title" => "hello, world" }, subject: "greeting", version: 1)
Karafka.producer.produce_async(topic: 'greeting', payload: message)
```

In the server terminal, this message should get consumed by `GreetingConsumer`.

Also try to produce an invalid message:

```ruby
message_bad = avro.encode({ "title" => 123456 }, subject: "greeting", version: 1)
# The datum 123456 is not an example of schema "string" (Avro::IO::AvroTypeError)
```

## Debug

Add `binding.b` or `debugger` to any Ruby file. See [ruby/debug](https://github.com/ruby/debug#control-flow) for more details.

## Further Reading

- [Broker Under the Hood](docs/broker_under_the_hood.md)

## References

- [Karafka](https://github.com/karafka/karafka)
- [Karafka Deserialization](https://karafka.io/docs/Deserialization/)
- [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/index.html)
- [Apache Avro](https://avro.apache.org/)
- [avro_turf](https://github.com/dasch/avro_turf/)
- [AvroTurf::ConfluentSchemaRegistry](https://github.com/dasch/avro_turf/blob/master/lib/avro_turf/confluent_schema_registry.rb)
- [AvroTurf::Messaging](https://github.com/dasch/avro_turf/blob/master/lib/avro_turf/messaging.rb)

## TODO

- For local file schema, does it really need schema name in message_type header? Since schema gets embedded in the message itself, maybe that's enough for decode method without also specifying schema?
- Explain how it works, pointers to relevant code
- RSpec tests
- Why is `docker-compose rm -f` required before `docker-compose up` when containers already exist?
- Not using rest_proxy container - could get rid of it?
- Put producers code in rake tasks

### Nice to Have

- [Dead Letter Queue](https://karafka.io/docs/Dead-Letter-Queue/) (not specifically related to Avro or Registry).
- Schema versioning? Only possible with schema registry? (maybe too complicated for this demo, point to Confluent docs on this topic)
