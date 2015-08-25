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

# TODO: Remove this shim but only after rails 4 has been running and the cache has been cleared
module ActiveSupport::Cache
  module Rails3Shim
    def namespaced_key(key, options)
      result = super
      rails3 = options && options.has_key?(:rails3) ? options[:rails3] : CANVAS_RAILS3
      result = "rails4:#{result}" unless rails3
      result
    end

    def delete(key, options = nil)
      r1 = super(key, (options || {}).merge(rails3: CANVAS_RAILS3)) # prefer rails 3 if on rails 3 and vis versa
      r2 = super(key, (options || {}).merge(rails3: !CANVAS_RAILS3))
      r1 || r2
    end
  end
  Store.prepend(Rails3Shim)
end