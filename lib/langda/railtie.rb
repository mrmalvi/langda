module Langda
  class Railtie < Rails::Railtie
    initializer "langda.active_record" do
      ActiveSupport.on_load(:active_record) do
        Langda.config.audit_models.each do |model_name|
          begin
            klass = model_name.constantize
            klass.include Langda::Model
          rescue NameError => e
            Rails.logger.warn("[Langda] Could not load model #{model_name}: #{e.message}") if defined?(Rails)
          end
        end
      end
    end
  end
end
