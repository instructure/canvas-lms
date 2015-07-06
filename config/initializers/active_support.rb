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
end
