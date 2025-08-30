# has_audit_log
# has_audit_log only: [:name, :email]
# has_audit_log except: [:password]
module Langda
  module Model
    extend ActiveSupport::Concern

    class_methods do
      def has_audit_log(only: nil, except: [])
        cattr_accessor :audit_only_attrs, :audit_except_attrs
        self.audit_only_attrs = only&.map(&:to_s)
        self.audit_except_attrs = except&.map(&:to_s) || []

        include Langda::Model::InstanceMethods
      end
    end

    module InstanceMethods
      extend ActiveSupport::Concern

      included do
        after_create  { audit_log("create", filtered_changes) }
        after_update  { audit_log("update", filtered_changes) }
        after_destroy { audit_log("destroy", {}) }
      end

      private

      def filtered_changes
        changes_to_log = previous_changes.dup
        changes_to_log.slice!(*self.class.audit_only_attrs) if self.class.audit_only_attrs
        changes_to_log.except!(*self.class.audit_except_attrs) if self.class.audit_except_attrs.any?
        changes_to_log
      end

      def audit_log(action, changes)
        log = {
          model: self.class.name,
          action: action,
          record_id: id,
          changes: changes,
          at: Time.current
        }
        Langda.config.logger&.info("[AUDIT] #{log.to_json}")
      rescue => e
        puts "[Langda] Logging failed: #{e.message}"
      end
    end
  end
end
