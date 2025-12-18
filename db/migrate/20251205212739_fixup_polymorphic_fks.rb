# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class FixupPolymorphicFks < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!
  tag :postdeploy

  def up
    {
      accessibility_issues: %i[wiki_pages assignments attachments],
      accessibility_resource_scans: %i[wiki_pages assignments attachments],
      estimated_durations: %i[discussion_topics assignments attachments quizzes wiki_pages content_tags],
      lti_context_controls: %i[accounts courses],
      rubric_imports: %i[accounts courses],
    }.each do |table, references|
      references.each do |ref|
        add_foreign_key table, ref, delay_validation: true, if_not_exists: true
      end
    end
  end
end
