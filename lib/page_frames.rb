# frozen_string_literal: true

require_relative 'page_frames/version'
require_relative 'page_frames/configuration'
require_relative 'page_frames/rabbit_mq'
require_relative 'page_frames/pageable'
require_relative 'page_frames/model_pages_config'
require_relative 'page_frames/calculate_frames'

module PageFrames
  class Error < StandardError; end

  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Configuration.new
  end
end
