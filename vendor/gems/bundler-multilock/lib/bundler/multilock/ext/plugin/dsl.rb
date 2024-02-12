# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module PluginExt
        module DSL
          ::Bundler::Plugin::DSL.include(self)

          def lockfile(*, **)
            # pass
          end
        end
      end
    end
  end
end
