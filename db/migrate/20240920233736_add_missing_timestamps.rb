# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class AddMissingTimestamps < ActiveRecord::Migration[7.1]
  tag :predeploy

  def change
    # these tables are missing both columns
    %i[attachment_associations
       content_participations
       conversation_message_participants
       custom_gradebook_column_data
       discussion_entry_participants
       discussion_topic_participants
       master_courses_child_content_tags
       master_courses_master_content_tags
       master_courses_migration_results
       submission_versions].each do |table|
      add_timestamps table, null: false, default: -> { "now()" }
    end

    # and this one is just missing updated_at
    change_table :conversation_messages do |t|
      t.datetime :updated_at, null: false, default: -> { "now()" }
    end
  end
end
