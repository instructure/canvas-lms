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

# @API Enrollments
#
# API for creating and viewing course enrollments
#
# @model Grade
#     {
#       "id": "Grade",
#       "description": "",
#       "properties": {
#         "html_url": {
#           "description": "The URL to the Canvas web UI page for the user's grades, if this is a student enrollment.",
#           "example": "",
#           "type": "string"
#         },
#         "current_grade": {
#           "description": "The user's current grade in the class. Only included if user has permissions to view this grade.",
#           "example": "",
#           "type": "string"
#         },
#         "final_grade": {
#           "description": "The user's final grade for the class. Only included if user has permissions to view this grade.",
#           "example": "",
#           "type": "string"
#         },
#         "current_score": {
#           "description": "The user's current score in the class. Only included if user has permissions to view this score.",
#           "example": "",
#           "type": "string"
#         },
#         "final_score": {
#           "description": "The user's final score for the class. Only included if user has permissions to view this score.",
#           "example": "",
#           "type": "string"
#         },
#         "current_points": {
#           "description": "The total points the user has earned in the class. Only included if user has permissions to view this score and 'current_points' is passed in the request's 'include' parameter.",
#           "example": 150,
#           "type": "integer"
#         },
#         "unposted_current_grade": {
#           "description": "The user's current grade in the class including muted/unposted assignments. Only included if user has permissions to view this grade, typically teachers, TAs, and admins.",
#           "example": "",
#           "type": "string"
#         },
#         "unposted_final_grade": {
#           "description": "The user's final grade for the class including muted/unposted assignments. Only included if user has permissions to view this grade, typically teachers, TAs, and admins..",
#           "example": "",
#           "type": "string"
#         },
#         "unposted_current_score": {
#           "description": "The user's current score in the class including muted/unposted assignments. Only included if user has permissions to view this score, typically teachers, TAs, and admins..",
#           "example": "",
#           "type": "string"
#         },
#         "unposted_final_score": {
#           "description": "The user's final score for the class including muted/unposted assignments. Only included if user has permissions to view this score, typically teachers, TAs, and admins..",
#           "example": "",
#           "type": "string"
#         },
#         "unposted_current_points": {
#           "description": "The total points the user has earned in the class, including muted/unposted assignments. Only included if user has permissions to view this score (typically teachers, TAs, and admins) and 'current_points' is passed in the request's 'include' parameter.",
#           "example": 150,
#           "type": "integer"
#         }
#       }
#     }
#
# @model Enrollment
#       {
#         "id": "Enrollment",
#         "description": "",
#         "properties": {
#           "id": {
#             "description": "The ID of the enrollment.",
#             "example": 1,
#             "type": "integer"
#           },
#           "course_id": {
#             "description": "The unique id of the course.",
#             "example": 1,
#             "type": "integer"
#           },
#           "sis_course_id": {
#             "description": "The SIS Course ID in which the enrollment is associated. Only displayed if present. This field is only included if the user has permission to view SIS information.",
#             "example": "SHEL93921",
#             "type": "string"
#           },
#           "course_integration_id": {
#             "description": "The Course Integration ID in which the enrollment is associated. This field is only included if the user has permission to view SIS information.",
#             "example": "SHEL93921",
#             "type": "string"
#           },
#           "course_section_id": {
#             "description": "The unique id of the user's section.",
#             "example": 1,
#             "type": "integer"
#           },
#           "section_integration_id": {
#             "description": "The Section Integration ID in which the enrollment is associated. This field is only included if the user has permission to view SIS information.",
#             "example": "SHEL93921",
#             "type": "string"
#           },
#           "sis_account_id": {
#             "description": "The SIS Account ID in which the enrollment is associated. Only displayed if present. This field is only included if the user has permission to view SIS information.",
#             "example": "SHEL93921",
#             "type": "string"
#           },
#           "sis_section_id": {
#             "description": "The SIS Section ID in which the enrollment is associated. Only displayed if present. This field is only included if the user has permission to view SIS information.",
#             "example": "SHEL93921",
#             "type": "string"
#           },
#           "sis_user_id": {
#             "description": "The SIS User ID in which the enrollment is associated. Only displayed if present. This field is only included if the user has permission to view SIS information.",
#             "example": "SHEL93921",
#             "type": "string"
#           },
#           "enrollment_state": {
#             "description": "The state of the user's enrollment in the course.",
#             "example": "active",
#             "type": "string"
#           },
#           "limit_privileges_to_course_section": {
#             "description": "User can only access his or her own course section.",
#             "example": true,
#             "type": "boolean"
#           },
#           "sis_import_id": {
#             "description": "The unique identifier for the SIS import. This field is only included if the user has permission to manage SIS information.",
#             "example": 83,
#             "type": "integer"
#           },
#           "root_account_id": {
#             "description": "The unique id of the user's account.",
#             "example": 1,
#             "type": "integer"
#           },
#           "type": {
#             "description": "The enrollment type. One of 'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment', 'ObserverEnrollment'.",
#             "example": "StudentEnrollment",
#             "type": "string"
#           },
#           "user_id": {
#             "description": "The unique id of the user.",
#             "example": 1,
#             "type": "integer"
#           },
#           "associated_user_id": {
#             "description": "The unique id of the associated user. Will be null unless type is ObserverEnrollment.",
#             "example": null,
#             "type": "integer"
#           },
#           "role": {
#             "description": "The enrollment role, for course-level permissions. This field will match `type` if the enrollment role has not been customized.",
#             "example": "StudentEnrollment",
#             "type": "string"
#           },
#           "role_id": {
#             "description": "The id of the enrollment role.",
#             "example": 1,
#             "type": "integer"
#           },
#           "created_at": {
#             "description": "The created time of the enrollment, in ISO8601 format.",
#             "example": "2012-04-18T23:08:51Z",
#             "type": "datetime"
#           },
#           "updated_at": {
#             "description": "The updated time of the enrollment, in ISO8601 format.",
#             "example": "2012-04-18T23:08:51Z",
#             "type": "datetime"
#           },
#           "start_at": {
#             "description": "The start time of the enrollment, in ISO8601 format.",
#             "example": "2012-04-18T23:08:51Z",
#             "type": "datetime"
#           },
#           "end_at": {
#             "description": "The end time of the enrollment, in ISO8601 format.",
#             "example": "2012-04-18T23:08:51Z",
#             "type": "datetime"
#           },
#           "last_activity_at": {
#             "description": "The last activity time of the user for the enrollment, in ISO8601 format.",
#             "example": "2012-04-18T23:08:51Z",
#             "type": "datetime"
#           },
#           "last_attended_at": {
#             "description": "The last attended date of the user for the enrollment in a course, in ISO8601 format.",
#             "example": "2012-04-18T23:08:51Z",
#             "type": "datetime"
#           },
#           "total_activity_time": {
#             "description": "The total activity time of the user for the enrollment, in seconds.",
#             "example": 260,
#             "type": "integer"
#           },
#           "html_url": {
#             "description": "The URL to the Canvas web UI page for this course enrollment.",
#             "example":  "https://...",
#             "type": "string"
#           },
#           "grades": {
#             "description": "The URL to the Canvas web UI page containing the grades associated with this enrollment.",
#             "example": {
#               "html_url": "https://...",
#               "current_score": 35,
#               "current_grade": null,
#               "final_score": 6.67,
#               "final_grade": null
#             },
#             "$ref": "Grade"
#           },
#           "user": {
#             "description": "A description of the user.",
#             "example": {
#               "id": 3,
#               "name": "Student 1",
#               "sortable_name": "1, Student",
#               "short_name": "Stud 1"
#             },
#             "$ref": "User"
#           },
#           "override_grade": {
#             "description": "The user's override grade for the course.",
#             "example": "A",
#             "type": "string"
#           },
#           "override_score": {
#             "description": "The user's override score for the course.",
#             "example": 99.99,
#             "type": "number"
#           },
#           "unposted_current_grade": {
#             "description": "The user's current grade in the class including muted/unposted assignments. Only included if user has permissions to view this grade, typically teachers, TAs, and admins.",
#             "example": "",
#             "type": "string"
#           },
#           "unposted_final_grade": {
#             "description": "The user's final grade for the class including muted/unposted assignments. Only included if user has permissions to view this grade, typically teachers, TAs, and admins..",
#             "example": "",
#             "type": "string"
#           },
#           "unposted_current_score": {
#             "description": "The user's current score in the class including muted/unposted assignments. Only included if user has permissions to view this score, typically teachers, TAs, and admins..",
#             "example": "",
#             "type": "string"
#           },
#           "unposted_final_score": {
#             "description": "The user's final score for the class including muted/unposted assignments. Only included if user has permissions to view this score, typically teachers, TAs, and admins..",
#             "example": "",
#             "type": "string"
#           },
#           "has_grading_periods": {
#             "description": "optional: Indicates whether the course the enrollment belongs to has grading periods set up. (applies only to student enrollments, and only available in course endpoints)",
#             "example": true,
#             "type": "boolean"
#           },
#           "totals_for_all_grading_periods_option": {
#             "description": "optional: Indicates whether the course the enrollment belongs to has the Display Totals for 'All Grading Periods' feature enabled. (applies only to student enrollments, and only available in course endpoints)",
#             "example": true,
#             "type": "boolean"
#           },
#           "current_grading_period_title": {
#             "description": "optional: The name of the currently active grading period, if one exists. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "Fall Grading Period",
#             "type": "string"
#           },
#           "current_grading_period_id": {
#             "description": "optional: The id of the currently active grading period, if one exists. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 5,
#             "type": "integer"
#           },
#           "current_period_override_grade": {
#             "description": "The user's override grade for the current grading period.",
#             "example": "A",
#             "type": "string"
#           },
#           "current_period_override_score": {
#             "description": "The user's override score for the current grading period.",
#             "example": 99.99,
#             "type": "number"
#           },
#           "current_period_unposted_current_score": {
#             "description": "optional: The student's score in the course for the current grading period, including muted/unposted assignments. Only included if user has permission to view this score, typically teachers, TAs, and admins. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 95.80,
#             "type": "number"
#           },
#           "current_period_unposted_final_score": {
#             "description": "optional: The student's score in the course for the current grading period, including muted/unposted assignments and including ungraded assignments with a score of 0. Only included if user has permission to view this score, typically teachers, TAs, and admins. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 85.25,
#             "type": "number"
#           },
#           "current_period_unposted_current_grade": {
#             "description": "optional: The letter grade equivalent of current_period_unposted_current_score, if available. Only included if user has permission to view this grade, typically teachers, TAs, and admins. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "A",
#             "type": "string"
#           },
#           "current_period_unposted_final_grade": {
#             "description": "optional: The letter grade equivalent of current_period_unposted_final_score, if available. Only included if user has permission to view this grade, typically teachers, TAs, and admins. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "B",
#             "type": "string"
#           }
#         }
#       }
#
class EnrollmentsApiController < ApplicationController
  before_action :get_course_from_section, :require_context
  before_action :require_user

  @@errors = {
    missing_parameters: "No parameters given",
    missing_user_id: "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment",
    missing_sis_or_integration_id: "Can't create an enrollment without a sis_user_id or integration_id when root_account is provided",
    bad_type: "Invalid type",
    bad_role: "Invalid role",
    inactive_role: "Cannot create an enrollment with this role because it is inactive.",
    base_type_mismatch: "The specified type must match the base type for the role",
    concluded_course: "Can't add an enrollment to a concluded course.",
    insufficient_sis_permissions: "Insufficient permissions to filter by SIS fields"
  }

  include Api::V1::User
  # @API List enrollments
  # Depending on the URL given, return a paginated list of either (1) all of
  # the enrollments in a course, (2) all of the enrollments in a section or (3)
  # all of a user's enrollments. This includes student, teacher, TA, and
  # observer enrollments.
  #
  # If a user has multiple enrollments in a context (e.g. as a teacher
  # and a student or in multiple course sections), each enrollment will be
  # listed separately.
  #
  # note: Currently, only a root level admin user can return other users' enrollments.
  # A user can, however, return his/her own enrollments.
  #
  # Enrollments scoped to a course context will include inactive states by default
  # if the caller has account admin authorization and the state[] parameter is omitted.
  #
  # @argument type[] [String]
  #   A list of enrollment types to return. Accepted values are
  #   'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment',
  #   'DesignerEnrollment', and 'ObserverEnrollment.' If omitted, all enrollment
  #   types are returned. This argument is ignored if `role` is given.
  #
  # @argument role[] [String]
  #   A list of enrollment roles to return. Accepted values include course-level
  #   roles created by the {api:RoleOverridesController#add_role Add Role API}
  #   as well as the base enrollment types accepted by the `type` argument above.
  #
  # @argument state[] [String, "active"|"invited"|"creation_pending"|"deleted"|"rejected"|"completed"|"inactive"|"current_and_invited"|"current_and_future"|"current_and_concluded"]
  #   Filter by enrollment state. If omitted, 'active' and 'invited' enrollments
  #   are returned. The following synthetic states are supported only when
  #   querying a user's enrollments (either via user_id argument or via user
  #   enrollments endpoint): +current_and_invited+, +current_and_future+, +current_and_concluded+
  #
  # @argument include[] [String, "avatar_url"|"group_ids"|"locked"|"observed_users"|"can_be_removed"|"uuid"|"current_points"]
  #   Array of additional information to include on the enrollment or user records.
  #   "avatar_url" and "group_ids" will be returned on the user record. If "current_points"
  #   is specified, the fields "current_points" and (if the caller has
  #   permissions to manage grades) "unposted_current_points" will be included
  #   in the "grades" hash for student enrollments.
  #
  # @argument user_id [String]
  #   Filter by user_id (only valid for course or section enrollment
  #   queries). If set to the current user's id, this is a way to
  #   determine if the user has any enrollments in the course or section,
  #   independent of whether the user has permission to view other people
  #   on the roster.
  #
  # @argument grading_period_id [Integer]
  #   Return grades for the given grading_period.  If this parameter is not
  #   specified, the returned grades will be for the whole course.
  #
  # @argument enrollment_term_id [Integer]
  #   Returns only enrollments for the specified enrollment term. This parameter
  #   only applies to the user enrollments path. May pass the ID from the
  #   enrollment terms api or the SIS id prepended with 'sis_term_id:'.
  #
  # @argument sis_account_id[] [String]
  #   Returns only enrollments for the specified SIS account ID(s). Does not
  #   look into sub_accounts. May pass in array or string.
  #
  # @argument sis_course_id[] [String]
  #   Returns only enrollments matching the specified SIS course ID(s).
  #   May pass in array or string.
  #
  # @argument sis_section_id[] [String]
  #   Returns only section enrollments matching the specified SIS section ID(s).
  #   May pass in array or string.
  #
  # @argument sis_user_id[] [String]
  #   Returns only enrollments for the specified SIS user ID(s). May pass in
  #   array or string.
  #
  # @argument created_for_sis_id[] [Boolean]
  #   If sis_user_id is present and created_for_sis_id is true, Returns only
  #   enrollments for the specified SIS ID(s).
  #   If a user has two sis_id's, one enrollment may be created using one of the
  #   two ids. This would limit the enrollments returned from the endpoint to
  #   enrollments that were created from a sis_import with that sis_user_id
  #
  # @returns [Enrollment]
  def index
    GuardRail.activate(:secondary) do
      endpoint_scope = if @context.is_a?(Course)
                         @section.present? ? "section" : "course"
                       else
                         "user"
                       end

      return unless (enrollments = if @context.is_a?(Course)
                                     course_index_enrollments
                                   else
                                     user_index_enrollments
                                   end)

      enrollments = enrollments.joins(:user).select("enrollments.*")

      has_courses = enrollments.where_clause.instance_variable_get(:@predicates)
                               .any? { |cond| cond.is_a?(String) && cond.include?("courses.") }
      enrollments = enrollments.joins(:course) if has_courses
      enrollments = enrollments.shard(@shard_scope) if @shard_scope

      sis_context = @context.is_a?(Course) ? @context : @domain_root_account
      unless check_sis_permissions(sis_context)
        render_create_errors([@@errors[:insufficient_sis_permissions]])
        return false
      end

      if params[:sis_user_id].present?
        enrollments =
          if value_to_boolean(params[:created_for_sis_id])
            pseudonyms = @domain_root_account.pseudonyms.where(sis_user_id: params[:sis_user_id])
            enrollments.where(sis_pseudonym: pseudonyms)
          else
            # include inactive enrollment states by default unless state param is specified
            filter_params = params[:state].present? ? { enrollment_state: params[:state] } : { include_inactive_enrollments: true }

            user_ids = Set.new
            sis_user_ids = Array.wrap(params[:sis_user_id])
            sis_user_ids.each do |sis_id|
              sis_id = sis_id.to_s
              users = UserSearch.for_user_in_context(sis_id,
                                                     @context,
                                                     @current_user,
                                                     session,
                                                     filter_params)
              users.find_each do |user|
                if user.pseudonyms.shard(user).active.where(sis_user_id: sis_id).exists?
                  user_ids << user.id
                end
              end
            end
            enrollments.where(user_id: user_ids)
          end
      end

      if params[:sis_section_id].present?
        sections = @domain_root_account.course_sections.where(sis_source_id: params[:sis_section_id])
        enrollments = enrollments.where(course_section_id: sections.pluck(:id))
      end

      if params[:sis_account_id].present?
        accounts = @domain_root_account.all_accounts.where(sis_source_id: params[:sis_account_id])
        courses = @domain_root_account.all_courses.where(account_id: accounts.pluck(:id))
        enrollments = enrollments.where(course_id: courses.pluck(:id))
      end

      if params[:sis_course_id].present?
        courses = @domain_root_account.all_courses.where(sis_source_id: params[:sis_course_id])
        enrollments = enrollments.where(course_id: courses.pluck(:id))
      end

      if params[:grading_period_id].present?
        grading_period = if @context.is_a? User
                           @context.courses.lazy.map do |course|
                             GradingPeriod.for(course).find_by(id: params[:grading_period_id])
                           end.detect(&:present?)
                         else
                           GradingPeriod.for(@context).find_by(id: params[:grading_period_id])
                         end

        unless grading_period
          render(json: { error: "invalid grading_period_id" }, status: :bad_request)
          return
        end
      end

      collection =
        if use_bookmarking?
          enrollments = enrollments.select("users.sortable_name AS sortable_name")
          bookmarker = BookmarkedCollection::SimpleBookmarker.new(Enrollment,
                                                                  { type: { skip_collation: true }, sortable_name: { type: :string, null: false } },
                                                                  :id)
          ShardedBookmarkedCollection.build(bookmarker, enrollments, always_use_bookmarks: true)
        else
          enrollments.order(:type, User.sortable_name_order_by_clause("users"), :id)
        end
      enrollments = Api.paginate(
        collection,
        self,
        send(:"api_v1_#{endpoint_scope}_enrollments_url")
      )

      ActiveRecord::Associations.preload(enrollments, %i[user course course_section root_account sis_pseudonym])

      include_group_ids = Array(params[:include]).include?("group_ids")
      includes = [:user] + Array(params[:include])
      user_json_preloads(enrollments.map(&:user), false, { group_memberships: include_group_ids })

      render json: enrollments.map { |e|
        enrollment_json(e,
                        @current_user,
                        session,
                        includes:,
                        opts: { grading_period: })
      }
    end
  end

  # @API Enrollment by ID
  # Get an Enrollment object by Enrollment ID
  #
  # @argument id [Required, Integer]
  #  The ID of the enrollment object
  # @returns Enrollment
  def show
    GuardRail.activate(:secondary) do
      enrollment = @context.all_enrollments.find(params[:id])
      if enrollment.user_id == @current_user.id || authorized_action(@context, @current_user, :read_roster)
        render json: enrollment_json(enrollment, @current_user, session)
      end
    end
  end

  # @API Enroll a user
  # Create a new user enrollment for a course or section.
  #
  # @argument enrollment[start_at] [DateTime]
  #   The start time of the enrollment, in ISO8601 format. e.g. 2012-04-18T23:08:51Z
  #
  # @argument enrollment[end_at] [DateTime]
  #   The end time of the enrollment, in ISO8601 format. e.g. 2012-04-18T23:08:51Z
  #
  # @argument enrollment[user_id] [Required, String]
  #   The ID of the user to be enrolled in the course.
  #
  # @argument enrollment[type] [Required, String, "StudentEnrollment"|"TeacherEnrollment"|"TaEnrollment"|"ObserverEnrollment"|"DesignerEnrollment"]
  #   Enroll the user as a student, teacher, TA, observer, or designer. If no
  #   value is given, the type will be inferred by enrollment[role] if supplied,
  #   otherwise 'StudentEnrollment' will be used.
  #
  # @argument enrollment[role] [Deprecated, String]
  #   Assigns a custom course-level role to the user.
  #
  # @argument enrollment[role_id] [Integer]
  #   Assigns a custom course-level role to the user.
  #
  # @argument enrollment[enrollment_state] [String, "active"|"invited"|"inactive"]
  #   If set to 'active,' student will be immediately enrolled in the course.
  #   Otherwise they will be required to accept a course invitation. Default is
  #   'invited.'.
  #
  #   If set to 'inactive', student will be listed in the course roster for
  #   teachers, but will not be able to participate in the course until
  #   their enrollment is activated.
  #
  # @argument enrollment[course_section_id] [Integer]
  #   The ID of the course section to enroll the student in. If the
  #   section-specific URL is used, this argument is redundant and will be
  #   ignored.
  #
  # @argument enrollment[limit_privileges_to_course_section] [Boolean]
  #   If set, the enrollment will only allow the user to see and interact with
  #   users enrolled in the section given by course_section_id.
  #   * For teachers and TAs, this includes grading privileges.
  #   * Section-limited students will not see any users (including teachers
  #     and TAs) not enrolled in their sections.
  #   * Users may have other enrollments that grant privileges to
  #     multiple sections in the same course.
  #
  # @argument enrollment[notify] [Boolean]
  #   If true, a notification will be sent to the enrolled user.
  #   Notifications are not sent by default.
  #
  # @argument enrollment[self_enrollment_code] [String]
  #   If the current user is not allowed to manage enrollments in this
  #   course, but the course allows self-enrollment, the user can self-
  #   enroll as a student in the default section by passing in a valid
  #   code. When self-enrolling, the user_id must be 'self'. The
  #   enrollment_state will be set to 'active' and all other arguments
  #   will be ignored.
  #
  # @argument enrollment[self_enrolled] [Boolean]
  #   If true, marks the enrollment as a self-enrollment, which gives
  #   students the ability to drop the course if desired. Defaults to false.
  #
  # @argument enrollment[associated_user_id] [Integer]
  #   For an observer enrollment, the ID of a student to observe.
  #   This is a one-off operation; to automatically observe all a
  #   student's enrollments (for example, as a parent), please use
  #   the {api:UserObserveesController#create User Observees API}.
  #
  # @argument enrollment[sis_user_id] [String]
  #   Required if the user is being enrolled from another trusted account.
  #   The unique identifier for the user (sis_user_id) must also be
  #   accompanied by the root_account parameter. The user_id will be ignored.
  #
  # @argument enrollment[integration_id] [String]
  #   Required if the user is being enrolled from another trusted account.
  #   The unique identifier for the user (integration_id) must also be
  #   accompanied by the root_account parameter. The user_id will be ignored.
  #
  # @argument root_account [String]
  #   The domain of the account to search for the user. Will be a no-op
  #   unless the sis_user_id or integration_id parameter is also included.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/enrollments \
  #     -X POST \
  #     -F 'enrollment[user_id]=1' \
  #     -F 'enrollment[type]=StudentEnrollment' \
  #     -F 'enrollment[enrollment_state]=active' \
  #     -F 'enrollment[course_section_id]=1' \
  #     -F 'enrollment[limit_privileges_to_course_section]=true' \
  #     -F 'enrollment[notify]=false'
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/enrollments \
  #     -X POST \
  #     -F 'enrollment[user_id]=2' \
  #     -F 'enrollment[type]=StudentEnrollment'
  #
  # @returns Enrollment
  def create
    # error handling
    errors = []

    if params[:enrollment].blank?
      errors << @@errors[:missing_parameters] if params[:enrollment].blank?
    else
      return create_self_enrollment if params[:enrollment][:self_enrollment_code]

      type = params[:enrollment].delete(:type)

      if (role_id = params[:enrollment].delete(:role_id))
        role = @context.account.get_role_by_id(role_id)
      elsif (role_name = params[:enrollment].delete(:role))
        role = @context.account.get_course_role_by_name(role_name)
      else
        type = "StudentEnrollment" if type.blank?
        role = Role.get_built_in_role(type, root_account_id: @context.root_account_id)
        if role.nil? || !role.course_role?
          errors << @@errors[:bad_type]
        end
      end

      if role&.course_role? && !role.deleted?
        type = role.base_role_type if type.blank?
        if role.inactive?
          errors << @@errors[:inactive_role]
        elsif type != role.base_role_type
          errors << @@errors[:base_type_mismatch]
        else
          params[:enrollment][:role] = role
        end
      elsif errors.empty?
        errors << @@errors[:bad_role]
      end

      if params[:root_account].present? && %i[sis_user_id integration_id].all? { |k| params[:enrollment][k].blank? }
        errors << @@errors[:missing_sis_or_integration_id]
      elsif params[:enrollment][:user_id].blank? && params[:root_account].blank?
        errors << @@errors[:missing_user_id]
      end
    end
    return render_create_errors(errors) if errors.present?

    # create enrollment

    params[:enrollment][:no_notify] = true unless value_to_boolean(params[:enrollment][:notify])
    unless @current_user.can_create_enrollment_for?(@context, session, type)
      render_unauthorized_action && return
    end

    params[:enrollment][:course_section_id] = @section.id if @section.present?
    if params[:enrollment][:course_section_id].present?
      @section = api_find(@context.course_sections.active, params[:enrollment].delete(:course_section_id))
      params[:enrollment][:section] = @section
    end

    user = if @trusted_account.present? && params.delete(:root_account)
             sis_user_id = params[:enrollment].delete(:sis_user_id)
             integration_id = params[:enrollment].delete(:integration_id)
             scope = @trusted_account.pseudonyms.active_only
             pseudo = sis_user_id.present? ? scope.find_by(sis_user_id:) : scope.find_by(integration_id:)
             pseudo&.user
           else
             api_user_id = params[:enrollment].delete(:user_id)
             api_find(User, api_user_id)
           end

    unless user.can_be_enrolled_in_course?(@context)
      unique_id = api_user_id || sis_user_id || integration_id
      raise(ActiveRecord::RecordNotFound, "Couldn't find User with API id '#{unique_id}'")
    end

    # allow moving users already in the course to open sections
    if @context.concluded? &&
       !(@section && user.enrollments.shard(@context.shard).where(course_id: @context).exists? && !@section.concluded?)
      return render_create_errors([@@errors[:concluded_course]])
    end

    if params[:enrollment].key?(:limit_privileges_to_course_section)
      params[:enrollment][:limit_privileges_to_course_section] =
        value_to_boolean(params[:enrollment][:limit_privileges_to_course_section])
    end

    params[:enrollment].slice!(
      :enrollment_state,
      :section,
      :limit_privileges_to_course_section,
      :associated_user_id,
      :temporary_enrollment_source_user_id,
      :temporary_enrollment_pairing_id,
      :role,
      :start_at,
      :end_at,
      :self_enrolled,
      :no_notify
    )

    SubmissionLifecycleManager.with_executing_user(@current_user) do
      @enrollment = @context.enroll_user(user, type, params[:enrollment].merge(allow_multiple_enrollments: true))
    end

    if @enrollment.valid?
      render(json: enrollment_json(@enrollment, @current_user, session))
    else
      render(json: @enrollment.errors, status: :bad_request)
    end
  end

  def create_self_enrollment
    options = params[:enrollment]
    code = options[:self_enrollment_code]
    # we don't just do a straight-up comparison of the code, since
    # plugins can override Account#self_enrollment_course_for to allow
    # for synthetic ones
    errors = []
    if @context != @context.root_account.self_enrollment_course_for(code)
      errors << "enrollment[self_enrollment_code] is invalid"
    end
    if options[:user_id] != "self"
      errors << "enrollment[user_id] must be 'self' when self-enrolling"
    end
    if MasterCourses::MasterTemplate.is_master_course?(@context)
      errors << "course is not open for self-enrollment"
    end
    return render_create_errors(errors) if errors.present?

    @current_user.validation_root_account = @domain_root_account
    @current_user.require_self_enrollment_code = true
    @current_user.self_enrollment_code = code

    SubmissionLifecycleManager.with_executing_user(@current_user) do
      if @current_user.save
        render(json: enrollment_json(@current_user.self_enrollment, @current_user, session))
      else
        render(json: { user: @current_user.errors }, status: :bad_request)
      end
    end
  end

  # @API Conclude, deactivate, or delete an enrollment
  # Conclude, deactivate, or delete an enrollment. If the +task+ argument isn't given, the enrollment
  # will be concluded.
  #
  # @argument task [String, "conclude"|"delete"|"inactivate"|"deactivate"]
  #   The action to take on the enrollment.
  #   When inactive, a user will still appear in the course roster to admins, but be unable to participate.
  #   ("inactivate" and "deactivate" are equivalent tasks)
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/enrollments/:enrollment_id \
  #     -X DELETE \
  #     -F 'task=conclude'
  #
  # @returns Enrollment
  def destroy
    @enrollment = @context.enrollments.find(params[:id])
    permission =
      case params[:task]
      when "delete", "deactivate", "inactivate"
        :can_be_deleted_by
      else # 'conclude'
        :can_be_concluded_by
      end

    action =
      case params[:task]
      when "delete"
        :destroy
      when "deactivate", "inactivate"
        :deactivate
      else # 'conclude'
        :conclude
      end

    unless @enrollment.send(permission, @current_user, @context, session)
      return render_unauthorized_action
    end

    if @enrollment.send(action)
      render json: enrollment_json(@enrollment, @current_user, session)
    else
      render json: @enrollment.errors, status: :bad_request
    end
  end

  # @API Accept Course Invitation
  # accepts a pending course invitation for the current user
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/enrollments/:id/accept \
  #     -X POST \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "success": true
  #   }
  def accept
    @enrollment = @context.enrollments.find(params[:id])
    return render_unauthorized_action unless @current_user && @enrollment.user == @current_user
    return render(json: { success: true }) if @enrollment.active?
    return render(json: { error: "membership not activated" }, status: :bad_request) if @enrollment.inactive?

    if @enrollment.rejected?
      @enrollment.workflow_state = "invited"
      @enrollment.save_without_broadcasting
    end
    return render(json: { error: "self enroll" }, status: :bad_request) if @enrollment.self_enrolled?
    return render(json: { error: "no current invitation" }, status: :bad_request) unless @enrollment.invited?

    @enrollment.accept!
    render json: { success: true }
  end

  # @API Reject Course Invitation
  # rejects a pending course invitation for the current user
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/<course_id>/enrollments/:id/reject \
  #     -X POST \
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #   {
  #     "success": true
  #   }
  def reject
    @enrollment = @context.enrollments.find(params[:id])
    return render_unauthorized_action unless @current_user && @enrollment.user == @current_user
    return render(json: { success: true }) if @enrollment.rejected?
    return render(json: { error: "membership not activated" }, status: :bad_request) if @enrollment.inactive?
    return render(json: { error: "self enroll" }, status: :bad_request) if @enrollment.self_enrolled?
    return render(json: { error: "no current invitation" }, status: :bad_request) unless @enrollment.invited?

    @enrollment.reject!
    render json: { success: true }
  end

  # @API Re-activate an enrollment
  # Activates an inactive enrollment
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/enrollments/:enrollment_id/reactivate \
  #     -X PUT
  #
  # @returns Enrollment
  def reactivate
    @enrollment = @context.enrollments.find(params[:id])

    unless @enrollment.send(:can_be_deleted_by, @current_user, @context, session)
      return render_unauthorized_action
    end

    unless @enrollment.workflow_state == "inactive"
      return render(json: { error: "enrollment not inactive" }, status: :bad_request)
    end

    if @enrollment.reactivate
      render json: enrollment_json(@enrollment, @current_user, session)
    else
      render json: @enrollment.errors, status: :bad_request
    end
  end

  # @API Add last attended date
  # Add last attended date to student enrollment in course
  #
  # @argument date [Date]
  #   The last attended date of a student enrollment in a course.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/user/:user_id/last_attended"
  #     -X PUT => date="Thu%20Dec%2021%202017%2000:00:00%20GMT-0700%20(MST)
  #
  # @returns Enrollment
  def last_attended
    return unless authorized_action(@context, @current_user, [:view_all_grades, :manage_grades])

    date = Time.zone.parse(params[:date])
    if date
      enrollments = Enrollment.where(course_id: params[:course_id], user_id: params[:user_id])
      enrollments.update_all(last_attended_at: date)
      render json: { date: }
    else
      render json: { message: "Invalid date time input" }, status: :bad_request
    end
  end

  # @API Show Temporary Enrollment recipient and provider status
  # @beta
  #
  # Returns a JSON Object containing the temporary enrollment status for a user.
  #
  # @argument account_id [Optional, String]
  #  The ID of the account to check for temporary enrollment status.
  #  Defaults to the domain root account if not provided.
  #
  # @example_response
  #   {
  #     "is_provider": false, "is_recipient": true
  #   }
  def show_temporary_enrollment_status
    GuardRail.activate(:secondary) do
      if (user = api_find(User, params[:user_id])) && @domain_root_account&.feature_enabled?(:temporary_enrollments)
        if user.grants_right?(@current_user, session, :api_show_user)
          account = api_find(Account, params[:account_id]) if params[:account_id].present?
          enrollment_scope =
            if account
              Enrollment.active_or_pending_by_date.joins(:course).where(courses: { account_id: account.id })
            else
              Enrollment.active_or_pending_by_date
            end
          is_provider = enrollment_scope.temporary_enrollment_recipients_for_provider(user).exists?
          is_recipient = enrollment_scope.temporary_enrollments_for_recipient(user).exists?

          render json: { is_provider:, is_recipient: }
        else
          render_unauthorized_action and return false
        end
      end
    end
  end

  protected

  # Internal: Collect course enrollments that @current_user has permissions to
  # read.
  #
  # Returns an ActiveRecord scope of enrollments on success, false on failure.
  def course_index_enrollments
    if params[:user_id]
      # if you pass in your own id, you can see if you are enrolled in the
      # course, regardless of whether you have read_roster
      return user_index_enrollments(course: @context)
    end

    if @context.grants_any_right?(@current_user, session, :read_roster, :view_all_grades, :manage_grades)
      scope = @context.apply_enrollment_visibility(@context.all_enrollments, @current_user).where(enrollment_index_conditions)

      unless params[:state].present?
        include_inactive = @context.grants_right?(@current_user, session, :read_as_admin)
        scope = include_inactive ? scope.all_active_or_pending : scope.active_or_pending
      end
      return scope
    elsif @context.user_has_been_observer?(@current_user)
      # Observers can see enrollments for the users they're observing, as well
      # as their own enrollments
      observer_enrollments = @context.observer_enrollments.active.where(user_id: @current_user)
      observed_student_ids = observer_enrollments.pluck(:associated_user_id).uniq.compact

      return @context.enrollments.where(user: @current_user).where(enrollment_index_conditions).union(
        @context.student_enrollments.where(user_id: observed_student_ids).where(enrollment_index_conditions)
      )
    end

    render_unauthorized_action and return false
  end

  # Internal: Collect user enrollments that @current_user has permissions to
  # read.
  #
  # Returns an ActiveRecord scope of enrollments on success, false on failure.
  def user_index_enrollments(course: nil)
    user = api_find(User, params[:user_id])

    if user && @domain_root_account&.feature_enabled?(:temporary_enrollments)
      temp_enroll_params = params.slice(:temporary_enrollments_for_recipient,
                                        :temporary_enrollment_recipients_for_provider)
      if temp_enroll_params.present?
        enrollments =
          temporary_enrollment_conditions(user, temp_enroll_params).to_a.select do |e|
            e.course.account.grants_any_right?(@current_user, *RoleOverride::MANAGE_TEMPORARY_ENROLLMENT_PERMISSIONS)
          end
        return Enrollment.where(id: enrollments) if enrollments.present?

        render_unauthorized_action and return false
      end
    end

    if user == @current_user
      if params[:state].present?
        valid_states = %w[active
                          inactive
                          rejected
                          invited
                          creation_pending
                          pending_active
                          pending_invited
                          completed
                          current_and_invited
                          current_and_future
                          current_and_concluded]

        params[:state].each do |state|
          unless valid_states.include?(state)
            return render(json: { error: "Invalid state #{state}" }, status: :bad_request)
          end
        end
      end
      # if user is requesting for themselves, just return all of their
      # enrollments without any extra checking.
      enrollments = if params[:state].present?
                      user.enrollments.where(enrollment_index_conditions(true)).joins(:enrollment_state)
                          .where(enrollment_states: { state: enrollment_states_for_state_param })
                    else
                      user.enrollments.current_and_invited.where(enrollment_index_conditions)
                          .joins(:enrollment_state).where("enrollment_states.state<>'completed'")
                    end
      enrollments = enrollments.where(course_id: course) if course
    else
      if course
        # if current user is requesting enrollments for themselves or a specific user
        # with params[:user_id] in a course context we want to follow the
        # course_index_enrollments construct
        unless course.user_has_been_observer?(@current_user) ||
               course.grants_any_right?(@current_user, session, :read_roster, :view_all_grades, :manage_grades)
          render_unauthorized_action and return false
        end

        enrollments = user.enrollments.where(enrollment_index_conditions).where(course_id: course)
      else
        is_approved_parent = user.grants_right?(@current_user, :read_as_parent)
        # otherwise check for read_roster rights on all of the requested
        # user's accounts
        approved_accounts = user.associated_root_accounts.filter_map do |ra|
          ra.id if is_approved_parent || ra.grants_right?(@current_user, session, :read_roster)
        end

        # if there aren't any ids in approved_accounts, then the user doesn't have
        # permissions.
        unless @domain_root_account.grants_right?(@current_user, session, :read_roster)
          render_unauthorized_action and return false if approved_accounts.empty?
        end

        enrollments = user.enrollments.where(enrollment_index_conditions)
                          .where(root_account_id: approved_accounts)
      end

      # by default, return active and invited courses. don't use the existing
      # current_and_invited_enrollments scope because it won't return enrollments
      # on unpublished courses.
      enrollments = enrollments.where(workflow_state: %w[active invited]) if params[:state].blank?
    end

    terms = @domain_root_account.enrollment_terms.active
    if params[:enrollment_term_id]
      term = api_find(terms, params[:enrollment_term_id])
      enrollments = enrollments.joins(:course).where(courses: { enrollment_term_id: term })
    end

    @shard_scope = user

    enrollments
  end

  # Internal: Collect type, section, state, and role info from params and format them
  # for use in a request for the requester's own enrollments.
  # index is :course or :user
  #
  # Returns [ sql fragment string, replacement hash ]
  def enrollment_index_conditions(use_course_state = false)
    type, state, role_names, role_ids = params.values_at(:type, :state, :role, :role_id)
    clauses = []
    replacements = {}

    if role_ids.blank? && role_names.present?
      role_names = Array(role_names)
      role_ids = role_names.filter_map { |name| @context.account.get_course_role_by_name(name)&.id }
      raise ActionController::BadRequest, "role not found" if role_ids.length != role_names.length
    end

    if role_ids.present?
      role_ids = Array(role_ids).map(&:to_i)
      condition = "enrollments.role_id IN (:role_ids)"
      replacements[:role_ids] = role_ids
      clauses << condition
    elsif type.present?
      clauses << "enrollments.type IN (:type)"
      replacements[:type] = Array(type)
    end

    if state.present?
      if use_course_state
        conditions = state.filter_map { |s| Enrollment::QueryBuilder.new(s.to_sym).conditions }
        clauses << "(#{conditions.join(" OR ")})"
      else
        clauses << "enrollments.workflow_state IN (:workflow_state)"
        unless state.is_a?(String) || (state.is_a?(Array) && state.all?(String))
          raise ActionController::BadRequest, "state must be a single string, or an array of strings"
        end

        replacements[:workflow_state] = Array(state)
      end
    end

    if @section.present?
      clauses << "enrollments.course_section_id = :course_section_id"
      replacements[:course_section_id] = @section.id
    end

    [clauses.join(" AND "), replacements]
  end

  # Internal: Collect provider and recipient enrollments that @current_user
  # has permissions to read.
  #
  # Returns an ActiveRecord scope of enrollments if present, otherwise false.
  def temporary_enrollment_conditions(user, temp_enroll_params)
    if value_to_boolean(temp_enroll_params[:temporary_enrollments_for_recipient])
      enrollments = Enrollment.temporary_enrollments_for_recipient(user)
    elsif value_to_boolean(temp_enroll_params[:temporary_enrollment_recipients_for_provider])
      enrollments = Enrollment.temporary_enrollment_recipients_for_provider(user)
    end
    return false unless enrollments.present?

    if params[:state].present?
      enrollments = enrollments.joins(:enrollment_state).where(enrollment_states: { state: enrollment_states_for_state_param })
    end

    enrollments
  end

  def enrollment_states_for_state_param
    states = Array(params[:state]).uniq
    states.push("active", "invited") if states.delete "current_and_invited"
    states.push("active", "invited", "creation_pending", "pending_active", "pending_invited") if states.delete "current_and_future"
    states.push("active", "completed") if states.delete "current_and_concluded"
    states.uniq
  end

  def check_sis_permissions(sis_context)
    sis_filters = %w[sis_account_id sis_course_id sis_section_id sis_user_id]
    if params.keys.intersect?(sis_filters) && !sis_context.grants_any_right?(@current_user, :read_sis, :manage_sis)
      return false
    end

    true
  end

  def render_create_errors(errors)
    render json: { message: errors.join(", ") }, status: :bad_request
  end

  def use_bookmarking?
    unless instance_variable_defined?(:@use_bookmarking)
      # a few specific developer keys temporarily need bookmarking disabled, see INTEROP-5326
      pagination_override_key_list = Setting.get("pagination_override_key_list", "").split(",").map(&:to_i)
      use_numeric_pagination_override = pagination_override_key_list.include?(@access_token&.global_developer_key_id)
      @use_bookmarking = !use_numeric_pagination_override
    end
    @use_bookmarking
  end
end
