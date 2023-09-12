# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module PluginExt
        module ClassMethods
          ::Bundler::Plugin.singleton_class.prepend(self)

          def load_plugin(name)
            return if @loaded_plugin_names.include?(name)

            super
          end
        end
      end
    end
  end
end
