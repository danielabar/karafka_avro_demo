namespace :waterdrop do

  desc 'Generate an Avro message to Kafka server'
  task :send_avro do
    # Schemas will be looked up from the specified directory.
    avro = AvroTurf.new(schemas_path: "app/schemas/")

    # Encode some data using the named schema.
    # Data can be validated before encoding to get a description of problem through
    # Avro::SchemaValidator::ValidationError exception
    message = avro.encode({ "full_name" => "Jane Doe", "age" => 28 }, schema_name: "person", validate: true)

    Karafka.producer.produce_async(topic: 'person', payload: message)
    Karafka.producer.close
  end

  desc 'Generate an Avro message with schema registry to Kafka server'
  task :send_avro_schema do
    # one-time only registry schema with confluent schema registry
    registry = AvroTurf::ConfluentSchemaRegistry.new("http://0.0.0.0:8081/")
    registry.register("greeting", File.read("app/schemas/greeting.avsc"))

    # You need to pass the URL of your Schema Registry.
    avro = AvroTurf::Messaging.new(registry_url: "http://0.0.0.0:8081")

    # The API for encoding and decoding data is similar to the default one. Encoding
    # data has the side effect of registering the schema. This only happens the first
    # time a schema is used.
    message = avro.encode({ "title" => "hello, world" }, subject: "greeting", version: 1)

    Karafka.producer.produce_async(topic: 'credit_signal', payload: message)
    Karafka.producer.close
  end
end
