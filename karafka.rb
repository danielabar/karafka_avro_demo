require "avro_turf/messaging"

ENV["KARAFKA_ENV"] ||= "development"
Bundler.require(:default, ENV.fetch("KARAFKA_ENV"))

# Zeitwerk custom loader for loading the app components before the whole
# Karafka framework configuration
APP_LOADER = Zeitwerk::Loader.new

%w[
  lib
  app/consumers
  app/deserializers
].each(&APP_LOADER.method(:push_dir))

APP_LOADER.setup
APP_LOADER.eager_load

# App class
class App < Karafka::App
  setup do |config|
    config.concurrency = 5
    config.max_wait_time = 1_000
    config.kafka = { "bootstrap.servers": ENV["KAFKA_HOST"] || "127.0.0.1:9092" }
  end
end

Karafka.producer.monitor.subscribe(WaterDrop::Instrumentation::LoggerListener.new(Karafka.logger))
Karafka.monitor.subscribe(Karafka::Instrumentation::LoggerListener.new)
Karafka.monitor.subscribe(Karafka::Instrumentation::ProctitleListener.new)

# See https://karafka.io/docs/Topics-management-and-administration/
App.consumer_groups.draw do
  consumer_group :batched_group do
    # For the `person` topic, use the schema from the file system app/schemas/person.avsc.
    # Both producer and consumer must have access to this file. In a real app,
    # the producer would be a different application therefore multiple copies of the file
    # would be required for each producer and consumer app. This is not ideal if a change is needed,
    # have to change the # file in all places its used.
    # Notice the schema is not specified at this point when initializing a deserializer. This is
    # because the schema information will be encoded in the `message_type` header when a message
    # is produced.
    topic :person do
      consumer PersonConsumer
      deserializer AvroLocalDeserializer.new(AvroTurf.new(schemas_path: "app/schemas/"))
    end

    # For the `greeting` topic, use the schema from a schema registry hosted at `http://0.0.0.0:8081`.
    # Notice we're not specifying which schema at this point when initializing a serializer. This is
    # because the schema information will be encoded in the message when its produced.
    topic :greeting do
      consumer GreetingConsumer
      avro = AvroTurf::Messaging.new(registry_url: ENV["SCHEMA_REGISTRY_HOST"] || "http://0.0.0.0:8081")
      deserializer AvroRegistryDeserializer.new(avro)
    end
  end
end
