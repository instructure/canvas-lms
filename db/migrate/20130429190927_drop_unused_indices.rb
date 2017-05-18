#
# Copyright (C) 2013 - present Instructure, Inc.
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

class DropUnusedIndices < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_index :abstract_courses, :enrollment_term_id
    remove_index :abstract_courses, :account_id
    remove_index :appointment_group_sub_contexts, :id
    remove_index :appointment_groups, :context_code
    remove_index :assignment_groups, :cloned_item_id
    remove_index :assignments, :cloned_item_id
    remove_index :calendar_events, :cloned_item_id
    remove_index :cloned_items, :name => 'cloned_items_original_item_id_and_type'
    remove_index :content_exports, :user_id
    remove_index :content_tags, :workflow_state
    remove_index :course_sections, :enrollment_term_id
    remove_index :courses, :abstract_course_id
    remove_index :delayed_notifications, [:workflow_state, :created_at]
    remove_index :discussion_entries, :attachment_id
    remove_index :discussion_topics, :cloned_item_id
    remove_index :discussion_topics, :attachment_id
    remove_index :discussion_topics, :context_code
    remove_index :external_feed_entries, :user_id
    remove_index :external_feeds, :user_id
    remove_index :grading_standards, :user_id
    remove_index :groups, :workflow_state
    remove_index :oauth_requests, :user_id
    remove_index :quizzes, :cloned_item_id
    remove_index :rubrics, :context_code
    remove_index :rubrics, :rubric_id
    remove_index :scribd_mime_types, :extension
    remove_index :submission_comments, :assessment_request_id
    remove_index :thumbnails, [:id, :uuid]
    remove_index :wiki_page_comments, [:wiki_page_id, :workflow_state]
    remove_index :wiki_pages, :cloned_item_id
  end

  def self.down
    add_index :abstract_courses, :workflow_state
    add_index :abstract_courses, :enrollment_term_id
    add_index :abstract_courses, :account_id
    add_index :appointment_group_sub_contexts, :id
    add_index :appointment_groups, :context_code
    add_index :assignment_groups, :cloned_item_id
    add_index :assignments, :cloned_item_id
    add_index :calendar_events, :cloned_item_id
    add_index :cloned_items, [:original_item_id, :original_item_type], :name => 'cloned_items_original_item_id_and_type'
    add_index :content_exports, :user_id
    add_index :content_tags, :workflow_state
    add_index :course_sections, :enrollment_term_id
    add_index :courses, :abstract_course_id
    add_index :delayed_notifications, [:workflow_state, :created_at]
    add_index :discussion_entries, :attachment_id
    add_index :discussion_topics, :cloned_item_id
    add_index :discussion_topics, :attachment_id
    add_index :discussion_topics, :context_code
    add_index :external_feed_entries, :user_id
    add_index :external_feeds, :user_id
    add_index :grading_standards, :user_id
    add_index :groups, :workflow_state
    add_index :oauth_requests, :user_id
    add_index :quizzes, :cloned_item_id
    add_index :rubrics, :context_code
    add_index :rubrics, :rubric_id
    add_index :scribd_mime_types, :extension
    add_index :submission_comments, :assessment_request_id
    add_index :thumbnails, [:id, :uuid]
    add_index :wiki_page_comments, [:wiki_page_id, :workflow_state]
    add_index :wiki_pages, :cloned_item_id
  end
end
