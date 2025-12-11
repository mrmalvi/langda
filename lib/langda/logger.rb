module Langda
  module Log
    APP_ROOT = Rails.root.to_s
    def self.warn(msg)

      loc = caller.find { |c| c.start_with?(APP_ROOT) }

      loc = caller.find do |c|
        c.include?("#{APP_ROOT}/app/")
      end
      return unless loc
      file = loc.split(":")
      if defined?(Rails) && Rails.logger
        super("[Langda] #{msg} at #{file}")
      else
        puts ("[Langda] #{msg} at #{file}")
      end
    end
  end
end
