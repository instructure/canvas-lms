# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module RuboCop
  module Cop
    module FileMeta
      SPEC_FILE_NAME_REGEX = /_spec\.rb$/
      CONTROLLER_FILE_NAME_REGEX = /controller\.rb$/

      def file_name
        file_path.split("/").last
      end

      def file_path
        processed_source.buffer.name
      end

      def named_as_spec?
        file_name =~ SPEC_FILE_NAME_REGEX
      end

      def named_as_controller?
        file_name =~ CONTROLLER_FILE_NAME_REGEX
      end
    end
  end
end
