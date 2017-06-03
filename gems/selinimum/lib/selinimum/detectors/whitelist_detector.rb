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
require "globby"

module Selinimum
  module Detectors
    # stuff we ignore that should never affect a build
    class WhitelistDetector < GenericDetector
      def commit_files=(files)
        # rather than glob **/* (which can be slow), just give globby the
        # files and dirs that actually changed
        dirs = Set.new
        files.each do |file|
          path = file.dup
          dirs << path + "/" while path.sub!(%r{/[^/]+\z}, '') && !dirs.include?(path)
        end

        @whitelisted_files = Set.new(
          Globby.select(
            Selinimum.whitelist,
            Globby::GlObject.new(files, dirs)
          )
        )
      end

      def can_process?(file, _)
        @whitelisted_files.include?(file)
      end
    end
  end
end
