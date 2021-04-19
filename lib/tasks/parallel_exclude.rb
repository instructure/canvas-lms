# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module ParallelExclude
  FILES = [
    "spec/apis/v1/calendar_events_api_spec.rb",
    "spec/integration/files_spec.rb",
    "spec/models/media_object_spec.rb",
    "spec/lib/content_zipper_spec.rb",
    "spec/lib/file_in_context_spec.rb",
    "vendor/plugins/respondus_lockdown_browser/spec_canvas/integration/respondus_ldb_spec.rb",
    "spec/models/attachment_spec.rb"
  ]

  test_files = FileList['{gems,vendor}/plugins/*/spec_canvas/**/*_spec.rb'].exclude(%r'spec_canvas/selenium') + FileList['spec/**/*_spec.rb'].exclude(%r'spec/selenium')
  AVAILABLE_FILES = FILES.select{|file_name| test_files.include?(file_name) }
end
