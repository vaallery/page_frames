# frozen_string_literal: true

module PageFrames
  module RpcApi
    def mass_update(frames)
      payload = { frames: frames }.to_json
      result = publish(payload, type: "mass_update")
      return true if result[:status] == 'ok'
      raise result[:errors]
    end

    def aggregated_md5(page_alias, pageable_type, pageable_ids)
      payload = { pageable_type: pageable_type, pageable_ids: pageable_ids, page_alias: page_alias }.to_json
      result = publish(payload, type: "aggregated_md5")
      return result[:result] if result[:status] == 'ok'
      raise StandardError, result[:errors]
    end
  end
end
