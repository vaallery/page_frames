# frozen_string_literal: true

module PageFrames
  class Configuration
    attr_accessor :bunny_amqp_addresses,
                  :rabbitmq_consumer_pool,
                  :model_pages,
                  :validators
  end
end
