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
#

class CreateDiscussionTopicSectionVisibilities < ActiveRecord::Migration[5.0]
    tag :predeploy

    def up
      create_table :discussion_topic_section_visibilities do |t|
        t.integer :discussion_topic_id, null: false, limit: 8
        t.integer :course_section_id, null: false, limit: 8
        t.timestamps null: false
        t.string :workflow_state, null: false, limit: 255
      end

      add_foreign_key :discussion_topic_section_visibilities, :discussion_topics
      add_foreign_key :discussion_topic_section_visibilities, :course_sections
      add_index :discussion_topic_section_visibilities, :discussion_topic_id,
        name: "idx_discussion_topic_section_visibility_on_topic"
      add_index :discussion_topic_section_visibilities, :course_section_id,
        name: "idx_discussion_topic_section_visibility_on_section"

      add_column :discussion_topics, :is_section_specific, :boolean
      change_column_default :discussion_topics, :is_section_specific, false
    end

    def down
      remove_column :discussion_topics, :is_section_specific
      remove_index(:discussion_topic_section_visibilities,
        { :name=>"idx_discussion_topic_section_visibility_on_section" })
      remove_index(:discussion_topic_section_visibilities,
        { :name=>"idx_discussion_topic_section_visibility_on_topic" })
      remove_foreign_key(:discussion_topic_section_visibilities, :course_sections)
      remove_foreign_key(:discussion_topic_section_visibilities, :discussion_topics)
      drop_table(:discussion_topic_section_visibilities, { :id => :bigserial })
    end
end
