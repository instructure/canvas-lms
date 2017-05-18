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

module Canvas
  module Cdn
    class << self

      def config
        @config ||= begin
          config = ActiveSupport::OrderedOptions.new
          config.enabled = false
          yml = ConfigFile.load('canvas_cdn')
          config.merge!(yml.symbolize_keys) if yml
          config
        end
      end

      def should_be_in_bucket?(source)
        source.start_with?('/dist/brandable_css') || Canvas::Cdn::RevManifest.include?(source)
      end

      def asset_host_for(source)
        return unless config.host # unless you've set a :host in the canvas_cdn.yml file, just serve normally
        config.host if should_be_in_bucket?(source)
        # Otherwise, return nil & use the same domain the page request came from, like normal.
      end

      def push_to_s3!(*args, &block)
        return unless config.bucket
        uploader = Canvas::Cdn::S3Uploader.new(*args)
        uploader.upload!(&block)
      end

      def enabled?
        !!config.bucket
      end
    end
  end
end
