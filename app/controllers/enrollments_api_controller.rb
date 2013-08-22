#
# Copyright (C) 2011-2012 Instructure, Inc.
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
# API for creating and viewing course enrollments
class EnrollmentsApiController < ApplicationController
  before_filter :get_course_from_section, :require_context

  @@errors = {
    :missing_parameters => 'No parameters given',
    :missing_user_id    => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment",
    :bad_type           => 'Invalid type',
    :bad_role           => 'Invalid role',
    :inactive_role      => 'Cannot create an enrollment with this role because it is inactive.',
    :base_type_mismatch => 'The specified type must match the base type for the role',
    :concluded_course   => 'Can\'t add an enrollment to a concluded course.'

  }

  include Api::V1::User
  # @API List enrollments
  # Depending on the URL given, return either (1) all of the enrollments in
  # a course, (2) all of the enrollments in a section or (3) all of a user's
  # enrollments. This includes student, teacher, TA, and observer enrollments.
  #
  # If a user has multiple enrollments in a context (e.g. as a teacher
  # and a student or in multiple course sections), each enrollment will be
  # listed separately.
  #
  # note: Currently, only an admin user can return other users' enrollments. A
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
  #   are returned.
  #
  # @response_field id The unique id of the enrollment.
  # @response_field course_id The unique id of the course.
  # @response_field course_section_id The unique id of the user's section.
  # @response_field enrollment_state The state of the user's enrollment in the course.
  # @response_field limit_privileges_to_course_section User can only access his or her own course section.
  # @response_field root_account_id The unique id of the user's account.
  # @response_field type The type of the enrollment.
  # @response_field role The enrollment role, for course-level permissions.
  # @response_field user_id The unique id of the user.
  # @response_field html_url The URL to the Canvas web UI page for this course enrollment.
  # @response_field grades[html_url] The URL to the Canvas web UI page for the user's grades, if this is a student enrollment.
  # @response_field grades[current_grade] The user's current grade in the class. Only included if user has permissions to view this grade.
  # @response_field grades[final_grade] The user's final grade for the class. Only included if user has permissions to view this grade.
  # @response_field user[id] The unique id of the user.
  # @response_field user[login_id] The unique login of the user.
  # @response_field user[name] The name of the user.
  # @response_field user[short_name] The short name of the user.
  # @response_field user[sortable_name] The sortable name of the user.
  #
  # @example_response
  #   [
  #     {
  #       "id": 1,
  #       "course_id": 1,
  #       "course_section_id": 1,
  #       "enrollment_state": "active",
  #       "limit_privileges_to_course_section": true,
  #       "root_account_id": 1,
  #       "type": "StudentEnrollment",
  #       "user_id": 1,
  #       "html_url": "https://...",
  #       "grades": {
  #         "html_url": "https://...",
  #       },
  #       "user": {
  #         "id": 1,
  #         "login_id": "bieberfever@example.com",
  #         "name": "Justin Bieber",
  #         "short_name": "Justin B.",
  #         "sortable_name": "Bieber, Justin"
  #       }
  #     },
  #     {
  #       "id": 2,
  #       "course_id": 1,
  #       "course_section_id": 2,
  #       "enrollment_state": "active",
  #       "limit_privileges_to_course_section": false,
  #       "root_account_id": 1,
  #       "type": "TeacherEnrollment",
  #       "user_id": 2,
  #       "html_url": "https://...",
  #       "grades": {
  #         "html_url": "https://...",
  #       },
  #       "user": {
  #         "id": 2,
  #         "login_id": "changyourmind@example.com",
  #         "name": "Señor Chang",
  #         "short_name": "S. Chang",
  #         "sortable_name": "Chang, Señor"
  #       }
  #     },
  #     {
  #       "id": 3,
  #       "course_id": 1,
  #       "course_section_id": 2,
  #       "enrollment_state": "active",
  #       "limit_privileges_to_course_section": false,
  #       "root_account_id": 1,
  #       "type": "StudentEnrollment",
  #       "user_id": 2,
  #       "html_url": "https://...",
  #       "grades": {
  #         "html_url": "https://...",
  #       },
  #       "user": {
  #         "id": 2,
  #         "login_id": "changyourmind@example.com",
  #         "name": "Señor Chang",
  #         "short_name": "S. Chang",
  #         "sortable_name": "Chang, Señor"
  #       }
  #     }
  #   ]
  def index
    endpoint_scope = (@context.is_a?(Course) ? (@section.present? ? "section" : "course") : "user")
    scope_arguments = {
      :conditions => enrollment_index_conditions,
      :order => 'enrollments.type ASC, users.sortable_name ASC',
      :include => [:user, :course, :course_section]
    }

    return unless enrollments = @context.is_a?(Course) ?
      course_index_enrollments(scope_arguments) :
      user_index_enrollments(scope_arguments)

    enrollments = Api.paginate(
      enrollments,
      self, send("api_v1_#{endpoint_scope}_enrollments_url"))
    includes = [:user] + Array(params[:include])

    user_json_preloads(enrollments.map(&:user))
    render :json => enrollments.map { |e| enrollment_json(e, @current_user, session, includes) }
  end

  # @API Enroll a user
  # Create a new user enrollment for a course or section.
  #
  # @argument enrollment[user_id] [String]
  #   The ID of the user to be enrolled in the course.
  #
  # @argument enrollment[type] [String, "StudentEnrollment"|"TeacherEnrollment"|"TaEnrollment"|"ObserverEnrollment"|"DesignerEnrollment"]
  #   Enroll the user as a student, teacher, TA, observer, or designer. If no
  #   value is given, the type will be inferred by enrollment[role] if supplied,
  #   otherwise 'StudentEnrollment' will be used.
  #
  # @argument enrollment[role] [Optional, String]
  #   Assigns a custom course-level role to the user.
  #
  # @argument enrollment[enrollment_state] [Optional, String, "active"|"invited"]
  #   If set to 'active,' student will be immediately enrolled in the course.
  #   Otherwise they will be required to accept a course invitation. Default is
  #   'invited.'
  # @argument enrollment[course_section_id] [Optional, Integer]
  #   The ID of the course section to enroll the student in. If the
  #   section-specific URL is used, this argument is redundant and will be
  #   ignored.
  #
  # @argument enrollment[limit_privileges_to_course_section] [Optional, Boolean]
  #   If a teacher or TA enrollment, teacher/TA will be restricted to the
  #   section given by course_section_id.
  #
  # @argument enrollment[notify] [Optional, Boolean]
  #   If false, a notification will not be sent to the enrolled user.
  #   Notifications are sent by default.
  def create
    # error handling
    errors = []

    if params[:enrollment].blank?
      errors << @@errors[:missing_parameters] if params[:enrollment].blank?
    else
      role_name = params[:enrollment].delete(:role)
      type = params[:enrollment].delete(:type)
      if Enrollment.valid_type?(role_name)
        type = role_name
        role_name = nil
      end
      
      if role_name.present?
        params[:enrollment][:role_name] = role_name
        course_role = @context.account.get_course_role(role_name)
        if course_role.nil?
          errors << @@errors[:bad_role]
        elsif course_role.workflow_state != 'active'
          errors << @@errors[:inactive_role]
        else
          if type.blank?
            type = course_role.base_role_type
          elsif type != course_role.base_role_type
            errors << @@errors[:base_type_mismatch]
          end
        end
      end

      if type.present?
        errors << @@errors[:bad_type] unless Enrollment.valid_type?(type)
      else
        type = 'StudentEnrollment'
      end

      errors << @@errors[:missing_user_id] unless params[:enrollment][:user_id].present?
    end
    errors << @@errors[:concluded_course] if @context.completed? || @context.soft_concluded?
    unless errors.blank?
      render(:json => { :message => errors.join(', ') }, :status => 403) && return
    end

    # create enrollment

    params[:enrollment][:no_notify] = true unless params[:enrollment][:notify].nil? && value_to_boolean(params[:enrollment][:notify])
    unless @current_user.can_create_enrollment_for?(@context, session, type)
      render_unauthorized_action(@context) && return
    end
    params[:enrollment][:course_section_id] = @section.id if @section.present?
    if params[:enrollment][:course_section_id].present?
      params[:enrollment][:section] = @context.course_sections.active.find params[:enrollment].delete(:course_section_id)
    end
    user = api_find(User, params[:enrollment].delete(:user_id))
    @enrollment = @context.enroll_user(user, type, params[:enrollment].merge(:allow_multiple_enrollments => true))
    @enrollment.valid? ?
      render(:json => enrollment_json(@enrollment, @current_user, session)) :
      render(:json => @enrollment.errors)
  end

  # @API Conclude an enrollment
  # Delete or conclude an enrollment.
  #
  # @argument task [String, "conclude"|"delete"]
  #   The action to take on the enrollment.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/courses/:course_id/enrollments/:enrollment_id \ 
  #     -X DELETE \ 
  #     -F 'task=conclude'
  #
  # @example_response
  #   {
  #     "root_account_id": 15,
  #     "id": 75,
  #     "user_id": 4,
  #     "course_section_id": 12,
  #     "limit_privileges_to_course_section": false,
  #     "enrollment_state": "completed",
  #     "course_id": 12,
  #     "type": "StudentEnrollment",
  #     "html_url": "http://www.example.com/courses/12/users/4",
  #     "grades": { "html_url": "http://www.example.com/courses/12/grades/4" },
  #     "associated_user_id": null,
  #     "updated_at": "2012-04-18T23:08:51Z"
  #   }
  def destroy
    @enrollment = Enrollment.find(params[:id])
    task = %w{conclude delete}.include?(params[:task]) ? params[:task] : 'conclude'

    unless @enrollment.send("can_be_#{task}d_by", @current_user, @context, session)
      return render_unauthorized_action(@context)
    end

    task = 'destroy' if task == 'delete'
    if @enrollment.send(task)
      render :json => enrollment_json(@enrollment, @current_user, session)
    else
      render :json => @enrollment.errors, :status => :bad_request
    end
  end

  protected
  # Internal: Collect course enrollments that @current_user has permissions to
  # read.
  #
  # scope_arguments - A hash to be passed as :conditions to an AR scope.
  #                   Allowed keys are any keys allowed in :conditions.
  #
  # Returns an ActiveRecord scope of enrollments on success, false on failure.
  def course_index_enrollments(scope_arguments)
    if authorized_action(@context, @current_user, [:read_roster, :view_all_grades, :manage_grades])
      scope = @context.enrollments_visible_to(@current_user, :type => :all, :include_priors => true).scoped(scope_arguments)
      unless params[:state].present?
        scope = scope.where("enrollments.workflow_state NOT IN ('rejected', 'completed', 'deleted', 'inactive')")
      end
      scope
    else
      false
    end
  end

  # Internal: Collect user enrollments that @current_user has permissions to
  # read.
  #
  # scope_arguments - A hash to be passed as :conditions to an AR scope.
  #                   Allowed keys are any keys allowed in :conditions.
  #
  # Returns an ActiveRecord scope of enrollments on success, false on failure.
  def user_index_enrollments(scope_arguments)
    user = api_find(User, params[:user_id])

    # if user is requesting for themselves, just return all of their
    # enrollments without any extra checking.
    if user == @current_user
      enrollments = if params[:state].present?
                      user.enrollments.scoped(scope_arguments.merge(
                        :conditions => enrollment_index_conditions(true)))
                    else
                      user.current_and_invited_enrollments.scoped(scope_arguments)
                    end

      return enrollments
    end

    # otherwise check for read_roster rights on all of the requested
    # user's accounts
    approved_accounts = user.associated_root_accounts.inject([]) do |accounts, ra|
      accounts << ra.id if ra.grants_right?(@current_user, session, :read_roster)
      accounts
    end

    # if there aren't any ids in approved_accounts, then the user doesn't have
    # permissions.
    render_unauthorized_action(@user) and return false if approved_accounts.empty?

    additional_conditions = { 'enrollments.root_account_id' => approved_accounts }

    # by default, return active and invited courses. don't use the existing
    # current_and_invited_enrollments scope because it won't return enrollments
    # on unpublished courses.
    additional_conditions.merge!({:workflow_state => %w{active invited}}) unless params[:state].present?

    user.enrollments.scoped(scope_arguments).where(additional_conditions)
  end

  # Internal: Collect type, section, state, and role info from params and format them
  # for use in a request for the requester's own enrollments.
  # index is :course or :user
  #
  # Returns [ sql fragment string, replacement hash ]
  def enrollment_index_conditions(use_course_state = false)
    type, state, role = params.values_at(:type, :state, :role)
    clauses = []
    replacements = {}

    if role.present?
      clauses << 'COALESCE (enrollments.role_name, enrollments.type) IN (:role)'
      replacements[:role] = Array(role)
    elsif type.present?
      clauses << 'enrollments.type IN (:type)'
      replacements[:type] = Array(type)
    end

    if state.present?
      if use_course_state
        clauses << "(#{state.map{|s| "(#{User.enrollment_conditions(s.to_sym)})" }.join(' OR ')})"
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
end
