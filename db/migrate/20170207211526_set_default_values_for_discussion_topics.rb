# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class SetDefaultValuesForDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    fields = [
      :could_be_locked, :podcast_enabled, :podcast_has_student_posts,
      :require_initial_post, :pinned, :locked, :allow_rating, :only_graders_can_rate,
      :sort_by_rating
    ]
    fields.each { |field| change_column_default(:discussion_topics, field, false) }
    DataFixup::BackfillNulls.run(DiscussionTopic, fields, default_value: false)
    fields.each { |field| change_column_null(:discussion_topics, field, false) }
  end

  def down
    fields = [
      :could_be_locked, :podcast_enabled, :podcast_has_student_posts,
      :require_initial_post, :pinned, :locked, :allow_rating, :only_graders_can_rate,
      :sort_by_rating
    ]
    fields.each { |field| change_column_null(:discussion_topics, field, true) }
    fields.each { |field| change_column_default(:discussion_topics, field, nil) }
  end
end
