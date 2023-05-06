class AvroRegistryDeserializer
  attr_reader :avro

  def initialize(avro)
    @avro = avro
  end

  def call(message)
    # This is just some additional info to verify that the schema is being used.
    # If you want to get decoded message as well as the schema used to encode the message,
    # you can use `#decode_message` method.
    result = avro.decode_message(message.raw_payload)
    puts result.message
    puts result.schema_id
    puts result.writer_schema
    puts result.reader_schema

    # When decoding, the schema will be fetched from the registry and cached. Subsequent
    # instances of the same schema id will be served by the cache.
    avro.decode(message.raw_payload)
  end
end
