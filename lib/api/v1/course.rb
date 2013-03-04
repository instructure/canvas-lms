#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

module Api::V1::Course
  include Api::V1::Json

  def course_settings_json(course)
    settings = {}
    settings[:allow_student_discussion_topics] = course.allow_student_discussion_topics?
    settings[:allow_student_forum_attachments] = course.allow_student_forum_attachments?
    settings[:allow_student_discussion_editing] = course.allow_student_discussion_editing?
    settings
  end

  def course_json(course, user, session, includes, enrollments)
    Api::V1::CourseJson.to_hash(course, user, includes, enrollments) do |builder, allowed_attributes, methods|
      hash = api_json(course, user, session, :only => allowed_attributes, :methods => methods)
      add_helper_dependant_entries(hash, course, builder)
    end
  end

  def copy_status_json(import, course, user, session)
    hash = api_json(import, user, session, :only => %w(id progress created_at workflow_state))

    # the type of object for course copy changed but we don't want the api to change
    # so map the workflow states to the old ones
    if hash['workflow_state'] == 'imported'
      hash['workflow_state'] = 'completed'
    elsif !['created', 'failed'].member?(hash['workflow_state'])
      hash['workflow_state'] = 'started'
    end

    hash[:status_url] = api_v1_course_copy_status_url(course, import)
    hash
  end

  def add_helper_dependant_entries(hash, course, builder)
    request = self.respond_to?(:request) ? self.request : nil
    hash['calendar'] = { 'ics' => "#{feeds_calendar_url(course.feed_code)}.ics" }
    hash['syllabus_body'] = api_user_content(course.syllabus_body, course) if builder.include_syllabus
    hash['html_url'] = course_url(course, :host => HostUrl.context_host(course, request.try(:host_with_port))) if builder.include_url
    hash
  end

end
