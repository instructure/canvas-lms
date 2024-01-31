# frozen_string_literal: true

require "bundler/lockfile_generator"

module Bundler
  module Multilock
    # generates a lockfile based on another LockfileParser
    class LockfileGenerator < Bundler::LockfileGenerator
      def self.generate(lockfile)
        new(LockfileAdapter.new(lockfile)).generate!
      end

      private

      class LockfileAdapter < SimpleDelegator
        def sources
          self
        end

        def lock_sources
          __getobj__.sources
        end

        def resolve
          specs
        end

        def dependencies
          super.values
        end

        def locked_ruby_version
          ruby_version
        end

        def locked_checksums
          checksums
        end
      end

      private_constant :LockfileAdapter

      def add_bundled_with
        add_section("BUNDLED WITH", definition.bundler_version.to_s)
      end
    end
  end
end
