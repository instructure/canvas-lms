# frozen_string_literal: true

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
  include Api::V1::Account
  include Api::V1::SectionEnrollments
  include Api::V1::PostGradesStatus
  include Api::V1::User
  include Api::V1::Tab

  def course_settings_json(course)
    settings = {}
    settings[:allow_final_grade_override] = course.allow_final_grade_override?
    settings[:allow_student_discussion_topics] = course.allow_student_discussion_topics?
    settings[:allow_student_forum_attachments] = course.allow_student_forum_attachments?
    settings[:allow_student_discussion_editing] = course.allow_student_discussion_editing?
    settings[:allow_student_discussion_reporting] = course.allow_student_discussion_reporting?
    settings[:allow_student_anonymous_discussion_topics] = course.allow_student_anonymous_discussion_topics?
    settings[:filter_speed_grader_by_student_group] = course.filter_speed_grader_by_student_group?
    settings[:grading_standard_enabled] = course.grading_standard_enabled?
    settings[:grading_standard_id] = course.grading_standard_id
    settings[:grade_passback_setting] = course.grade_passback_setting
    settings[:allow_student_organized_groups] = course.allow_student_organized_groups?
    settings[:hide_final_grades] = course.hide_final_grades?
    settings[:hide_distribution_graphs] = course.hide_distribution_graphs?
    settings[:hide_sections_on_course_users_page] = course.hide_sections_on_course_users_page?
    settings[:lock_all_announcements] = course.lock_all_announcements?
    settings[:usage_rights_required] = course.usage_rights_required?
    settings[:restrict_student_past_view] = course.restrict_student_past_view?
    settings[:restrict_student_future_view] = course.restrict_student_future_view?
    settings[:restrict_quantitative_data] = course.restrict_quantitative_data
    settings[:show_announcements_on_home_page] = course.show_announcements_on_home_page?
    settings[:home_page_announcement_limit] = course.home_page_announcement_limit
    settings[:syllabus_course_summary] = course.syllabus_course_summary?
    settings[:homeroom_course] = course.homeroom_course?
    settings[:image_url] = course.image_url
    settings[:image_id] = course.image_id
    settings[:image] = course.image
    settings[:banner_image_url] = course.banner_image_url
    settings[:banner_image_id] = course.banner_image_id
    settings[:banner_image] = course.banner_image
    settings[:course_color] = course.course_color
    settings[:friendly_name] = course.friendly_name
    settings[:default_due_time] = course.default_due_time || "23:59:59"
    settings[:conditional_release] = course.conditional_release?

    settings
  end

  def courses_json(courses, user, session, includes, enrollments)
    courses.map { |course| course_json(course, user, session, includes, enrollments) }
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
  #     "permissions" => { :create_discussion_topic => true },
  #     "uuid" => "WvAHhY5FINzq5IyRIJybGeiXyFkG3SqHUPb7jZY5"
  #   }
  #
  def course_json(course, user, session, includes, enrollments, subject_user = user, preloaded_progressions: nil, precalculated_permissions: nil, prefer_friendly_name: true)
    if includes.include?("access_restricted_by_date") && enrollments&.all?(&:inactive?) && !course.grants_right?(user, :read_as_admin)
      return { "id" => course.id, "access_restricted_by_date" => true }
    end

    Api::V1::CourseJson.to_hash(course,
                                user,
                                includes,
                                enrollments,
                                precalculated_permissions:) do |builder, allowed_attributes, methods, permissions_to_include|
      hash = api_json(course, user, session, { only: allowed_attributes, methods: }, permissions_to_include)
      hash["term"] = enrollment_term_json(course.enrollment_term, user, session, enrollments, []) if includes.include?("term")
      if includes.include?("grading_periods")
        hash["grading_periods"] = course.enrollment_term&.grading_period_group&.grading_periods&.map do |gp|
          api_json(gp, user, session, only: %w[id title start_date end_date workflow_state])
        end
      end
      if includes.include?("course_progress")
        hash["course_progress"] = CourseProgress.new(course,
                                                     subject_user,
                                                     preloaded_progressions:).to_json
      end
      hash["apply_assignment_group_weights"] = course.apply_group_weights?
      if includes.include?("sections")
        hash["sections"] = if enrollments.any?
                             section_enrollments_json(enrollments)
                           else
                             course.course_sections.map { |section| section.attributes.slice(*%w[id name start_at end_at]) }
                           end
      end
      hash["total_students"] = course.student_count || course.student_enrollments.not_fake.distinct.count(:user_id) if includes.include?("total_students")
      hash["passback_status"] = post_grades_status_json(course) if includes.include?("passback_status")
      hash["is_favorite"] = course.favorite_for_user?(subject_user) if includes.include?("favorites")
      if includes.include?("teachers")
        if course.teacher_count
          hash["teacher_count"] = course.teacher_count
        else
          hash["teachers"] = course.teachers.distinct.map { |teacher| user_display_json(teacher) }
        end
      end
      # undocumented; used in AccountCourseUserSearch
      if includes.include?("active_teachers")
        course.shard.activate do
          scope =
            TeacherEnrollment.where.not(workflow_state: %w[rejected completed deleted inactive]).where(course_id: course.id).distinct.select(:user_id)
          hash["teachers"] =
            User.where(id: scope).map { |teacher| user_display_json(teacher) }
        end
      end
      hash["tabs"] = tabs_available_json(course, user, session, ["external"], precalculated_permissions:) if includes.include?("tabs")
      hash["locale"] = course.locale unless course.locale.nil?
      hash["account"] = account_json(course.account, user, session, []) if includes.include?("account")
      # undocumented, but leaving for backwards compatibility.
      hash["subaccount_id"] = course.account.id if includes.include?("subaccount")
      hash["subaccount_name"] = course.account.name if includes.include?("subaccount")
      add_helper_dependant_entries(hash, course, builder)
      apply_nickname(hash, course, user, prefer_friendly_name:)

      hash["image_download_url"] = course.image if includes.include?("course_image")
      hash["banner_image_download_url"] = course.banner_image if includes.include?("banner_image")
      hash["concluded"] = course.concluded? if includes.include?("concluded")
      apply_master_course_settings(hash, course, user)
      if course.root_account.feature_enabled?(:course_templates)
        hash["template"] = course.template?
        if course.template? && includes.include?("templated_accounts")
          hash["templated_accounts"] = course.templated_accounts.map { |a| { id: a.id, name: a.name } }
        end
      end

      hash["grading_scheme"] = course.grading_standard_or_default.data if includes.include?("grading_scheme")
      hash["restrict_quantitative_data"] = course.restrict_quantitative_data?(user) if includes.include?("restrict_quantitative_data")

      # return hash from the block for additional processing in Api::V1::CourseJson
      hash
    end
  end

  def copy_status_json(import, course, user, session)
    hash = api_json(import, user, session, only: %w[id progress created_at workflow_state integration_id])

    # the type of object for course copy changed but we don't want the api to change
    # so map the workflow states to the old ones
    if hash["workflow_state"] == "imported"
      hash["workflow_state"] = "completed"
    elsif !["created", "failed"].member?(hash["workflow_state"])
      hash["workflow_state"] = "started"
    end

    hash[:status_url] = api_v1_course_copy_status_url(course, import)
    hash
  end

  def add_helper_dependant_entries(hash, course, builder)
    request = respond_to?(:request) ? self.request : nil
    hash["calendar"] = { "ics" => "#{feeds_calendar_url(course.feed_code)}.ics" }
    hash["syllabus_body"] = api_user_content(course.syllabus_body, course) if builder.include_syllabus
    hash["html_url"] = course_url(course, host: HostUrl.context_host(course, request.try(:host_with_port))) if builder.include_url
    hash["time_zone"] = course.time_zone&.tzinfo&.name
    hash
  end

  def apply_nickname(hash, course, user, prefer_friendly_name: true)
    nickname = course.friendly_name if prefer_friendly_name
    nickname ||= course.preloaded_nickname? ? course.preloaded_nickname : user&.course_nickname(course)
    if nickname
      hash["original_name"] = hash["name"]
      hash["name"] = nickname
    end
    hash
  end

  def apply_master_course_settings(hash, course, _user)
    is_mc = MasterCourses::MasterTemplate.is_master_course?(course)
    hash["blueprint"] = is_mc

    if is_mc
      template = MasterCourses::MasterTemplate.full_template_for(course)
      if template&.use_default_restrictions_by_type
        hash["blueprint_restrictions_by_object_type"] = template.default_restrictions_by_type_for_api
      else
        hash["blueprint_restrictions"] = template&.default_restrictions
      end
    end
  end

  def preload_teachers(courses)
    threshold = params[:teacher_limit].presence&.to_i
    if threshold
      scope = TeacherEnrollment.where.not(workflow_state: %w[deleted rejected]).where(course_id: courses).distinct.select(:user_id, :course_id)
      teacher_counts = Enrollment.from("(#{scope.to_sql}) AS t").group("t.course_id").count
      to_preload = []
      courses.each do |course|
        next unless (count = teacher_counts[course.id])

        if count > threshold
          course.teacher_count = count
        else
          to_preload << course
        end
      end
      ActiveRecord::Associations.preload(to_preload, [:teachers]) if to_preload.any?
    else
      ActiveRecord::Associations.preload(courses, [:teachers])
    end
  end
end
