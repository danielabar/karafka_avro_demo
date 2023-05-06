class PersonConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload
      timestamp = message.timestamp
      partition = message.partition
      puts "Payload: #{payload}, Timestamp: #{timestamp}, Partition: #{partition}"

      # do something with payload...
      puts payload["age"]
    end
  end
end
