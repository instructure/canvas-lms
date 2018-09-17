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
#           "computed_current_score": {
#             "description": "optional: The student's score in the course, ignoring ungraded assignments. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 90.25,
#             "type": "number"
#           },
#           "computed_final_score": {
#             "description": "optional: The student's score in the course including ungraded assignments with a score of 0. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 80.67,
#             "type": "number"
#           },
#           "computed_current_grade": {
#             "description": "optional: The letter grade equivalent of computed_current_score, if available. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "A-",
#             "type": "string"
#           },
#           "computed_final_grade": {
#             "description": "optional: The letter grade equivalent of computed_final_score, if available. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "B-",
#             "type": "string"
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
#           "current_period_computed_current_score": {
#             "description": "optional: The student's score in the course for the current grading period, ignoring ungraded assignments. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 95.80,
#             "type": "number"
#           },
#           "current_period_computed_final_score": {
#             "description": "optional: The student's score in the course for the current grading period, including ungraded assignments with a score of 0. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": 85.25,
#             "type": "number"
#           },
#           "current_period_computed_current_grade": {
#             "description": "optional: The letter grade equivalent of current_period_computed_current_score, if available. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "A",
#             "type": "string"
#           },
#           "current_period_computed_final_grade": {
#             "description": "optional: The letter grade equivalent of current_period_computed_final_score, if available. If the course the enrollment belongs to does not have grading periods, or if no currently active grading period exists, the value will be null. (applies only to student enrollments, and only available in course endpoints)",
#             "example": "B",
#             "type": "string"
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
    :missing_parameters                => 'No parameters given',
    :missing_user_id                   => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment",
    :bad_type                          => 'Invalid type',
    :bad_role                          => 'Invalid role',
    :inactive_role                     => 'Cannot create an enrollment with this role because it is inactive.',
    :base_type_mismatch                => 'The specified type must match the base type for the role',
    :concluded_course                  => 'Can\'t add an enrollment to a concluded course.',
    :insufficient_sis_permissions      => 'Insufficient permissions to filter by SIS fields'
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
  # note: Currently, only a root level admin user can return other users' enrollments. A
  # user can, however, return his/her own enrollments.
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
  # @argument state[] [String, "active"|"invited"|"creation_pending"|"deleted"|"rejected"|"completed"|"inactive"]
  #   Filter by enrollment state. If omitted, 'active' and 'invited' enrollments
  #   are returned. When querying a user's enrollments (either via user_id
  #   argument or via user enrollments endpoint), the following additional
  #   synthetic states are supported: "current_and_invited"|"current_and_future"|"current_and_concluded"
  #
  # @argument include[] [String, "avatar_url"|"group_ids"|"locked"|"observed_users"|"can_be_removed"]
  #   Array of additional information to include on the enrollment or user records.
  #   "avatar_url" and "group_ids" will be returned on the user record.
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
  # @returns [Enrollment]
  def index
    endpoint_scope = (@context.is_a?(Course) ? (@section.present? ? "section" : "course") : "user")

    return unless enrollments = @context.is_a?(Course) ?
      course_index_enrollments :
      user_index_enrollments

    enrollments = enrollments.joins(:user).select("enrollments.*").
      order(:type, User.sortable_name_order_by_clause("users"), :id)

    has_courses = enrollments.where_clause.instance_variable_get(:@predicates).
      any? { |cond| cond.is_a?(String) && cond =~ /courses\./ }
    enrollments = enrollments.joins(:course) if has_courses
    enrollments = enrollments.shard(@shard_scope) if @shard_scope

    sis_context = @context.is_a?(Course) ? @context : @domain_root_account
    unless check_sis_permissions(sis_context)
      render_create_errors([@@errors[:insufficient_sis_permissions]])
      return false
    end

    if params[:sis_user_id].present?
      pseudonyms = @domain_root_account.pseudonyms.where(sis_user_id: params[:sis_user_id])
      enrollments = enrollments.where(user_id: pseudonyms.pluck(:user_id))
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
      if @context.is_a? User
        grading_period = @context.courses.lazy.map do |course|
          GradingPeriod.for(course).find_by(id: params[:grading_period_id])
        end.detect(&:present?)
      else
        grading_period = GradingPeriod.for(@context).find_by(id: params[:grading_period_id])
      end

      unless grading_period
        render(:json => {error: "invalid grading_period_id"}, :status => :bad_request)
        return
      end
    end

    enrollments = Api.paginate(
      enrollments,
      self, send("api_v1_#{endpoint_scope}_enrollments_url"))

    ActiveRecord::Associations::Preloader.new.preload(enrollments, [:user, :course, :course_section, :root_account, :sis_pseudonym])

    include_group_ids = Array(params[:include]).include?("group_ids")
    includes = [:user] + Array(params[:include])
    user_json_preloads(enrollments.map(&:user), false, {group_memberships: include_group_ids})

    render :json => enrollments.map { |e|
      enrollment_json(e, @current_user, session, includes,
                      grading_period: grading_period)
    }
  end

  # @API Enrollment by ID
  # Get an Enrollment object by Enrollment ID
  #
  # @argument id [Required, Integer]
  #  The ID of the enrollment object
  # @returns Enrollment
  def show
    enrollment = @context.all_enrollments.find(params[:id])
    if enrollment.user_id == @current_user.id || authorized_action(@context, @current_user, :read_roster)
      render :json => enrollment_json(enrollment, @current_user, session)
    end
  end

  # @API Enroll a user
  # Create a new user enrollment for a course or section.
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
  #   For an observer enrollment, the ID of a student to observe. The
  #   caller must have +manage_students+ permission in the course.
  #   This is a one-off operation; to automatically observe all a
  #   student's enrollments (for example, as a parent), please use
  #   the {api:UserObserveesController#create User Observees API}.
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

      if role_id = params[:enrollment].delete(:role_id)
        role = @context.account.get_role_by_id(role_id)
      elsif role_name = params[:enrollment].delete(:role)
        role = @context.account.get_course_role_by_name(role_name)
      else
        type = "StudentEnrollment" if type.blank?
        role = Role.get_built_in_role(type)
        if role.nil? || !role.course_role?
          errors << @@errors[:bad_type]
        end
      end

      if role && role.course_role? && !role.deleted?
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

      errors << @@errors[:missing_user_id] unless params[:enrollment][:user_id].present?
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
    api_user_id = params[:enrollment].delete(:user_id)
    user = api_find(User, api_user_id)
    raise(ActiveRecord::RecordNotFound, "Couldn't find User with API id '#{api_user_id}'") unless user.can_be_enrolled_in_course?(@context)

    if @context.concluded?
      # allow moving users already in the course to open sections
      unless @section && user.enrollments.where(course_id: @context).exists? && !@section.concluded?
        return render_create_errors([@@errors[:concluded_course]])
      end
    end

    params[:enrollment][:limit_privileges_to_course_section] = value_to_boolean(params[:enrollment][:limit_privileges_to_course_section]) if params[:enrollment].has_key?(:limit_privileges_to_course_section)
    params[:enrollment].slice!(:enrollment_state, :section, :limit_privileges_to_course_section, :associated_user_id, :role, :start_at, :end_at, :self_enrolled, :no_notify)

    @enrollment = @context.enroll_user(user, type, params[:enrollment].merge(:allow_multiple_enrollments => true))
    @enrollment.valid? ?
      render(:json => enrollment_json(@enrollment, @current_user, session)) :
      render(:json => @enrollment.errors, :status => :bad_request)
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
    if options[:user_id] != 'self'
      errors << "enrollment[user_id] must be 'self' when self-enrolling"
    end
    return render_create_errors(errors) if errors.present?

    @current_user.validation_root_account = @domain_root_account
    @current_user.require_self_enrollment_code = true
    @current_user.self_enrollment_code = code
    if @current_user.save
      render(json: enrollment_json(@current_user.self_enrollment, @current_user, session))
    else
      render(json: {user: @current_user.errors}, status: :bad_request)
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
      when 'conclude'
        :can_be_concluded_by
      when 'delete', 'deactivate', 'inactivate'
        :can_be_deleted_by
      else
        :can_be_concluded_by
      end

    action =
      case params[:task]
      when 'conclude'
        :conclude
      when 'delete'
        :destroy
      when 'deactivate', 'inactivate'
        :deactivate
      else
        :conclude
      end

    unless @enrollment.send(permission, @current_user, @context, session)
      return render_unauthorized_action
    end

    if @enrollment.send(action)
      render :json => enrollment_json(@enrollment, @current_user, session)
    else
      render :json => @enrollment.errors, :status => :bad_request
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
    return render(json: {success: true}) if @enrollment.active?
    return render(json: {error: 'membership not activated'}, status: :bad_request) if @enrollment.inactive?
    if @enrollment.rejected?
      @enrollment.workflow_state = 'invited'
      @enrollment.save_without_broadcasting
    end
    return render(json: {error: 'self enroll'}, status: :bad_request) if @enrollment.self_enrolled?
    return render(json: {error: 'no current invitation'}, status: :bad_request) unless @enrollment.invited?
    @enrollment.accept!
    render json: {success: true}
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
    return render(json: {success: true}) if @enrollment.rejected?
    return render(json: {error: 'membership not activated'}, status: :bad_request) if @enrollment.inactive?
    return render(json: {error: 'self enroll'}, status: :bad_request) if @enrollment.self_enrolled?
    return render(json: {error: 'no current invitation'}, status: :bad_request) unless @enrollment.invited?
    @enrollment.reject!
    render json: {success: true}
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


    unless @enrollment.workflow_state == 'inactive'
      return render(:json => {:error => "enrollment not inactive"}, :status => :bad_request)
    end

    if @enrollment.reactivate
      render :json => enrollment_json(@enrollment, @current_user, session)
    else
      render :json => @enrollment.errors, :status => :bad_request
    end
  end

  # @API Adds last attended date to student enrollment in course
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/user/:user_id/last_attended"
  #     -X PUT => date="Thu%20Dec%2021%202017%2000:00:00%20GMT-0700%20(MST)
  #
  #
  # @returns Enrollment
  def last_attended
    return unless authorized_action(@context, @current_user, [:view_all_grades, :manage_grades])
    date = Time.zone.parse(params[:date])
    if date
      enrollments = Enrollment.where(:course_id => params[:course_id], :user_id => params[:user_id])
      enrollments.update_all(last_attended_at: date)
      render :json => {:date => date}
    else
      render :json => { :message => 'Invalid date time input' }, :status => :bad_request
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
      scope = user_index_enrollments
      return scope && scope.where(course_id: @context.id)
    end

    if authorized_action(@context, @current_user, [:read_roster, :view_all_grades, :manage_grades])
      scope = @context.apply_enrollment_visibility(@context.all_enrollments, @current_user).where(enrollment_index_conditions)

      unless params[:state].present?
        include_inactive = @context.grants_right?(@current_user, session, :read_as_admin)
        scope = include_inactive ? scope.all_active_or_pending : scope.active_or_pending
      end
      scope
    else
      false
    end
  end

  # Internal: Collect user enrollments that @current_user has permissions to
  # read.
  #
  # Returns an ActiveRecord scope of enrollments on success, false on failure.
  def user_index_enrollments
    user = api_find(User, params[:user_id])

    if user == @current_user
      # if user is requesting for themselves, just return all of their
      # enrollments without any extra checking.
      if params[:state].present?
        enrollments = user.enrollments.where(enrollment_index_conditions(true))
      else
        enrollments = user.enrollments.current_and_invited.where(enrollment_index_conditions).
            joins(:enrollment_state).where("enrollment_states.state<>'completed'")
      end
    else
      is_approved_parent = user.grants_right?(@current_user, :read_as_parent)
      # otherwise check for read_roster rights on all of the requested
      # user's accounts
      approved_accounts = user.associated_root_accounts.inject([]) do |accounts, ra|
        accounts << ra.id if is_approved_parent || ra.grants_right?(@current_user, session, :read_roster)
        accounts
      end

      # if there aren't any ids in approved_accounts, then the user doesn't have
      # permissions.
      render_unauthorized_action and return false if approved_accounts.empty?

      enrollments = user.enrollments.where(enrollment_index_conditions).
        where(root_account_id: approved_accounts)

      # by default, return active and invited courses. don't use the existing
      # current_and_invited_enrollments scope because it won't return enrollments
      # on unpublished courses.
      enrollments = enrollments.where(workflow_state: %w{active invited}) if params[:state].blank?
    end

    terms = @domain_root_account.enrollment_terms.active
    if params[:enrollment_term_id]
      term = api_find(terms, params[:enrollment_term_id])
      enrollments = enrollments.joins(:course).where(courses: {enrollment_term_id: term})
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

    if !role_ids.present? && role_names.present?
      role_ids = Array(role_names).map{|name| @context.account.get_course_role_by_name(name).id}
    end

    if role_ids.present?
      role_ids = Array(role_ids).map(&:to_i)
      condition = 'enrollments.role_id IN (:role_ids)'
      replacements[:role_ids] = role_ids

      built_in_roles = role_ids.map{|r_id| Role.built_in_roles_by_id[r_id]}.compact
      if built_in_roles.present?
        condition = "(#{condition} OR (enrollments.role_id IS NULL AND enrollments.type IN (:built_in_role_types)))"
        replacements[:built_in_role_types] = built_in_roles.map(&:name)
      end
      clauses << condition
    elsif type.present?
      clauses << 'enrollments.type IN (:type)'
      replacements[:type] = Array(type)
    end

    if state.present?
      if use_course_state
        conditions = state.map{ |s| Enrollment::QueryBuilder.new(s.to_sym).conditions }.compact
        clauses << "(#{conditions.join(' OR ')})"
      else
        clauses << 'enrollments.workflow_state IN (:workflow_state)'
        replacements[:workflow_state] = Array(state)
      end
    end

    if @section.present?
      clauses << 'enrollments.course_section_id = :course_section_id'
      replacements[:course_section_id] = @section.id
    end

    [ clauses.join(' AND '), replacements ]
  end

  def check_sis_permissions(sis_context)
    sis_filters = %w(sis_account_id sis_course_id sis_section_id sis_user_id)
    if (params.keys & sis_filters).present?
      unless sis_context.grants_any_right?(@current_user, :read_sis, :manage_sis)
        return false
      end
    end

    true
  end

  def render_create_errors(errors)
    render json: {message: errors.join(', ')}, status: :bad_request
  end
end
