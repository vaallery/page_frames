require_relative 'calculate_frames'
require_relative 'rpc_client'

module PageFrames
  module Recalculate
    module_function

    def call(model, organization_id = nil)
      calculator = PageFrames::CalculateFrames.new(model)
      items = organization_id ? model.where(organization_id: organization_id) : model
      items.find_in_batches(batch_size: 1000) do |group|
        frames = group.map do |obj|
          {
            pageable_type: obj.class.name,
            pageable_id: obj.id,
            pages: calculator.call(obj),
            organization_id: obj.organization_id
          }
        end
        PageFrames::RpcClient.fetch.mass_update(frames)
      end
    end
  end
end
