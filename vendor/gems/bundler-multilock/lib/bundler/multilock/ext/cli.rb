# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module CLI
        module ClassMethods
          def instance
            return @instance if instance_variable_defined?(:@instance)

            # this is a little icky, but there's no other way to determine which command was run
            @instance = ObjectSpace.each_object(::Bundler::CLI).first
          end
        end

        ::Bundler::CLI.extend(ClassMethods)
      end
    end
  end
end
