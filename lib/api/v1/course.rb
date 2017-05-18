#
# Copyright (C) 2011 - present Instructure, Inc.
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
  include Api::V1::SectionEnrollments
  include Api::V1::PostGradesStatus
  include Api::V1::User
  include Api::V1::Tab

  def course_settings_json(course)
    settings = {}
    settings[:allow_student_discussion_topics] = course.allow_student_discussion_topics?
    settings[:allow_student_forum_attachments] = course.allow_student_forum_attachments?
    settings[:allow_student_discussion_editing] = course.allow_student_discussion_editing?
    settings[:grading_standard_enabled] = course.grading_standard_enabled?
    settings[:grading_standard_id] = course.grading_standard_id
    settings[:allow_student_organized_groups] = course.allow_student_organized_groups?
    settings[:hide_final_grades] = course.hide_final_grades?
    settings[:hide_distribution_graphs] = course.hide_distribution_graphs?
    settings[:lock_all_announcements] = course.lock_all_announcements?
    settings[:restrict_student_past_view] = course.restrict_student_past_view?
    settings[:restrict_student_future_view] = course.restrict_student_future_view?
    settings[:show_announcements_on_home_page] = course.show_announcements_on_home_page?
    settings[:home_page_announcement_limit] = course.home_page_announcement_limit
    settings[:image_url] = course.image_url
    settings[:image_id] = course.image_id
    settings[:image] = course.image

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
  #     "public_syllabus_to_auth" => false,
  #     "storage_quota_mb" => 500,
  #     "hide_final_grades" => false,
  #     "apply_assignment_group_weights" => false,
  #     "calendar" => { "ics" => "http://localhost:3000/feeds/calendars/course_Y6uXZZPu965ziva2pqI7c0QR9v1yu2QZk9X0do2D.ics" },
  #     "permissions" => { :create_discussion_topic => true }
  #   }
  #
  def course_json(course, user, session, includes, enrollments)
    if includes.include?('access_restricted_by_date') && enrollments && enrollments.all?(&:inactive?)
      return {'id' => course.id, 'access_restricted_by_date' => true}
    end

    Api::V1::CourseJson.to_hash(course, user, includes, enrollments) do |builder, allowed_attributes, methods, permissions_to_include|
      hash = api_json(course, user, session, { :only => allowed_attributes, :methods => methods }, permissions_to_include)
      hash['term'] = enrollment_term_json(course.enrollment_term, user, session, enrollments, []) if includes.include?('term')
      hash['course_progress'] = CourseProgress.new(course, user).to_json if includes.include?('course_progress')
      hash['apply_assignment_group_weights'] = course.apply_group_weights?
      hash['sections'] = section_enrollments_json(enrollments) if includes.include?('sections')
      hash['total_students'] = course.student_count || course.students.count if includes.include?('total_students')
      hash['passback_status'] = post_grades_status_json(course) if includes.include?('passback_status')
      hash['is_favorite'] = course.favorite_for_user?(user) if includes.include?('favorites')
      hash['teachers'] = course.teachers.map { |teacher| user_display_json(teacher) } if includes.include?('teachers')
      hash['tabs'] = tabs_available_json(course, user, session, ['external']) if includes.include?('tabs')
      hash['locale'] = course.locale unless course.locale.nil?
      add_helper_dependant_entries(hash, course, builder)
      apply_nickname(hash, course, user) if user

      hash['image_download_url'] = course.image if includes.include?('course_image') && course.feature_enabled?('course_card_images')

      # return hash from the block for additional processing in Api::V1::CourseJson
      hash
    end
  end

  def copy_status_json(import, course, user, session)
    hash = api_json(import, user, session, :only => %w(id progress created_at workflow_state integration_id))

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
    hash['time_zone'] = course.time_zone && course.time_zone.tzinfo.name
    hash
  end

  def apply_nickname(hash, course, user)
    nickname = user.course_nickname(course)
    if nickname
      hash['original_name'] = hash['name']
      hash['name'] = nickname
    end
    hash
  end

end
