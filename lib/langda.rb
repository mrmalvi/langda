require "langda/logger"

module Langda
  class << self
    attr_accessor :enabled, :threshold_ms
  end

  self.enabled = true
  self.threshold_ms = 2.0

  def self.enabled?
    !!enabled
  end
end
require "langda/patches"
