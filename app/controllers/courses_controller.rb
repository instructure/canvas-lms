#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

require 'atom'
require 'set'
require 'securerandom'

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
#         "integration_id": {
#           "description": "the integration identifier for the course, if defined. This field is only included if the user has permission to view SIS information.",
#           "type": "string"
#         },
#         "name": {
#           "description": "the full name of the course",
#           "example": "InstructureCon 2012",
#           "type": "string"
#         },
#         "course_code": {
#           "description": "the course code",
#           "example": "INSTCON12",
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
#         "grading_standard_id": {
#            "description": "the grading standard associated with the course",
#            "example": 25,
#            "type": "integer"
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
#           "description": "optional (beta): information on progress through the course returned only if include[]=course_progress",
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
  include CustomSidebarLinksHelper
  include SyllabusHelper

  before_filter :require_user, :only => [:index, :activity_stream, :activity_stream_summary, :effective_due_dates, :offline_web_exports, :start_offline_web_export]
  before_filter :require_user_or_observer, :only=>[:user_index]
  before_filter :require_context, :only => [:roster, :locks, :create_file, :ping, :effective_due_dates, :offline_web_exports, :start_offline_web_export]
  skip_after_filter :update_enrollment_last_activity_at, only: [:enrollment_invitation, :activity_stream_summary]

  include Api::V1::Course
  include Api::V1::Progress

  # @API List your courses
  # Returns the list of active courses for the current user.
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
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"public_description"|"total_scores"|"current_grading_period_scores"|"term"|"course_progress"|"sections"|"storage_quota_used_mb"|"total_students"|"passback_status"|"favorites"|"teachers"|"observed_users"|"course_image"]
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
  #     'multiple_grading_periods_enabled',
  #     'totals_for_all_grading_periods_option', 'current_grading_period_title',
  #     'current_grading_period_id', current_period_computed_current_score',
  #     'current_period_computed_final_score',
  #     'current_period_computed_current_grade', and
  #     'current_period_computed_final_grade' (see Enrollment documentation for
  #     more information on these fields). In addition, when this argument is
  #     passed, the course will have a 'multiple_grading_periods_enabled' attribute
  #     on it. This argument is ignored if the course is configured to hide final
  #     grades or if the total_scores argument is not included.
  #   - "term": Optional information to include with each Course. When
  #     term is given, the information for the enrollment term for each course
  #     is returned.
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
  #   - "course_image": Optional course image data for when there is a course image
  #     and the course image feature flag has been enabled
  #
  # @argument state[] [String, "unpublished"|"available"|"completed"|"deleted"]
  #   If set, only return courses that are in the given state(s).
  #   By default, "available" is returned for students and observers, and
  #   anything except "deleted", for all other enrollment types
  #
  # @returns [Course]
  def index
    respond_to do |format|
      format.html {
        all_enrollments = @current_user.enrollments.not_deleted.shard(@current_user).to_a
        @past_enrollments = []
        @current_enrollments = []
        @future_enrollments  = []
        Canvas::Builders::EnrollmentDateBuilder.preload(all_enrollments)
        all_enrollments.group_by{|e| [e.course_id, e.type]}.values.each do |enrollments|
          e = enrollments.sort_by{|e| e.state_with_date_sortable}.first
          if enrollments.count > 1
            e.course_section = nil
            e.readonly!
          end

          state = e.state_based_on_date
          if [:completed, :rejected].include?(state)
            @past_enrollments << e unless e.workflow_state == "invited" || e.restrict_past_view?
          else
            start_at, end_at = e.enrollment_dates.first
            if start_at && start_at > Time.now.utc
              @future_enrollments << e unless e.restrict_future_listing?
            elsif state != :inactive
              @current_enrollments << e
            end
          end
        end
        @visible_groups = @current_user.visible_groups

        @past_enrollments.sort_by!{|e| Canvas::ICU.collation_key(e.long_name(@current_user))}
        [@current_enrollments, @future_enrollments].each{|list| list.sort_by!{|e| [e.active? ? 1 : 0, Canvas::ICU.collation_key(e.long_name(@current_user))] }}
      }

      format.json {
        render json: courses_for_user(@current_user)
      }
    end
  end

  # @API List courses for a user
  # Returns a list of active courses for this user. To view the course list for a user other than yourself, you must be either an observer of that user or an administrator.
  #
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"public_description"|"total_scores"|"current_grading_period_scores"|"term"|"course_progress"|"sections"|"storage_quota_used_mb"|"total_students"|"passback_status"|"favorites"|"teachers"|"observed_users"|"course_image"]
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
  #     'multiple_grading_periods_enabled',
  #     'totals_for_all_grading_periods_option', 'current_grading_period_title',
  #     'current_grading_period_id', current_period_computed_current_score',
  #     'current_period_computed_final_score',
  #     'current_period_computed_current_grade', and
  #     'current_period_computed_final_grade' (see Enrollment documentation for
  #     more information on these fields). In addition, when this argument is
  #     passed, the course will have a 'multiple_grading_periods_enabled' attribute
  #     on it. This argument is ignored if the course is configured to hide final
  #     grades or if the total_scores argument is not included.
  #   - "term": Optional information to include with each Course. When
  #     term is given, the information for the enrollment term for each course
  #     is returned.
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
  #   - "course_image": Optional course image data for when there is a course image
  #     and the course image feature flag has been enabled
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
  # @returns [Course]
  def user_index
    @user.shard.activate do
      render json: courses_for_user(@user, paginate_url: api_v1_user_courses_url(@user))
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
  #
  # @argument course[end_at] [DateTime]
  #   Course end date in ISO8601 format. e.g. 2011-01-01T01:00Z
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
  #   course.
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
  # @argument course[syllabus_body] [String]
  #   The syllabus body for the course
  #
  # @argument course[grading_standard_id] [Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
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

      if params_for_create.has_key?(:syllabus_body)
        params_for_create[:syllabus_body] = process_incoming_html_content(params_for_create[:syllabus_body])
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

      unless @account.grants_right? @current_user, session, :manage_storage_quotas
        params_for_create.delete :storage_quota
        params_for_create.delete :storage_quota_mb
      end

      can_manage_sis = api_request? && @account.grants_right?(@current_user, :manage_sis)
      if can_manage_sis && value_to_boolean(params[:enable_sis_reactivation])
        @course = @domain_root_account.all_courses.where(
          :sis_source_id => sis_course_id, :workflow_state => 'deleted').first
        if @course
          @course.workflow_state = 'claimed'
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

      changes = changed_settings(@course.changes, @course.settings)

      respond_to do |format|
        if @course.save
          Auditors::Course.record_created(@course, @current_user, changes, source: (api_request? ? :api : :manual))
          @course.enroll_user(@current_user, 'TeacherEnrollment', :enrollment_state => 'active') if params[:enroll_me].to_s == 'true'
          @course.require_assignment_group rescue nil
          # offer updates the workflow state, saving the record without doing validation callbacks
          if api_request? and value_to_boolean(params[:offer])
            @course.offer
            Auditors::Course.record_published(@course, @current_user, source: :api)
          end
          format.html { redirect_to @course }
          format.json { render :json => course_json(
            @course,
            @current_user,
            session,
            [:start_at, course_end, :license,
             :is_public, :is_public_to_auth_users, :public_syllabus, :public_syllabus_to_auth, :allow_student_assignment_edits, :allow_wiki_comments,
             :allow_student_forum_attachments, :open_enrollment, :self_enrollment,
             :root_account_id, :account_id, :public_description,
             :restrict_enrollments_to_course_dates, :hide_final_grades], nil)
          }
        else
          flash[:error] = t('errors.create_failed', "Course creation failed")
          format.html { redirect_to :root_url }
          format.json { render :json => @course.errors, :status => :bad_request }
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
    @attachment = Attachment.new(:context => @context)
    if authorized_action(@attachment, @current_user, :create)
      api_attachment_preflight(@context, request, :check_quota => true)
    end
  end

  def backup
    get_context
    if authorized_action(@context, @current_user, :update)
      backup_json = @context.backup_to_json
      send_file_headers!( :length=>backup_json.length, :filename=>"#{@context.name.underscore.gsub(/\s/, "_")}_#{Time.zone.today}_backup.instructure", :disposition => 'attachment', :type => 'application/instructure')
      render :text => proc {|response, output|
        output.write backup_json
      }
    end
  end

  def restore
    get_context
    if authorized_action(@context, @current_user, :update)
      respond_to do |format|
        if params[:restore]
          @context.restore_from_json_backup(params[:restore])
          flash[:notice] = t('notices.backup_restored', "Backup Successfully Restored!")
          format.html { redirect_to named_context_url(@context, :context_url) }
        else
          format.html
        end
      end
    end
  end

  def unconclude
    get_context
    if authorized_action(@context, @current_user, :change_course_state)
      @context.unconclude
      Auditors::Course.record_unconcluded(@context, @current_user, source: (api_request? ? :api : :manual))
      flash[:notice] = t('notices.unconcluded', "Course un-concluded")
      redirect_to(named_context_url(@context, :context_url))
    end
  end

  include Api::V1::User

  # @API List students
  #
  # Returns the list of students enrolled in this course.
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
      render :json => proxy.map { |u| user_json(u, @current_user, session) }
    end
  end

  # @API List users in course
  # Returns the list of users in this course. And optionally the user's enrollments in the course.
  #
  # @argument search_term [String]
  #   The partial name or full ID of the users to match and return in the results list.
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
  # @argument include[] [String, "email"|"enrollments"|"locked"|"avatar_url"|"test_student"|"bio"|"custom_links"]
  #   - "email": Optional user email.
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
    get_context
    if authorized_action(@context, @current_user, [:read_roster, :view_all_grades, :manage_grades])
      #backcompat limit param
      params[:per_page] ||= params[:limit]

      search_params = params.slice(:search_term, :enrollment_role, :enrollment_role_id, :enrollment_type, :enrollment_state)
      include_inactive = @context.grants_right?(@current_user, session, :read_as_admin) && (!params.has_key?(:include_inactive) || value_to_boolean(params[:include_inactive]))

      search_params[:include_inactive_enrollments] = true if include_inactive
      search_term = search_params[:search_term].presence

      if search_term
        users = UserSearch.for_user_in_context(search_term, @context, @current_user, session, search_params)
      else
        users = UserSearch.scope_for(@context, @current_user, search_params)
      end
      # If a user_id is passed in, modify the page parameter so that the page
      # that contains that user is returned.
      # We delete it from params so that it is not maintained in pagination links.
      user_id = params[:user_id]
      if user_id.present? && user = users.where(:users => { :id => user_id }).first
        position_scope = users.where("#{User.sortable_name_order_by_clause}<=#{User.best_unicode_collation_key('?')}", user.sortable_name)
        position = position_scope.uniq.count(:all)
        per_page = Api.per_page_for(self)
        params[:page] = (position.to_f / per_page.to_f).ceil
      end

      user_ids = params[:user_ids]
      if user_ids.present?
        users = users.where(id: user_ids)
      end

      users = Api.paginate(users, self, api_v1_course_users_url)
      includes = Array(params[:include])
      user_json_preloads(
        users,
        includes.include?('email'),
        group_memberships: includes.include?('group_ids')
      )
      unless includes.include?('test_student') || Array(params[:enrollment_type]).include?("student_view")
        users.reject! do |u|
          u.preferences[:fake_student]
        end
      end
      if includes.include?('enrollments')
        enrollment_scope = @context.enrollments.
          where(user_id: users).
          preload(:course)

        if search_params[:enrollment_state]
          enrollment_scope = enrollment_scope.where(:workflow_state => search_params[:enrollment_state])
        else
          enrollment_scope = include_inactive ? enrollment_scope.all_active_or_pending : enrollment_scope.active_or_pending
        end
        enrollments_by_user = enrollment_scope.group_by(&:user_id)
      end
      render :json => users.map { |u|
        enrollments = enrollments_by_user[u.id] || [] if includes.include?('enrollments')
        user_json(u, @current_user, session, includes, @context, enrollments)
      }
    end
  end

  # @API List recently logged in students
  #
  # Returns the list of users in this course, ordered by how recently they have
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
      scope = User.for_course_with_last_login(@context, @context.root_account_id, 'StudentEnrollment')
      scope = scope.order('login_info_exists, last_login DESC')
      users = Api.paginate(scope, self, api_v1_course_recent_students_url)
      user_json_preloads(users)
      render :json => users.map { |u| user_json(u, @current_user, session, ['last_login']) }
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
      users = api_find_all(@context.users_visible_to(@current_user), [params[:id]])
      includes = Array(params[:include])
      user_json_preloads(users, includes.include?('email'))
      if includes.include?('enrollments')
        # not_ended_enrollments for enrollment_json
        # enrollments course for has_grade_permissions?
        ActiveRecord::Associations::Preloader.new.preload(users, :not_ended_enrollments, Enrollment.where(:course_id => @context))
        ActiveRecord::Associations::Preloader.new.preload(users, {:not_ended_enrollments => :course})
      end
      user = users.first or raise ActiveRecord::RecordNotFound
      enrollments = user.not_ended_enrollments if includes.include?('enrollments')
      render :json => user_json(user, @current_user, session, includes, @context, enrollments)
    end
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
      api_render_stream_summary([@context])
    end
  end

  include Api::V1::TodoItem
  # @API Course TODO items
  # Returns the current user's course-specific todo items.
  #
  # For full documentation, see the API documentation for the user todo items, in the user api.
  def todo_items
    get_context
    if authorized_action(@context, @current_user, :read)
      grading = @current_user.assignments_needing_grading(:contexts => [@context]).map { |a| todo_item_json(a, @current_user, session, 'grading') }
      submitting = @current_user.assignments_needing_submitting(:include_ungraded => true, :contexts => [@context]).map { |a| todo_item_json(a, @current_user, session, 'submitting') }
      if Array(params[:include]).include? 'ungraded_quizzes'
        submitting += @current_user.ungraded_quizzes_needing_submitting(:contexts => [@context]).map { |q| todo_item_json(q, @current_user, session, 'submitting') }
        submitting.sort_by! { |j| (j[:assignment] || j[:quiz])[:due_at] }
      end
      render :json => (grading + submitting)
    end
  end

  # @API Conclude a course
  # Delete or conclude an existing course
  #
  # @argument event [Required, String, "delete"|"conclude"]
  #   The action to take on the course.
  def destroy
    @context = api_find(Course, params[:id])
    if api_request? && !['delete', 'conclude'].include?(params[:event])
      return render(:json => { :message => 'Only "delete" and "conclude" events are allowed.' }, :status => :bad_request)
    end
    if params[:event] != 'conclude' && (@context.created? || @context.claimed? || params[:event] == 'delete')
      return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))
      @context.destroy
      Auditors::Course.record_deleted(@context, @current_user, source: (api_request? ? :api : :manual))
      flash[:notice] = t('notices.deleted', "Course successfully deleted")
    else
      return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))

      @context.complete
      if @context.save
        Auditors::Course.record_concluded(@context, @current_user, source: (api_request? ? :api : :manual))
        flash[:notice] = t('notices.concluded', "Course successfully concluded")
      else
        flash[:notice] = t('notices.failed_conclude', "Course failed to conclude")
      end
    end
    @current_user.touch
    respond_to do |format|
      format.html { redirect_to dashboard_url }
      format.json {
        render :json => { params[:event] => true }
      }
    end
  end

  def statistics
    get_context
    if authorized_action(@context, @current_user, :read_reports)
      @student_ids = @context.student_ids
      @range_start = Date.parse("Jan 1 2000")
      @range_end = Date.tomorrow

      query = "SELECT COUNT(id), SUM(size) FROM #{Attachment.quoted_table_name} WHERE context_id=%s AND context_type='Course' AND root_attachment_id IS NULL AND file_state != 'deleted'"
      row = Attachment.connection.select_rows(query % [@context.id]).first
      @file_count, @files_size = [row[0].to_i, row[1].to_i]
      query = "SELECT COUNT(id), SUM(max_size) FROM #{MediaObject.quoted_table_name} WHERE context_id=%s AND context_type='Course' AND attachment_id IS NULL AND workflow_state != 'deleted'"
      row = MediaObject.connection.select_rows(query % [@context.id]).first
      @media_file_count, @media_files_size = [row[0].to_i, row[1].to_i]

      if params[:range] && params[:date]
        date = Date.parse(params[:date]) rescue nil
        date ||= Time.zone.today
        if params[:range] == 'week'
          @view_week = (date - 1) - (date - 1).wday + 1
          @range_start = @view_week
          @range_end = @view_week + 6
          @old_range_start = @view_week - 7.days
        elsif params[:range] == 'month'
          @view_month = Date.new(date.year, date.month, d=1) #view.created_at.strftime("%m:%Y")
          @range_start = @view_month
          @range_end = (@view_month >> 1) - 1
          @old_range_start = @view_month << 1
        end
      end

      respond_to do |format|
        format.html do
          js_env(:RECENT_STUDENTS_URL => api_v1_course_recent_students_url(@context))
        end
        format.json { render :json => @categories }
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
  #     "lock_all_announcements": true
  #   }
  def settings
    get_context
    if authorized_action(@context, @current_user, :read_as_admin)
      if api_request?
        render :json => course_settings_json(@context)
        return
      end

      load_all_contexts(:context => @context)

      @all_roles = Role.custom_roles_and_counts_for_course(@context, @current_user, true)

      @invited_count = @context.invited_count_visible_to(@current_user)

      @publishing_enabled = @context.allows_grade_publishing_by(@current_user) &&
        can_do(@context, @current_user, :manage_grades)

      @alerts = @context.alerts
      add_crumb(t('#crumbs.settings', "Settings"), named_context_url(@context, :context_details_url))

      js_env({
        COURSE_ID: @context.id,
        USERS_URL: "/api/v1/courses/#{@context.id}/users",
        ALL_ROLES: @all_roles,
        COURSE_ROOT_URL: "/courses/#{@context.id}",
        SEARCH_URL: search_recipients_url,
        CONTEXTS: @contexts,
        USER_PARAMS: {:include => ['email', 'enrollments', 'locked', 'observed_users']},
        PERMISSIONS: {
          :manage_students => @context.grants_right?(@current_user, session, :manage_students),
          :manage_admin_users => @context.grants_right?(@current_user, session, :manage_admin_users),
          :manage_account_settings => @context.account.grants_right?(@current_user, session, :manage_account_settings),
          :create_tool_manually => @context.grants_right?(@current_user, session, :create_tool_manually),
        },
        APP_CENTER: {
          enabled: Canvas::Plugin.find(:app_center).enabled?
        },
        LTI_LAUNCH_URL: course_tool_proxy_registration_path(@context),
        CONTEXT_BASE_URL: "/courses/#{@context.id}",
        PUBLISHING_ENABLED: @publishing_enabled,
        COURSE_IMAGES_ENABLED: @context.feature_enabled?(:course_card_images)
      })

      @course_settings_sub_navigation_tools = ContextExternalTool.all_tools_for(@context, :type => :course_settings_sub_navigation, :root_account => @domain_root_account, :current_user => @current_user)
      unless @context.grants_right?(@current_user, session, :read_as_admin)
        @course_settings_sub_navigation_tools.reject! { |tool| tool.course_settings_sub_navigation(:visibility) == 'admins' }
      end
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
  #   Let students edit or delete their own discussion posts
  #
  # @argument allow_student_organized_groups [Boolean]
  #   Let students organize their own groups
  #
  # @argument hide_final_grades [Boolean]
  #   Hide totals in student grades summary
  #
  # @argument hide_distribution_graphs [Boolean]
  #   Hide grade distribution graphs from students
  #
  # @argument lock_all_announcements [Boolean]
  #   Disable comments on announcements
  #
  # @argument restrict_student_past_view [Boolean]
  #   Restrict students from viewing courses after end date
  #
  # @argument restrict_student_future_view [Boolean]
  #   Restrict students from viewing courses before start date
  #
  # @argument show_announcements_on_home_page [Boolean]
  #   Show the most recent announcements on the Course home page (if a Wiki, defaults to five announcements, configurable via home_page_announcement_limit)
  #
  # @argument home_page_announcement_limit [Integer]
  #   Limit the number of announcements on the home page if enabled via show_announcements_on_home_page
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/settings \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'allow_student_discussion_topics=false'
  def update_settings
    return unless api_request?
    @course = api_find(Course, params[:course_id])
    return unless authorized_action(@course, @current_user, :update)

    old_settings = @course.settings
    @course.attributes = params.permit(
      :allow_student_discussion_topics,
      :allow_student_forum_attachments,
      :allow_student_discussion_editing,
      :show_total_grade_as_points,
      :allow_student_organized_groups,
      :hide_final_grades,
      :hide_distribution_graphs,
      :lock_all_announcements,
      :restrict_student_past_view,
      :restrict_student_future_view,
      :show_announcements_on_home_page,
      :home_page_announcement_limit
    )
    changes = changed_settings(@course.changes, @course.settings, old_settings)
    @course.send_later_if_production_enqueue_args(:touch_content_if_public_visibility_changed,
      { :priority => Delayed::LOW_PRIORITY }, changes)

    if @course.save
      Auditors::Course.record_updated(@course, @current_user, changes, source: :api)
      render :json => course_settings_json(@course)
    else
      render :json => @course.errors, :status => :bad_request
    end
  end

  def update_nav
    get_context
    if authorized_action(@context, @current_user, :update)
      @context.tab_configuration = JSON.parse(params[:tabs_json])
      @context.save
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_details_url) }
        format.json { render :json => {:update_nav => true} }
      end
    end
  end

  def re_send_invitations
    get_context
    if authorized_action(@context, @current_user, [:manage_students, :manage_admin_users])
      @context.send_later_if_production(:re_send_invitations!, @current_user)

      respond_to do |format|
        format.html { redirect_to course_settings_url }
        format.json { render :json => {:re_sent => true} }
      end
    end
  end

  def enrollment_invitation
    get_context

    return if check_enrollment(true)
    return !!redirect_to(course_url(@context.id)) unless @pending_enrollment

    if params[:reject]
      return reject_enrollment(@pending_enrollment)
    elsif params[:accept]
      return accept_enrollment(@pending_enrollment)
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
      if enrollment.workflow_state == 'invited'
        enrollment.accept!
        @pending_enrollment = nil
        flash[:notice] = t('notices.invitation_accepted', 'Invitation accepted!  Welcome to %{course}!', :course => @context.name)
      end

      session[:accepted_enrollment_uuid] = enrollment.uuid

      if params[:action] != 'show'
        redirect_to course_url(@context.id)
      else
        @context_enrollment = enrollment
        enrollment = nil
        return false
      end
    elsif !@current_user && enrollment.user.registered? || !enrollment.user.email_channel
      session[:return_to] = course_url(@context.id)
      flash[:notice] = t('notices.login_to_accept', "You'll need to log in before you can accept the enrollment.")
      return redirect_to login_url(:force_login => 1) if @current_user
      redirect_to login_url
    else
      # defer to CommunicationChannelsController#confirm for the logic of merging users
      redirect_to registration_confirmation_path(enrollment.user.email_channel.confirmation_code, :enrollment => enrollment.uuid)
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
      enrollment.reject!
      flash[:notice] = t('notices.invitation_cancelled', 'Invitation canceled.')
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

    if enrollment = fetch_enrollment
      if enrollment.state_based_on_date == :inactive && !ignore_restricted_courses
        flash[:notice] = t('notices.enrollment_not_active', 'Your membership in the course, %{course}, is not yet activated', :course => @context.name)
        return !!redirect_to(enrollment.workflow_state == 'invited' ? courses_url : dashboard_url)
      end

      if enrollment.rejected?
        enrollment.workflow_state = 'invited'
        enrollment.save_without_broadcasting
      end

      if enrollment.self_enrolled?
        return !!redirect_to(registration_confirmation_path(enrollment.user.email_channel.confirmation_code, :enrollment => enrollment.uuid))
      end

      session[:enrollment_uuid] = enrollment.uuid
      session[:enrollment_uuid_course_id] = enrollment.course_id
      session[:permissions_key] = SecureRandom.uuid

      @pending_enrollment = enrollment

      if @context.root_account.allow_invitation_previews? || enrollment.admin?
        flash[:notice] = t('notices.preview_course', "You've been invited to join this course.  You can look around, but you'll need to accept the enrollment invitation before you can participate.")
      elsif params[:action] != "enrollment_invitation"
        # directly call the next action; it's just going to redirect anyway, so no need to have
        # an additional redirect to get to it
        params[:accept] = 1
        return enrollment_invitation
      end
    end

    if session[:accepted_enrollment_uuid].present? &&
      enrollment = @context.enrollments.where(uuid: session[:accepted_enrollment_uuid]).first

      success = false
      if enrollment.invited?
        success = enrollment.accept!
        flash[:notice] = t('notices.invitation_accepted', "Invitation accepted!  Welcome to %{course}!", :course => @context.name)
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
    enrollment = @context_enrollment if @context_enrollment && @context_enrollment.pending? && (@context_enrollment.uuid == params[:invitation] || params[:invitation].blank?)
    @current_user.reload if @context_enrollment && @context_enrollment.enrollment_state.user_needs_touch # needed to prevent permission caching

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
      locks_hash = Rails.cache.fetch(['locked_for_results', @current_user, Digest::MD5.hexdigest(params[:assets])].cache_key) do
        locks = {}
        types.each do |type, ids|
          if type == 'assignment'
            @context.assignments.active.where(id: ids).each do |assignment|
              locks[assignment.asset_string] = assignment.locked_for?(@current_user)
            end
          elsif type == 'quiz'
            @context.quizzes.active.include_assignment.where(id: ids).each do |quiz|
              locks[quiz.asset_string] = quiz.locked_for?(@current_user)
            end
          elsif type == 'discussion_topic'
            @context.discussion_topics.active.where(id: ids).each do |topic|
              locks[topic.asset_string] = topic.locked_for?(@current_user)
            end
          end
        end
        locks
      end
      render :json => locks_hash
    end
  end

  def self_unenrollment
    get_context
    if @context_enrollment && params[:self_unenrollment] && params[:self_unenrollment] == @context_enrollment.uuid && @context_enrollment.self_enrolled?
      @context_enrollment.conclude
      render :json => ""
    else
      render :json => "", :status => :bad_request
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
        e = @context.enrollments.where(uuid: uuid).first
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
    xlist_enrollment = @current_user.enrollments.active.joins(:course_section).
      where(:course_sections => { :nonxlist_course_id => @context }).first
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

  # @API Get a single course
  # Return information on a single course.
  #
  # Accepts the same include[] parameters as the list action plus:
  #
  # @argument include[] [String, "needs_grading_count"|"syllabus_body"|"public_description"|"total_scores"|"current_grading_period_scores"|"term"|"course_progress"|"sections"|"storage_quota_used_mb"|"total_students"|"passback_status"|"favorites"|"teachers"|"observed_users"|"all_courses"|"permissions"|"observed_users"|"course_image"]
  #   - "all_courses": Also search recently deleted courses.
  #   - "permissions": Include permissions the current user has
  #     for the course.
  #   - "observed_users": include observed users in the enrollments
  #   - "course_image": Optional course image data for when there is a course image
  #     and the course image feature flag has been enabled
  #
  # @returns Course
  def show
    if api_request?
      includes = Set.new(Array(params[:include]))

      if params[:account_id]
        @account = api_find(Account.active, params[:account_id])
        scope = @account.associated_courses
      else
        scope = Course
      end

      if !includes.member?("all_courses")
        scope = scope.not_deleted
      end
      @course = api_find(scope, params[:id])

      if authorized_action(@course, @current_user, :read)
        enrollments = @course.current_enrollments.where(:user_id => @current_user).to_a
        if includes.include?("observed_users") &&
            enrollments.any?(&:assigned_observer?)
          enrollments.concat(ObserverEnrollment.observed_enrollments_for_courses(@course, @current_user))
        end

        includes << :hide_final_grades
        render :json => course_json(@course, @current_user, session, includes, enrollments)
      end
      return
    end


    @context = api_find(Course.active, params[:id])
    assign_localizer
    if request.xhr?
      if authorized_action(@context, @current_user, [:read, :read_as_admin])
        render :json => @context
      end
      return
    end

    if @context && @current_user
      @context_enrollment = @context.enrollments.where(user_id: @current_user).except(:preload).first
      if @context_enrollment
        @context_membership = @context_enrollment # for AUA
        @context_enrollment.course = @context
        @context_enrollment.user = @current_user
      end
    end

    return if check_for_xlist
    @unauthorized_message = t('unauthorized.invalid_link', "The enrollment link you used appears to no longer be valid.  Please contact the course instructor and make sure you're still correctly enrolled.") if params[:invitation]
    claim_course if session[:claim_course_uuid] || params[:verification]
    @context.claim if @context.created?
    return if check_enrollment
    check_pending_teacher
    check_unknown_user
    @user_groups = @current_user.group_memberships_for(@context) if @current_user

    if !@context.grants_right?(@current_user, session, :read) && @context.grants_right?(@current_user, session, :read_as_admin)
      return redirect_to course_settings_path(@context.id)
    end

    @context_enrollment ||= @pending_enrollment
    if @context.grants_right?(@current_user, session, :read)
      check_for_readonly_enrollment_state

      log_asset_access([ "home", @context ], "home", "other")

      check_incomplete_registration

      add_crumb(@context.nickname_for(@current_user, :short_name), url_for(@context), :id => "crumb_#{@context.asset_string}")
      set_badge_counts_for(@context, @current_user, @current_enrollment)

      @course_home_view = "feed" if params[:view] == "feed"
      @course_home_view ||= @context.default_view || @context.default_home_page

      # make sure the wiki front page exists
      if @course_home_view == 'wiki'&& @context.wiki.front_page.nil?
        @course_home_view = @context.default_home_page
      end

      @contexts = [@context]
      case @course_home_view
      when "wiki"
        @wiki = @context.wiki
        @page = @wiki.front_page
        set_js_rights [:wiki, :page]
        set_js_wiki_data :course_home => true, :show_announcements => @context.show_announcements_on_home_page?
        @padless = true
      when 'assignments'
        add_crumb(t('#crumbs.assignments', "Assignments"))
        set_js_assignment_data
        js_env(:COURSE_HOME => true)
        @upcoming_assignments = get_upcoming_assignments(@context)
      when 'modules'
        add_crumb(t('#crumbs.modules', "Modules"))
        load_modules
      when 'syllabus'
        rce_js_env(:sidebar)
        add_crumb(t('#crumbs.syllabus', "Syllabus"))
        @groups = @context.assignment_groups.active.order(
          :position,
          AssignmentGroup.best_unicode_collation_key('name')
        ).to_a
        @syllabus_body = syllabus_user_content
      else
        @active_tab = "home"
        if @context.grants_right?(@current_user, session, :manage_groups)
          @contexts += @context.groups
        else
          @contexts += @user_groups if @user_groups
        end
        web_conferences = @context.web_conferences.active.to_a
        @current_conferences = web_conferences.select{|c| c.active?(false, false) && c.users.include?(@current_user) }
        @scheduled_conferences = web_conferences.select{|c| c.scheduled? && c.users.include?(@current_user)}
        @stream_items = @current_user.try(:cached_recent_stream_items, { :contexts => @contexts }) || []
      end

      if @current_user and (@show_recent_feedback = @context.user_is_student?(@current_user))
        @recent_feedback = (@current_user && @current_user.recent_feedback(:contexts => @contexts)) || []
      end

      @course_home_sub_navigation_tools = ContextExternalTool.all_tools_for(@context, :placements => :course_home_sub_navigation, :root_account => @domain_root_account, :current_user => @current_user).to_a
      unless @context.grants_right?(@current_user, session, :manage_content)
        @course_home_sub_navigation_tools.reject! { |tool| tool.course_home_sub_navigation(:visibility) == 'admins' }
      end
    elsif @context.indexed && @context.available?
      render :description
    else
      # clear notices that would have been displayed as a result of processing
      # an enrollment invitation, since we're giving an error
      flash[:notice] = nil
      render_unauthorized_action
    end
  end

  def set_js_course_wizard_data
    # Course Wizard JS Info
    js_env({:COURSE_WIZARD => {
      :just_saved =>  @context_just_saved,
      :checklist_states => {
        :import_step => !@context.attachments.active.exists?,
        :assignment_step => !@context.assignments.active.exists?,
        :add_student_step => !@context.students.exists?,
        :navigation_step => @context.tab_configuration.empty?,
        :home_page_step => true, # The current wizard just always marks this as complete.
        :calendar_event_step => !@context.calendar_events.active.exists?,
        :add_ta_step => !@context.tas.exists?,
        :publish_step => @context.workflow_state === "available"
      },
      :urls => {
        :content_import => context_url(@context, :context_content_migrations_url),
        :add_assignments => context_url(@context, :context_assignments_url, :wizard => 1),
        :add_students => course_users_path(course_id: @context),
        :add_files => context_url(@context, :context_files_url, :wizard => 1),
        :select_navigation => context_url(@context, :context_details_url),
        :course_calendar => calendar_path(course_id: @context),
        :add_tas => course_users_path(:course_id => @context),
        :publish_course => course_path(@context)
      },
      :permissions => {
        # Sending the permissions just so maybe later we can extract this easier.
        :can_manage_content => can_do(@context, @current_user, :manage_content),
        :can_manage_students => can_do(@context, @current_user, :manage_students),
        :can_manage_assignments => can_do(@context, @current_user, :manage_assignments),
        :can_manage_files => can_do(@context, @current_user, :manage_files),
        :can_update => can_do(@context, @current_user, :update),
        :can_manage_calendar => can_do(@context, @current_user, :manage_calendar),
        :can_manage_admin_users => can_do(@context, @current_user, :manage_admin_users),
        :can_change_course_state => can_do(@context, @current_user, :change_course_state)
      }
    }
    })
  end
  helper_method :set_js_course_wizard_data

  def confirm_action
    get_context
    params[:event] ||= (@context.claimed? || @context.created? || @context.completed?) ? 'delete' : 'conclude'
    return unless authorized_action(@context, @current_user, permission_for_event(params[:event]))
  end

  def conclude_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    if @enrollment.can_be_concluded_by(@current_user, @context, session)
      respond_to do |format|
        if @enrollment.conclude
          format.json { render :json => @enrollment }
        else
          format.json { render :json => @enrollment, :status => :bad_request }
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
    can_remove ||= @context.grants_right?(@current_user, session, :manage_admin_users)
    if can_remove
      respond_to do |format|
        if @enrollment.unconclude
          format.json { render :json => @enrollment }
        else
          format.json { render :json => @enrollment, :status => :bad_request }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def limit_user
    get_context
    @user = @context.users.find(params[:id])
    if authorized_action(@context, @current_user, :manage_admin_users)
      if params[:limit] == "1"
        Enrollment.limit_privileges_to_course_section!(@context, @user, true)
        render :json => {:limited => true}
      else
        Enrollment.limit_privileges_to_course_section!(@context, @user, false)
        render :json => {:limited => false}
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def unenroll_user
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    if @enrollment.can_be_deleted_by(@current_user, @context, session)
      if (!@enrollment.defined_by_sis? || @context.grants_right?(@current_user, session, :manage_account_settings)) && @enrollment.destroy
        render :json => @enrollment
      else
        render :json => @enrollment, :status => :bad_request
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def enroll_users
    get_context
    params[:enrollment_type] ||= 'StudentEnrollment'

    custom_role = nil
    if params[:role_id].present? || !Role.get_built_in_role(params[:enrollment_type])
      custom_role = @context.account.get_role_by_id(params[:role_id]) if params[:role_id].present?
      custom_role ||= @context.account.get_role_by_name(params[:enrollment_type]) # backwards compatibility
      if custom_role && custom_role.course_role?
        if custom_role.inactive?
          render :json => t('errors.role_not_active', "Can't add users for non-active role: '%{role}'", :role => custom_role.name), :status => :bad_request
          return
        else
          params[:enrollment_type] = custom_role.base_role_type
        end
      else
        render :json => t('errors.role_not_found', "Could not find role"), :status => :bad_request
        return
      end
    end

    params[:course_section_id] ||= @context.default_section.id
    if @current_user && @current_user.can_create_enrollment_for?(@context, session, params[:enrollment_type])
      params[:user_list] ||= ""

      # Enrollment settings hash
      # Change :limit_privileges_to_course_section to be an explicit true/false value
      enrollment_options = params.slice(:course_section_id, :enrollment_type, :limit_privileges_to_course_section)
      limit_privileges = value_to_boolean(enrollment_options[:limit_privileges_to_course_section])
      enrollment_options[:limit_privileges_to_course_section] = limit_privileges
      enrollment_options[:role] = custom_role if custom_role

      list =
        if params[:user_ids]
          Array(params[:user_ids])
        else
          UserList.new(params[:user_list],
                          root_account: @context.root_account,
                          search_method: @context.user_list_search_mode_for(@current_user),
                          initial_type: params[:enrollment_type],
                          current_user: @current_user)
        end
      if !@context.concluded? && (@enrollments = EnrollmentsFromUserList.process(list, @context, enrollment_options))
        ActiveRecord::Associations::Preloader.new.preload(@enrollments, [:course_section, {:user => [:communication_channel, :pseudonym]}])
        json = @enrollments.map { |e|
          { 'enrollment' =>
            { 'associated_user_id' => e.associated_user_id,
              'communication_channel_id' => e.user.communication_channel.try(:id),
              'email' => e.email,
              'id' => e.id,
              'name' => (e.user.last_name_first || e.user.name),
              'pseudonym_id' => e.user.pseudonym.try(:id),
              'section' => e.course_section.display_name,
              'short_name' => e.user.short_name,
              'type' => e.type,
              'user_id' => e.user_id,
              'workflow_state' => e.workflow_state,
              'role_id' => e.role_id,
              'already_enrolled' => e.already_enrolled
            }
          }
        }
        render :json => json
      else
        render :json => "", :status => :bad_request
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def link_enrollment
    get_context
    if authorized_action(@context, @current_user, :manage_admin_users)
      enrollment = @context.observer_enrollments.find(params[:enrollment_id])
      student = nil
      student = @context.students.find(params[:student_id]) if params[:student_id] != 'none'
      # this is used for linking and un-linking enrollments
      enrollment.associated_user_id = student ? student.id : nil
      enrollment.save!
      render :json => enrollment.as_json(:methods => :associated_user_name)
    end
  end

  def move_enrollment
    get_context
    @enrollment = @context.enrollments.find(params[:id])
    can_move = [StudentEnrollment, ObserverEnrollment].include?(@enrollment.class) && @context.grants_right?(@current_user, session, :manage_students)
    can_move ||= @context.grants_right?(@current_user, session, :manage_admin_users)
    can_move &&= @context.grants_right?(@current_user, session, :manage_account_settings) if @enrollment.defined_by_sis?
    if can_move
      respond_to do |format|
        # ensure user_id,section_id,type,associated_user_id is unique (this
        # will become a DB constraint eventually)
        @possible_dup = @context.enrollments.where(
          "id<>? AND user_id=? AND course_section_id=? AND type=? AND (associated_user_id IS NULL OR associated_user_id=?)",
          @enrollment, @enrollment.user_id, params[:course_section_id], @enrollment.type, @enrollment.associated_user_id).first
        if @possible_dup.present?
          format.json { render :json => @enrollment, :status => :forbidden }
        else
          @enrollment.course_section = @context.course_sections.find(params[:course_section_id])
          @enrollment.save!

          format.json { render :json => @enrollment }
        end
      end
    else
      authorized_action(@context, @current_user, :permission_fail)
    end
  end

  def copy
    get_context
    return unless authorized_action(@context, @current_user, :read_as_admin)

    account = @context.account
    unless account.grants_any_right?(@current_user, session, :create_courses, :manage_courses)
      account = @domain_root_account.manually_created_courses_account
    end
    return unless authorized_action(account, @current_user, [:create_courses, :manage_courses])

    # For prepopulating the date fields
    js_env(:OLD_START_DATE => datetime_string(@context.start_at, :verbose))
    js_env(:OLD_END_DATE => datetime_string(@context.conclude_at, :verbose))
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
      account = nil unless account.grants_any_right?(@current_user, session, :create_courses, :manage_courses)
      account ||= @domain_root_account.manually_created_courses_account
      return unless authorized_action(account, @current_user, [:create_courses, :manage_courses])
      if account.grants_right?(@current_user, session, :manage_courses)
        root_account = account.root_account
        enrollment_term_id = params[:course].delete(:term_id).presence || params[:course].delete(:enrollment_term_id).presence
        args[:enrollment_term] = root_account.enrollment_terms.where(id: enrollment_term_id).first if enrollment_term_id
      end
      args[:enrollment_term] ||= @context.enrollment_term if @context.grants_right?(@current_user, session, :manage) # this will be false for teachers in concluded courses
      args[:abstract_course] = @context.abstract_course
      args[:account] = account
      @course = @context.account.courses.new
      @course.attributes = args
      @course.start_at = DateTime.parse(params[:course][:start_at]).utc rescue nil
      @course.conclude_at = DateTime.parse(params[:course][:conclude_at]).utc rescue nil
      @course.workflow_state = 'claimed'
      @course.save!
      @course.enroll_user(@current_user, 'TeacherEnrollment', :enrollment_state => 'active')

      @content_migration = @course.content_migrations.build(:user => @current_user, :source_course => @context, :context => @course, :migration_type => 'course_copy_importer', :initiated_source => api_request? ? :api : :manual)
      @content_migration.migration_settings[:source_course_id] = @context.id
      @content_migration.workflow_state = 'created'
      if (adjust_dates = params[:adjust_dates]) && Canvas::Plugin.value_to_boolean(adjust_dates[:enabled])
        params[:date_shift_options][adjust_dates[:operation]] = '1'
      end
      @content_migration.set_date_shift_options(params[:date_shift_options].to_hash.with_indifferent_access)

      if Canvas::Plugin.value_to_boolean(params[:selective_import])
        @content_migration.migration_settings[:import_immediately] = false
        @content_migration.workflow_state = 'exported'
        @content_migration.save
      else
        @content_migration.migration_settings[:import_immediately] = true
        @content_migration.copy_options = {:everything => true}
        @content_migration.migration_settings[:migration_ids_to_import] = {:copy => {:everything => true}}
        @content_migration.workflow_state = 'importing'
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
  #
  # @argument course[end_at] [DateTime]
  #   Course end date in ISO8601 format. e.g. 2011-01-01T01:00Z
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
  #   course.
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
  #   * 'undelete' attempts to recover a course that has been deleted. (Recovery is not guaranteed; please conclude
  #     rather than delete a course if there is any possibility the course will be used again.) The recovered course
  #     will be unpublished. Deleted enrollments will not be recovered.
  #
  # @argument course[syllabus_body] [String]
  #   The syllabus body for the course
  #
  # @argument course[grading_standard_id] [Integer]
  #   The grading standard id to set for the course.  If no value is provided for this argument the current grading_standard will be un-set from this course.
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
    params[:course][:event] = :offer if params[:offer].present?

    if params[:course][:event] && params[:course].size == 1
      if authorized_action(@course, @current_user, :change_course_state) && process_course_event
        render_update_success
      end
      return
    end

    if authorized_action(@course, @current_user, [:update, :manage_content])
      return render_update_success if params[:for_reload]

      unless @course.grants_right?(@current_user, :update)
        params_for_update = params_for_update.slice(:syllabus_body) # let users with :manage_content only update the body
      end
      if params_for_update.has_key?(:syllabus_body)
        params_for_update[:syllabus_body] = process_incoming_html_content(params_for_update[:syllabus_body])
      end

      account_id = params[:course].delete :account_id
      if account_id && @course.account.grants_right?(@current_user, session, :manage_courses)
        account = api_find(Account, account_id)
        if account && account != @course.account && account.grants_right?(@current_user, session, :manage_courses)
          @course.account = account
        end
      end

      root_account_id = params[:course].delete :root_account_id
      if root_account_id && Account.site_admin.grants_right?(@current_user, session, :manage_courses)
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

      term_id = params[:course].delete(:term_id)
      enrollment_term_id = params[:course].delete(:enrollment_term_id) || term_id
      if enrollment_term_id && @course.root_account.grants_right?(@current_user, session, :manage_courses)
        enrollment_term = api_find(@course.root_account.enrollment_terms, enrollment_term_id)
        @course.enrollment_term = enrollment_term if enrollment_term && enrollment_term != @course.enrollment_term
      end

      if params_for_update.has_key? :grading_standard_id
        standard_id = params_for_update.delete :grading_standard_id
        grading_standard = GradingStandard.for(@course).where(id: standard_id).first if standard_id.present?
        if grading_standard != @course.grading_standard
          if authorized_action?(@course, @current_user, :manage_grades)
            if standard_id.present?
              @course.grading_standard = grading_standard if grading_standard
            else
              @course.grading_standard = nil
            end
          else
            return
          end
        end
      end
      unless @course.account.grants_right? @current_user, session, :manage_storage_quotas
        params_for_update.delete :storage_quota
        params_for_update.delete :storage_quota_mb
      end
      unless @course.account.grants_right?(@current_user, session, :manage_courses)
        if @course.root_account.settings[:prevent_course_renaming_by_teachers]
          params_for_update.delete :name
          params_for_update.delete :course_code
        end
      end
      params[:course][:sis_source_id] = params[:course].delete(:sis_course_id) if api_request?
      if sis_id = params[:course].delete(:sis_source_id)
        if sis_id != @course.sis_source_id && @course.root_account.grants_right?(@current_user, session, :manage_sis)
          if sis_id == ''
            @course.sis_source_id = nil
          else
            @course.sis_source_id = sis_id
          end
        end
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

      if params_for_update.has_key?(:locale) && params_for_update[:locale].blank?
        params_for_update[:locale] = nil
      end

      if params[:course][:event] && @course.grants_right?(@current_user, session, :change_course_state)
        return unless process_course_event
      end

      if params[:course][:image_url] && params[:course][:image_id]
        respond_to do |format|
          format.json { render :json => {message: "You cannot provide both an image_url and a image_id."}, :status => :bad_request }
          return
        end
      end

      if params[:course][:image_url]
        @course.image_url = params[:course][:image_url]
        @course.image_id = nil
      end

      if params[:course][:image_id]
        if @course.attachments.active.where(id: params[:course][:image_id]).exists?
          @course.image_id = params[:course][:image_id]
          @course.image_url = nil
        else
          respond_to do |format|
            format.json { render :json => {message: "The image_id is not a valid course file id."}, :status => :bad_request }
            return
          end
        end
      end

      if params[:course][:remove_image]
        @course.image_url = nil
        @course.image_id = nil
      end

      params_for_update[:conclude_at] = params[:course].delete(:end_at) if api_request? && params[:course].has_key?(:end_at)
      @default_wiki_editing_roles_was = @course.default_wiki_editing_roles

      @course.attributes = params_for_update

      if params[:course][:course_visibility].present?
        visibility_configuration(params[:course])
      end

      changes = changed_settings(@course.changes, @course.settings, old_settings)

      @course.send_later_if_production_enqueue_args(:touch_content_if_public_visibility_changed,
        { :priority => Delayed::LOW_PRIORITY }, changes)

      if @course.save
        Auditors::Course.record_updated(@course, @current_user, changes, source: logging_source)
        @current_user.touch
        if params[:update_default_pages]
          @course.wiki.update_default_wiki_page_roles(@course.default_wiki_editing_roles, @default_wiki_editing_roles_was)
        end
        render_update_success
      else
        respond_to do |format|
          format.html do
            flash[:error] = t('There was an error saving the changes to the course')
            redirect_to course_url(@course)
          end
          format.json { render :json => @course.errors, :status => :bad_request }
        end
      end
    end
  end

  def process_course_event
    event = params[:course].delete(:event)
    event = event.to_sym
    if event == :claim && !@course.unpublishable?
      flash[:error] = t('errors.unpublish', 'Course cannot be unpublished if student submissions exist.')
      redirect_to(course_url(@course))
      return false
    else
      @course.process_event(event)
      logging_source = api_request? ? :api : :manual
      if event == :offer
        Auditors::Course.record_published(@course, @current_user, source: logging_source)
      elsif event == :claim
        Auditors::Course.record_claimed(@course, @current_user, source: logging_source)
      end
    end
  end

  def render_update_success
    respond_to do |format|
      format.html {
        flash[:notice] = t('notices.updated', 'Course was successfully updated.')
        redirect_to((!params[:continue_to] || params[:continue_to].empty?) ? course_url(@course) : params[:continue_to])
      }
      format.json do
        if api_request?
          render :json => course_json(@course, @current_user, session, [:hide_final_grades], nil)
        else
          render :json => @course.as_json(:methods => [:readable_license, :quota, :account_name, :term_name, :grading_standard_title, :storage_quota_mb]), :status => :ok
        end
      end
    end
  end

  # @API Update courses
  # Update multiple courses in an account.  Operates asynchronously; use the {api:ProgressController#show progress endpoint}
  # to query the status of an operation.
  #
  # @argument course_ids[] [Required] List of ids of courses to update. At most 500 courses may be updated in one call.
  # @argument event [Required, String, "offer"|"conclude"|"delete"|"undelete"]
  # The action to take on each course.  Must be one of 'offer', 'conclude', 'delete', or 'undelete'.
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
    if params[:event] == 'undelete'
      permission = :undelete_courses
    else
      permission = :manage_courses
    end

    if authorized_action(@account, @current_user, permission)
      return render(:json => { :message => 'must specify course_ids[]' }, :status => :bad_request) unless params[:course_ids].is_a?(Array)
      @course_ids = Api.map_ids(params[:course_ids], Course, @domain_root_account, @current_user)
      return render(:json => { :message => 'course batch size limit (500) exceeded' }, :status => :forbidden) if @course_ids.size > 500
      update_params = params.slice(:event).to_hash.with_indifferent_access
      return render(:json => { :message => 'need to specify event' }, :status => :bad_request) unless update_params[:event]
      return render(:json => { :message => 'invalid event' }, :status => :bad_request) unless %w(offer conclude delete undelete).include? update_params[:event]
      progress = Course.batch_update(@account, @current_user, @course_ids, update_params, :api)
      render :json => progress_json(progress, @current_user, session)
    end
  end

  def public_feed
    return unless get_feed_context(:only => [:course])
    feed = Atom::Feed.new do |f|
      f.title = t('titles.rss_feed', "%{course} Feed", :course => @context.name)
      f.links << Atom::Link.new(:href => course_url(@context), :rel => 'self')
      f.updated = Time.now
      f.id = course_url(@context)
    end
    @entries = []
    @entries.concat @context.assignments.published
    @entries.concat @context.calendar_events.active
    @entries.concat(@context.discussion_topics.active.select{ |dt|
      dt.published? && !dt.locked_for?(@current_user, :check_policies => true)
    })
    @entries.concat @context.wiki.wiki_pages
    @entries = @entries.sort_by{|e| e.updated_at}
    @entries.each do |entry|
      feed.entries << entry.to_atom(:context => @context)
    end
    respond_to do |format|
      format.atom { render :text => feed.to_xml }
    end
  end

  def publish_to_sis
    sis_publish_status(true)
  end

  def sis_publish_status(publish_grades=false)
    get_context
    return unless authorized_action(@context, @current_user, :manage_grades)
    @context.publish_final_grades(@current_user) if publish_grades

    processed_grade_publishing_statuses = {}
    grade_publishing_statuses, overall_status = @context.grade_publishing_statuses
    grade_publishing_statuses.each do |message, enrollments|
      processed_grade_publishing_statuses[message] = enrollments.map do |enrollment|
        { :id => enrollment.user.id,
          :name => enrollment.user.name,
          :sortable_name => enrollment.user.sortable_name,
          :url => course_user_url(@context, enrollment.user) }
      end
    end

    render :json => { :sis_publish_overall_status => overall_status,
                      :sis_publish_statuses => processed_grade_publishing_statuses }
  end

  # @API Reset a course
  # Deletes the current course, and creates a new equivalent course with
  # no content, but all sections and users moved over.
  #
  # @returns Course
  def reset_content
    get_context
    return unless authorized_action(@context, @current_user, :reset_content)
    @new_course = @context.reset_content
    Auditors::Course.record_reset(@context, @new_course, @current_user, source: api_request? ? :api : :manual)
    if api_request?
      render :json => course_json(@new_course, @current_user, session, [], nil)
    else
      redirect_to course_settings_path(@new_course.id)
    end
  end

  # @API Get effective due dates
  # For each assignment in the course, returns each assigned student's ID
  # and their corresponding due date along with some Multiple Grading Periods
  # data. Returns a collection with keys representing assignment IDs and values
  # as a collection containing keys representing student IDs and values representing
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
  # @returns {EffectiveDueDates}
  def effective_due_dates
    return unless authorized_action(@context, @current_user, :read_as_admin)

    assignment_ids = effective_due_dates_params[:assignment_ids]
    if assignment_ids.present?
      due_dates = EffectiveDueDates.for_course(@context, assignment_ids)
    else
      due_dates = EffectiveDueDates.for_course(@context)
    end

    render json: due_dates.to_hash([
      :due_at, :grading_period_id, :in_closed_grading_period
    ])
  end

  # @API Permissions
  # Returns permission information for provided course & current_user
  #
  # @argument permissions[] [String]
  #   List of permissions to check against authenticated user
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
    return return_to(return_url, request.referer || dashboard_url)
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
      ModeratedGrading::ProvisionalGrade.where(:submission_id => @fake_student.submissions).delete_all
      @fake_student.submissions.destroy_all
      @fake_student.quiz_submissions.each{|qs| qs.events.destroy_all}
      @fake_student.quiz_submissions.destroy_all

      flash[:notice] = t('notices.reset_test_student', "The test student has been reset successfully.")
      enter_student_view
    end
  end

  def enter_student_view
    @fake_student = @context.student_view_student
    session[:become_user_id] = @fake_student.id
    return_url = course_path(@context)
    session.delete(:masquerade_return_to)
    return return_to(return_url, request.referer || dashboard_url)
  end
  protected :enter_student_view

  def permission_for_event(event)
    case event
    when 'conclude'
      :change_course_state
    when 'delete'
      :delete
    else
      :nothing
    end
  end

  def changed_settings(changes, new_settings, old_settings=nil)
    # frd? storing a hash?
    # Settings is stored as a hash in a column which
    # causes us to do some more work if it has been changed.

    # Since course uses write_attribute on settings its not accurate
    # so just ignore it if its in the changes hash
    changes.delete("settings") if changes.has_key?("settings")

    unless old_settings == new_settings
      settings = Course.settings_options.keys.inject({}) do |results, key|
        if old_settings.present? && old_settings.has_key?(key)
          old_value = old_settings[key]
        else
          old_value = nil
        end

        if new_settings.present? && new_settings.has_key?(key)
          new_value = new_settings[key]
        else
          new_value = nil
        end

        results[key.to_s] = [ old_value, new_value ] unless old_value == new_value

        results
      end
      changes.merge!(settings)
    end

    changes
  end

  def ping
    render json: {success: true}
  end

  def link_validation
    get_context
    return unless authorized_action(@context, @current_user, :manage_content)

    if progress = CourseLinkValidator.current_progress(@context)
      hash = {:state => progress.workflow_state}
      if !progress.pending? && progress.results
        hash.merge!(progress.results)
      end
      render :json => hash
    else
      render :json => {}
    end
  end

  def start_link_validation
    get_context
    return unless authorized_action(@context, @current_user, :manage_content)

    CourseLinkValidator.queue_course(@context)
    render :json => {:success => true}
  end

  def link_validator
    get_context
    return unless authorized_action(@context, @current_user, :manage_content)
    # render view
  end

  def retrieve_observed_enrollments(enrollments, active_by_date: false)
    observer_enrolls = enrollments.select(&:assigned_observer?)
    ObserverEnrollment.observed_enrollments_for_enrollments(observer_enrolls, active_by_date: active_by_date)
  end

  def courses_for_user(user, paginate_url: api_v1_courses_url)
    include_observed = params.fetch(:include, []).include?("observed_users")

    if params[:state]
      states = Array(params[:state])
      states += %w(created claimed) if states.include?('unpublished')
      conditions = states.map do |state|
        Enrollment::QueryBuilder.new(nil, course_workflow_state: state, enforce_course_workflow_state: true).conditions
      end.compact.join(" OR ")
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
      ActiveRecord::Associations::Preloader.new.preload(enrollments, :course)
    else
      enrollments = user.cached_current_enrollments(preload_courses: true)
    end

    if include_observed
      enrollments.concat(
        retrieve_observed_enrollments(enrollments, active_by_date: (params[:enrollment_state] == "active"))
      )
    end

    # these are all duplicated in the params[:state] block above in SQL. but if
    # used the cached ones, or we added include_observed, we have to re-run them
    # in pure ruby
    if include_observed || !params[:state]
      if params[:enrollment_role]
        ActiveRecord::Associations::Preloader.new.preload(enrollments, :role)
        enrollments.reject! { |e| e.role.name != params[:enrollment_role] }
      elsif params[:enrollment_role_id]
        enrollments.reject! { |e| e.role_id != params[:enrollment_role_id].to_i }
      elsif params[:enrollment_type]
        e_type = "#{params[:enrollment_type].capitalize}Enrollment"
        enrollments.reject! { |e| e.class.name != e_type }
      end

      if params[:enrollment_state] && params[:enrollment_state] != "active"
        Canvas::Builders::EnrollmentDateBuilder.preload_state(enrollments)
        case params[:enrollment_state]
        when "invited_or_pending"
          enrollments.select!{|e| e.invited? || e.accepted?}
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
    includes << 'access_restricted_by_date'
    # We only want to return the permissions for single courses and not lists of courses.
    includes.delete 'permissions'

    hash = []

    Canvas::Builders::EnrollmentDateBuilder.preload_state(enrollments)
    enrollments_by_course = enrollments.group_by(&:course_id).values
    enrollments_by_course = Api.paginate(enrollments_by_course, self, paginate_url) if api_request?
    courses = enrollments_by_course.map(&:first).map(&:course)
    preloads = [:account, :root_account]
    preloads << :teachers if includes.include?('teachers')
    preloads << :grading_standard if includes.include?('total_scores')
    ActiveRecord::Associations::Preloader.new.preload(courses, preloads)

    enrollments_by_course.each do |course_enrollments|
      course = course_enrollments.first.course
      hash << course_json(course, user, session, includes, course_enrollments)
    end
    hash
  end

  def require_user_or_observer
    return render_unauthorized_action unless @current_user.present?
    @user = params[:user_id]=="self" ? @current_user : api_find(User,params[:user_id])
    authorized_action(@user,@current_user,:read)
  end

  def visibility_configuration(params)
    if params[:course_visibility] == 'institution'
      @course.is_public_to_auth_users = true
      @course.is_public = false
    elsif params[:course_visibility] == 'public'
      @course.is_public = true
    else
      @course.is_public_to_auth_users = false
      @course.is_public = false
    end
    if params[:syllabus_visibility_option].present?
      customized = params[:syllabus_visibility_option]
      if @course.is_public || customized == 'public'
        @course.public_syllabus = true
      elsif @course.is_public_to_auth_users || customized == 'institution'
        @course.public_syllabus_to_auth = true
        @course.public_syllabus = false
      else
        @course.public_syllabus = false
        @course.public_syllabus_to_auth = false
      end
    end
  end

  def can_change_group_weighting_scheme?
    return true unless @course.feature_enabled?(:multiple_grading_periods)
    return true if @course.account_membership_allows(@current_user)
    !@course.any_assignment_in_closed_grading_period?
  end

  def offline_web_exports
    return render status: 404, template: 'shared/errors/404_message' unless @context.allow_web_export_download?
    if authorized_action(WebZipExport.new(course: @context), @current_user, :create)
      title = t('Exported Package History')
      @page_title = title
      add_crumb(title)
      js_bundle :webzip_export
      css_bundle :webzip_export
      render :text => '<div id="course-webzip-export-app"></div>'.html_safe, :layout => true
    end
  end

  def start_offline_web_export
    return render status: 404, template: 'shared/errors/404_message' unless @context.allow_web_export_download?
    if authorized_action(WebZipExport.new(course: @context), @current_user, :create)
      @service = EpubExports::CreateService.new(@context, @current_user, :web_zip_export)
      @service.save
      redirect_to context_url(@context, :context_offline_web_exports_url)
    end
  end

  private

  def effective_due_dates_params
    params.permit(assignment_ids: [])
  end

  def course_params
    return {} unless params[:course]
    params[:course].permit(:name, :group_weighting_scheme, :start_at, :conclude_at,
      :grading_standard_id, :is_public, :is_public_to_auth_users, :allow_student_wiki_edits, :show_public_context_messages,
      :syllabus_body, :public_description, :allow_student_forum_attachments, :allow_student_discussion_topics, :allow_student_discussion_editing,
      :show_total_grade_as_points, :default_wiki_editing_roles, :allow_student_organized_groups, :course_code, :default_view,
      :open_enrollment, :allow_wiki_comments, :turnitin_comments, :self_enrollment, :license, :indexed,
      :abstract_course, :storage_quota, :storage_quota_mb, :restrict_enrollments_to_course_dates,
      :restrict_student_past_view, :restrict_student_future_view, :grading_standard, :grading_standard_enabled,
      :locale, :integration_id, :hide_final_grades, :hide_distribution_graphs, :lock_all_announcements, :public_syllabus,
      :public_syllabus_to_auth, :course_format, :time_zone, :organize_epub_by_content_type, :enable_offline_web_export,
      :show_announcements_on_home_page, :home_page_announcement_limit
    )
  end
end
