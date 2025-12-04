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

class FixupPolymorphicFkIndexes < ActiveRecord::Migration[8.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    {
      accessibility_issues: %i[wiki_page_id assignment_id attachment_id],
      accessibility_resource_scans: %i[wiki_page_id assignment_id attachment_id],
      estimated_durations: %i[discussion_topic_id assignment_id attachment_id quiz_id wiki_page_id content_tag_id],
      lti_context_controls: %i[account_id course_id],
      rubric_imports: %i[account_id course_id],
    }.each do |table, columns|
      columns.each do |column|
        name = "index_#{table}_on_#{column}"
        if connection.index_exists?(table, column, name:, where: "(#{column} IS NOT NULL)")
          remove_index table, name: "#{name}_old", if_exists: true, algorithm: :concurrently
          next
        end

        if connection.index_name_exists?(table, name) &&
           !connection.index_name_exists?(table, "#{name}_old")
          rename_index table, name, "#{name}_old"
        end

        add_index table, # rubocop:disable Migration/Predeploy,Migration/NonTransactional
                  column,
                  where: "#{column} IS NOT NULL",
                  algorithm: :concurrently
        remove_index table, name: "#{name}_old", if_exists: true, algorithm: :concurrently
      end
    end
  end
end
