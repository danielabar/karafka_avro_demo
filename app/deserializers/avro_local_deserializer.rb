class AvroLocalDeserializer
  attr_reader :avro

  def initialize(avro)
    @avro = avro
  end

  def call(message)
    avro.decode(message.raw_payload, schema_name: message.headers["message_type"])
  end
end
