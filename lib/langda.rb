# frozen_string_literal: true

require "langda/version"
require "langda/config"
require "langda/model"
require "langda/railtie" if defined?(Rails)

module Langda
  class << self
    attr_accessor :config
  end

  def self.configure
    self.config ||= Config.new
    yield(config)
  end
end
