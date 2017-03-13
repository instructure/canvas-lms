ActiveSupport::TimeWithZone.delegate :to_yaml, :to => :utc
ActiveSupport::SafeBuffer.class_eval do
  def encode_with(coder)
    coder.scalar("!str", self.to_str)
  end
end

module ActiveSupport::Cache
  module RailsCacheShim
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{CANVAS_RAILS4_2 ? 'namespaced_key' : 'normalize_key'}(key, options)
        result = super
        if options && options.has_key?(:use_new_rails) ? options[:use_new_rails] : !CANVAS_RAILS4_2
          result = "rails5:\#{result}"
        end
        result
      end
RUBY

    def delete(key, options = nil)
      r1 = super(key, (options || {}).merge(use_new_rails: !CANVAS_RAILS4_2)) # prefer rails 3 if on rails 3 and vis versa
      r2 = super(key, (options || {}).merge(use_new_rails: CANVAS_RAILS4_2))
      r1 || r2
    end
  end
  Store.prepend(RailsCacheShim)
end

unless CANVAS_RAILS4_2
  module IgnoreMonkeyPatchesInDeprecations
    def extract_callstack(callstack)
      return _extract_callstack(callstack) if callstack.first.is_a? String

      offending_line = callstack.find { |frame|
        # pass the whole frame to the filter function, so we can ignore specific methods
        !ignored_callstack(frame)
      } || callstack.first

      [offending_line.path, offending_line.lineno, offending_line.label]
    end

    def ignored_callstack(frame)
      return super if frame.is_a?(String)
      return true if frame.absolute_path&.start_with?(File.dirname(__FILE__) + "/active_record.rb")
      return true if frame.label == 'render' && frame.absolute_path&.end_with?("application_controller.rb")

      return false unless frame.absolute_path
      super(frame.absolute_path)
    end
  end
  ActiveSupport::Deprecation.prepend(IgnoreMonkeyPatchesInDeprecations)
end
