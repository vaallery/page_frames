require_relative 'recalculate'

module PageFrames::Consumer
  module_function

  def call
    channel = RabbitMq.consumer_channel
    exchange = channel.default_exchange
    queue = channel.queue("frames.recalculate", durable: true)

    queue.subscribe(manual_ack: true) do |delivery_info, properties, payload|
      payload = JSON(payload, symbolize_names: true)

      result = if (model_class = payload[:model].safe_constantize)
                 channel.acknowledge(delivery_info.delivery_tag, false)
                 begin
                   PageFrames::Recalculate.call(model_class, payload[:organization_id])
                   { status: :ok }
                 rescue StandardError => e
                   { status: :fail, message: e.message }
                 end
               end
      if result
        exchange.publish(
          result.to_json,
          routing_key: properties.reply_to,
          correlation_id: properties.correlation_id
        )
      end
    end
  end
end