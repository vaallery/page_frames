# frozen_string_literal: true

require 'securerandom'
require_relative 'rpc_api'

# Служебные функции обеспечивающие работу RPC клиента

module PageFrames
  class RpcClient
    extend Dry::Initializer[undefined: false]
    include RpcApi

    option :queue, default: proc { create_queue }
    option :reply_queue, default: proc { create_reply_queue }
    option :lock, default: proc { Mutex.new }
    option :condition, default: proc { ConditionVariable.new }

    def self.fetch
      Thread.current['frame_service.rpc_client'] ||= new.start
    end

    def start
      @reply_queue.subscribe do |_delivery_info, properties, payload|
        if properties[:correlation_id] == @correlation_id
          @lock.synchronize do
            @reply_payload = JSON(payload, symbolize_names: true)
            @condition.signal
          end
        end
      end

      self
    end

    private

    attr_writer :correlation_id

    def create_queue
      channel = RabbitMq.channel
      channel.queue('frame', durable: true)
    end

    def create_reply_queue
      channel = RabbitMq.channel
      channel.queue('amq.rabbitmq.reply-to')
    end

    def publish(payload, opts = {})
      @lock.synchronize do
        self.correlation_id = SecureRandom.uuid

        @queue.publish(
          payload,
          opts.merge(
            app_id: 'gdocs',
            correlation_id: @correlation_id,
            reply_to: @reply_queue.name
          )
        )

        @condition.wait(@lock)
        @reply_payload
      end
    end
  end
end
