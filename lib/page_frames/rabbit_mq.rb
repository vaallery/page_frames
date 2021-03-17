require 'bunny'

module PageFrames
  module RabbitMq
    extend self

    @mutex = Mutex.new

    def connection=(value)
      @connection = value
    end

    def connection
      @mutex.synchronize do
        @connection ||= Bunny.new(addresses: addresses).tap(&:start)
      end
    end

    def addresses
      PageFrames.config.bunny_amqp_addresses&.split(",")
    end

    def channel
      Thread.current[:rabbitmq_channel] ||= connection.create_channel
    end

    def consumer_channel
      # See http://rubybunny.info/articles/concurrency.html#consumer_work_pools
      Thread.current[:rabbitmq_consumer_channel] ||=
        connection.create_channel(
          nil,
          PageFrames.config.rabbitmq_consumer_pool.to_i
        )
    end
  end
end
