# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require "canvas/cdn/registry/gulp"
require "canvas/cdn/registry/webpack"

module Canvas
  module Cdn
    # A registry of the available javascripts and static assets - like images
    # and fonts - along with their location on disk. Since these assets have a
    # dynamic filename that incorporates a hash fragment, we need a proxy
    # interface like this one to resolve their location by their name.
    #
    # The resolving metadata is provided by the JS bundler, like Webpack, and
    # the asset processor, like Gulp.
    #
    # @see Canvas::Cdn.registry
    class Registry
      attr_reader :cache, :environment

      # @param [Union.<ProcessCache, RequestCache, StaticCache>] :cache
      #  Control the behavior of loading manifests, see the respective classes
      #  for more information.
      #
      # @param [String] :environment
      #  This only controls the variant of JavaScript assets to locate and has
      #  no effect on static assets
      #
      def initialize(cache:, environment: Rails.env)
        @cache = cache
        @environment = environment
      end

      # Whether the file is tracked by the registry (i.e. is a JS or static
      # asset)
      #
      # Note that file is expected not to be qualified with a protocol/host; so
      # something like /images/foo.png but not http://localhost/images/foo.png.
      def include?(realpath)
        bundler.include?(realpath) || gulp.include?(realpath)
      end

      # Whether static assets are locatable
      def statics_available?
        gulp.available?
      end

      # Whether JS files are locatable
      def scripts_available?
        bundler.available?
      end

      # @return [Array.<String>]
      #  Real paths to the JS files that make up the specified bundle
      delegate :scripts_for, to: :bundler
      delegate :entries, to: :bundler

      # @return [String]
      #  Real path to the asset.
      #
      # @param [String] source
      #  Path to the source asset prior to any fingerprinting. This is relative
      #  to Rails public directory, like "/images/apple-touch-icon.png"
      #
      delegate :url_for, to: :gulp

      private

      def gulp
        @cache.gulp
      end

      def bundler
        @cache.webpack(environment: @environment)
      end
    end

    # Load manifests at most once per instance
    class Registry::ProcessCache
      def gulp(*args, **kwargs)
        @gulp ||= Registry::Gulp.new(*args, **kwargs)
      end

      def webpack(*args, **kwargs)
        @webpack ||= Registry::Webpack.new(*args, **kwargs)
      end
    end

    # (Re)load manifests on every request
    class Registry::RequestCache
      def gulp(*args, **kwargs)
        ::RequestCache.cache(["registry", "gulp"]) do
          Registry::Gulp.new(*args, **kwargs)
        end
      end

      def webpack(*args, **kwargs)
        ::RequestCache.cache(["registry", "webpack"]) do
          Registry::Webpack.new(*args, **kwargs)
        end
      end
    end

    # Bypass the disk to supply pre-defined manifests
    class Registry::StaticCache
      def initialize(gulp:, webpack:)
        @gulp_manifest = gulp
        @webpack_manifest = webpack
      end

      def gulp(*args, **kwargs)
        @gulp ||= Registry::Gulp.new(
          *args,
          **kwargs.merge(manifest: @gulp_manifest)
        )
      end

      def webpack(*args, **kwargs)
        @webpack ||= Registry::Webpack.new(
          *args,
          **kwargs.merge(manifest: @webpack_manifest)
        )
      end
    end
  end
end
