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

require_relative "generic_detector"
require_relative "../errors"

module Selinimum
  module Detectors
    class JSDetector < GenericDetector
      def can_process?(file, _)
        file =~ %r{\Apublic/javascripts/.*\.js\z}
      end

      # CommonsChunk entry point, plus the other two bundles on every page
      GLOBAL_BUNDLES = %w[
        js:vendor
        js:common
        js:appBootstrap
      ].freeze

      def dependents_for(file)
        bundles = find_js_bundles(file)
        raise UnknownDependentsError, file if bundles.empty?
        raise TooManyDependentsError, file if (GLOBAL_BUNDLES & bundles).any?
        bundles
      end

      def find_js_bundles(mod)
        (graph["./" + mod] || []).map { |bundle| "js:#{bundle}" }
      end

      def graph
        @graph ||= begin
          manifest = "public/dist/webpack-production/selinimum-manifest.json"
          if File.exist?(manifest)
            JSON.parse(File.read(manifest))
          else
            {}
          end
        end
      end
    end
  end
end
