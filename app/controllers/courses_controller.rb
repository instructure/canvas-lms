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

# @API Courses
# API for accessing course information.
#
# @model Term
#     {
#       "id": "Term",
#       "description": "",
#       "properties": {
#         "id": {
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "example": "Default Term",
#           "type": "string"
#         },
#         "start_at": {
#           "example": "2012-06-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "type": "datetime"
#         }
#       }
#     }
#
# @model CourseProgress
#     {
#       "id": "CourseProgress",
#       "description": "",
#       "properties": {
#         "requirement_count": {
#           "description": "total number of requirements from all modules",
#           "example": 10,
#           "type": "integer"
#         },
#         "requirement_completed_count": {
#           "description": "total number of requirements the user has completed from all modules",
#           "example": 1,
#           "type": "integer"
#         },
#         "next_requirement_url": {
#           "description": "url to next module item that has an unmet requirement. null if the user has completed the course or the current module does not require sequential progress",
#           "example": "http://localhost/courses/1/modules/items/2",
#           "type": "string"
#         },
#         "completed_at": {
#           "description": "date the course was completed. null if the course has not been completed by this user",
#           "example": "2013-06-01T00:00:00-06:00",
#           "type": "datetime"
#         }
#       }
#     }
#
# @model Course
#     {
#       "id": "Course",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the course",
#           "example": 370663,
#           "type": "integer"
#         },
#         "sis_course_id": {
#           "description": "the SIS identifier for the course, if defined. This field is only included if the user has permission to view SIS information.",
#           "type": "string"
#         },
#         "uuid": {
#           "description": "the UUID of the course",
#           "example": "WvAHhY5FINzq5IyRIJybGeiXyFkG3SqHUPb7jZY5",
#           "type": "string"
#         },
#         "integration_id": {
#           "description": "the integration identifier for the course, if defined. This field is only included if the user has permission to view SIS information.",
#           "type": "string"
#         },
#         "sis_import_id": {
#           "description": "the unique identifier for the SIS import. This field is only included if the user has permission to manage SIS information.",
#           "example": 34,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the full name of the course. If the requesting user has set a nickname for the course, the nickname will be shown here.",
#           "example": "InstructureCon 2012",
#           "type": "string"
#         },
#         "course_code": {
#           "description": "the course code",
#           "example": "INSTCON12",
#           "type": "string"
#         },
#         "original_name": {
#           "description": "the actual course name. This field is returned only if the requesting user has set a nickname for the course.",
#           "example": "InstructureCon-2012-01",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "the current state of the course one of 'unpublished', 'available', 'completed', or 'deleted'",
#           "example": "available",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "unpublished",
#               "available",
#               "completed",
#               "deleted"
#             ]
#           }
#         },
#         "account_id": {
#           "description": "the account associated with the course",
#           "example": 81259,
#           "type": "integer"
#         },
#         "root_account_id": {
#           "description": "the root account associated with the course",
#           "example": 81259,
#           "type": "integer"
#         },
#         "enrollment_term_id": {
#           "description": "the enrollment term associated with the course",
#           "example": 34,
#           "type": "integer"
#         },
#         "grading_periods": {
#           "description": "A list of grading periods associated with the course",
#           "type": "array",
#           "items": { "$ref": "GradingPeriod" }
#         },
#         "grading_standard_id": {
#            "description": "the grading standard associated with the course",
#            "example": 25,
#            "type": "integer"
#         },
#         "grade_passback_setting": {
#            "description": "the grade_passback_setting set on the course",
#            "example": "nightly_sync",
#            "type": "string"
#         },
#         "created_at": {
#           "description": "the date the course was created.",
#           "example": "2012-05-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "start_at": {
#           "description": "the start date for the course, if applicable",
#           "example": "2012-06-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "end_at": {
#           "description": "the end date for the course, if applicable",
#           "example": "2012-09-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "locale": {
#           "description": "the course-set locale, if applicable",
#           "example": "en",
#           "type": "string"
#         },
#         "enrollments": {
#           "description": "A list of enrollments linking the current user to the course. for student enrollments, grading information may be included if include[]=total_scores",
#           "type": "array",
#           "items": { "$ref": "Enrollment" }
#         },
#         "total_students": {
#           "description": "optional: the total number of active and invited students in the course",
#           "example": 32,
#           "type": "integer"
#         },
#         "calendar": {
#           "description": "course calendar",
#           "$ref": "CalendarLink"
#         },
#         "default_view": {
#           "description": "the type of page that users will see when they first visit the course - 'feed': Recent Activity Dashboard - 'wiki': Wiki Front Page - 'modules': Course Modules/Sections Page - 'assignments': Course Assignments List - 'syllabus': Course Syllabus Page other types may be added in the future",
#           "example": "feed",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "feed",
#               "wiki",
#               "modules",
#               "syllabus",
#               "assignments"
#             ]
#           }
#         },
#         "syllabus_body": {
#           "description": "optional: user-generated HTML for the course syllabus",
#           "example": "<p>syllabus html goes here</p>",
#           "type": "string"
#         },
#         "needs_grading_count": {
#           "description": "optional: the number of submissions needing grading returned only if the current user has grading rights and include[]=needs_grading_count",
#           "example": 17,
#           "type": "integer"
#         },
#         "term": {
#           "description": "optional: the enrollment term object for the course returned only if include[]=term",
#           "$ref": "Term"
#         },
#         "course_progress": {
#           "description": "optional: information on progress through the course returned only if include[]=course_progress",
#           "$ref": "CourseProgress"
#         },
#         "apply_assignment_group_weights": {
#           "description": "weight final grade based on assignment group percentages",
#           "example": true,
#           "type": "boolean"
#         },
#         "permissions": {
#           "description": "optional: the permissions the user has for the course. returned only for a single course and include[]=permissions",
#           "example": {"create_discussion_topic": true, "create_announcement": true},
#           "type": "object",
#           "key": { "type": "string" },
#           "value": { "type": "boolean" }
#         },
#         "is_public": {
#           "example": true,
#           "type": "boolean"
#         },
#         "is_public_to_auth_users": {
#           "example": true,
#           "type": "boolean"
#         },
#         "public_syllabus": {
#           "example": true,
#           "type": "boolean"
#         },
#         "public_syllabus_to_auth": {
#           "example": true,
#           "type": "boolean"
#         },
#         "public_description": {
#           "description": "optional: the public description of the course",
#           "example": "Come one, come all to InstructureCon 2012!",
#           "type": "string"
#         },
#         "storage_quota_mb": {
#           "example": 5,
#           "type": "integer"
#         },
#         "storage_quota_used_mb": {
#           "example": 5,
#           "type": "number"
#         },
#         "hide_final_grades": {
#           "example": false,
#           "type": "boolean"
#         },
#         "license": {
#           "example": "Creative Commons",
#           "type": "string"
#         },
#         "allow_student_assignment_edits": {
#           "example": false,
#           "type": "boolean"
#         },
#         "allow_wiki_comments": {
#           "example": false,
#           "type": "boolean"
#         },
#         "allow_student_forum_attachments": {
#           "example": false,
#           "type": "boolean"
#         },
#         "open_enrollment": {
#           "example": true,
#           "type": "boolean"
#         },
#         "self_enrollment": {
#           "example": false,
#           "type": "boolean"
#         },
#         "restrict_enrollments_to_course_dates": {
#           "example": false,
#           "type": "boolean"
#         },
#         "course_format": {
#           "example": "online",
#           "type": "string"
#         },
#         "access_restricted_by_date": {
#           "description": "optional: this will be true if this user is currently prevented from viewing the course because of date restriction settings",
#           "example": false,
#           "type": "boolean"
#         },
#         "time_zone": {
#           "description": "The course's IANA time zone name.",
#           "example": "America/Denver",
#           "type": "string"
#         },
#         "blueprint": {
#           "description": "optional: whether the course is set as a Blueprint Course (blueprint fields require the Blueprint Courses feature)",
#           "example": true,
#           "type": "boolean"
#         },
#         "blueprint_restrictions": {
#           "description": "optional: Set of restrictions applied to all locked course objects",
#           "example": {"content": true, "points": true, "due_dates": false, "availability_dates": false},
#           "type": "object"
#         },
#         "blueprint_restrictions_by_object_type": {
#           "description": "optional: Sets of restrictions differentiated by object type applied to locked course objects",
#           "example": {"assignment": {"content": true, "points": true}, "wiki_page": {"content": true}},
#           "type": "object"
#         },
#         "template": {
#           "description": "optional: whether the course is set as a template (requires the Course Templates feature)",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model CalendarLink
#     {
#       "id": "CalendarLink",
#       "description": "",
#       "properties": {
#         "ics": {
#           "description": "The URL of the calendar in ICS format",
#           "example": "https://canvas.instructure.com/feeds/calendars/course_abcdef.ics",
#           "type": "string"
#          }
#       }
#     }
#
class CoursesController < ApplicationController
  include SearchHelper
  include ContextExternalToolsHelper
  include CustomColorHelper
  include CustomSidebarLinksHelper
  include SyllabusHelper
  include WebZipExportHelper
  include CoursesHelper
  include NewQuizzesFeaturesHelper
  include ObserverEnrollmentsHelper
  include DefaultDueTimeHelper

  before_action :require_user, only: %i[index activity_stream activity_stream_summary effective_due_dates offline_web_exports start_offline_web_export]
  before_action :require_user_or_observer, only: [:user_index]
  before_action :require_context, only: %i[roster locks create_file ping confirm_action copy effective_due_dates offline_web_exports link_validator settings start_offline_web_export statistics user_progress]
  skip_after_action :update_enrollment_last_activity_at, only: [:enrollment_invitation, :activity_stream_summary]

  include Api::V1::Course
  include Api::V1::Progress
  include K5Mode

  # @API List your courses
  # Returns the paginated list of active courses for the current user.
  #
  # @argument enrollment_type [String, "teacher"|"student"|"ta"|"observer"|"designer"]
  #   When set, only return courses where the user is enrolled as this type. For
  #   example, set to "teacher" to return only courses where the user is
  #   enrolled as a Teacher.  This argument is ignored if enrollment_role is given.
  #
  # @argument enrollment_role [String] Deprecated
  #   When set, only return courses where the user is enrolled with the specified
  #   course-level role.  This can be a role created with the
  #   {api:RoleOverridesController#add_role Add Role API} or a base role type of
  #   'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment',
  #   or 'DesignerEnrollment'.
  #
  # @argument enrollment_role_id [Integer]
  #   When set, only return courses where the user is enrolled with the specified
  #   course-level role.  This can be a role created with the
  #   {api:RoleOverridesController#add_role Add Role API} or a built_in role type of
  #   'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment',
  #   or 'DesignerEnrollment'.
  #
  # @argument enrollment_state [String, "active"|"invited_or_pending"|"completed"]
  #   When set, only return courses where the user has an enrollment with the given state.
  #   This will respect section/course/term date overrides.
  #
  # @argument exclude_blueprint_courses [Boolean]
  #   When set, only return courses that are not configured as blueprint courses.
  #
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"public_description"|"total_scores"|"current_grading_period_scores"|"grading_periods"|"term"|"account"|"course_progress"|"sections"|"storage_quota_used_mb"|"total_students"|"passback_status"|"favorites"|"teachers"|"observed_users"|"course_image"|"banner_image"|"concluded"]
  #   - "needs_grading_count": Optional information to include with each Course.
  #     When needs_grading_count is given, and the current user has grading
  #     rights, the total number of submissions needing grading for all
  #     assignments is returned.
  #   - "syllabus_body": Optional information to include with each Course.
  #     When syllabus_body is given the user-generated html for the course
  #     syllabus is returned.
  #   - "public_description": Optional information to include with each Course.
  #     When public_description is given the user-generated text for the course
  #     public description is returned.
  #   - "total_scores": Optional information to include with each Course.
  #     When total_scores is given, any student enrollments will also
  #     include the fields 'computed_current_score', 'computed_final_score',
  #     'computed_current_grade', and 'computed_final_grade', as well as (if
  #     the user has permission) 'unposted_current_score',
  #     'unposted_final_score', 'unposted_current_grade', and
  #     'unposted_final_grade' (see Enrollment documentation for more
  #     information on these fields). This argument is ignored if the course is
  #     configured to hide final grades.
  #   - "current_grading_period_scores": Optional information to include with
  #     each Course. When current_grading_period_scores is given and total_scores
  #     is given, any student enrollments will also include the fields
  #     'has_grading_periods',
  #     'totals_for_all_grading_periods_option', 'current_grading_period_title',
  #     'current_grading_period_id', current_period_computed_current_score',
  #     'current_period_computed_final_score',
  #     'current_period_computed_current_grade', and
  #     'current_period_computed_final_grade', as well as (if the user has permission)
  #     'current_period_unposted_current_score',
  #     'current_period_unposted_final_score',
  #     'current_period_unposted_current_grade', and
  #     'current_period_unposted_final_grade' (see Enrollment documentation for
  #     more information on these fields). In addition, when this argument is
  #     passed, the course will have a 'has_grading_periods' attribute
  #     on it. This argument is ignored if the total_scores argument is not
  #     included. If the course is configured to hide final grades, the
  #     following fields are not returned:
  #     'totals_for_all_grading_periods_option',
  #     'current_period_computed_current_score',
  #     'current_period_computed_final_score',
  #     'current_period_computed_current_grade',
  #     'current_period_computed_final_grade',
  #     'current_period_unposted_current_score',
  #     'current_period_unposted_final_score',
  #     'current_period_unposted_current_grade', and
  #     'current_period_unposted_final_grade'
  #   - "grading_periods": Optional information to include with each Course. When
  #     grading_periods is given, a list of the grading periods associated with
  #     each course is returned.
  #   - "term": Optional information to include with each Course. When
  #     term is given, the information for the enrollment term for each course
  #     is returned.
  #   - "account": Optional information to include with each Course. When
  #     account is given, the account json for each course is returned.
  #   - "course_progress": Optional information to include with each Course.
  #     When course_progress is given, each course will include a
  #     'course_progress' object with the fields: 'requirement_count', an integer
  #     specifying the total number of requirements in the course,
  #     'requirement_completed_count', an integer specifying the total number of
  #     requirements in this course that have been completed, and
  #     'next_requirement_url', a string url to the next requirement item, and
  #     'completed_at', the date the course was completed (null if incomplete).
  #     'next_requirement_url' will be null if all requirements have been
  #     completed or the current module does not require sequential progress.
  #     "course_progress" will return an error message if the course is not
  #     module based or the user is not enrolled as a student in the course.
  #   - "sections": Section enrollment information to include with each Course.
  #     Returns an array of hashes containing the section ID (id), section name
  #     (name), start and end dates (start_at, end_at), as well as the enrollment
  #     type (enrollment_role, e.g. 'StudentEnrollment').
  #   - "storage_quota_used_mb": The amount of storage space used by the files in this course
  #   - "total_students": Optional information to include with each Course.
  #     Returns an integer for the total amount of active and invited students.
  #   - "passback_status": Include the grade passback_status
  #   - "favorites": Optional information to include with each Course.
  #     Indicates if the user has marked the course as a favorite course.
  #   - "teachers": Teacher information to include with each Course.
  #     Returns an array of hashes containing the {api:Users:UserDisplay UserDisplay} information
  #     for each teacher in the course.
  #   - "observed_users": Optional information to include with each Course.
  #     Will include data for observed users if the current user has an
  #     observer enrollment.
  #   - "tabs": Optional information to include with each Course.
  #     Will include the list of tabs configured for each course.  See the
  #     {api:TabsController#index List available tabs API} for more information.
  #   - "course_image": Optional information to include with each Course. Returns course
  #     image url if a course image has been set.
  #   - "banner_image": Optional information to include with each Course. Returns course
  #     banner image url if the course is a Canvas for Elementary subject and a banner
  #     image has been set.
  #   - "concluded": Optional information to include with each Course. Indicates whether
  #     the course has been concluded, taking course and term dates into account.
  #
  # @argument state[] [String, "unpublished"|"available"|"completed"|"deleted"]
  #   If set, only return courses that are in the given state(s).
  #   By default, "available" is returned for students and observers, and
  #   anything except "deleted", for all other enrollment types
  #
  # @returns [Course]
  def index
    GuardRail.activate(:secondary) do
      respond_to do |format|
        format.html do
          css_bundle :context_list, :course_list
          js_bundle :course_list

          create_permission_root_account = @current_user.create_courses_right(@domain_root_account)
          create_permission_mcc_account = @current_user.create_courses_right(@domain_root_account.manually_created_courses_account)

          js_env({
                   CREATE_COURSES_PERMISSIONS: {
                     PERMISSION: create_permission_root_account || create_permission_mcc_account,
                     RESTRICT_TO_MCC_ACCOUNT: !!(!create_permission_root_account && create_permission_mcc_account)
                   }
                 })

          set_k5_mode(require_k5_theme: true)

          if @current_user
            content_for_head helpers.auto_discovery_link_tag(:atom, feeds_user_format_path(@current_user.feed_code, :atom), { title: t("titles.rss.course_announcements", "Course Announcements Atom Feed") })
          end

          render stream: can_stream_template?
        end

        format.json do
          render json: courses_for_user(@current_user)
        end
      end
    end
  end

  def load_enrollments_for_index
    all_enrollments = @current_user.enrollments.not_deleted.shard(@current_user.in_region_associated_shards).preload(:enrollment_state, :course, :course_section).to_a
    if @current_user.roles(@domain_root_account).all? { |role| role == "student" || role == "user" }
      all_enrollments = all_enrollments.reject { |e| e.course.elementary_homeroom_course? }
    end
    @past_enrollments = []
    @current_enrollments = []
    @future_enrollments = []

    completed_states = %i[completed rejected]
    active_states = %i[active invited]
    all_enrollments.group_by { |e| [e.course_id, e.type] }.each_value do |enrollments|
      first_enrollment = enrollments.min_by(&:state_with_date_sortable)
      if enrollments.count > 1
        # pick the last one so if all sections have "ended" it still shows up in past enrollments because dates are still terrible
        first_enrollment.course_section = enrollments.map(&:course_section).max_by { |cs| cs.end_at || CanvasSort::Last }
        first_enrollment.readonly!
      end

      state = first_enrollment.state_based_on_date
      if completed_states.include?(state) ||
         (active_states.include?(state) && first_enrollment.section_or_course_date_in_past?) # strictly speaking, these enrollments are perfectly active but enrollment dates are terrible
        @past_enrollments << first_enrollment unless first_enrollment.workflow_state == "invited"
      elsif !first_enrollment.hard_inactive?
        if first_enrollment.enrollment_state.pending? || state == :creation_pending ||
           (first_enrollment.admin? && (
               first_enrollment.course.restrict_enrollments_to_course_dates &&
               first_enrollment.course.start_at&.>(Time.now.utc)
             )
           )
          @future_enrollments << first_enrollment unless first_enrollment.restrict_future_listing?
        elsif state != :inactive
          @current_enrollments << first_enrollment
        end
      end
    end

    @past_enrollments.sort_by! { |e| [e.course.published? ? 0 : 1, Canvas::ICU.collation_key(e.long_name)] }
    [@current_enrollments, @future_enrollments].each do |list|
      list.sort_by! do |e|
        [e.course.published? ? 0 : 1, e.active? ? 1 : 0, Canvas::ICU.collation_key(e.long_name)]
      end
    end
  end
  helper_method :load_enrollments_for_index

  def enrollments_for_index(type)
    instance_variable_get(:"@#{type}_enrollments")
  end
  helper_method :enrollments_for_index

  def show_favorites_col_for_index?(type)
    enrollments_for_index(type).any?(&:allows_favoriting?)
  end
  helper_method :show_favorites_col_for_index?

  # @API List courses for a user
  # Returns a paginated list of active courses for this user. To view the course list for a user other than yourself, you must be either an observer of that user or an administrator.
  #
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"public_description"|"total_scores"|"current_grading_period_scores"|"grading_periods"|term"|"account"|"course_progress"|"sections"|"storage_quota_used_mb"|"total_students"|"passback_status"|"favorites"|"teachers"|"observed_users"|"course_image"|"banner_image"|"concluded"]
  #   - "needs_grading_count": Optional information to include with each Course.
  #     When needs_grading_count is given, and the current user has grading
  #     rights, the total number of submissions needing grading for all
  #     assignments is returned.
  #   - "syllabus_body": Optional information to include with each Course.
  #     When syllabus_body is given the user-generated html for the course
  #     syllabus is returned.
  #   - "public_description": Optional information to include with each Course.
  #     When public_description is given the user-generated text for the course
  #     public description is returned.
  #   - "total_scores": Optional information to include with each Course.
  #     When total_scores is given, any student enrollments will also
  #     include the fields 'computed_current_score', 'computed_final_score',
  #     'computed_current_grade', and 'computed_final_grade' (see Enrollment
  #     documentation for more information on these fields). This argument
  #     is ignored if the course is configured to hide final grades.
  #   - "current_grading_period_scores": Optional information to include with
  #     each Course. When current_grading_period_scores is given and total_scores
  #     is given, any student enrollments will also include the fields
  #     'has_grading_periods',
  #     'totals_for_all_grading_periods_option', 'current_grading_period_title',
  #     'current_grading_period_id', current_period_computed_current_score',
  #     'current_period_computed_final_score',
  #     'current_period_computed_current_grade', and
  #     'current_period_computed_final_grade', as well as (if the user has permission)
  #     'current_period_unposted_current_score',
  #     'current_period_unposted_final_score',
  #     'current_period_unposted_current_grade', and
  #     'current_period_unposted_final_grade' (see Enrollment documentation for
  #     more information on these fields). In addition, when this argument is
  #     passed, the course will have a 'has_grading_periods' attribute
  #     on it. This argument is ignored if the course is configured to hide final
  #     grades or if the total_scores argument is not included.
  #   - "grading_periods": Optional information to include with each Course. When
  #     grading_periods is given, a list of the grading periods associated with
  #     each course is returned.
  #   - "term": Optional information to include with each Course. When
  #     term is given, the information for the enrollment term for each course
  #     is returned.
  #   - "account": Optional information to include with each Course. When
  #     account is given, the account json for each course is returned.
  #   - "course_progress": Optional information to include with each Course.
  #     When course_progress is given, each course will include a
  #     'course_progress' object with the fields: 'requirement_count', an integer
  #     specifying the total number of requirements in the course,
  #     'requirement_completed_count', an integer specifying the total number of
  #     requirements in this course that have been completed, and
  #     'next_requirement_url', a string url to the next requirement item, and
  #     'completed_at', the date the course was completed (null if incomplete).
  #     'next_requirement_url' will be null if all requirements have been
  #     completed or the current module does not require sequential progress.
  #     "course_progress" will return an error message if the course is not
  #     module based or the user is not enrolled as a student in the course.
  #   - "sections": Section enrollment information to include with each Course.
  #     Returns an array of hashes containing the section ID (id), section name
  #     (name), start and end dates (start_at, end_at), as well as the enrollment
  #     type (enrollment_role, e.g. 'StudentEnrollment').
  #   - "storage_quota_used_mb": The amount of storage space used by the files in this course
  #   - "total_students": Optional information to include with each Course.
  #     Returns an integer for the total amount of active and invited students.
  #   - "passback_status": Include the grade passback_status
  #   - "favorites": Optional information to include with each Course.
  #     Indicates if the user has marked the course as a favorite course.
  #   - "teachers": Teacher information to include with each Course.
  #     Returns an array of hashes containing the {api:Users:UserDisplay UserDisplay} information
  #     for each teacher in the course.
  #   - "observed_users": Optional information to include with each Course.
  #     Will include data for observed users if the current user has an
  #     observer enrollment.
  #   - "tabs": Optional information to include with each Course.
  #     Will include the list of tabs configured for each course.  See the
  #     {api:TabsController#index List available tabs API} for more information.
  #   - "course_image": Optional information to include with each Course. Returns course
  #     image url if a course image has been set.
  #   - "banner_image": Optional information to include with each Course. Returns course
  #     banner image url if the course is a Canvas for Elementary subject and a banner
  #     image has been set.
  #   - "concluded": Optional information to include with each Course. Indicates whether
  #     the course has been concluded, taking course and term dates into account.
  #
  # @argument state[] [String, "unpublished"|"available"|"completed"|"deleted"]
  #   If set, only return courses that are in the given state(s).
  #   By default, "available" is returned for students and observers, and
  #   anything except "deleted", for all other enrollment types
  #
  # @argument enrollment_state [String, "active"|"invited_or_pending"|"completed"]
  #   When set, only return courses where the user has an enrollment with the given state.
  #   This will respect section/course/term date overrides.
  #
  # @argument homeroom [Optional, Boolean]
  #   If set, only return homeroom courses.
  #
  # @argument account_id [Optional, String]
  #   If set, only include courses associated with this account
  #
  # @returns [Course]
  def user_index
    GuardRail.activate(:secondary) do
      render json: courses_for_user(@user, paginate_url: api_v1_user_courses_url(@user))
    end
  end

  # @API Get user progress
  # Return progress information for the user and course
  #
  # You can supply +self+ as the user_id to query your own progress in a course. To query another user's progress,
  # you must be a teacher in the course, an administrator, or a linked observer of the user.
  #
  # @returns CourseProgress
  def user_progress
    # NOTE: this endpoint must remain on the primary db since it's queried in response to a live event
    target_user = api_find(@context.users, params[:user_id])
    if @context.grants_right?(@current_user, session, :view_all_grades) || target_user.grants_right?(@current_user, session, :read)
      json = CourseProgress.new(@context, target_user, read_only: true).to_json
      render json:, status: json.key?(:error) ? :bad_request : :ok
    else
      render_unauthorized_action
    end
  end

  # @API Create a new course
  # Create a new course
  #
  # @argument course[name] [String]
  #   The name of the course. If omitted, the course will be named "Unnamed
  #   Course."
  #
  # @argument course[course_code] [String]
  #   The course code for the course.
  #
  # @argument course[start_at] [DateTime]
  #   Course start date in ISO8601 format, e.g. 2011-01-01T01:00Z
  #   This value is ignored unless 'restrict_enrollments_to_course_dates' is set to true.
  #
  # @argument course[end_at] [DateTime]
  #   Course end date in ISO8601 format. e.g. 2011-01-01T01:00Z
  #   This value is ignored unless 'restrict_enrollments_to_course_dates' is set to true.
  #
  # @argument course[license] [String]
  #   The name of the licensing. Should be one of the following abbreviations
  #   (a descriptive name is included in parenthesis for reference):
  #   - 'private' (Private Copyrighted)
  #   - 'cc_by_nc_nd' (CC Attribution Non-Commercial No Derivatives)
  #   - 'cc_by_nc_sa' (CC Attribution Non-Commercial Share Alike)
  #   - 'cc_by_nc' (CC Attribution Non-Commercial)
  #   - 'cc_by_nd' (CC Attribution No Derivatives)
  #   - 'cc_by_sa' (CC Attribution Share Alike)
  #   - 'cc_by' (CC Attribution)
  #   - 'public_domain' (Public Domain).
  #
  # @argument course[is_public] [Boolean]
  #   Set to true if course is public to both authenticated and unauthenticated users.
  #
  # @argument course[is_public_to_auth_users] [Boolean]
  #   Set to true if course is public only to authenticated users.
  #
  # @argument course[public_syllabus] [Boolean]
  #   Set to true to make the course syllabus public.
  #
  # @argument course[public_syllabus_to_auth] [Boolean]
  #   Set to true to make the course syllabus public for authenticated users.
  #
  # @argument course[public_description] [String]
  #   A publicly visible description of the course.
  #
  # @argument course[allow_student_wiki_edits] [Boolean]
  #   If true, students will be able to modify the course wiki.
  #
  # @argument course[allow_wiki_comments] [Boolean]
  #   If true, course members will be able to comment on wiki pages.
  #
  # @argument course[allow_student_forum_attachments] [Boolean]
  #   If true, students can attach files to forum posts.
  #
  # @argument course[open_enrollment] [Boolean]
  #   Set to true if the course is open enrollment.
  #
  # @argument course[self_enrollment] [Boolean]
  #   Set to true if the course is self enrollment.
  #
  # @argument course[restrict_enrollments_to_course_dates] [Boolean]
  #   Set to true to restrict user enrollments to the start and end dates of the
  #   course. This value must be set to true
  #   in order to specify a course start date and/or end date.
  #
  # @argument course[term_id] [String]
  #   The unique ID of the term to create to course in.
  #
  # @argument course[sis_course_id] [String]
  #   The unique SIS identifier.
  #
  # @argument course[integration_id] [String]
  #   The unique Integration identifier.
  #
  # @argument course[hide_final_grades] [Boolean]
  #   If this option is set to true, the totals in student grades summary will
  #   be hidden.
  #
  # @argument course[apply_assignment_group_weights] [Boolean]
  #   Set to true to weight final grade based on assignment groups percentages.
  #
  # @argument course[time_zone] [String]
  #   The time zone for the course. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument offer [Boolean]
  #   If this option is set to true, the course will be available to students
  #   immediately.
  #
  # @argument enroll_me [Boolean]
  #   Set to true to enroll the current user as the teacher.
  #
  # @argument course[default_view]  [String, "feed"|"wiki"|"modules"|"syllabus"|"assignments"]
  #   The type of page that users will see when they first visit the course
  #   * 'feed' Recent Activity Dashboard
  #   * 'modules' Course Modules/Sections Page
  #   * 'assignments' Course Assignments List
  #   * 'syllabus' Course Syllabus Page
  #   other types may be added in the future
  #
  # @argument course[syllabus_body] [String]
  #   The syllabus body for the course
  #
  # @argument course[grading_standard_id] [Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
  #
  # @argument course[grade_passback_setting] [String]
  #   Optional. The grade_passback_setting for the course. Only 'nightly_sync', 'disabled', and '' are allowed
  #
  # @argument course[course_format] [String]
  #   Optional. Specifies the format of the course. (Should be 'on_campus', 'online', or 'blended')
  #
  # @argument enable_sis_reactivation [Boolean]
  #   When true, will first try to re-activate a deleted course with matching sis_course_id if possible.
  #
  # @returns Course
  def create
    @account = params[:account_id] ? api_find(Account, params[:account_id]) : @domain_root_account.manually_created_courses_account

    if authorized_action(@account, @current_user, [:manage_courses, :create_courses])
      params[:course] ||= {}
      params_for_create = course_params

      if params_for_create.key?(:syllabus_body)
        begin
          params_for_create[:syllabus_body] = process_incoming_html_content(params_for_create[:syllabus_body])
        rescue Api::Html::UnparsableContentError => e
          return render json: { errors: { unparsable_content: e.message } }, status: :bad_request
        end
      end

      if (sub_account_id = params[:course].delete(:account_id)) && sub_account_id.to_i != @account.id
        @sub_account = @account.find_child(sub_account_id)
      end

      term_id = params[:course].delete(:term_id).presence || params[:course].delete(:enrollment_term_id).presence
      params_for_create[:enrollment_term] = api_find(@account.root_account.enrollment_terms, term_id) if term_id

      sis_course_id = params[:course].delete(:sis_course_id)
      apply_assignment_group_weights = params[:course].delete(:apply_assignment_group_weights)

      # accept end_at as an alias for conclude_at. continue to accept
      # conclude_at for legacy support, and return conclude_at only if
      # the user uses that name.
      course_end = if params[:course][:end_at].present?
                     params_for_create[:conclude_at] = params[:course].delete(:end_at)
                     :end_at
                   else
                     :conclude_at
                   end

      # If Term enrollment is specified, don't allow setting enrollment dates
      params_for_create = params_for_create.except(:start_at, :conclude_at) unless value_to_boolean(params_for_create[:restrict_enrollments_to_course_dates])

      unless @account.grants_right? @current_user, session, :manage_storage_quotas
        params_for_create.delete :storage_quota
        params_for_create.delete :storage_quota_mb
      end

      # Hang on... caller may not have permission to manage course visibility
      # settings. If not, make sure any attempt doesn't see the light of day.
      unless course_permission_to?("manage_course_visibility", @account)
        params_for_create.delete :public_syllabus
        params_for_create.delete :is_public_to_auth_users
        params_for_create.delete :public_syllabus_to_auth
        params_for_create[:is_public] = false
      end

      can_manage_sis = api_request? && @account.grants_right?(@current_user, :manage_sis)
      if can_manage_sis && value_to_boolean(params[:enable_sis_reactivation])
        @course = @domain_root_account.all_courses.where(
          sis_source_id: sis_course_id, workflow_state: "deleted"
        ).first
        if @course
          @course.workflow_state = "claimed"
          @course.account = @sub_account if @sub_account
        end
      end
      @course ||= (@sub_account || @account).courses.build(params_for_create)

      if can_manage_sis
        @course.sis_source_id = sis_course_id
      end

      if apply_assignment_group_weights
        @course.apply_assignment_group_weights = value_to_boolean apply_assignment_group_weights
      end

      if params_for_create.key?(:grade_passback_setting)
        grade_passback_setting = params_for_create.delete(:grade_passback_setting)
        update_grade_passback_setting(grade_passback_setting)
      end

      changes = changed_settings(@course.changes, @course.settings)

      respond_to do |format|
        if @course.save
          Auditors::Course.record_created(@course, @current_user, changes, source: (api_request? ? :api : :manual))
          @course.enroll_user(@current_user, "TeacherEnrollment", enrollment_state: "active") if params[:enroll_me].to_s == "true"
          @course.require_assignment_group rescue nil
          # offer updates the workflow state, saving the record without doing validation callbacks
          if api_request? && value_to_boolean(params[:offer])
            return unless verified_user_check

            @course.offer
            Auditors::Course.record_published(@course, @current_user, source: :api)
          end
          # Sync homeroom enrollments and participation if enabled and the course isn't a SIS import
          if @course.elementary_enabled? && value_to_boolean(params[:course][:sync_enrollments_from_homeroom]) && params[:course][:homeroom_course_id] && @course.sis_batch_id.blank?
            progress = Progress.new(context: @course, tag: :sync_homeroom_enrollments)
            progress.user = @current_user
            progress.reset!
            progress.process_job(@course, :sync_homeroom_enrollments, { priority: Delayed::LOW_PRIORITY })
            # Participation sync should be done in the normal request flow, as it only needs to update a couple of
            # specific fields, delegating that to a job will cause the controller to return the old values, which will
            # force the user to refresh the page after the job finishes to see the changes
            @course.sync_homeroom_participation
          end
          format.html { redirect_to @course }
          format.json do
            render json: course_json(
              @course,
              @current_user,
              session,
              [:start_at,
               course_end,
               :license,
               :is_public,
               :is_public_to_auth_users,
               :public_syllabus,
               :public_syllabus_to_auth,
               :allow_student_assignment_edits,
               :allow_wiki_comments,
               :allow_student_forum_attachments,
               :open_enrollment,
               :self_enrollment,
               :root_account_id,
               :account_id,
               :public_description,
               :restrict_enrollments_to_course_dates,
               :hide_final_grades],
              nil,
              prefer_friendly_name: false
            )
          end
        else
          flash[:error] = t("errors.create_failed", "Course creation failed")
          format.html { redirect_to :root_url }
          format.json { render json: @course.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Upload a file
  #
  # Upload a file to the course.
  #
  # This API endpoint is the first step in uploading a file to a course.
  # See the {file:file_uploads.html File Upload Documentation} for details on
  # the file upload workflow.
  #
  # Only those with the "Manage Files" permission on a course can upload files
  # to the course. By default, this is Teachers, TAs and Designers.
  def create_file
    @attachment = Attachment.new(context: @context)
    if authorized_action(@attachment, @current_user, :create)
      api_attachment_preflight(@context, request, check_quota: true)
    end
  end

  def unconclude
    get_context
    if authorized_action(@context, @current_user, [:change_course_state, :manage_courses_conclude])
      @context.unconclude
      Auditors::Course.record_unconcluded(@context, @current_user, source: (api_request? ? :api : :manual))
      flash[:notice] = t("notices.unconcluded", "Course un-concluded")
      redirect_to(named_context_url(@context, :context_url))
    end
  end

  include Api::V1::User

  # @API List students
  #
  # Returns the paginated list of students enrolled in this course.
  #
  # DEPRECATED: Please use the {api:CoursesController#users course users} endpoint
  # and pass "student" as the enrollment_type.
  #
  # @returns [User]
  def students
    # DEPRECATED. Needs to stay separate from #users though, because this is un-paginated
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      proxy = @context.students.order_by_sortable_name
      user_json_preloads(proxy, false)
      render json: proxy.map { |u| user_json(u, @current_user, session) }
    end
  end

  # @API List users in course
  # Returns the paginated list of users in this course. And optionally the user's enrollments in the course.
  #
  # @argument search_term [String]
  #   The partial name or full ID of the users to match and return in the results list.
  #
  # @argument sort [String, "username"|"last_login"|"email"|"sis_id"]
  #   When set, sort the results of the search based on the given field.
  #
  # @argument enrollment_type[] [String, "teacher"|"student"|"student_view"|"ta"|"observer"|"designer"]
  #   When set, only return users where the user is enrolled as this type.
  #   "student_view" implies include[]=test_student.
  #   This argument is ignored if enrollment_role is given.
  #
  # @argument enrollment_role [String] Deprecated
  #   When set, only return users enrolled with the specified course-level role.  This can be
  #   a role created with the {api:RoleOverridesController#add_role Add Role API} or a
  #   base role type of 'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment',
  #   'ObserverEnrollment', or 'DesignerEnrollment'.
  #
  # @argument enrollment_role_id [Integer]
  #   When set, only return courses where the user is enrolled with the specified
  #   course-level role.  This can be a role created with the
  #   {api:RoleOverridesController#add_role Add Role API} or a built_in role id with type
  #   'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'ObserverEnrollment',
  #   or 'DesignerEnrollment'.
  #
  # @argument include[] [String, "enrollments"|"locked"|"avatar_url"|"test_student"|"bio"|"custom_links"|"current_grading_period_scores"|"uuid"]
  #   - "enrollments":
  #   Optionally include with each Course the user's current and invited
  #   enrollments. If the user is enrolled as a student, and the account has
  #   permission to manage or view all grades, each enrollment will include a
  #   'grades' key with 'current_score', 'final_score', 'current_grade' and
  #   'final_grade' values.
  #   - "locked": Optionally include whether an enrollment is locked.
  #   - "avatar_url": Optionally include avatar_url.
  #   - "bio": Optionally include each user's bio.
  #   - "test_student": Optionally include the course's Test Student,
  #   if present. Default is to not include Test Student.
  #   - "custom_links": Optionally include plugin-supplied custom links for each student,
  #   such as analytics information
  #   - "current_grading_period_scores": if enrollments is included as
  #   well as this directive, the scores returned in the enrollment
  #   will be for the current grading period if there is one. A
  #   'grading_period_id' value will also be included with the
  #   scores. if grading_period_id is nil there is no current grading
  #   period and the score is a total score.
  #   - "uuid": Optionally include the users uuid
  #
  # @argument user_id [String]
  #   If this parameter is given and it corresponds to a user in the course,
  #   the +page+ parameter will be ignored and the page containing the specified user
  #   will be returned instead.
  #
  # @argument user_ids[] [Integer]
  #   If included, the course users set will only include users with IDs
  #   specified by the param. Note: this will not work in conjunction
  #   with the "user_id" argument but multiple user_ids can be included.
  #
  # @argument enrollment_state[] [String, "active"|"invited"|"rejected"|"completed"|"inactive"]
  #  When set, only return users where the enrollment workflow state is of one of the given types.
  #  "active" and "invited" enrollments are returned by default.
  # @returns [User]
  def users
    GuardRail.activate(:secondary) do
      get_context
      if authorized_action(@context, @current_user, %i[read_roster view_all_grades manage_grades])
        log_api_asset_access(["roster", @context], "roster", "other")
        # backcompat limit param
        params[:per_page] ||= params[:limit]

        search_params = params.slice(:search_term, :enrollment_role, :enrollment_role_id, :enrollment_type, :enrollment_state, :sort)
        include_inactive = @context.grants_right?(@current_user, session, :read_as_admin) && value_to_boolean(params[:include_inactive])

        search_params[:include_inactive_enrollments] = true if include_inactive
        search_term = search_params[:search_term].presence

        users = if search_term
                  UserSearch.for_user_in_context(search_term, @context, @current_user, session, search_params)
                else
                  UserSearch.scope_for(@context, @current_user, search_params)
                end

        # If a user_id is passed in, modify the page parameter so that the page
        # that contains that user is returned.
        # We delete it from params so that it is not maintained in pagination links.
        user_id = params[:user_id]
        if user_id.present? && (user = users.where(users: { id: user_id }).first)
          position_scope = users.where("#{User.sortable_name_order_by_clause}<=#{User.best_unicode_collation_key("?")}",
                                       user.sortable_name)
          position = position_scope.distinct.count(:all)
          per_page = Api.per_page_for(self)
          params[:page] = (position.to_f / per_page.to_f).ceil
        end

        user_ids = params[:user_ids]
        if user_ids.present?
          user_ids = user_ids.split(",") if user_ids.is_a?(String)
          users = users.where(id: user_ids)
        end

        user_uuids = params[:user_uuids]
        if user_uuids.present?
          user_uuids = user_uuids.split(",") if user_uuids.is_a?(String)
          users = users.where(uuid: user_uuids)
        end

        # don't calculate a total count/last page for this endpoint.
        # total_entries: nil
        users = Api.paginate(users, self, api_v1_course_users_url, { total_entries: nil })
        includes = Array(params[:include]).push("sis_user_id", "email")

        # user_json_preloads loads both active/accepted and deleted
        # group_memberships when passed "group_memberships: true." In a
        # known case in the wild, each student had thousands of deleted
        # group memberships. Since we only care about active group
        # memberships for this course, load the data in a more targeted way.
        user_json_preloads(users, includes.include?("email"))
        UserPastLtiId.manual_preload_past_lti_ids(users, @context) if ["uuid", "lti_id"].any? { |id| includes.include? id }
        include_group_ids = includes.delete("group_ids").present?

        unless includes.include?("test_student") || Array(params[:enrollment_type]).include?("student_view")
          users.reject! do |u|
            u.preferences[:fake_student]
          end
        end
        if includes.include?("enrollments")
          enrollment_scope = @context.enrollments
                                     .where(user_id: users)
                                     .preload(:course, :scores)

          enrollment_scope = if search_params[:enrollment_state]
                               enrollment_scope.where(workflow_state: search_params[:enrollment_state])
                             elsif include_inactive
                               enrollment_scope.all_active_or_pending
                             else
                               enrollment_scope.active_or_pending
                             end
          enrollments_by_user = enrollment_scope.group_by(&:user_id)
        else
          confirmed_user_ids = @context.enrollments.where.not(workflow_state: %w[invited creation_pending rejected])
                                       .where(user_id: users).distinct.pluck(:user_id)
        end

        render json: users.map { |u|
          enrollments = enrollments_by_user[u.id] || [] if includes.include?("enrollments")
          user_unconfirmed = if enrollments
                               enrollments.all? { |e| %w[invited creation_pending rejected].include?(e.workflow_state) }
                             else
                               !confirmed_user_ids.include?(u.id)
                             end
          excludes = user_unconfirmed ? %w[pseudonym personal_info] : []
          if @context.sections_hidden_on_roster_page?(current_user: @current_user)
            excludes.append("course_section_id")
          end
          user_json(u, @current_user, session, includes, @context, enrollments, excludes).tap do |json|
            json[:group_ids] = active_group_memberships(users)[u.id]&.map(&:group_id) || [] if include_group_ids
          end
        }
      end
    end
  end

  # @API List recently logged in students
  #
  # Returns the paginated list of users in this course, ordered by how recently they have
  # logged in. The records include the 'last_login' field which contains
  # a timestamp of the last time that user logged into canvas.  The querying
  # user must have the 'View usage reports' permission.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/<course_id>/recent_users
  #
  # @returns [User]
  def recent_students
    get_context
    if authorized_action(@context, @current_user, :read_reports)
      scope = User.for_course_with_last_login(@context, @context.root_account_id, "StudentEnrollment")
      scope = scope.order("last_login DESC NULLS LAST")
      users = Api.paginate(scope, self, api_v1_course_recent_students_url)
      user_json_preloads(users)
      render json: users.map { |u| user_json(u, @current_user, session, ["last_login"]) }
    end
  end

  # @API Get single user
  # Return information on a single user.
  #
  # Accepts the same include[] parameters as the :users: action, and returns a
  # single user with the same fields as that action.
  #
  # @returns User
  def user
    get_context
    if authorized_action(@context, @current_user, :read_roster)
      includes = Array(params[:include])
      users = api_find_all(@context.users_visible_to(@current_user, {
                                                       include_inactive: includes.include?("inactive_enrollments")
                                                     }),
                           [params[:id]])

      user_json_preloads(users, includes.include?("email"))
      user = users.first or raise ActiveRecord::RecordNotFound
      enrollments = user.not_ended_enrollments.where(course_id: @context).preload(:course, :root_account, :sis_pseudonym) if includes.include?("enrollments")
      render json: user_json(user, @current_user, session, includes, @context, enrollments)
    end
  end

  # @API Search for content share users
  #
  # Returns a paginated list of users you can share content with.  Requires the content share
  # feature and the user must have the manage content permission for the course.
  #
  # @argument search_term [Required, String]
  #   Term used to find users.  Will search available share users with the search term in their name.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/<course_id>/content_share_users \
  #          -d 'search_term=smith'
  #
  # @returns [User]
  def content_share_users
    get_context
    reject!("Search term required") unless params[:search_term]
    return unless authorized_action(@context, @current_user, :read_as_admin)

    users_scope = User.shard(Shard.current).has_created_account.distinct
    union_scope = teacher_scope(name_scope(users_scope), @context.root_account_id)
                  .union(
                    teacher_scope(email_scope(users_scope), @context.root_account_id),
                    admin_scope(name_scope(users_scope), @context.root_account_id).merge(Role.full_account_admin),
                    admin_scope(email_scope(users_scope), @context.root_account_id).merge(Role.full_account_admin),
                    admin_scope(name_scope(users_scope), @context.root_account_id).merge(Role.custom_account_admin_with_permission("manage_content")),
                    admin_scope(email_scope(users_scope), @context.root_account_id).merge(Role.custom_account_admin_with_permission("manage_content"))
                  )
                  .order(:name)
                  .distinct
    users = Api.paginate(union_scope, self, api_v1_course_content_share_users_url)
    render json: users_json(users, @current_user, session, ["avatar_url", "email"], @context, nil, ["pseudonym"])
  end

  def admin_scope(scope, root_account_id)
    scope.joins(account_users: [:account, :role])
         .merge(AccountUser.active)
         .merge(Account.active)
         .where("accounts.id = ? OR accounts.root_account_id = ?", root_account_id, root_account_id)
  end

  def teacher_scope(scope, root_account_id)
    scope.joins(enrollments: :course)
         .merge(Enrollment.active.of_admin_type)
         .merge(Course.active)
         .where(courses: { root_account_id: })
  end

  def name_scope(scope)
    scope.where(UserSearch.like_condition("users.name"), pattern: UserSearch.like_string_for(params[:search_term]))
  end

  def email_scope(scope)
    scope.joins(:communication_channels)
         .where(communication_channels: { workflow_state: ["active", "unconfirmed"], path_type: "email" })
         .where(UserSearch.like_condition("communication_channels.path"), pattern: UserSearch.like_string_for(params[:search_term]))
  end

  include Api::V1::PreviewHtml
  # @API Preview processed html
  #
  # Preview html content processed for this course
  #
  # @argument html The html content to process
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/preview_html \
  #          -F 'html=<p><badhtml></badhtml>processed html</p>' \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "html": "<p>processed html</p>"
  #   }
  def preview_html
    get_context
    if @context && authorized_action(@context, @current_user, :read)
      render_preview_html
    end
  end

  include Api::V1::StreamItem
  # @API Course activity stream
  # Returns the current user's course-specific activity stream, paginated.
  #
  # For full documentation, see the API documentation for the user activity
  # stream, in the user api.
  def activity_stream
    get_context
    if authorized_action(@context, @current_user, :read)
      api_render_stream(contexts: [@context], paginate_url: :api_v1_course_activity_stream_url)
    end
  end

  # @API Course activity stream summary
  # Returns a summary of the current user's course-specific activity stream.
  #
  # For full documentation, see the API documentation for the user activity
  # stream summary, in the user api.
  def activity_stream_summary
    get_context
    if authorized_action(@context, @current_user, :read)
      api_render_stream_summary(contexts: [@context])
    end
  end

  include Api::V1::TodoItem
  # @API Course TODO items
  # Returns the current user's course-specific todo items.
  #
  # For full documentation, see the API documentation for the user todo items, in the user api.
  def todo_items
    GuardRail.activate(:secondary) do
      get_context
      if authorized_action(@context, @current_user, :read)
        bookmark = Plannable::Bookmarker.new(Assignment, false, [:due_at, :created_at], :id)

        grading_scope = @current_user.assignments_needing_grading(contexts: [@context], scope_only: true)
                                     .reorder(:due_at, :id).preload(:external_tool_tag, :rubric_association, :rubric, :discussion_topic, :quiz, :duplicate_of)
        submitting_scope = @current_user
                           .assignments_needing_submitting(
                             contexts: [@context],
                             include_ungraded: true,
                             scope_only: true
                           )
                           .reorder(:due_at, :id).preload(:external_tool_tag, :rubric_association, :rubric, :discussion_topic, :quiz).eager_load(:duplicate_of)

        grading_collection = BookmarkedCollection.wrap(bookmark, grading_scope)
        grading_collection = BookmarkedCollection.transform(grading_collection) do |a|
          todo_item_json(a, @current_user, session, "grading")
        end
        submitting_collection = BookmarkedCollection.wrap(bookmark, submitting_scope)
        submitting_collection = BookmarkedCollection.transform(submitting_collection) do |a|
          todo_item_json(a, @current_user, session, "submitting")
        end

        collections = [
          ["grading", grading_collection],
          ["submitting", submitting_collection]
        ]

        if Array(params[:include]).include? "ungraded_quizzes"
          quizzes_bookmark = Plannable::Bookmarker.new(Quizzes::Quiz, false, [:due_at, :created_at], :id)
          quizzes_scope = @current_user
                          .ungraded_quizzes(
                            contexts: [@context],
                            needing_submitting: true,
                            scope_only: true
                          )
                          .reorder(:due_at, :id)
          quizzes_collection = BookmarkedCollection.wrap(quizzes_bookmark, quizzes_scope)
          quizzes_collection = BookmarkedCollection.transform(quizzes_collection) do |a|
            todo_item_json(a, @current_user, session, "submitting")
          end

          collections << ["quizzes", quizzes_collection]
        end

        paginated_collection = BookmarkedCollection.merge(*collections)
        todos = Api.paginate(paginated_collection, self, api_v1_course_todo_list_items_url)

        render json: todos
      end
    end
  end

  # @API Delete/Conclude a course
  # Delete or conclude an existing course
  #
  # @argument event [Required, String, "delete"|"conclude"]
  #   The action to take on the course.
  #
  # @example_response
  #   { "delete": "true" }
  def destroy
    @context = api_find(Course, params[:id])
    if api_request? && !["delete", "conclude"].include?(params[:event])
      return render(json: { message: 'Only "delete" and "conclude" events are allowed.' }, status: :bad_request)
    end
    return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))

    if params[:event] != "conclude" && (@context.created? || @context.claimed? || params[:event] == "delete")
      if (success = @context.destroy)
        Auditors::Course.record_deleted(@context, @current_user, source: (api_request? ? :api : :manual))
        flash[:notice] = t("notices.deleted", "Course successfully deleted")
      else
        flash[:notice] = t("Course cannot be deleted")
      end
    else
      @context.complete
      if (success = @context.save)
        Auditors::Course.record_concluded(@context, @current_user, source: (api_request? ? :api : :manual))
        flash[:notice] = t("notices.concluded", "Course successfully concluded")
      else
        flash[:notice] = t("notices.failed_conclude", "Course failed to conclude")
      end
    end
    @current_user.touch
    respond_to do |format|
      format.html { redirect_to dashboard_url }
      format.json do
        render json: { params[:event] => success }, status: success ? 200 : 400
      end
    end
  end

  def statistics
    if authorized_action(@context, @current_user, :read_reports)
      @student_ids = @context.student_ids

      query = "SELECT COUNT(id), SUM(size) FROM #{Attachment.quoted_table_name} WHERE context_id=%s AND context_type='Course' AND root_attachment_id IS NULL AND file_state != 'deleted'"
      row = Attachment.connection.select_rows(query % [@context.id]).first
      @file_count, @files_size = [row[0].to_i, row[1].to_i]
      query = "SELECT COUNT(id), SUM(max_size) FROM #{MediaObject.quoted_table_name} WHERE context_id=%s AND context_type='Course' AND attachment_id IS NULL AND workflow_state != 'deleted'"
      row = MediaObject.connection.select_rows(query % [@context.id]).first
      @media_file_count, @media_files_size = [row[0].to_i, row[1].to_i]

      respond_to do |format|
        format.html do
          js_env(RECENT_STUDENTS_URL: api_v1_course_recent_students_url(@context))
        end
        format.json { render json: @categories }
      end
    end
  end

  # @API Get course settings
  # Returns some of a course's settings.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/settings \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "allow_student_discussion_topics": true,
  #     "allow_student_forum_attachments": false,
  #     "allow_student_discussion_editing": true,
  #     "grading_standard_enabled": true,
  #     "grading_standard_id": 137,
  #     "allow_student_organized_groups": true,
  #     "hide_final_grades": false,
  #     "hide_distribution_graphs": false,
  #     "hide_sections_on_course_users_page": false,
  #     "lock_all_announcements": true,
  #     "usage_rights_required": false,
  #     "homeroom_course": false,
  #     "default_due_time": "23:59:59",
  #     "conditional_release": false
  #   }
  def api_settings
    get_context
    if authorized_action @context, @current_user, :read
      render json: course_settings_json(@context)
    end
  end

  def settings
    if authorized_action(@context, @current_user, :read_as_admin)
      load_all_contexts(context: @context)

      @all_roles = Role.custom_roles_and_counts_for_course(@context, @current_user, true)

      @invited_count = @context.invited_count_visible_to(@current_user)

      @publishing_enabled = @context.allows_grade_publishing_by(@current_user) &&
                            can_do(@context, @current_user, :manage_grades)

      @homeroom_courses = if can_do(@context.account, @current_user, :manage_courses, :manage_courses_admin)
                            @context.account.courses.active.homeroom.to_a
                          else
                            @current_user.courses_for_enrollments(@current_user.teacher_enrollments).homeroom.to_a
                          end

      if @context.elementary_homeroom_course?
        @synced_subjects = Course.where(homeroom_course_id: @context.id).syncing_subjects.limit(100).select(&:elementary_subject_course?).sort_by { |c| Canvas::ICU.collation_key(c.name) }
      end

      @alerts = @context.alerts
      add_crumb(t("#crumbs.settings", "Settings"), named_context_url(@context, :context_details_url))

      js_permissions = {
        can_manage_courses: @context.account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin),
        manage_grading_schemes: @context.grants_right?(@current_user, session, :manage_grades),
        manage_students: @context.grants_right?(@current_user, session, :manage_students),
        manage_account_settings: @context.account.grants_right?(@current_user, session, :manage_account_settings),
        manage_feature_flags: @context.grants_right?(@current_user, session, :manage_feature_flags),
        manage: @context.grants_right?(@current_user, session, :manage),
        edit_course_availability: @context.grants_right?(@current_user, session, :edit_course_availability)
      }
      if @context.root_account.feature_enabled?(:granular_permissions_manage_users)
        js_permissions[:can_allow_course_admin_actions] = @context.grants_right?(@current_user, session, :allow_course_admin_actions)
      else
        js_permissions[:manage_admin_users] = @context.grants_right?(@current_user, session, :manage_admin_users)
      end
      if @context.root_account.feature_enabled?(:granular_permissions_manage_lti)
        js_permissions[:add_tool_manually] = @context.grants_right?(@current_user, session, :manage_lti_add)
        js_permissions[:edit_tool_manually] = @context.grants_right?(@current_user, session, :manage_lti_edit)
        js_permissions[:delete_tool_manually] = @context.grants_right?(@current_user, session, :manage_lti_delete)
      else
        js_permissions[:create_tool_manually] = @context.grants_right?(@current_user, session, :create_tool_manually)
      end
      js_env({
               COURSE_ID: @context.id,
               USERS_URL: "/api/v1/courses/#{@context.id}/users",
               ALL_ROLES: @all_roles,
               COURSE_ROOT_URL: "/courses/#{@context.id}",
               SEARCH_URL: search_recipients_url,
               CONTEXTS: @contexts,
               USER_PARAMS: { include: %w[email enrollments locked observed_users] },
               PERMISSIONS: js_permissions,
               APP_CENTER: {
                 enabled: Canvas::Plugin.find(:app_center).enabled?
               },
               LTI_LAUNCH_URL: course_tool_proxy_registration_path(@context),
               EXTERNAL_TOOLS_CREATE_URL: url_for(controller: :external_tools, action: :create, course_id: @context.id),
               TOOL_CONFIGURATION_SHOW_URL: course_show_tool_configuration_url(course_id: @context.id, developer_key_id: ":developer_key_id"),
               MEMBERSHIP_SERVICE_FEATURE_FLAG_ENABLED: @context.root_account.feature_enabled?(:membership_service_for_lti_tools),
               CONTEXT_BASE_URL: "/courses/#{@context.id}",
               COURSE_COLOR: @context.elementary_enabled? && @context.course_color,
               PUBLISHING_ENABLED: @publishing_enabled,
               COURSE_COLORS_ENABLED: @context.elementary_enabled?,
               COURSE_VISIBILITY_OPTION_DESCRIPTIONS: @context.course_visibility_option_descriptions,
               STUDENTS_ENROLLMENT_DATES: @context.enrollment_term&.enrollment_dates_overrides&.detect { |term| term[:enrollment_type] == "StudentEnrollment" }&.slice(:start_at, :end_at),
               DEFAULT_TERM_DATES: @context.enrollment_term&.slice(:start_at, :end_at),
               COURSE_DATES: { start_at: @context.start_at, end_at: @context.conclude_at },
               RESTRICT_STUDENT_PAST_VIEW_LOCKED: @context.account.restrict_student_past_view[:locked],
               RESTRICT_STUDENT_FUTURE_VIEW_LOCKED: @context.account.restrict_student_future_view[:locked],
               CAN_EDIT_RESTRICT_QUANTITATIVE_DATA: @context.restrict_quantitative_data_setting_changeable?,
               PREVENT_COURSE_AVAILABILITY_EDITING_BY_TEACHERS: @context.root_account.settings[:prevent_course_availability_editing_by_teachers],
               MANUAL_MSFT_SYNC_COOLDOWN: MicrosoftSync::Group.manual_sync_cooldown,
               MSFT_SYNC_ENABLED: !!@context.root_account.settings[:microsoft_sync_enabled],
               MSFT_SYNC_CAN_BYPASS_COOLDOWN: Account.site_admin.account_users_for(@current_user).present?,
               MSFT_SYNC_MAX_ENROLLMENT_MEMBERS: MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_MEMBERS,
               MSFT_SYNC_MAX_ENROLLMENT_OWNERS: MicrosoftSync::MembershipDiff::MAX_ENROLLMENT_OWNERS,
               COURSE_PACES_ENABLED: @context.enable_course_paces?,
               ARCHIVED_GRADING_SCHEMES_ENABLED: Account.site_admin.feature_enabled?(:archived_grading_schemes),
             })

      set_tutorial_js_env

      master_template = @context.master_course_templates.for_full_course.first
      restrictions_by_object_type = master_template&.default_restrictions_by_type_for_api || {}
      message = !MasterCourses::MasterTemplate.is_master_course?(@context) && why_cant_i_enable_master_course(@context)
      message ||= ""
      js_env({
               IS_MASTER_COURSE: MasterCourses::MasterTemplate.is_master_course?(@context),
               DISABLED_BLUEPRINT_MESSAGE: message,
               BLUEPRINT_RESTRICTIONS: master_template&.default_restrictions || { content: true },
               USE_BLUEPRINT_RESTRICTIONS_BY_OBJECT_TYPE: master_template&.use_default_restrictions_by_type || false,
               BLUEPRINT_RESTRICTIONS_BY_OBJECT_TYPE: restrictions_by_object_type
             })

      @course_settings_sub_navigation_tools = Lti::ContextToolFinder.new(
        @context,
        type: :course_settings_sub_navigation,
        root_account: @domain_root_account,
        current_user: @current_user
      ).all_tools_sorted_array(
        exclude_admin_visibility: !@context.grants_right?(@current_user, session, :read_as_admin)
      )
    end
  end

  def update_user_engine_choice(course, selection_obj)
    new_selections = {}
    new_selections[:user_id] = {
      newquizzes_engine_selected: selection_obj[:newquizzes_engine_selected],
      expiration: selection_obj[:expiration]
    }
    new_selections.reverse_merge!(course.settings[:engine_selected])
    new_selections
  end

  def new_quizzes_selection_update
    @course = api_find(Course, params[:id])
    if @course.root_account.feature_enabled?(:newquizzes_on_quiz_page)
      old_settings = @course.settings
      key_exists = old_settings.key?(:engine_selected)
      selection_obj = {
        newquizzes_engine_selected: params[:newquizzes_engine_selected],
        expiration: Time.zone.today + 30.days
      }

      new_settings = {}

      new_settings[:engine_selected] = if key_exists
                                         update_user_engine_choice(@course, selection_obj)
                                       else
                                         { user_id: selection_obj }
                                       end
      new_settings.reverse_merge!(old_settings)
      @course.settings = new_settings
      @course.save
      render json: new_settings
    end
  end

  # @API Update course settings
  # Can update the following course settings:
  #
  # @argument allow_student_discussion_topics [Boolean]
  #   Let students create discussion topics
  #
  # @argument allow_student_forum_attachments [Boolean]
  #   Let students attach files to discussions
  #
  # @argument allow_student_discussion_editing [Boolean]
  #   Let students edit or delete their own discussion replies
  #
  # @argument allow_student_organized_groups [Boolean]
  #   Let students organize their own groups
  #
  # @argument allow_student_discussion_reporting [Boolean]
  #   Let students report offensive discussion content
  #
  # @argument allow_student_anonymous_discussion_topics [Boolean]
  #   Let students create anonymous discussion topics
  #
  # @argument filter_speed_grader_by_student_group [Boolean]
  #   Filter SpeedGrader to only the selected student group
  #
  # @argument hide_final_grades [Boolean]
  #   Hide totals in student grades summary
  #
  # @argument hide_distribution_graphs [Boolean]
  #   Hide grade distribution graphs from students
  #
  # @argument hide_sections_on_course_users_page [Boolean]
  #   Disallow students from viewing students in sections they do not belong to
  #
  # @argument lock_all_announcements [Boolean]
  #   Disable comments on announcements
  #
  # @argument usage_rights_required [Boolean]
  #   Copyright and license information must be provided for files before they are published.
  #
  # @argument restrict_student_past_view [Boolean]
  #   Restrict students from viewing courses after end date
  #
  # @argument restrict_student_future_view [Boolean]
  #   Restrict students from viewing courses before start date
  #
  # @argument show_announcements_on_home_page [Boolean]
  #   Show the most recent announcements on the Course home page (if a Wiki, defaults to five announcements, configurable via home_page_announcement_limit).
  #   Canvas for Elementary subjects ignore this setting.
  #
  # @argument home_page_announcement_limit [Integer]
  #   Limit the number of announcements on the home page if enabled via show_announcements_on_home_page
  #
  # @argument syllabus_course_summary [Boolean]
  #   Show the course summary (list of assignments and calendar events) on the syllabus page. Default is true.
  #
  # @argument default_due_time [String]
  #   Set the default due time for assignments. This is the time that will be pre-selected in the Canvas user interface
  #   when setting a due date for an assignment. It does not change when any existing assignment is due. It should be
  #   given in 24-hour HH:MM:SS format. The default is "23:59:59". Use "inherit" to inherit the account setting.
  #
  # @argument conditional_release [Boolean]
  #   Enable or disable individual learning paths for students based on assessment
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/settings \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'allow_student_discussion_topics=false'
  def update_settings
    return unless api_request?

    @course = api_find(Course, params[:course_id])
    return unless authorized_action(@course, @current_user, %i[manage_content manage_course_content_edit])

    old_settings = @course.settings

    if (default_due_time = params.delete(:default_due_time))
      @course.default_due_time = normalize_due_time(default_due_time)
    end

    # Remove the conditional release param if the account is locking the feature
    params[:conditional_release] = nil if params.key?(:conditional_release) && @course.account.conditional_release[:locked]

    @course.attributes = params.permit(
      :allow_final_grade_override,
      :allow_student_discussion_topics,
      :allow_student_forum_attachments,
      :allow_student_discussion_editing,
      :allow_student_discussion_reporting,
      :allow_student_anonymous_discussion_topics,
      :filter_speed_grader_by_student_group,
      :show_total_grade_as_points,
      :allow_student_organized_groups,
      :hide_final_grades,
      :hide_distribution_graphs,
      :hide_sections_on_course_users_page,
      :lock_all_announcements,
      :usage_rights_required,
      :restrict_student_past_view,
      :restrict_student_future_view,
      :restrict_quantitative_data,
      :show_announcements_on_home_page,
      :syllabus_course_summary,
      :home_page_announcement_limit,
      :homeroom_course,
      :sync_enrollments_from_homeroom,
      :homeroom_course_id,
      :course_color,
      :friendly_name,
      :enable_course_paces,
      :conditional_release
    )
    changes = changed_settings(@course.changes, @course.settings, old_settings)

    @course.delay_if_production(priority: Delayed::LOW_PRIORITY)
           .touch_content_if_public_visibility_changed(changes)

    disable_conditional_release if changes[:conditional_release]&.last == false

    SubmissionLifecycleManager.with_executing_user(@current_user) do
      if @course.save
        Auditors::Course.record_updated(@course, @current_user, changes, source: :api)
        render json: course_settings_json(@course)
      else
        render json: @course.errors, status: :bad_request
      end
    end
  end

  # @API Return test student for course
  #
  # Returns information for a test student in this course. Creates a test
  # student if one does not already exist for the course. The caller must have
  # permission to access the course's student view.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/student_view_student \
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def student_view_student
    get_context
    if authorized_action(@context, @current_user, :use_student_view)
      render json: user_json(@context.student_view_student, @current_user, session)
    end
  end

  def observer_pairing_codes_csv
    get_context
    return render_unauthorized_action unless @context.root_account.self_registration?
    return unless authorized_action(@context, @current_user, :generate_observer_pairing_code)

    res = CSV.generate do |csv|
      csv << [
        I18n.t("Last Name"),
        I18n.t("First Name"),
        I18n.t("SIS ID"),
        I18n.t("Pairing Code"),
        I18n.t("Expires At"),
      ]
      @context.students.each do |u|
        opc = ObserverPairingCode.create(user: u, expires_at: 1.week.from_now, code: SecureRandom.hex(3))
        row = []
        row << opc.user.last_name
        row << opc.user.first_name
        row << opc.user.pseudonym&.sis_user_id
        row << ('="' + opc.code + '"')
        row << opc.expires_at
        csv << row
      end
    end
    send_data res, type: "text/csv", filename: "#{@context.course_code}_Pairing_Codes.csv"
  end

  def update_nav
    get_context
    if authorized_action(@context, @current_user, :update)
      @context.tab_configuration = JSON.parse(params[:tabs_json]).compact
      @context.save
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_details_url) }
        format.json { render json: { update_nav: true } }
      end
    end
  end

  def re_send_invitations
    get_context
    if authorized_action(@context, @current_user, [:manage_students, manage_admin_users_perm])
      @context.delay_if_production.re_send_invitations!(@current_user)

      respond_to do |format|
        format.html { redirect_to course_settings_url }
        format.json { render json: { re_sent: true } }
      end
    end
  end

  def enrollment_invitation
    get_context

    return if check_enrollment(true)
    return !!redirect_to(course_url(@context.id)) unless @pending_enrollment

    if params[:reject]
      reject_enrollment(@pending_enrollment)
    elsif params[:accept]
      accept_enrollment(@pending_enrollment)
    else
      redirect_to course_url(@context.id)
    end
  end

  # Internal: Accept an enrollment invitation and redirect.
  #
  # enrollment - An enrollment object to accept.
  #
  # Returns nothing.
  def accept_enrollment(enrollment)
    if @current_user && enrollment.user == @current_user
      if enrollment.invited?
        GuardRail.activate(:primary) do
          SubmissionLifecycleManager.with_executing_user(@current_user) do
            enrollment.accept!
          end
        end
        @pending_enrollment = nil
        flash[:notice] = t("notices.invitation_accepted", "Invitation accepted!  Welcome to %{course}!", course: @context.name)
      end

      session[:accepted_enrollment_uuid] = enrollment.uuid

      if params[:action] == "show"
        @context_enrollment = enrollment
        enrollment = nil
        false
      else
        # Redirects back to HTTP_REFERER if it exists (so if you accept from an assignent page it will put
        # you back on the same page you were looking at). Otherwise, it redirects back to the course homepage
        redirect_back(fallback_location: course_url(@context.id))
      end
    elsif (!@current_user && enrollment.user.registered?) || !enrollment.user.email_channel
      session[:return_to] = course_url(@context.id)
      flash[:notice] = t("notices.login_to_accept", "You'll need to log in before you can accept the enrollment.")
      return redirect_to login_url(force_login: 1) if @current_user

      redirect_to login_url
    else
      # defer to CommunicationChannelsController#confirm for the logic of merging users
      redirect_to registration_confirmation_path(enrollment.user.email_channel.confirmation_code, enrollment: enrollment.uuid)
    end
  end
  protected :accept_enrollment

  # Internal: Reject an enrollment invitation and redirect.
  #
  # enrollment - An enrollment object to reject.
  #
  # Returns nothing.
  def reject_enrollment(enrollment)
    if enrollment.invited?
      GuardRail.activate(:primary) do
        enrollment.reject!
      end
      flash[:notice] = t("notices.invitation_cancelled", "Invitation canceled.")
    end

    session.delete(:enrollment_uuid)
    session[:permissions_key] = SecureRandom.uuid

    redirect_to(@current_user ? dashboard_url : root_url)
  end
  protected :reject_enrollment

  def claim_course
    if params[:verification] == @context.uuid
      session[:claim_course_uuid] = @context.uuid
      # session[:course_uuid] = @context.uuid
    end
    if session[:claim_course_uuid] == @context.uuid && @current_user && @context.state == :created
      claim_session_course(@context, @current_user)
    end
  end
  protected :claim_course

  # Protected: Check a user's enrollment in the current course and redirect
  #   them/clean up the session as needed.
  #
  # ignore_restricted_courses - if true, don't exit on enrollments to non-active,
  #   date-restricted courses.
  #
  # Returns boolean (true if parent request should be cancelled).
  def check_enrollment(ignore_restricted_courses = false)
    return false if @pending_enrollment

    if (enrollment = fetch_enrollment)
      if enrollment.state_based_on_date == :inactive && !ignore_restricted_courses
        flash[:notice] = t("notices.enrollment_not_active", "Your membership in the course, %{course}, is not yet activated", course: @context.name)
        return !!redirect_to((enrollment.workflow_state == "invited") ? courses_url : dashboard_url)
      end

      if enrollment.rejected?
        enrollment.workflow_state = "invited"
        GuardRail.activate(:primary) { enrollment.save_without_broadcasting }
      end

      if enrollment.self_enrolled?
        return !!redirect_to(registration_confirmation_path(enrollment.user.email_channel.confirmation_code, enrollment: enrollment.uuid))
      end

      session[:enrollment_uuid] = enrollment.uuid
      session[:enrollment_uuid_course_id] = enrollment.course_id
      session[:permissions_key] = SecureRandom.uuid

      @pending_enrollment = enrollment

      if @context.root_account.allow_invitation_previews?
        flash[:notice] = t("notices.preview_course", "You've been invited to join this course.  You can look around, but you'll need to accept the enrollment invitation before you can participate.")
      elsif params[:action] != "enrollment_invitation"
        # directly call the next action; it's just going to redirect anyway, so no need to have
        # an additional redirect to get to it
        params[:accept] = 1
        return enrollment_invitation
      end
    end

    if session[:accepted_enrollment_uuid].present? &&
       (enrollment = @context.enrollments.where(uuid: session[:accepted_enrollment_uuid]).first)

      if enrollment.invited?
        enrollment.accept!
        flash[:notice] = t("notices.invitation_accepted", "Invitation accepted!  Welcome to %{course}!", course: @context.name)
      end

      if session[:enrollment_uuid] == session[:accepted_enrollment_uuid]
        session.delete(:enrollment_uuid)
        session[:permissions_key] = SecureRandom.uuid
      end
      session.delete(:accepted_enrollment_uuid)
      session.delete(:enrollment_uuid_course_id)
    end

    false
  end
  protected :check_enrollment

  # Internal: Get the current user's enrollment (if any) in the requested course.
  #
  # Returns enrollment (or nil).
  def fetch_enrollment
    # Use the enrollment we already fetched, if possible
    enrollment = @context_enrollment if @context_enrollment&.pending? && (@context_enrollment.uuid == params[:invitation] || params[:invitation].blank?)
    @current_user.reload if @context_enrollment&.enrollment_state&.user_needs_touch # needed to prevent permission caching

    # Overwrite with the session enrollment, if one exists, and it's different than the current user's
    if session[:enrollment_uuid] && enrollment.try(:uuid) != session[:enrollment_uuid] &&
       params[:invitation].blank? && session[:enrollment_uuid_course_id] == @context.id

      enrollment = @context.enrollments.where(uuid: session[:enrollment_uuid], workflow_state: "invited").first
    end

    # Look for enrollments to matching temporary users
    if @current_user
      enrollment ||= @current_user.temporary_invitations.find do |invitation|
        invitation.course_id == @context.id
      end
    end

    # Look up the explicitly provided invitation
    unless params[:invitation].blank?
      enrollment ||= @context.enrollments.where("enrollments.uuid=? AND enrollments.workflow_state IN ('invited', 'rejected')", params[:invitation]).first
    end

    enrollment
  end
  protected :fetch_enrollment

  def locks
    if authorized_action(@context, @current_user, :read)
      assets = params[:assets].split(",")
      types = {}
      assets.each do |asset|
        split = asset.split("_")
        id = split.pop
        (types[split.join("_")] ||= []) << id
      end
      locks_hash = Rails.cache.fetch(["locked_for_results", @current_user, Digest::SHA256.hexdigest(params[:assets])].cache_key) do
        locks = {}
        types.each do |type, ids|
          case type
          when "assignment"
            @context.assignments.active.where(id: ids).each do |assignment|
              locks[assignment.asset_string] = assignment.locked_for?(@current_user)
            end
          when "quiz"
            @context.quizzes.active.include_assignment.where(id: ids).each do |quiz|
              locks[quiz.asset_string] = quiz.locked_for?(@current_user)
            end
          when "discussion_topic"
            @context.discussion_topics.active.where(id: ids).each do |topic|
              locks[topic.asset_string] = topic.locked_for?(@current_user)
            end
          end
        end
        locks
      end
      render json: locks_hash
    end
  end

  def self_unenrollment
    get_context
    if @context_enrollment && params[:self_unenrollment] && params[:self_unenrollment] == @context_enrollment.uuid && @context_enrollment.self_enrolled?
      @context_enrollment.conclude
      render json: ""
    else
      render json: "", status: :bad_request
    end
  end

  # DEPRECATED
  def self_enrollment
    get_context
    unless params[:self_enrollment] &&
           @context.self_enrollment_codes.include?(params[:self_enrollment]) &&
           @context.self_enrollment_code
      return redirect_to course_url(@context)
    end

    redirect_to enroll_url(@context.self_enrollment_code)
  end

  def check_pending_teacher
    store_location if @context.created?
    if session[:saved_course_uuid] == @context.uuid
      @context_just_saved = true
      session.delete(:saved_course_uuid)
    end
    return unless session[:claimed_course_uuids] && session[:claimed_enrollment_uuids]

    if session[:claimed_course_uuids].include?(@context.uuid)
      session[:claimed_enrollment_uuids].each do |uuid|
        e = @context.enrollments.where(uuid:).first
        @pending_teacher = e.user if e
      end
    end
  end
  protected :check_pending_teacher

  def check_unknown_user
    @public_view = true unless @current_user && @context.grants_right?(@current_user, session, :read_roster)
  end
  protected :check_unknown_user

  def check_for_xlist
    return false unless @current_user.present? && @context_enrollment.blank?

    xlist_enrollment_scope = @current_user.enrollments.active.joins(:course_section)
                                          .where(course_sections: { nonxlist_course_id: @context })

    if observee_selected?
      xlist_enrollment_scope = xlist_enrollment_scope.where(associated_user_id: @selected_observed_user)
    end

    xlist_enrollment = xlist_enrollment_scope.first

    if xlist_enrollment.present?
      redirect_params = {}
      redirect_params[:invitation] = params[:invitation] if params[:invitation].present?
      redirect_to course_path(xlist_enrollment.course_id, redirect_params)
      return true
    end
    false
  end
  protected :check_for_xlist

  include Api::V1::ContextModule
  include ContextModulesController::ModuleIndexHelper
  include AnnouncementsController::AnnouncementsIndexHelper

  # @API Get a single course
  # Return information on a single course.
  #
  # Accepts the same include[] parameters as the list action plus:
  #
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"public_description"|"total_scores"|"current_grading_period_scores"|"term"|"account"|"course_progress"|"sections"|"storage_quota_used_mb"|"total_students"|"passback_status"|"favorites"|"teachers"|"observed_users"|"all_courses"|"permissions"|"course_image"|"banner_image"|"concluded"|"lti_context_id"]
  #   - "all_courses": Also search recently deleted courses.
  #   - "permissions": Include permissions the current user has
  #     for the course.
  #   - "observed_users": Include observed users in the enrollments
  #   - "course_image": Include course image url if a course image has been set
  #   - "banner_image": Include course banner image url if the course is a Canvas for
  #     Elementary subject and a banner image has been set
  #   - "concluded": Optional information to include with Course. Indicates whether
  #     the course has been concluded, taking course and term dates into account.
  #   - "lti_context_id": Include course LTI tool id.
  #
  # @argument teacher_limit [Integer]
  #   The maximum number of teacher enrollments to show.
  #   If the course contains more teachers than this, instead of giving the teacher
  #   enrollments, the count of teachers will be given under a _teacher_count_ key.
  #
  # @returns Course
  def show
    GuardRail.activate(:secondary) do
      if api_request?
        includes = Set.new(Array(params[:include]))

        if params[:account_id]
          @account = api_find(Account.active, params[:account_id])
          scope = @account.associated_courses
        else
          scope = Course
        end

        unless includes.member?("all_courses")
          scope = scope.not_deleted
        end
        @context = @course = api_find(scope, params[:id])
        @context_membership = @context.enrollments.where(user_id: @current_user).except(:preload).first # for AUA

        if authorized_action(@course, @current_user, :read)
          log_asset_access(["home", @context], "home", "other", nil, @context_membership.class.to_s, context: @context)
          enrollments = @course.current_enrollments.where(user_id: @current_user).to_a
          if includes.include?("observed_users") &&
             enrollments.any?(&:assigned_observer?)
            enrollments.concat(ObserverEnrollment.observed_enrollments_for_courses(@course, @current_user))
          end

          includes << :hide_final_grades
          render json: course_json(@course, @current_user, session, includes, enrollments)
        end
        return
      end

      @context = api_find(Course.active, params[:id])

      assign_localizer
      if request.xhr?
        if authorized_action(@context, @current_user, [:read, :read_as_admin])
          render json: @context
        end
        return
      end

      if @context && @current_user
        observed_users(@current_user, session, @context.id) # sets @selected_observed_user
        context_enrollment_scope = @context.enrollments.where(user_id: @current_user)
        if observee_selected?
          context_enrollment_scope = context_enrollment_scope.where(associated_user_id: @selected_observed_user)
        end
        @context_enrollment = context_enrollment_scope.first
        js_env({ OBSERVER_OPTIONS: {
                 OBSERVED_USERS_LIST: observed_users(@current_user, session, @context.id),
                 CAN_ADD_OBSERVEE: @current_user
                                    .profile
                                    .tabs_available(@current_user, root_account: @domain_root_account)
                                    .any? { |t| t[:id] == UserProfile::TAB_OBSERVEES }
               } })

        if @context_enrollment
          @context_membership = @context_enrollment # for AUA
          @context_enrollment.course = @context
          @context_enrollment.user = @current_user
          @course_notifications_enabled = NotificationPolicyOverride.enabled_for(@current_user, @context)
        end
      end

      return if check_for_xlist

      @unauthorized_message = t("unauthorized.invalid_link", "The enrollment link you used appears to no longer be valid.  Please contact the course instructor and make sure you're still correctly enrolled.") if params[:invitation]
      GuardRail.activate(:primary) do
        claim_course if session[:claim_course_uuid] || params[:verification]
        @context.claim if @context.created?
      end
      return if check_enrollment

      check_pending_teacher
      check_unknown_user
      @user_groups = @current_user.group_memberships_for(@context) if @current_user

      if !@context.grants_right?(@current_user, session, :read) && @context.grants_right?(@current_user, session, :read_as_admin)
        return redirect_to course_settings_path(@context.id)
      end

      @context_enrollment ||= @pending_enrollment
      if @context.grants_right?(@current_user, session, :read)
        # No matter who the user is we want the course dashboard to hide the left nav
        set_k5_mode
        @show_left_side = !@context.elementary_subject_course?

        check_for_readonly_enrollment_state

        log_asset_access(["home", @context], "home", "other", nil, @context_enrollment.class.to_s, context: @context)

        check_incomplete_registration

        unless @context.elementary_subject_course?
          add_crumb(@context.nickname_for(@current_user, :short_name), url_for(@context), id: "crumb_#{@context.asset_string}")
        end
        GuardRail.activate(:primary) do
          set_badge_counts_for(@context, @current_user)
        end

        set_tutorial_js_env

        default_view = @context.default_view || @context.default_home_page
        @course_home_view = "feed" if params[:view] == "feed"
        @course_home_view ||= default_view
        @course_home_view = "k5_dashboard" if @context.elementary_subject_course?
        @course_home_view = "announcements" if @context.elementary_homeroom_course?
        @course_home_view = "syllabus" if @context.elementary_homeroom_course? && !@context.grants_right?(@current_user, session, :read_announcements)

        course_env_variables = {}
        # env.COURSE variables that apply to both classic and k5 courses
        course_env_variables.merge!({
                                      id: @context.id.to_s,
                                      long_name: "#{@context.name} - #{@context.short_name}",
                                      pages_url: polymorphic_url([@context, :wiki_pages]),
                                      is_student: @context.user_is_student?(@current_user),
                                      is_instructor: @context.user_is_instructor?(@current_user) || @context.grants_right?(@current_user, session, :read_as_admin)
                                    })
        # env.COURSE variables that only apply to classic courses
        unless @context.elementary_subject_course?
          course_env_variables[:front_page_title] = @context&.wiki&.front_page&.title
          course_env_variables[:default_view] = default_view
        end
        js_env({ COURSE: course_env_variables })

        # make sure the wiki front page exists
        if @course_home_view == "wiki" && @context.wiki.front_page.nil?
          @course_home_view = @context.default_home_page
        end

        if @context.show_announcements_on_home_page? && @context.grants_right?(@current_user, session, :read_announcements)
          js_env(SHOW_ANNOUNCEMENTS: true, ANNOUNCEMENT_LIMIT: @context.home_page_announcement_limit)
        end

        return render_course_notification_settings if params[:view] == "notifications"

        @contexts = [@context]
        case @course_home_view
        when "wiki"
          @wiki = @context.wiki
          @page = @wiki.front_page
          set_js_rights [:wiki, :page]
          set_js_wiki_data course_home: true
          @padless = true
        when "assignments"
          add_crumb(t("#crumbs.assignments", "Assignments"))
          set_js_assignment_data
          js_env(SIS_NAME: AssignmentUtil.post_to_sis_friendly_name(@context))
          js_env(
            SHOW_SPEED_GRADER_LINK: @current_user.present? && context.allows_speed_grader? && context.grants_any_right?(@current_user, :manage_grades, :view_all_grades),
            QUIZ_LTI_ENABLED: @context.feature_enabled?(:quizzes_next) &&
              !@context.root_account.feature_enabled?(:newquizzes_on_quiz_page) &&
              @context.quiz_lti_tool.present?,
            FLAGS: {
              newquizzes_on_quiz_page: @context.root_account.feature_enabled?(:newquizzes_on_quiz_page),
              show_additional_speed_grader_link: Account.site_admin.feature_enabled?(:additional_speedgrader_links),
            }
          )
          js_env(COURSE_HOME: true)
          @upcoming_assignments = get_upcoming_assignments(@context)
        when "modules"
          add_crumb(t("#crumbs.modules", "Modules"))
          load_modules
        when "syllabus"
          set_active_tab "syllabus"
          rce_js_env
          add_crumb @context.elementary_enabled? ? t("Important Info") : t("#crumbs.syllabus", "Syllabus")
          @groups = @context.assignment_groups.active.order(
            :position,
            AssignmentGroup.best_unicode_collation_key("name")
          ).to_a
          @syllabus_body = syllabus_user_content
        when "k5_dashboard"
          load_modules # hidden until the modules tab of the k5 course is active
        when "announcements"
          add_crumb(t("Announcements"))
          set_active_tab "announcements"
          load_announcements
        else
          set_active_tab "home"
          if @context.grants_any_right?(@current_user, session, :manage_groups, *RoleOverride::GRANULAR_MANAGE_GROUPS_PERMISSIONS)
            @contexts += @context.groups
          elsif @user_groups
            @contexts += @user_groups
          end
          web_conferences = @context.web_conferences.active.to_a
          @current_conferences = web_conferences.select { |c| c.active?(false, false) && c.users.include?(@current_user) }
          @scheduled_conferences = web_conferences.select { |c| c.scheduled? && c.users.include?(@current_user) }
          @stream_items = @current_user.try(:cached_recent_stream_items, { contexts: @contexts }) || []
        end

        if @current_user && (@show_recent_feedback = @context.user_is_student?(@current_user))
          @recent_feedback = @current_user.recent_feedback(contexts: @contexts) || []
        end

        flash[:notice] = t("notices.updated", "Course was successfully updated.") if params[:for_reload]

        can_see_admin_tools = @context.grants_any_right?(
          @current_user, session, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
        )
        @course_home_sub_navigation_tools = Lti::ContextToolFinder.new(
          @context,
          type: :course_home_sub_navigation,
          root_account: @domain_root_account,
          current_user: @current_user
        ).all_tools_sorted_array(exclude_admin_visibility: !can_see_admin_tools)

        css_bundle :dashboard
        css_bundle :react_todo_sidebar if planner_enabled?
        case @course_home_view
        when "wiki"
          js_bundle :wiki_page_show
          css_bundle :wiki_page, :tinymce
        when "modules"
          @progress = Progress.find_by(
            context: @context,
            tag: "context_module_batch_update",
            workflow_state: ["queued", "running"]
          )

          js_env(CONTEXT_MODULE_ASSIGNMENT_INFO_URL: context_url(@context, :context_context_modules_assignment_info_url))

          js_bundle :context_modules
          css_bundle :content_next, :context_modules2
        when "assignments"
          js_bundle :assignment_index
          css_bundle :new_assignments
          add_body_class("with_item_groups")
        when "syllabus"
          deferred_js_bundle :syllabus
          css_bundle :syllabus, :tinymce
        when "k5_dashboard"
          embed_mode = value_to_boolean(params[:embed])
          @headers = false if embed_mode

          if @context.grants_right?(@current_user, session, :read_announcements)
            start_date = 14.days.ago.beginning_of_day
            end_date = start_date + 28.days
            scope = Announcement.where(context_type: "Course", context_id: @context.id, workflow_state: "active")
                                .ordered_between(start_date, end_date)
            unless @context.grants_any_right?(@current_user, session, :read_as_admin, :manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS)
              scope = scope.visible_to_student_sections(@current_user)
            end
            latest_announcement = scope.limit(1).first
          end

          # env variables that apply only to k5 subjects
          js_env(
            CONTEXT_MODULE_ASSIGNMENT_INFO_URL: context_url(@context, :context_context_modules_assignment_info_url),
            PERMISSIONS: {
              manage: @context.grants_right?(@current_user, session, :manage),
              manage_groups: @context.grants_any_right?(@current_user,
                                                        session,
                                                        :manage_groups,
                                                        :manage_groups_add,
                                                        :manage_groups_manage,
                                                        :manage_groups_delete),
              read_as_admin: @context.grants_right?(@current_user, session, :read_as_admin),
              read_announcements: @context.grants_right?(@current_user, session, :read_announcements)
            },
            STUDENT_PLANNER_ENABLED: planner_enabled?,
            TABS: @context.tabs_available(@current_user, course_subject_tabs: true, session:),
            OBSERVED_USERS_LIST: observed_users(@current_user, session, @context.id),
            TAB_CONTENT_ONLY: embed_mode,
            SHOW_IMMERSIVE_READER: show_immersive_reader?,
            GRADING_SCHEME: @context.grading_standard_or_default.data,
            RESTRICT_QUANTITATIVE_DATA: @context.restrict_quantitative_data?(@current_user)
          )

          self_enrollment_option = visible_self_enrollment_option
          self_enrollment_url = enroll_url(@context.self_enrollment_code) if self_enrollment_option == :enroll
          self_enrollment_url = course_self_unenrollment_path(@context, @context_enrollment.uuid) if self_enrollment_option == :unenroll

          course_env_variables.merge!({
                                        name: @context.nickname_for(@current_user),
                                        image_url: @context.image,
                                        banner_image_url: @context.banner_image,
                                        color: @context.course_color,
                                        course_overview: {
                                          body: @context.wiki&.front_page&.body,
                                          url: @context.wiki&.front_page_url,
                                          canEdit: @context.wiki&.front_page&.grants_any_right?(@current_user, session, :update, :update_content) && !@context.wiki&.front_page&.editing_restricted?(:content)
                                        },
                                        hide_final_grades: @context.hide_final_grades?,
                                        student_outcome_gradebook_enabled: @context.feature_enabled?(:student_outcome_gradebook),
                                        outcome_proficiency: @context.root_account.feature_enabled?(:account_level_mastery_scales) ? @context.resolved_outcome_proficiency&.as_json : @context.account.resolved_outcome_proficiency&.as_json,
                                        show_student_view: can_do(@context, @current_user, :use_student_view),
                                        student_view_path: course_student_view_path(course_id: @context, redirect_to_referer: 1),
                                        settings_path: course_settings_path(@context.id),
                                        groups_path: course_groups_path(@context.id),
                                        latest_announcement: latest_announcement && discussion_topic_api_json(latest_announcement, @context, @current_user, session),
                                        has_wiki_pages: @context.wiki_pages.not_deleted.exists?,
                                        has_syllabus_body: @context.syllabus_body.present?,
                                        is_student_or_fake_student: @context.user_is_student?(@current_user, include_fake_student: true),
                                        self_enrollment: {
                                          option: self_enrollment_option,
                                          url: self_enrollment_url
                                        }
                                      })

          js_env({ COURSE: course_env_variables }, true)
          js_bundle :k5_course, :context_modules
          css_bundle :k5_common, :k5_course, :content_next, :context_modules2, :grade_summary
        when "announcements"
          js_bundle :announcements
          css_bundle :announcements_index
        else
          js_bundle :dashboard
        end

        js_bundle :course, :course_show
        css_bundle :course_show

        if @context_enrollment
          content_for_head helpers.auto_discovery_link_tag(:atom, feeds_course_format_path(@context_enrollment.feed_code, :atom), { title: t("Course Atom Feed") })
        elsif @context.available?
          content_for_head helpers.auto_discovery_link_tag(:atom, feeds_course_format_path(@context.feed_code, :atom), { title: t("Course Atom Feed") })
        end

        set_active_tab "home" unless get_active_tab
        render stream: can_stream_template?
      elsif @context.indexed && @context.available?
        render :description
      else
        # clear notices that would have been displayed as a result of processing
        # an enrollment invitation, since we're giving an error
        flash[:notice] = nil
        # We know this will fail since we got to this block, but this way we can reuse the error handling
        authorized_action(@context, @current_user, :read)
      end
    end
  end

  def render_course_notification_settings
    add_crumb(t("Course Notification Settings"))
    js_env(
      course_name: @context.name,
      NOTIFICATION_PREFERENCES_OPTIONS: {
        allowed_push_categories: Notification.categories_to_send_in_push,
        send_scores_in_emails_text: Notification.where(category: "Grading").first&.related_user_setting(@current_user, @domain_root_account)
      }
    )
    js_bundle :course_notification_settings
    render html: "", layout: true
  end

  def confirm_action
    params[:event] ||= (@context.claimed? || @context.created? || @context.completed?) ? "delete" : "conclude"
    authorized_action(@context, @current_user, permission_for_event(params[:event]))
  end

  def conclude_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    if @enrollment.can_be_concluded_by(@current_user, @context, session)
      respond_to do |format|
        if @enrollment.conclude
          format.json { render json: @enrollment }
        else
          format.json { render json: @enrollment, status: :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def unconclude_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    can_remove = @enrollment.is_a?(StudentEnrollment) && @context.grants_right?(@current_user, session, :manage_students)
    can_remove ||= @context.grants_right?(@current_user, session, manage_admin_users_perm)
    if can_remove
      respond_to do |format|
        if @enrollment.unconclude
          format.json { render json: @enrollment }
        else
          format.json { render json: @enrollment, status: :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def limit_user
    get_context
    @user = @context.users.find(params[:id])
    if authorized_action(@context, @current_user, manage_admin_users_perm)
      if params[:limit] == "1"
        Enrollment.limit_privileges_to_course_section!(@context, @user, true)
        render json: { limited: true }
      else
        Enrollment.limit_privileges_to_course_section!(@context, @user, false)
        render json: { limited: false }
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def unenroll_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    if @enrollment.can_be_deleted_by(@current_user, @context, session)
      if (!@enrollment.defined_by_sis? || @context.grants_any_right?(@current_user, session, :manage_account_settings, :manage_sis)) && @enrollment.destroy
        render json: @enrollment
      else
        render json: @enrollment, status: :bad_request
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def enroll_users
    get_context
    params[:enrollment_type] ||= "StudentEnrollment"

    custom_role = nil
    if params[:role_id].present? || !Role.get_built_in_role(params[:enrollment_type], root_account_id: @context.root_account_id)
      custom_role = @context.account.get_role_by_id(params[:role_id]) if params[:role_id].present?
      custom_role ||= @context.account.get_role_by_name(params[:enrollment_type]) # backwards compatibility
      if custom_role&.course_role?
        if custom_role.inactive?
          render json: t("errors.role_not_active", "Can't add users for non-active role: '%{role}'", role: custom_role.name), status: :bad_request
          return
        else
          params[:enrollment_type] = custom_role.base_role_type
        end
      else
        render json: t("errors.role_not_found", "Could not find role"), status: :bad_request
        return
      end
    end

    params[:course_section_id] ||= @context.default_section.id
    if @current_user&.can_create_enrollment_for?(@context, session, params[:enrollment_type])
      params[:user_list] ||= ""

      # Enrollment settings hash
      # Change :limit_privileges_to_course_section to be an explicit true/false value
      enrollment_options = params.slice(:course_section_id, :enrollment_type, :limit_privileges_to_course_section)
      limit_privileges = value_to_boolean(enrollment_options[:limit_privileges_to_course_section])
      enrollment_options[:limit_privileges_to_course_section] = limit_privileges
      enrollment_options[:role] = custom_role if custom_role
      enrollment_options[:updating_user] = @current_user

      list =
        if params[:user_tokens]
          Array(params[:user_tokens])
        else
          UserList.new(params[:user_list],
                       root_account: @context.root_account,
                       search_method: @context.user_list_search_mode_for(@current_user),
                       initial_type: params[:enrollment_type],
                       current_user: @current_user)
        end
      if !@context.concluded? && (@enrollments = EnrollmentsFromUserList.process(list, @context, enrollment_options))
        ActiveRecord::Associations.preload(@enrollments, [:course_section, { user: [:communication_channel, :pseudonym] }])
        InstStatsd::Statsd.count("course.#{@context.enable_course_paces ? "paced" : "unpaced"}.student_enrollment_count", @context.student_enrollments.count)
        json = @enrollments.map do |e|
          { "enrollment" =>
            { "associated_user_id" => e.associated_user_id,
              "communication_channel_id" => e.user.communication_channel.try(:id),
              "email" => e.email,
              "id" => e.id,
              "name" => e.user.last_name_first || e.user.name,
              "pseudonym_id" => e.user.pseudonym.try(:id),
              "section" => e.course_section.display_name,
              "short_name" => e.user.short_name,
              "type" => e.type,
              "user_id" => e.user_id,
              "workflow_state" => e.workflow_state,
              "role_id" => e.role_id,
              "already_enrolled" => e.already_enrolled } }
        end
        render json:
      else
        render json: "", status: :bad_request
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def link_enrollment
    get_context
    if authorized_action(@context, @current_user, manage_admin_users_perm)
      enrollment = @context.observer_enrollments.find(params[:enrollment_id])
      student = nil
      student = @context.students.find(params[:student_id]) if params[:student_id] != "none"
      # this is used for linking and un-linking enrollments
      enrollment.associated_user_id = student ? student.id : nil
      enrollment.save!
      render json: enrollment.as_json(methods: :associated_user_name)
    end
  end

  def move_enrollment
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    can_move = [StudentEnrollment, ObserverEnrollment].include?(@enrollment.class) && @context.grants_right?(@current_user, session, :manage_students)
    can_move ||= @context.grants_right?(@current_user, session, manage_admin_users_perm)
    can_move &&= @context.grants_any_right?(@current_user, session, :manage_account_settings, :manage_sis) if @enrollment.defined_by_sis?
    if can_move
      respond_to do |format|
        # ensure user_id,section_id,type,associated_user_id is unique (this
        # will become a DB constraint eventually)
        @possible_dup = @context.enrollments.where(
          "id<>? AND user_id=? AND course_section_id=? AND type=? AND (associated_user_id IS NULL OR associated_user_id=?)",
          @enrollment,
          @enrollment.user_id,
          params[:course_section_id],
          @enrollment.type,
          @enrollment.associated_user_id
        ).first
        if @possible_dup.present?
          format.json { render json: @enrollment, status: :forbidden }
        else
          @enrollment.course_section = @context.course_sections.find(params[:course_section_id])
          @enrollment.save!

          format.json { render json: @enrollment }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def copy
    return unless authorized_action(@context, @current_user, :read_as_admin)

    account = @context.account
    unless account.grants_any_right?(@current_user, session, :create_courses, :manage_courses, :manage_courses_admin)
      account = @domain_root_account.manually_created_courses_account
    end

    return unless authorized_action(account, @current_user, [:manage_courses, :create_courses])

    # For warnings messages previous to export
    warnings = @context.export_warnings
    js_env(EXPORT_WARNINGS: warnings) unless warnings.empty?

    # For prepopulating the date fields
    js_env(OLD_START_DATE: datetime_string(@context.start_at, :verbose))
    js_env(OLD_END_DATE: datetime_string(@context.conclude_at, :verbose))
    js_env(QUIZZES_NEXT_ENABLED: new_quizzes_enabled?)
    js_env(NEW_QUIZZES_IMPORT: new_quizzes_import_enabled?)
    js_env(NEW_QUIZZES_MIGRATION: new_quizzes_migration_enabled?)
    js_env(NEW_QUIZZES_MIGRATION_DEFAULT: new_quizzes_migration_default)
  end

  def copy_course
    get_context
    if authorized_action(@context, @current_user, :read) &&
       authorized_action(@context, @current_user, :read_as_admin)
      args = params.require(:course).permit(:name, :course_code)
      account = @context.account
      if params[:course][:account_id]
        account = Account.find(params[:course][:account_id])
      end
      account = nil unless account.grants_any_right?(@current_user, session, :create_courses, :manage_courses, :manage_courses_admin)
      account ||= @domain_root_account.manually_created_courses_account
      return unless authorized_action(account, @current_user, [:manage_courses, :create_courses])

      if account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin)
        root_account = account.root_account
        enrollment_term_id =
          params[:course].delete(:term_id).presence ||
          params[:course].delete(:enrollment_term_id).presence
        if enrollment_term_id
          args[:enrollment_term] =
            root_account.enrollment_terms.where(id: enrollment_term_id).first
        end
      end
      # :manage will be false for teachers in concluded courses (but they may have manage rights due to course dates)
      args[:enrollment_term] ||= @context.enrollment_term if @context.grants_right?(@current_user, session, :manage) && !@context.restrict_enrollments_to_course_dates
      args[:abstract_course] = @context.abstract_course
      args[:account] = account
      @course = @context.account.courses.new
      @course.attributes = args
      @course.start_at = DateTime.parse(params[:course][:start_at]).utc rescue nil
      @course.conclude_at = DateTime.parse(params[:course][:conclude_at]).utc rescue nil
      @course.workflow_state = "claimed"

      Course.suspend_callbacks(:copy_from_course_template) do
        @course.save!
      end
      @course.enroll_user(@current_user, "TeacherEnrollment", enrollment_state: "active")

      @content_migration = @course.content_migrations.build(
        user: @current_user,
        source_course: @context,
        context: @course,
        migration_type: "course_copy_importer",
        initiated_source: if api_request?
                            in_app? ? :api_in_app : :api
                          else
                            :manual
                          end
      )
      @content_migration.migration_settings[:source_course_id] = @context.id
      @content_migration.migration_settings[:import_quizzes_next] = true if params.dig(:settings, :import_quizzes_next)
      @content_migration.migration_settings[:import_blueprint_settings] = true if params.dig(:settings, :import_blueprint_settings)
      @content_migration.workflow_state = "created"
      if (adjust_dates = params[:adjust_dates]) && Canvas::Plugin.value_to_boolean(adjust_dates[:enabled])
        params[:date_shift_options][adjust_dates[:operation]] = "1"
      end
      @content_migration.set_date_shift_options(params[:date_shift_options].to_unsafe_h) if params[:date_shift_options]

      if Canvas::Plugin.value_to_boolean(params[:selective_import])
        @content_migration.migration_settings[:import_immediately] = false
        @content_migration.workflow_state = "exported"
        @content_migration.save
      else
        @content_migration.migration_settings[:import_immediately] = true
        @content_migration.copy_options = { everything: true }
        @content_migration.migration_settings[:migration_ids_to_import] = { copy: { everything: true } }
        @content_migration.workflow_state = "importing"
        @content_migration.save
        @content_migration.queue_migration
      end

      redirect_to course_content_migrations_url(@course)
    end
  end

  # @API Update a course
  # Update an existing course.
  #
  # Arguments are the same as Courses#create, with a few exceptions (enroll_me).
  #
  # If a user has content management rights, but not full course editing rights, the only attribute
  # editable through this endpoint will be "syllabus_body"
  #
  # If an account has set prevent_course_availability_editing_by_teachers, a teacher cannot change
  # course[start_at], course[conclude_at], or course[restrict_enrollments_to_course_dates] here.
  #
  # @argument course[account_id] [Integer]
  #   The unique ID of the account to move the course to.
  #
  # @argument course[name] [String]
  #   The name of the course. If omitted, the course will be named "Unnamed
  #   Course."
  #
  # @argument course[course_code] [String]
  #   The course code for the course.
  #
  # @argument course[start_at] [DateTime]
  #   Course start date in ISO8601 format, e.g. 2011-01-01T01:00Z
  #   This value is ignored unless 'restrict_enrollments_to_course_dates' is set to true,
  #   or the course is already published.
  #
  # @argument course[end_at] [DateTime]
  #   Course end date in ISO8601 format. e.g. 2011-01-01T01:00Z
  #   This value is ignored unless 'restrict_enrollments_to_course_dates' is set to true.
  #
  # @argument course[license] [String]
  #   The name of the licensing. Should be one of the following abbreviations
  #   (a descriptive name is included in parenthesis for reference):
  #   - 'private' (Private Copyrighted)
  #   - 'cc_by_nc_nd' (CC Attribution Non-Commercial No Derivatives)
  #   - 'cc_by_nc_sa' (CC Attribution Non-Commercial Share Alike)
  #   - 'cc_by_nc' (CC Attribution Non-Commercial)
  #   - 'cc_by_nd' (CC Attribution No Derivatives)
  #   - 'cc_by_sa' (CC Attribution Share Alike)
  #   - 'cc_by' (CC Attribution)
  #   - 'public_domain' (Public Domain).
  #
  # @argument course[is_public] [Boolean]
  #   Set to true if course is public to both authenticated and unauthenticated users.
  #
  # @argument course[is_public_to_auth_users] [Boolean]
  #   Set to true if course is public only to authenticated users.
  #
  # @argument course[public_syllabus] [Boolean]
  #   Set to true to make the course syllabus public.
  #
  # @argument course[public_syllabus_to_auth] [Boolean]
  #   Set to true to make the course syllabus to public for authenticated users.
  #
  # @argument course[public_description] [String]
  #   A publicly visible description of the course.
  #
  # @argument course[allow_student_wiki_edits] [Boolean]
  #   If true, students will be able to modify the course wiki.
  #
  # @argument course[allow_wiki_comments] [Boolean]
  #   If true, course members will be able to comment on wiki pages.
  #
  # @argument course[allow_student_forum_attachments] [Boolean]
  #   If true, students can attach files to forum posts.
  #
  # @argument course[open_enrollment] [Boolean]
  #   Set to true if the course is open enrollment.
  #
  # @argument course[self_enrollment] [Boolean]
  #   Set to true if the course is self enrollment.
  #
  # @argument course[restrict_enrollments_to_course_dates] [Boolean]
  #   Set to true to restrict user enrollments to the start and end dates of the
  #   course. Setting this value to false will
  #   remove the course end date (if it exists), as well as the course start date
  #   (if the course is unpublished).
  #
  # @argument course[term_id] [Integer]
  #   The unique ID of the term to create to course in.
  #
  # @argument course[sis_course_id] [String]
  #   The unique SIS identifier.
  #
  # @argument course[integration_id] [String]
  #   The unique Integration identifier.
  #
  # @argument course[hide_final_grades] [Boolean]
  #   If this option is set to true, the totals in student grades summary will
  #   be hidden.
  #
  # @argument course[time_zone] [String]
  #   The time zone for the course. Allowed time zones are
  #   {http://www.iana.org/time-zones IANA time zones} or friendlier
  #   {http://api.rubyonrails.org/classes/ActiveSupport/TimeZone.html Ruby on Rails time zones}.
  #
  # @argument course[apply_assignment_group_weights] [Boolean]
  #   Set to true to weight final grade based on assignment groups percentages.
  #
  # @argument course[storage_quota_mb] [Integer]
  #   Set the storage quota for the course, in megabytes. The caller must have
  #   the "Manage storage quotas" account permission.
  #
  # @argument offer [Boolean]
  #   If this option is set to true, the course will be available to students
  #   immediately.
  #
  # @argument course[event] [String, "claim"|"offer"|"conclude"|"delete"|"undelete"]
  #   The action to take on each course.
  #   * 'claim' makes a course no longer visible to students. This action is also called "unpublish" on the web site.
  #     A course cannot be unpublished if students have received graded submissions.
  #   * 'offer' makes a course visible to students. This action is also called "publish" on the web site.
  #   * 'conclude' prevents future enrollments and makes a course read-only for all participants. The course still appears
  #     in prior-enrollment lists.
  #   * 'delete' completely removes the course from the web site (including course menus and prior-enrollment lists).
  #     All enrollments are deleted. Course content may be physically deleted at a future date.
  #   * 'undelete' attempts to recover a course that has been deleted. This action requires account administrative rights.
  #     (Recovery is not guaranteed; please conclude rather than delete a course if there is any possibility the course
  #     will be used again.) The recovered course will be unpublished. Deleted enrollments will not be recovered.
  #
  # @argument course[default_view]  [String, "feed"|"wiki"|"modules"|"syllabus"|"assignments"]
  #   The type of page that users will see when they first visit the course
  #   * 'feed' Recent Activity Dashboard
  #   * 'wiki' Wiki Front Page
  #   * 'modules' Course Modules/Sections Page
  #   * 'assignments' Course Assignments List
  #   * 'syllabus' Course Syllabus Page
  #   other types may be added in the future
  #
  # @argument course[syllabus_body] [String]
  #   The syllabus body for the course
  #
  # @argument course[syllabus_course_summary] [Boolean]
  #   Optional. Indicates whether the Course Summary (consisting of the course's assignments and calendar events) is displayed on the syllabus page. Defaults to +true+.
  #
  # @argument course[grading_standard_id] [Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
  #
  # @argument course[grade_passback_setting] [String]
  #   Optional. The grade_passback_setting for the course. Only 'nightly_sync' and '' are allowed
  #
  # @argument course[course_format] [String]
  #   Optional. Specifies the format of the course. (Should be either 'on_campus' or 'online')
  #
  # @argument course[image_id] [Integer]
  #   This is a file ID corresponding to an image file in the course that will
  #   be used as the course image.
  #   This will clear the course's image_url setting if set.  If you attempt
  #   to provide image_url and image_id in a request it will fail.
  #
  # @argument course[image_url] [String]
  #   This is a URL to an image to be used as the course image.
  #   This will clear the course's image_id setting if set.  If you attempt
  #   to provide image_url and image_id in a request it will fail.
  #
  # @argument course[remove_image] [Boolean]
  #   If this option is set to true, the course image url and course image
  #   ID are both set to nil
  #
  # @argument course[remove_banner_image] [Boolean]
  #   If this option is set to true, the course banner image url and course
  #   banner image ID are both set to nil
  #
  # @argument course[blueprint] [Boolean]
  #   Sets the course as a blueprint course.
  #
  # @argument course[blueprint_restrictions] [BlueprintRestriction]
  #   Sets a default set to apply to blueprint course objects when restricted,
  #   unless _use_blueprint_restrictions_by_object_type_ is enabled.
  #   See the {api:Blueprint_Courses:BlueprintRestriction Blueprint Restriction} documentation
  #
  # @argument course[use_blueprint_restrictions_by_object_type] [Boolean]
  #   When enabled, the _blueprint_restrictions_ parameter will be ignored in favor of
  #   the _blueprint_restrictions_by_object_type_ parameter
  #
  # @argument course[blueprint_restrictions_by_object_type] [multiple BlueprintRestrictions]
  #   Allows setting multiple {api:Blueprint_Courses:BlueprintRestriction Blueprint Restriction}
  #   to apply to blueprint course objects of the matching type when restricted.
  #   The possible object types are "assignment", "attachment", "discussion_topic", "quiz" and "wiki_page".
  #   Example usage:
  #     course[blueprint_restrictions_by_object_type][assignment][content]=1
  #
  # @argument course[homeroom_course] [Boolean]
  #   Sets the course as a homeroom course. The setting takes effect only when the course is associated
  #   with a Canvas for Elementary-enabled account.
  #
  # @argument course[sync_enrollments_from_homeroom] [String]
  #   Syncs enrollments from the homeroom that is set in homeroom_course_id. The setting only takes effect when the
  #   course is associated with a Canvas for Elementary-enabled account and sync_enrollments_from_homeroom is enabled.
  #
  # @argument course[homeroom_course_id] [String]
  #   Sets the Homeroom Course id to be used with sync_enrollments_from_homeroom. The setting only takes effect when the
  #   course is associated with a Canvas for Elementary-enabled account and sync_enrollments_from_homeroom is enabled.
  #
  # @argument course[template] [Boolean]
  #   Enable or disable the course as a template that can be selected by an account
  #
  # @argument course[course_color] [String]
  #   Sets a color in hex code format to be associated with the course. The setting takes effect only when the course
  #   is associated with a Canvas for Elementary-enabled account.
  #
  # @argument course[friendly_name] [String]
  #   Set a friendly name for the course. If this is provided and the course is associated with a Canvas for
  #   Elementary account, it will be shown instead of the course name. This setting takes priority over
  #   course nicknames defined by individual users.
  #
  # @argument course[enable_course_paces] [Boolean]
  #   Enable or disable Course Pacing for the course. This setting only has an effect when the Course Pacing feature flag is
  #   enabled for the sub-account. Otherwise, Course Pacing are always disabled.
  #     Note: Course Pacing is in active development.
  #
  # @argument course[conditional_release] [Boolean]
  #   Enable or disable individual learning paths for students based on assessment
  #
  # @argument override_sis_stickiness [boolean]
  #   Default is true. If false, any fields containing “sticky” changes will not be updated.
  #   See SIS CSV Format documentation for information on which fields can have SIS stickiness
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id> \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'course[name]=New course name' \
  #     -d 'course[start_at]=2012-05-05T00:00:00Z'
  #
  # @example_response
  #   {
  #     "name": "New course name",
  #     "course_code": "COURSE-001",
  #     "start_at": "2012-05-05T00:00:00Z",
  #     "end_at": "2012-08-05T23:59:59Z",
  #     "sis_course_id": "12345"
  #   }
  def update
    @course = api_find(Course, params[:id])
    old_settings = @course.settings
    logging_source = api_request? ? :api : :manual

    params[:course] ||= {}
    params_for_update = course_params
    params[:course][:event] = :offer if value_to_boolean(params[:offer])

    if params[:course][:event] && params[:course].keys.size == 1
      return unless verified_user_check

      event = params[:course][:event].to_s
      # check permissions on processable events
      # allow invalid and non_events to pass through
      return if %w[offer claim conclude delete undelete].include?(event) &&
                !authorized_action(@course, @current_user, permission_for_event(event))

      # authorized, invalid, and non_events are processed
      if process_course_event
        render_update_success
      else
        render_update_failure
      end
      return
    end

    if authorized_action(@course, @current_user, %i[manage_content manage_course_content_edit])
      return render_update_success if params[:for_reload]

      unless @course.grants_right?(@current_user, :update)
        # let users with :manage_couse_content_edit only update the body
        params_for_update = params_for_update.slice(:syllabus_body)
      end
      if params_for_update.key?(:syllabus_body)
        begin
          params_for_update[:syllabus_body] = process_incoming_html_content(params_for_update[:syllabus_body])
        rescue Api::Html::UnparsableContentError => e
          @course.errors.add(:unparsable_content, e.message)
        end
      end
      unless @course.grants_right?(@current_user, :manage_course_visibility)
        params_for_update.delete(:indexed)
      end
      if params_for_update.key?(:template)
        template = value_to_boolean(params_for_update.delete(:template))
        if (template && @course.grants_right?(@current_user, session, :add_course_template)) ||
           (!template && @course.grants_right?(@current_user, session, :delete_course_template))
          @course.template = template
        end
      end

      account_id = params[:course].delete :account_id
      if account_id && @course.account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin)
        account = api_find(Account, account_id)
        if account && account != @course.account && account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin)
          @course.account = account
        end
      end

      root_account_id = params[:course].delete :root_account_id
      if root_account_id && Account.site_admin.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin)
        @course.root_account = Account.root_accounts.find(root_account_id)
        @course.account = @course.root_account if @course.account.root_account != @course.root_account
      end

      if params[:course].key?(:apply_assignment_group_weights)
        @course.apply_assignment_group_weights =
          value_to_boolean params[:course].delete(:apply_assignment_group_weights)
      end
      if params[:course].key?(:group_weighting_scheme)
        @course.group_weighting_scheme = params[:course].delete(:group_weighting_scheme)
      end

      if @course.group_weighting_scheme_changed? && !can_change_group_weighting_scheme?
        return render_unauthorized_action
      end

      term_id_param_was_sent = params[:course][:term_id] || params[:course][:enrollment_term_id]
      term_id = params[:course].delete(:term_id)
      enrollment_term_id = params[:course].delete(:enrollment_term_id) || term_id
      if enrollment_term_id && @course.account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin)
        enrollment_term = api_find(@course.root_account.enrollment_terms, enrollment_term_id)
        @course.enrollment_term = enrollment_term if enrollment_term && enrollment_term != @course.enrollment_term
      end

      if params_for_update.key? :grading_standard_id
        standard_id = params_for_update.delete :grading_standard_id
        grading_standard = GradingStandard.for(@course).where(id: standard_id).first if standard_id.present?
        if grading_standard != @course.grading_standard
          if standard_id.present?
            @course.grading_standard = grading_standard if grading_standard
          else
            @course.grading_standard = nil
          end
        end
      end

      if params_for_update.key?(:grade_passback_setting)
        grade_passback_setting = params_for_update.delete(:grade_passback_setting)
        return unless authorized_action?(@course, @current_user, :manage_grades)

        update_grade_passback_setting(grade_passback_setting)
      end

      unless @course.account.grants_right? @current_user, session, :manage_storage_quotas
        params_for_update.delete :storage_quota
        params_for_update.delete :storage_quota_mb
      end
      if !@course.account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin) &&
         @course.root_account.settings[:prevent_course_renaming_by_teachers]
        params_for_update.delete :name
        params_for_update.delete :course_code
      end
      params[:course][:sis_source_id] = params[:course].delete(:sis_course_id) if api_request?
      if (sis_id = params[:course].delete(:sis_source_id)) &&
         sis_id != @course.sis_source_id &&
         @course.root_account.grants_right?(@current_user, session, :manage_sis)
        @course.sis_source_id = sis_id.presence
      end

      lock_announcements = params[:course].delete(:lock_all_announcements)
      unless lock_announcements.nil?
        if value_to_boolean(lock_announcements)
          @course.lock_all_announcements = true
          Announcement.lock_from_course(@course)
        elsif @course.lock_all_announcements
          @course.lock_all_announcements = false
        end
      end

      if params[:course].key?(:usage_rights_required)
        @course.usage_rights_required = value_to_boolean(params[:course].delete(:usage_rights_required))
      end

      if params_for_update.key?(:locale) && params_for_update[:locale].blank?
        params_for_update[:locale] = nil
      end

      if params[:course][:event]
        return unless verified_user_check

        event = params[:course][:event].to_s
        # check permissions on processable events
        # allow invalid and non_events to pass through
        return if %w[offer claim conclude delete undelete].include?(event) &&
                  !authorized_action(@course, @current_user, permission_for_event(event))

        # authorized, invalid, and non_events are processed
        unless process_course_event
          render_update_failure
          return
        end
      end

      color = params[:course][:course_color]
      if color
        if color.strip.empty? || color.length == 1
          @course.course_color = nil
          params_for_update.delete :course_color
        elsif valid_hexcode?(color)
          @course.course_color = normalize_hexcode(color)
          params_for_update.delete :course_color
        else
          @course.errors.add(:course_color, t("Invalid hexcode provided"))
        end
      end

      if (default_due_time = params_for_update.delete(:default_due_time))
        @course.default_due_time = normalize_due_time(default_due_time)
      end

      update_image(params, "image")
      update_image(params, "banner_image")

      params_for_update[:conclude_at] = params[:course].delete(:end_at) if api_request? && params[:course].key?(:end_at)

      # Remove enrollment dates if "Term" enrollment is specified
      if params_for_update.key?(:restrict_enrollments_to_course_dates)
        restrict_enrollments_to_course_dates =
          value_to_boolean(params_for_update[:restrict_enrollments_to_course_dates])
        if restrict_enrollments_to_course_dates.nil?
          unrecognized_message = t("The argument provided is expected to be of type boolean.")
          @course.errors.add(:restrict_enrollments_to_course_dates, unrecognized_message)
        end
      else
        restrict_enrollments_to_course_dates = @course.restrict_enrollments_to_course_dates
      end
      if @course.enrollment_term && !restrict_enrollments_to_course_dates
        params_for_update[:start_at] = nil if @course.unpublished?
        params_for_update[:conclude_at] = nil
      end

      @default_wiki_editing_roles_was = @course.default_wiki_editing_roles || "teachers"

      # Saving master course setting for statsd logging later
      @old_save_master_course = false
      @new_save_master_course = false
      if params[:course].key?(:blueprint)
        @old_save_master_course = MasterCourses::MasterTemplate.is_master_course?(@course)
        master_course = value_to_boolean(params[:course].delete(:blueprint))
        if master_course != MasterCourses::MasterTemplate.is_master_course?(@course)
          return unless authorized_action(@course.account, @current_user, :manage_master_courses)

          message = master_course && why_cant_i_enable_master_course(@course)
          if message
            @course.errors.add(:master_course, message)
          else
            action = master_course ? "set" : "remove"
            MasterCourses::MasterTemplate.send(:"#{action}_as_master_course", @course)
            @new_save_master_course = master_course
          end
        end
      end
      blueprint_keys = %i[blueprint_restrictions use_blueprint_restrictions_by_object_type blueprint_restrictions_by_object_type]
      if blueprint_keys.any? { |k| params[:course].key?(k) } && MasterCourses::MasterTemplate.is_master_course?(@course)
        template = MasterCourses::MasterTemplate.full_template_for(@course)

        if params[:course].key?(:use_blueprint_restrictions_by_object_type)
          template.use_default_restrictions_by_type = value_to_boolean(params[:course][:use_blueprint_restrictions_by_object_type])
        end

        if (mc_restrictions = params[:course][:blueprint_restrictions])
          template.default_restrictions = mc_restrictions.to_unsafe_h.to_h { |k, v| [k.to_sym, value_to_boolean(v)] }
        end

        if (mc_restrictions_by_type = params[:course][:blueprint_restrictions_by_object_type])
          parsed_restrictions_by_type = {}
          mc_restrictions_by_type.to_unsafe_h.each do |type, restrictions|
            class_name = (type == "quiz") ? "Quizzes::Quiz" : type.camelcase
            parsed_restrictions_by_type[class_name] = restrictions.to_h { |k, v| [k.to_sym, value_to_boolean(v)] }
          end
          template.default_restrictions_by_type = parsed_restrictions_by_type
        end

        if template.changed?
          return unless authorized_action(@course.account, @current_user, :manage_master_courses)

          @course.errors.add(:master_course_restrictions, t("Invalid restrictions")) unless template.save
        end
      end

      if params[:override_sis_stickiness] && !value_to_boolean(params[:override_sis_stickiness])
        params_for_update -= [*@course.stuck_sis_fields]
      end

      @course.attributes = params_for_update

      if params[:course][:course_visibility].present? && @course.grants_right?(@current_user, :manage_course_visibility)
        visibility_configuration(params[:course])
      end

      if params[:course][:homeroom_course].present? && value_to_boolean(params[:course][:homeroom_course]) && @course.enable_course_paces
        homeroom_message = t("Homeroom Course cannot be used with Course Pacing")
        @course.errors.add(:homeroom_course, homeroom_message)
      end

      if params[:course][:enable_course_paces].present? && value_to_boolean(params[:course][:enable_course_paces]) && @course.homeroom_course
        pacing_message = t("Course Pacing cannot be used with Homeroom Course")
        @course.errors.add(:enable_course_paces, pacing_message)
      end

      changes = changed_settings(@course.changes, @course.settings, old_settings)
      changes.delete(:start_at) if changes.dig(:start_at, 0)&.to_s == changes.dig(:start_at, 1)&.to_s
      changes.delete(:conclude_at) if changes.dig(:conclude_at, 0)&.to_s == changes.dig(:conclude_at, 1)&.to_s
      availability_changes = changes.keys & %w[start_at conclude_at restrict_enrollments_to_course_dates]
      course_availability_changed = availability_changes.present?
      # allow dates to be dropped if using term dates, even if update is done by someone without permission
      unless @course.restrict_enrollments_to_course_dates
        availability_changes -= ["start_at"] if @course.start_at.nil?
        availability_changes -= ["conclude_at"] if @course.conclude_at.nil?
      end
      return if availability_changes.present? && !authorized_action(@course, @current_user, :edit_course_availability)

      # Republish course paces if the course dates have been changed
      term_changed = (@course.enrollment_term_id != enrollment_term_id) && term_id_param_was_sent
      if @course.account.feature_enabled?(:course_paces) && (course_availability_changed || term_changed)
        @course.course_paces.find_each(&:create_publish_progress)
      end
      disable_conditional_release if changes[:conditional_release]&.last == false

      # RUBY 3.0 - **{} can go away, because data won't implicitly convert to kwargs
      @course.delay_if_production(priority: Delayed::LOW_PRIORITY).touch_content_if_public_visibility_changed(changes, **{})

      if @course.errors.none? && @course.save
        Auditors::Course.record_updated(@course, @current_user, changes, source: logging_source)
        @current_user.touch
        if params[:update_default_pages]
          @course.wiki.update_default_wiki_page_roles(@course.default_wiki_editing_roles, @default_wiki_editing_roles_was)
        end
        # Sync homeroom enrollments and participation if enabled and course isn't a SIS import
        if @course.can_sync_with_homeroom?
          progress = Progress.new(context: @course, tag: :sync_homeroom_enrollments)
          progress.user = @current_user
          progress.reset!
          progress.process_job(@course, :sync_homeroom_enrollments, { priority: Delayed::LOW_PRIORITY })
          # Participation sync should be done in the normal request flow, as it only needs to update a couple of
          # specific fields, delegating that to a job will cause the controller to return the old values, which will
          # force the user to refresh the page after the job finishes to see the changes
          @course.sync_homeroom_participation
        end

        # Increment a log if both master course and course pacing are on
        if @old_save_master_course == @new_save_master_course
          if !changes[:enable_course_paces].nil? && (changes[:enable_course_paces][1] && MasterCourses::MasterTemplate.is_master_course?(@course))
            InstStatsd::Statsd.increment("course.paced.blueprint_course")
          end
        elsif @old_save_master_course == false && @new_save_master_course == true
          if @course.enable_course_paces == true
            InstStatsd::Statsd.increment("course.paced.blueprint_course")
          end
        end

        render_update_success
      else
        render_update_failure
      end
    end
  end

  def update_image(params, setting_name)
    if params[:course][:"#{setting_name}_url"] && params[:course][:"#{setting_name}_id"]
      respond_to do |format|
        format.json { render json: { message: "You cannot provide both an #{setting_name}_url and a #{setting_name}_id." }, status: :bad_request }
        return
      end
    end

    if params[:course][:"#{setting_name}_url"]
      @course.send(:"#{setting_name}_url=", params[:course][:"#{setting_name}_url"])
      @course.send(:"#{setting_name}_id=", nil)
    end

    if params[:course][:"#{setting_name}_id"]
      if @course.attachments.active.where(id: params[:course][:"#{setting_name}_id"]).exists?
        @course.send(:"#{setting_name}_id=", params[:course][:"#{setting_name}_id"])
        @course.send(:"#{setting_name}_url=", nil)
      else
        respond_to do |format|
          format.json { render json: { message: "The image_id is not a valid course file id." }, status: :bad_request }
          return
        end
      end
    end

    if params[:course][:"remove_#{setting_name}"]
      @course.send(:"#{setting_name}_url=", nil)
      @course.send(:"#{setting_name}_id=", nil)
    end
  end

  def render_update_failure
    respond_to do |format|
      format.html do
        flash[:error] = t("There was an error saving the changes to the course")
        redirect_to course_url(@course)
      end
      format.json { render json: @course.errors, status: :bad_request }
    end
  end

  # prevent API from failing when a no-op event is given
  def non_event?(course, event)
    case event
    when :offer
      course.available?
    when :claim
      course.claimed?
    when :complete
      course.completed?
    when :delete
      course.deleted?
    else
      false
    end
  end

  def process_course_event
    event = params[:course].delete(:event)
    event = event.to_sym
    event = :complete if event == :conclude
    return true if non_event?(@course, event)

    if event == :claim && !@course.unpublishable?
      cant_unpublish_message = t("errors.unpublish", "Course cannot be unpublished if student submissions exist.")
      respond_to do |format|
        format.json do
          @course.errors.add(:workflow_state, cant_unpublish_message)
        end
        format.html do
          flash[:error] = cant_unpublish_message
          redirect_to(course_url(@course))
        end
      end
      false
    else
      result = @course.process_event(event)
      if result
        opts = { source: api_request? ? :api : :manual }
        case event
        when :offer
          Auditors::Course.record_published(@course, @current_user, opts)
        when :claim
          Auditors::Course.record_claimed(@course, @current_user, opts)
        when :complete
          Auditors::Course.record_concluded(@course, @current_user, opts)
        when :delete
          Auditors::Course.record_deleted(@course, @current_user, opts)
        when :undelete
          Auditors::Course.record_restored(@course, @current_user, opts)
        end
      else
        @course.errors.add(:workflow_state, @course.halted_because)
      end
      result
    end
  end

  def render_update_success
    respond_to do |format|
      format.html do
        flash[:notice] = t("notices.updated", "Course was successfully updated.")
        redirect_to(params[:continue_to].presence || course_url(@course))
      end
      format.json do
        if api_request?
          render json: course_json(@course, @current_user, session, [:hide_final_grades], nil)
        else
          render json: @course.as_json(methods: %i[readable_license quota account_name term_name grading_standard_title storage_quota_mb]), status: :ok
        end
      end
    end
  end

  # @API Update courses
  # Update multiple courses in an account.  Operates asynchronously; use the {api:ProgressController#show progress endpoint}
  # to query the status of an operation.
  #
  # @argument course_ids[] [Required]
  #   List of ids of courses to update. At most 500 courses may be updated in one call.
  # @argument event [Required, String, "offer"|"conclude"|"delete"|"undelete"]
  #   The action to take on each course.  Must be one of 'offer', 'conclude', 'delete', or 'undelete'.
  #   * 'offer' makes a course visible to students. This action is also called "publish" on the web site.
  #   * 'conclude' prevents future enrollments and makes a course read-only for all participants. The course still appears
  #     in prior-enrollment lists.
  #   * 'delete' completely removes the course from the web site (including course menus and prior-enrollment lists).
  #     All enrollments are deleted. Course content may be physically deleted at a future date.
  #   * 'undelete' attempts to recover a course that has been deleted. (Recovery is not guaranteed; please conclude
  #     rather than delete a course if there is any possibility the course will be used again.) The recovered course
  #     will be unpublished. Deleted enrollments will not be recovered.
  # @example_request
  #     curl https://<canvas>/api/v1/accounts/<account_id>/courses \
  #       -X PUT \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'event=offer' \
  #       -d 'course_ids[]=1' \
  #       -d 'course_ids[]=2'
  #
  # @returns Progress
  def batch_update
    @account = api_find(Account, params[:account_id])
    permission = if params[:event] == "undelete"
                   :undelete_courses
                 else
                   [:manage_courses, :manage_courses_admin]
                 end

    if authorized_action(@account, @current_user, permission)
      return render(json: { message: "must specify course_ids[]" }, status: :bad_request) unless params[:course_ids].is_a?(Array)

      @course_ids = Api.map_ids(params[:course_ids], Course, @domain_root_account, @current_user)
      return render(json: { message: "course batch size limit (500) exceeded" }, status: :forbidden) if @course_ids.size > 500

      update_params = params.permit(:event).to_unsafe_h
      return render(json: { message: "need to specify event" }, status: :bad_request) unless update_params[:event]

      return render(json: { message: "invalid event" }, status: :bad_request) unless %w[offer conclude delete undelete].include? update_params[:event]

      progress = Course.batch_update(@account, @current_user, @course_ids, update_params, :api)
      render json: progress_json(progress, @current_user, session)
    end
  end

  def public_feed
    return unless get_feed_context(only: [:course])

    title = t("titles.rss_feed", "%{course} Feed", course: @context.name)
    link = course_url(@context)

    @entries = []
    @entries.concat Assignments::ScopedToUser.new(@context, @current_user, @context.assignments.published).scope
    @entries.concat @context.calendar_events.active
    @entries.concat(DiscussionTopic::ScopedToUser.new(@context, @current_user, @context.discussion_topics.published).scope.reject do |dt|
      dt.locked_for?(@current_user, check_policies: true)
    end)
    @entries.concat WikiPages::ScopedToUser.new(@context, @current_user, @context.wiki_pages.published).scope
    @entries = @entries.sort_by(&:updated_at)

    respond_to do |format|
      format.atom { render plain: AtomFeedHelper.render_xml(title:, link:, entries: @entries, context: @context) }
    end
  end

  def publish_to_sis
    sis_publish_status(true)
  end

  def sis_publish_status(publish_grades = false)
    get_context
    return unless authorized_action(@context, @current_user, :manage_grades)

    @context.publish_final_grades(@current_user) if publish_grades

    processed_grade_publishing_statuses = {}
    grade_publishing_statuses, overall_status = @context.grade_publishing_statuses
    grade_publishing_statuses.each do |message, enrollments|
      processed_grade_publishing_statuses[message] = enrollments.map do |enrollment|
        { id: enrollment.user.id,
          name: enrollment.user.name,
          sortable_name: enrollment.user.sortable_name,
          url: course_user_url(@context, enrollment.user) }
      end
    end

    render json: { sis_publish_overall_status: overall_status,
                   sis_publish_statuses: processed_grade_publishing_statuses }
  end

  # @API Reset a course
  # Deletes the current course, and creates a new equivalent course with
  # no content, but all sections and users moved over.
  #
  # @returns Course
  def reset_content
    get_context
    return unless authorized_action(@context, @current_user, :reset_content)

    if MasterCourses::MasterTemplate.is_master_course?(@context) || @context.template?
      return render json: {
                      message: "cannot reset_content on a blueprint or template course"
                    },
                    status: :bad_request
    end

    @new_course = @context.reset_content
    Auditors::Course.record_reset(@context, @new_course, @current_user, source: api_request? ? :api : :manual)
    if api_request?
      render json: course_json(@new_course, @current_user, session, [], nil)
    else
      redirect_to course_settings_path(@new_course.id)
    end
  end

  # @API Get effective due dates
  # For each assignment in the course, returns each assigned student's ID
  # and their corresponding due date along with some grading period data.
  # Returns a collection with keys representing assignment IDs and values as a
  # collection containing keys representing student IDs and values representing
  # the student's effective due_at, the grading_period_id of which the due_at falls
  # in, and whether or not the grading period is closed (in_closed_grading_period)
  #
  # @argument assignment_ids[] [Optional, String]
  # The list of assignment IDs for which effective student due dates are
  # requested. If not provided, all assignments in the course will be used.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/effective_due_dates
  #     -X GET \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "1": {
  #        "14": { "due_at": "2015-09-05", "grading_period_id": null, "in_closed_grading_period": false },
  #        "15": { due_at: null, "grading_period_id": 3, "in_closed_grading_period": true }
  #     },
  #     "2": {
  #        "14": { "due_at": "2015-08-05", "grading_period_id": 3, "in_closed_grading_period": true }
  #     }
  #   }
  def effective_due_dates
    return unless authorized_action(@context, @current_user, :read_as_admin)

    assignment_ids = effective_due_dates_params[:assignment_ids]
    unless validate_assignment_ids(assignment_ids)
      return render json: { errors: t("%{assignment_ids} param is invalid", assignment_ids: "assignment_ids") }, status: :unprocessable_entity
    end

    due_dates = if assignment_ids.present?
                  EffectiveDueDates.for_course(@context, assignment_ids)
                else
                  EffectiveDueDates.for_course(@context)
                end

    render json: due_dates.to_hash(%i[
                                     due_at grading_period_id in_closed_grading_period
                                   ])
  end

  # @API Permissions
  # Returns permission information for the calling user in the given course.
  # See also the {api:AccountsController#permissions Account} and
  # {api:GroupsController#permissions Group} counterparts.
  #
  # @argument permissions[] [String]
  #   List of permissions to check against the authenticated user.
  #   Permission names are documented in the {api:RoleOverridesController#add_role Create a role} endpoint.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/permissions \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'permissions[]=manage_grades'
  #       -d 'permissions[]=send_messages'
  #
  # @example_response
  #   {'manage_grades': 'false', 'send_messages': 'true'}
  def permissions
    get_context
    return unless authorized_action(@context, @current_user, :read)

    permissions = Array(params[:permissions]).map(&:to_sym)
    render json: @context.rights_status(@current_user, session, *permissions)
  end

  # @API Get bulk user progress
  # Returns progress information for all users enrolled in the given course.
  #
  # You must be a user who has permission to view all grades in the course (such as a teacher or administrator).
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/bulk_user_progress \
  #       -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   [
  #     {
  #       "id": 1,
  #       "display_name": "Test Student 1",
  #       "avatar_image_url": "https://<canvas>/images/messages/avatar-50.png",
  #       "html_url": "https://<canvas>/courses/1/users/1",
  #       "pronouns": null,
  #       "progress": {
  #         "requirement_count": 2,
  #         "requirement_completed_count": 1,
  #         "next_requirement_url": "https://<canvas>/courses/<course_id>/modules/items/<item_id>",
  #         "completed_at": null
  #       }
  #     },
  #     {
  #       "id": 2,
  #       "display_name": "Test Student 2",
  #       "avatar_image_url": "https://<canvas>/images/messages/avatar-50.png",
  #       "html_url": "https://<canvas>/courses/1/users/2",
  #       "pronouns": null,
  #       "progress": {
  #         "requirement_count": 2,
  #         "requirement_completed_count": 2,
  #         "next_requirement_url": null,
  #         "completed_at": "2021-08-10T16:26:08Z"
  #       }
  #     }
  #   ]
  def bulk_user_progress
    get_context
    return unless authorized_action(@context, @current_user, :view_all_grades)

    unless @context.module_based?
      return render json: {
                      error: { message: "No progress available because this course is not module based (meaning, it does not have modules and module completion requirements)." }
                    },
                    status: :bad_request
    end

    # NOTE: Similar to #user_progress, this endpoint should remain on the primary db
    users = Api.paginate(UserSearch.scope_for(@context, @current_user, enrollment_type: %w[Student]), self, api_v1_course_bulk_user_progress_url)
    cmps = ContextModuleProgression.where(user_id: users.map(&:id))
                                   .joins(:context_module)
                                   .where(context_modules: { context: @context, context_type: "Course" })
    cmps_by_user = cmps.group_by(&:user_id)

    progress = users.map do |user|
      progressions = {}
      progressions[@context.id] = cmps_by_user[user.id] || []
      user_display_json(user, @context).merge(progress: CourseProgress.new(@context, user, read_only: true, preloaded_progressions: progressions).to_json)
    end

    render json: progress.to_json, status: :ok
  end

  def student_view
    get_context
    if authorized_action(@context, @current_user, :use_student_view)
      enter_student_view
    end
  end

  def leave_student_view
    session.delete(:become_user_id)
    return_url = session[:masquerade_return_to]
    session.delete(:masquerade_return_to)
    return_to(return_url, request.referer || dashboard_url)
  end

  def reset_test_student
    get_context
    if @current_user.fake_student? && authorized_action(@context, @real_current_user, :use_student_view)
      # destroy the exising student
      @fake_student = @context.student_view_student
      # but first, remove all existing quiz submissions / submissions

      AssessmentRequest.for_assessee(@fake_student).destroy_all

      @fake_student.destroy

      # destroy these after enrollment so
      # needs_grading_count callbacks work
      ModeratedGrading::Selection.where(student_id: @fake_student).delete_all
      pg_scope = ModeratedGrading::ProvisionalGrade.where(submission_id: @fake_student.all_submissions)
      SubmissionComment.where(provisional_grade_id: pg_scope).delete_all
      pg_scope.delete_all
      OriginalityReport.where(submission_id: @fake_student.all_submissions).delete_all
      AnonymousOrModerationEvent.where(submission: @fake_student.all_submissions).destroy_all
      @fake_student.all_submissions.preload(:all_submission_comments, :submission_drafts, :lti_result, :versions).destroy_all
      @fake_student.quiz_submissions.each { |qs| qs.events.destroy_all }
      @fake_student.quiz_submissions.destroy_all
      @fake_student.learning_outcome_results.preload(:artifact).each { |lor| lor.artifact.destroy }
      @fake_student.learning_outcome_results.destroy_all

      flash[:notice] = t("notices.reset_test_student", "The test student has been reset successfully.")
      enter_student_view
    end
  end

  def enter_student_view
    @fake_student = @context.student_view_student
    session[:become_user_id] = @fake_student.id
    return_url = course_path(@context)
    session.delete(:masquerade_return_to)
    return return_to(request.referer, return_url || dashboard_url) if value_to_boolean(params[:redirect_to_referer])

    return_to(return_url, request.referer || dashboard_url)
  end
  protected :enter_student_view

  def permission_for_event(event)
    @context ||= @course
    case event
    when "offer", "claim"
      if @context.root_account.feature_enabled?(:granular_permissions_manage_courses)
        :manage_courses_publish
      else
        :change_course_state
      end
    when "conclude", "complete"
      if @context.root_account.feature_enabled?(:granular_permissions_manage_courses)
        :manage_courses_conclude
      else
        :change_course_state
      end
    when "delete"
      :delete
    when "undelete"
      if @context.root_account.feature_enabled?(:granular_permissions_manage_courses)
        :delete
      else
        :change_course_state
      end
    else
      :nothing
    end
  end

  def changed_settings(changes, new_settings, old_settings = nil)
    # frd? storing a hash?
    # Settings is stored as a hash in a column which
    # causes us to do some more work if it has been changed.

    # Since course uses write_attribute on settings its not accurate
    # so just ignore it if its in the changes hash
    changes.delete("settings") if changes.key?("settings")

    unless old_settings == new_settings
      settings = Course.settings_options.keys.each_with_object({}) do |key, results|
        old_value = if old_settings.present? && old_settings.key?(key)
                      old_settings[key]
                    else
                      nil
                    end

        new_value = if new_settings.present? && new_settings.key?(key)
                      new_settings[key]
                    else
                      nil
                    end

        results[key.to_s] = [old_value, new_value] unless old_value == new_value
      end
      changes.merge!(settings)
    end

    changes
  end

  def ping
    render json: { success: true }
  end

  def link_validation
    get_context
    return unless authorized_action(@context, @current_user, [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS])

    if (progress = CourseLinkValidator.current_progress(@context))
      render json: progress_json(progress, @current_user, session)
    else
      render json: {}
    end
  end

  # @API Remove quiz migration alert
  #
  # Remove alert about the limitations of quiz migrations that is displayed
  # to a user in a course
  #
  # you must be logged in to use this endpoint
  #
  # @example_response
  #   { "success": "true" }
  def dismiss_migration_limitation_msg
    @course = api_find(Course, params[:id])
    quiz_migration_alert = @course.quiz_migration_alert_for_user(@current_user&.id)
    if quiz_migration_alert
      quiz_migration_alert.destroy
      render json: { success: true }, status: :ok
    else
      render json: { message: "Quiz migration alert not found" }, status: :not_found
    end
  end

  def start_link_validation
    get_context
    return unless authorized_action(@context, @current_user, [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS])

    CourseLinkValidator.queue_course(@context)
    render json: { success: true }
  end

  def link_validator
    authorized_action(@context, @current_user, [:manage_content, *RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS])
    # render view
  end

  def retrieve_observed_enrollments(enrollments, active_by_date: false, observed_user_id: nil)
    observer_enrolls = enrollments.select(&:assigned_observer?)
    unless observed_user_id.nil?
      observer_enrolls = observer_enrolls.select { |e| e.associated_user_id == observed_user_id.to_i }
    end
    ObserverEnrollment.observed_enrollments_for_enrollments(observer_enrolls, active_by_date:)
  end

  def courses_for_user(user, paginate_url: api_v1_courses_url)
    include_observed = params.fetch(:include, []).include?("observed_users")

    if params[:state]
      states = Array(params[:state])
      states += %w[created claimed] if states.include?("unpublished")
      conditions = states.filter_map do |state|
        Enrollment::QueryBuilder.new(nil, course_workflow_state: state, enforce_course_workflow_state: true).conditions
      end.join(" OR ")
      enrollments = user.enrollments.eager_load(:course).where(conditions).shard(user.in_region_associated_shards)

      if params[:enrollment_role]
        enrollments = enrollments.joins(:role).where(roles: { name: params[:enrollment_role] })
      elsif params[:enrollment_role_id]
        enrollments = enrollments.where(role_id: params[:enrollment_role_id].to_i)
      elsif params[:enrollment_type]
        e_type = "#{params[:enrollment_type].capitalize}Enrollment"
        enrollments = enrollments.where(type: e_type)
      end

      case params[:enrollment_state]
      when "active"
        enrollments = enrollments.active_by_date
      when "invited_or_pending"
        enrollments = enrollments.invited_or_pending_by_date
      when "completed"
        enrollments = enrollments.completed_by_date
      end

      if value_to_boolean(params[:current_domain_only])
        enrollments = enrollments.where(root_account_id: @domain_root_account)
      elsif params[:root_account_id]
        root_account = api_find_all(Account, [params[:root_account_id]]).take
        enrollments = root_account ? enrollments.where(root_account_id: root_account) : Enrollment.none
      end

      enrollments = enrollments.to_a
    elsif params[:enrollment_state] == "active"
      enrollments = user.participating_enrollments
      ActiveRecord::Associations.preload(enrollments, :course)
    else
      enrollments = user.cached_currentish_enrollments(preload_courses: true)
    end

    if include_observed
      enrollments.concat(
        retrieve_observed_enrollments(enrollments, active_by_date: (params[:enrollment_state] == "active"), observed_user_id: params[:observed_user_id])
      )
    end

    # we always output the role in the JSON, but we need it now in case we're
    # running the condition below
    ActiveRecord::Associations.preload(enrollments, :role)
    # these are all duplicated in the params[:state] block above in SQL. but if
    # used the cached ones, or we added include_observed, we have to re-run them
    # in pure ruby
    if include_observed || !params[:state]
      if params[:enrollment_role]
        enrollments.select! { |e| e.role.name == params[:enrollment_role] }
      elsif params[:enrollment_role_id]
        enrollments.select! { |e| e.role_id == params[:enrollment_role_id].to_i }
      elsif params[:enrollment_type]
        e_type = "#{params[:enrollment_type].capitalize}Enrollment"
        enrollments.select! { |e| e.class.sti_name == e_type }
      end

      if params[:enrollment_state] && params[:enrollment_state] != "active"
        Canvas::Builders::EnrollmentDateBuilder.preload_state(enrollments)
        case params[:enrollment_state]
        when "invited_or_pending"
          enrollments.select! { |e| e.invited? || e.accepted? }
        when "completed"
          enrollments.select!(&:completed?)
        end
      end

      if value_to_boolean(params[:current_domain_only])
        enrollments = enrollments.select { |e| e.root_account_id == @domain_root_account.id }
      elsif params[:root_account_id]
        root_account = api_find_all(Account, [params[:root_account_id]]).take
        enrollments = root_account ? enrollments.select { |e| e.root_account_id == root_account.id } : []
      end
    end

    includes = Set.new(Array(params[:include]))
    includes << "access_restricted_by_date"
    # We only want to return the permissions for single courses and not lists of courses.
    includes.delete "permissions"

    hash = []

    if enrollments.any? && value_to_boolean(params[:exclude_blueprint_courses])
      mc_ids = MasterCourses::MasterTemplate.active.where(course_id: enrollments.map(&:course_id)).pluck(:course_id)
      enrollments.reject! { |e| mc_ids.include?(e.course_id) }
    end

    if value_to_boolean(params[:homeroom])
      homeroom_ids = Course.homeroom.where(id: enrollments.map(&:course_id)).pluck(:id)
      enrollments.reject! { |e| homeroom_ids.exclude?(e.course_id) }
    end

    if params[:account_id]
      account = api_find(Account.active, params[:account_id])
      enrollments = enrollments.select { |e| e.course.account == account }
    end

    Canvas::Builders::EnrollmentDateBuilder.preload_state(enrollments)
    enrollments_by_course = enrollments.group_by(&:course_id).values
    enrollments_by_course.sort_by! do |course_enrollments|
      Canvas::ICU.collation_key(course_enrollments.first.course.nickname_for(@current_user))
    end
    enrollments_by_course = Api.paginate(enrollments_by_course, self, paginate_url) if api_request?
    courses = enrollments_by_course.map { |ces| ces.first.course }
    preloads = %i[account root_account]
    preload_teachers(courses) if includes.include?("teachers")
    preloads << :grading_standard if includes.include?("total_scores")
    preloads << :account if includes.include?("subaccount") || includes.include?("account")
    if includes.include?("current_grading_period_scores") || includes.include?("grading_periods")
      preloads << { enrollment_term: { grading_period_group: :grading_periods } }
      preloads << { grading_period_groups: :grading_periods }
    end
    preloads << { context_modules: :content_tags } if includes.include?("course_progress")
    preloads << :enrollment_term if includes.include?("term") || includes.include?("concluded")
    ActiveRecord::Associations.preload(courses, preloads)
    MasterCourses::MasterTemplate.preload_is_master_course(courses)

    preloads = []
    preloads << :course_section if includes.include?("sections")
    preloads << { scores: :course } if includes.include?("total_scores") || includes.include?("current_grading_period_scores")

    ActiveRecord::Associations.preload(enrollments, preloads) unless preloads.empty?
    if includes.include?("course_progress")
      progressions = ContextModuleProgression.joins(:context_module).where(user:, context_modules: { course: courses }).select("context_module_progressions.*, context_modules.context_id AS course_id").to_a.group_by { |cmp| cmp["course_id"] }
    end

    permissions_to_precalculate = [:read_sis, :manage_sis]
    if includes.include?("tabs")
      permissions_to_precalculate += SectionTabHelper::PERMISSIONS_TO_PRECALCULATE

      # TODO: move granular user permissions to SectionTabHelper::PERMISSIONS_TO_PRECALCULATE
      # when removing :granular_permissions_manage_users flag
      if @domain_root_account.feature_enabled?(:granular_permissions_manage_users)
        permissions_to_precalculate += RoleOverride::GRANULAR_MANAGE_USER_PERMISSIONS
      end
    end

    all_precalculated_permissions = @current_user.precalculate_permissions_for_courses(courses, permissions_to_precalculate)
    Course.preload_menu_data_for(courses, @current_user, preload_favorites: true)

    enrollments_by_course.each do |course_enrollments|
      course = course_enrollments.first.course
      hash << course_json(course,
                          @current_user,
                          session,
                          includes,
                          course_enrollments,
                          user,
                          preloaded_progressions: progressions,
                          precalculated_permissions: all_precalculated_permissions&.dig(course.global_id))
    end
    hash
  end

  def require_user_or_observer
    return render_unauthorized_action unless @current_user.present?

    @user = (params[:user_id] == "self") ? @current_user : api_find(User, params[:user_id])
    unless @user.grants_right?(@current_user, :read) || @user.check_accounts_right?(@current_user, :read)
      render_unauthorized_action
    end
  end

  def visibility_configuration(params)
    @course.apply_visibility_configuration(params[:course_visibility])

    if params[:custom_course_visibility].present? && !value_to_boolean(params[:custom_course_visibility])
      Course::CUSTOMIZABLE_PERMISSIONS.each_key do |key|
        @course.apply_custom_visibility_configuration(key, "inherit")
      end
    else
      Course::CUSTOMIZABLE_PERMISSIONS.each_key do |key|
        @course.apply_custom_visibility_configuration(key, params[:"#{key}_visibility_option"])
      end
    end
  end

  def can_change_group_weighting_scheme?
    return true unless @course.grading_periods?
    return true if @course.account_membership_allows(@current_user)

    !@course.any_assignment_in_closed_grading_period?
  end

  def offline_web_exports
    return render status: :not_found, template: "shared/errors/404_message" unless allow_web_export_download?

    if authorized_action(WebZipExport.new(course: @context), @current_user, :create)
      title = t("Exported Package History")
      @page_title = title
      add_crumb(title)
      js_bundle :webzip_export
      css_bundle :webzip_export
      render html: '<div id="course-webzip-export-app"></div>'.html_safe, layout: true
    end
  end

  def start_offline_web_export
    return render status: :not_found, template: "shared/errors/404_message" unless allow_web_export_download?

    if authorized_action(WebZipExport.new(course: @context), @current_user, :create)
      @service = EpubExports::CreateService.new(@context, @current_user, :web_zip_export)
      @service.save
      redirect_to context_url(@context, :context_offline_web_exports_url)
    end
  end

  def visible_self_enrollment_option
    if @context.available? &&
       @context.self_enrollment_enabled? &&
       @context.open_enrollment &&
       (!@context_enrollment || !@context_enrollment.active?)
      :enroll
    elsif @context_enrollment&.self_enrolled && @context_enrollment&.active?
      :unenroll
    end
  end
  helper_method :visible_self_enrollment_option

  private

  def validate_assignment_ids(assignment_ids)
    assignment_ids.nil? || assignment_ids.all?(/\A\d+\z/)
  end

  def observee_selected?
    @selected_observed_user.present? && @selected_observed_user != @current_user
  end

  def update_grade_passback_setting(grade_passback_setting)
    valid_states = ["nightly_sync", "disabled"]
    unless grade_passback_setting.blank? || valid_states.include?(grade_passback_setting)
      @course.errors.add(:grade_passback_setting, t("Invalid grade_passback_setting"))
    end
    @course.grade_passback_setting = grade_passback_setting.presence
  end

  def active_group_memberships(users)
    @active_group_memberships ||= GroupMembership.active_for_context_and_users(@context, users).group_by(&:user_id)
  end

  def effective_due_dates_params
    params.permit(assignment_ids: [])
  end

  def manage_admin_users_perm
    if @context.root_account.feature_enabled?(:granular_permissions_manage_users)
      :allow_course_admin_actions
    else
      :manage_admin_users
    end
  end

  def course_params
    return {} unless params[:course]

    params[:course].permit(
      :name,
      :group_weighting_scheme,
      :start_at,
      :conclude_at,
      :grading_standard_id,
      :grade_passback_setting,
      :is_public,
      :is_public_to_auth_users,
      :allow_student_wiki_edits,
      :show_public_context_messages,
      :syllabus_body,
      :syllabus_course_summary,
      :public_description,
      :allow_student_forum_attachments,
      :allow_student_discussion_topics,
      :allow_student_discussion_editing,
      :show_total_grade_as_points,
      :default_wiki_editing_roles,
      :allow_student_organized_groups,
      :course_code,
      :default_view,
      :open_enrollment,
      :allow_wiki_comments,
      :turnitin_comments,
      :self_enrollment,
      :license,
      :indexed,
      :abstract_course,
      :storage_quota,
      :storage_quota_mb,
      :restrict_enrollments_to_course_dates,
      :use_rights_required,
      :restrict_student_past_view,
      :restrict_student_future_view,
      :restrict_quantitative_data,
      :grading_standard,
      :grading_standard_enabled,
      :course_grading_standard_enabled,
      :locale,
      :integration_id,
      :hide_final_grades,
      :hide_distribution_graphs,
      :hide_sections_on_course_users_page,
      :lock_all_announcements,
      :public_syllabus,
      :quiz_engine_selected,
      :public_syllabus_to_auth,
      :course_format,
      :time_zone,
      :organize_epub_by_content_type,
      :enable_offline_web_export,
      :show_announcements_on_home_page,
      :home_page_announcement_limit,
      :allow_final_grade_override,
      :filter_speed_grader_by_student_group,
      :homeroom_course,
      :template,
      :course_color,
      :homeroom_course_id,
      :sync_enrollments_from_homeroom,
      :friendly_name,
      :enable_course_paces,
      :default_due_time,
      :conditional_release
    )
  end

  def disable_conditional_release
    ConditionalRelease::Service.delay_if_production(priority: Delayed::LOW_PRIORITY,
                                                    n_strand: ["conditional_release_unassignment", @course.global_root_account_id])
                               .release_mastery_paths_content_in_course(@course)
  end
end
