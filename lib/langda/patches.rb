# frozen_string_literal: true

require "logger"

module IterationLogger
  VERSION = "0.1.0"

  ITERATION_METHODS = [
    :each, :map, :collect, :select, :find_all, :reject, :grep, :grep_v,
    :each_with_index, :flat_map, :inject, :reduce, :partition, :find,
    :any?, :all?, :none?, :times
  ].to_set.freeze

  class << self
    def logger
      @logger ||= begin
        if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
          Rails.logger
        else
          std_logger = ::Logger.new($stdout)
          std_logger.level = ::Logger::INFO
          std_logger.progname = "Langda Logger"
          std_logger
        end
      end
    end

    # Enable the TracePoint listener (idempotent)
    def enable!
      return if enabled?

      @tracepoint = TracePoint.new(:call, :c_call) do |tp|
        begin
          handle_tracepoint(tp)
        rescue => e
          # Avoid raising inside TracePoint (would be fatal)
          logger.error("Langda Logger internal error: #{e.class}: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}")
        end
      end

      @tracepoint.enable
      @enabled = true
      logger.info("Langda Logger enabled (version #{VERSION})")
    end

    def disable!
      return unless enabled?
      @tracepoint&.disable
      @tracepoint = nil
      @enabled = false
      logger.info("Langda Logger disabled")
    end

    def enabled?
      !!@enabled
    end

    private

    # Decide whether to log and what to log
    def handle_tracepoint(tp)
      method_sym = tp.method_id
      return unless method_sym && ITERATION_METHODS.include?(method_sym)

      path = tp.path
      lineno = tp.lineno

      # We only log when the call site is inside /app/
      return unless path && path.include?("/app/")

      receiver = safe_receiver(tp)
      class_name = receiver_class_name(receiver, tp)

      method_name = method_sym.to_s

      # Try to determine "current count" - number of elements to be iterated
      count = determine_count(receiver, method_sym)

      message = {
        file: path,
        line: lineno,
        class: class_name,
        method: method_name,
        count: count
      }

      # Use Rails.logger if available, otherwise STDOUT via our logger
      logger.info("Langda Logger: #{message}")
    end

    # Safely fetch the receiver (tp.self can sometimes be nil/corrupt in odd cases; rescue)
    def safe_receiver(tp)
      tp.self
    rescue => _
      nil
    end

    def receiver_class_name(receiver, tp)
      if receiver
        # Prefer actual receiver class name
        receiver.class.name rescue tp.defined_class.to_s
      else
        # Fallback to defined_class or '?'
        (tp.defined_class && tp.defined_class.to_s) || "Unknown"
      end
    end

    # Best-effort to determine count:
    # - For Integer#times, the receiver (an Integer) itself is the count
    # - Prefer length, size, then count method if available, but call in safe rescue
    # - For ActiveRecord::Relation, size may perform DB work; user should be aware
    def determine_count(receiver, method_sym)
      # Integer#times => receiver is an Integer
      if method_sym == :times && receiver.is_a?(Integer)
        return receiver
      end

      return nil unless receiver

      # Try methods in an order that is best-effort and less likely to cause heavy DB ops
      [:length, :size, :count].each do |m|
        if receiver.respond_to?(m)
          begin
            val = receiver.public_send(m)
            # Ensure it's numeric
            return val if val.is_a?(Integer)
          rescue => _
            # swallow - sometimes ActiveRecord proxies may raise when calling count/size
            next
          end
        end
      end

      nil
    end
  end

  # Railtie to auto-start in Rails apps
  if defined?(Rails)
    require "rails/railtie"

    class Railtie < Rails::Railtie
      initializer "iteration_logger.configure_rails_initialization" do
        # Enable after Rails finishes initializing to ensure Rails.logger is available
        ActiveSupport.on_load(:after_initialize) do
          begin
            IterationLogger.enable!
          rescue => e
            IterationLogger.logger.error("Langda Logger failed to enable: #{e.class}: #{e.message}")
          end
        end
      end

      # Allow config flag to disable if apps wish to
      rake_tasks do
        # no rake tasks; placeholder so Rails doesn't warn about railtie with no hooks
      end
    end
  end
end
