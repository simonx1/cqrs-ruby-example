# frozen_string_literal: true

App.boot(:kafka_producer) do |app|
  init do
    require 'waterdrop'

    WaterDrop.setup do |config|
      config.deliver = true
      config.kafka.seed_brokers = %w[kafka://localhost:9092]
    end

    class KafkaProducer
      def call(event:, topic:)
        puts " CALLED HERE "
        puts "event: #{event.serialize.to_json}"
        puts "topic: #{topic}"
        WaterDrop::SyncProducer.call(event.serialize.to_json, topic: topic)
      end
    end

    register(:kafka_producer, KafkaProducer.new)
  end
end
