if CANVAS_RAILS3
  module ActiveSupport
    module JSON
      module Encoding
        private
        class EscapedString
          def to_s
            self
          end
        end
      end
    end
  end
else
  ActiveSupport::TimeWithZone.delegate :to_yaml, :to => :utc
  ActiveSupport::SafeBuffer.delegate :to_yaml, :to => :to_str
end

# TODO: Comment this shim out after rails 4 has been running and the cache has been cleared
# but hold onto it so we remember to keep the :use_new_rails behavior for the next upgrade
module ActiveSupport::Cache
  module Rails3Shim
    def namespaced_key(key, options)
      result = super
      if options && options.has_key?(:use_new_rails) ? options[:use_new_rails] : !CANVAS_RAILS3
        result = "rails4:#{result}"
      end
      result
    end

    def delete(key, options = nil)
      r1 = super(key, (options || {}).merge(use_new_rails: !CANVAS_RAILS3)) # prefer rails 3 if on rails 3 and vis versa
      r2 = super(key, (options || {}).merge(use_new_rails: CANVAS_RAILS3))
      r1 || r2
    end
  end
  Store.prepend(Rails3Shim)
end