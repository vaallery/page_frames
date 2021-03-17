# frozen_string_literal: true

require_relative "page_frames/version"
require_relative 'page_frames/configuration'
require_relative 'page_frames/rabbit_mq'

module PageFrames
  class Error < StandardError; end
  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Configuration.new
  end
end
