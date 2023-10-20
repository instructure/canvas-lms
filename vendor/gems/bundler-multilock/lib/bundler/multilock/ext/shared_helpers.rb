# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module SharedHeleprs
        module ClassMethods
          ::Bundler::SharedHelpers.singleton_class.prepend(self)
          ::Bundler::SharedHelpers.instance_variable_set(:@filesystem_accesses, nil)

          def capture_filesystem_access
            @filesystem_accesses = []
            yield
            @filesystem_accesses
          ensure
            @filesystem_accesses = nil
          end

          def filesystem_access(path, action = :write)
            @filesystem_accesses << [path, action] if @filesystem_accesses

            super
          end
        end
      end
    end
  end
end
