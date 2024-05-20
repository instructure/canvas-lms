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

module Api::V1::PlannerNote
  include Api::V1::Json

  LINKED_OBJECT_TYPES = {
    "announcement" => "Announcement",
    "assignment" => "Assignment",
    "discussion_topic" => "DiscussionTopic",
    "wiki_page" => "WikiPage",
    "quiz" => "Quizzes::Quiz"
  }.freeze

  API_JSON_OPTS = {
    only: %w[id todo_date title details user_id course_id workflow_state created_at updated_at]
  }.freeze

  def planner_note_json(note, user, session, opts = {})
    api_json(note, user, session, opts.merge(API_JSON_OPTS)).tap do |json|
      if note.linked_object_type.present?
        json["linked_object_id"] = note.linked_object_id
        json["linked_object_type"] = LINKED_OBJECT_TYPES.key(note.linked_object_type)
        json["linked_object_url"], json["linked_object_html_url"] = linked_object_urls(note)
      end
    end
  end

  def planner_notes_json(notes, user, session, opts = {})
    notes.map do |note|
      planner_note_json(note, user, session, opts)
    end
  end

  private

  def linked_object_urls(note)
    klass = note.linked_object_type.constantize
    # avoid instantiating the WikiPage by creating an id link instead of a 'url' one
    asset_id = (klass == WikiPage) ? "page_id:#{note.linked_object_id}" : note.linked_object_id
    asset_path = klass.table_name.singularize
    [public_send(:"api_v1_course_#{asset_path}_url", note.course_id, asset_id),
     public_send(:"course_#{asset_path}_url", note.course_id, asset_id)]
  end
end
