# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require "canvas/cdn/registry"

module Canvas
  module Cdn
    class << self
      def config
        @config ||= begin
          config = ActiveSupport::OrderedOptions.new
          config.enabled = false
          yml = ConfigFile.load("canvas_cdn")
          creds = Rails.application.credentials.canvas_cdn_creds
          config.merge!(yml.symbolize_keys) if yml
          config.merge!(creds) if creds
          config
        end
      end

      # Provides an instance of Cdn::Registry for the current Rails environment.
      #
      # Set ENV['USE_OPTIMIZED_JS'] to a truthy value to load the optimized
      # version of the JavaScripts even if you're running a development Rails
      # server.
      def registry
        @registry ||= begin
          environment = if %w[1 True true].include?(ENV["USE_OPTIMIZED_JS"])
                          "production"
                        else
                          Rails.env
                        end

          Cdn::Registry.new(
            environment:,
            cache: if ActionController::Base.perform_caching
                     Cdn::Registry::ProcessCache.new
                   else
                     Cdn::Registry::RequestCache.new
                   end
          )
        end
      end

      def should_be_in_bucket?(source)
        source.start_with?("/dist/brandable_css") || registry.include?(source)
      end

      def asset_host_for(source)
        # use the :host specified in canvas_cdn.yml
        if config.host && should_be_in_bucket?(source)
          config.host
        else
          # Otherwise, use the same domain the page request came from, like normal.
          nil
        end
      end

      def push_to_s3!(*args, **kwargs, &)
        return unless config.bucket

        uploader = Canvas::Cdn::S3Uploader.new(*args, **kwargs)
        uploader.upload!(&)
      end

      def enabled?
        !!config.bucket
      end
    end
  end
end
