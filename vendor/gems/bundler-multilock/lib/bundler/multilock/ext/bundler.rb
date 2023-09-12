# frozen_string_literal: true

module Bundler
  module Multilock
    module Ext
      module BundlerClassMethods
        def self.prepended(klass)
          super

          klass.attr_writer :cache_root, :default_lockfile, :root
        end

        ::Bundler.singleton_class.prepend(self)

        def app_cache(custom_path = nil)
          super(custom_path || @cache_root)
        end

        def default_lockfile(force_original: false)
          return @default_lockfile if @default_lockfile && !force_original

          super()
        end

        def with_default_lockfile(lockfile)
          previous_default_lockfile, @default_lockfile = @default_lockfile, lockfile
          yield
        ensure
          @default_lockfile = previous_default_lockfile
        end

        def reset!
          super
          Multilock.reset!
        end
      end
    end
  end
end
