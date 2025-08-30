module Langda
  class Config
    attr_accessor :logger, :skip_models, :audit_models

    def initialize
      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @skip_models = []
      @audit_models = []
    end

    def audit_models(*models)
      @audit_models += models.map(&:to_s)
    end
  end
end
