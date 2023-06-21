# frozen_string_literal: true

#
# Copyright (C) 2020 Instructure, Inc.
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
class DataServicesEventsLoader
  attr_accessor :json_base_path

  CUSTOM_EVENTS_CATEGORIES = {
    "doc/api/data_services/json/canvas/event-types/course_grade_change.json" => "grade",
    "doc/api/data_services/json/canvas/event-types/outcome_proficiency_created.json" => "learning",
    "doc/api/data_services/json/canvas/event-types/outcome_proficiency_updated.json" => "learning",
    "doc/api/data_services/json/caliper/event-types/quiz_submitted.json" => "assessment",
    "doc/api/data_services/json/caliper/event-types/assignment_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/assignment_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/assignment_override_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/assignment_override_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/attachment_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/attachment_deleted.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/attachment_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/course_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/course_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/enrollment_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/enrollment_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/enrollment_state_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/enrollment_state_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/group_category_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/group_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/group_membership_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/submission_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/submission_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/syllabus_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/wiki_page_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/wiki_page_deleted.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/wiki_page_updated.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/user_account_association_created.json" => "basic",
    "doc/api/data_services/json/caliper/event-types/discussion_topic_created.json" => "forum",
    "doc/api/data_services/json/caliper/event-types/discussion_entry_created.json" => "forum",
    "doc/api/data_services/json/caliper/event-types/grade_change.json" => "grading",
    "doc/api/data_services/json/caliper/event-types/asset_accessed.json" => "navigation_events",
    "doc/api/data_services/json/caliper/event-types/logged_in.json" => "session",
    "doc/api/data_services/json/caliper/event-types/logged_out.json" => "session"
  }.freeze

  def initialize(json_base_path)
    @json_base_path = json_base_path
  end

  def data
    @data ||= event_types.collect do |event_category, event_files|
      {
        event_category:,
        page_title: page_tile_formatter(event_category),
        event_payloads: load_json_events(event_files.sort)
      }
    end
  end

  private

  def files
    @files ||= Dir.glob("#{json_base_path}/event-types/*json")
  end

  def event_types
    @event_types ||= files
                     .group_by { |file_path| extrat_category_from_file_path(file_path) }
                     .sort
                     .to_h
  end

  def extrat_category_from_file_path(file_path)
    CUSTOM_EVENTS_CATEGORIES[file_path] || file_path.split("/").last.split("_").first
  end

  def load_json_events(event_files)
    event_files.collect { |file| JSON.parse(File.read(file)) }
  end

  def page_tile_formatter(event_category)
    event_category.split("_").join(" ").titleize
  end
end
