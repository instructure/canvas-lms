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

require_relative "js_detector"
require_relative "../errors"

module Selinimum
  module Detectors
    class CSSDetector < JSDetector
      DIRECTORY = "app/stylesheets"

      def can_process?(file, _)
        file =~ %r{\Aapp/stylesheets/.*css\z}
      end

      BUNDLE_REGEX = %r{\A#{DIRECTORY}/bundles/(.*)\.scss\z}

      def dependents_for(file)
        if file =~ %r{/jst/}
          file = file.gsub(%r{\A#{DIRECTORY}/|\.scss\z}, "")
          return super file
        end

        bundles = find_bundles_for(file).inject([]) do |result, bundle|
          if bundle =~ %r{/jst/}
            result.concat dependents_for(bundle)
          elsif !bundle.sub!(BUNDLE_REGEX, "\\1")
            $stderr.puts("#{file} is used by #{bundle}, which is not a top-level bundle")
            raise UnknownDependentsError, file
          else
            result << "css:#{bundle}"
          end
        end

        bundles << "css:#{file.sub(BUNDLE_REGEX, "\\1")}" if file =~ BUNDLE_REGEX

        raise UnknownDependentsError, file if bundles.empty?
        raise TooManyDependentsError, file if bundles.include?("css:common")

        bundles
      end

      def find_bundles_for(file)
        finder.puts(file)
        JSON.parse(finder.readline)
      end

      def finder
        @finder ||= begin
          finder = IO.popen("#{File.dirname(__FILE__)}/../../../bin/find_css_bundles 2>&-", "r+")
          finder.puts DIRECTORY
          result = finder.readline.strip rescue nil
          raise "error starting bin/find_css_bundles: #{result}" if result != "Ready"
          finder
        end
      end
    end
  end
end

