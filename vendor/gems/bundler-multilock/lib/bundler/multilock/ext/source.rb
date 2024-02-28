# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module Source
        ::Bundler::Source.prepend(self)

        def print_using_message(*)
          return if Bundler.settings[:suppress_install_using_messages]

          super
        end
      end
    end
  end
end
