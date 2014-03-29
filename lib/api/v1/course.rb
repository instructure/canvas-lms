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
  include Api::V1::EnrollmentTerm

  def course_settings_json(course)
    settings = {}
    settings[:allow_student_discussion_topics] = course.allow_student_discussion_topics?
    settings[:allow_student_forum_attachments] = course.allow_student_forum_attachments?
    settings[:allow_student_discussion_editing] = course.allow_student_discussion_editing?
    settings
  end

  def courses_json(courses, user, session, includes, enrollments)
    courses.map{ |course| course_json(course, user, session, includes, enrollments) }
  end

  # Public: Returns a course hash to serialize for a json api request.
  #
  # course - The course information to return as the hash.
  # user - The user requesting the information for permissions.
  # session - The current users session object.
  # includes - Custom attributes to include in the data response.
  # enrollments - Course enrollments to include in the response.
  #
  # Examples
  #
  #   course_json(course, user, session, includes, enrollments)
  #   # => {
  #     "account_id" => 3,
  #     "course_code" => "TestCourse",
  #     "default_view" => "feed",
  #     "id" => 1,
  #     "name" => "TestCourse",
  #     "start_at" => nil,
  #     "end_at" => nil,
  #     "public_syllabus" => false,
  #     "storage_quota_mb" => 500,
  #     "hide_final_grades" => false,
  #     "apply_assignment_group_weights" => false,
  #     "calendar" => { "ics" => "http://localhost:3000/feeds/calendars/course_Y6uXZZPu965ziva2pqI7c0QR9v1yu2QZk9X0do2D.ics" },
  #     "permissions" => { :create_discussion_topic => true }
  #   }
  #
  def course_json(course, user, session, includes, enrollments)
    Api::V1::CourseJson.to_hash(course, user, includes, enrollments) do |builder, allowed_attributes, methods, permissions_to_include|
      hash = api_json(course, user, session, { :only => allowed_attributes, :methods => methods }, permissions_to_include)
      hash['term'] = enrollment_term_json(course.enrollment_term, user, session, {}) if includes.include?('term')
      if includes.include?('course_progress')
        hash['course_progress'] = course_progress_json(course, user) ||
                                  { error: { message: 'no progress available because this course in not module based (has modules and module completion requirements)' } }
      end
      hash['apply_assignment_group_weights'] = course.apply_group_weights?
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

  def course_progress_json(course, user)
    return unless course.module_based? && course.user_is_student?(user)

    mods = course.modules_visible_to(user)
    requirement_count = mods.flat_map(&:completion_requirements).size

    requirement_completed_count = user.context_module_progressions
                                      .where("context_module_id IN (?)", mods.map(&:id))
                                      .flat_map { |cmp| cmp.requirements_met.to_a.uniq { |r| r[:id] } }
                                      .size

    course_progress = {
        requirement_count: requirement_count,
        requirement_completed_count: requirement_completed_count,
        next_requirement_url: nil
    }

    if requirement_completed_count < requirement_count
      current_mod = mods.detect { |m| m.evaluate_for(user).completed? == false }

      if current_mod.require_sequential_progress
        current_position = current_mod.evaluate_for(user).current_position
        content_tag = current_mod.content_tags.where(:position => current_position).first
        next_requirement_url = course_context_modules_item_redirect_url(:course_id => course.id, :id => content_tag.id, :host => HostUrl.context_host(course))
        course_progress[:next_requirement_url] = next_requirement_url
      end
    end

    course_progress
  end

  def add_helper_dependant_entries(hash, course, builder)
    request = self.respond_to?(:request) ? self.request : nil
    hash['calendar'] = { 'ics' => "#{feeds_calendar_url(course.feed_code)}.ics" }
    hash['syllabus_body'] = api_user_content(course.syllabus_body, course) if builder.include_syllabus
    hash['html_url'] = course_url(course, :host => HostUrl.context_host(course, request.try(:host_with_port))) if builder.include_url
    hash
  end

end
