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
    :bad_type           => 'Invalid type'
  }
  @@valid_types = %w{StudentEnrollment TeacherEnrollment TaEnrollment ObserverEnrollment}

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
  # @argument type[] A list of enrollment types to return. Accepted values are 'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', and 'ObserverEnrollment.' If omitted, all enrollment types are returned.
  # @argument state[] Filter by enrollment state. Accepted values are 'active', 'invited', and 'creation_pending', 'deleted', 'rejected', 'completed', and 'inactive'. If omitted, 'active' and 'invited' enrollments are returned.
  #
  # @response_field id The unique id of the enrollment.
  # @response_field course_id The unique id of the course.
  # @response_field course_section_id The unique id of the user's section.
  # @response_field enrollment_state The state of the user's enrollment in the course.
  # @response_field limit_privileges_to_course_section User can only access his or her own course section.
  # @response_field root_account_id The unique id of the user's account.
  # @response_field type The type of the enrollment.
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
    @conditions = {}.tap { |c|
      c[:type] = params[:type] if params[:type].present?
      c[:workflow_state] = params[:state] if params[:state].present?
      c[:course_section_id] = @section.id if @section.present?
    }

    endpoint_scope = (@context.is_a?(Course) ? (@section.present? ? "section" : "course") : "user")
    scope_arguments = { :conditions => @conditions,
      :order => 'enrollments.type ASC, users.sortable_name ASC',
      :include => {:user => [], :course => [], :course_section => []} }
    if user_json_is_admin?
      scope_arguments[:include][:user] = :pseudonyms
    end

    return unless enrollments = @context.is_a?(Course) ?
      course_index_enrollments(scope_arguments) :
      user_index_enrollments(scope_arguments)

    enrollments = Api.paginate(
      enrollments,
      self, send("api_v1_#{endpoint_scope}_enrollments_path"))
    includes = [:user] + Array(params[:include])

    render :json => enrollments.map { |e| enrollment_json(e, @current_user, session, includes) }
  end

  # @API Enroll a user
  # Create a new user enrollment for a course or section.
  #
  # @argument enrollment[user_id] [String] The ID of the user to be enrolled in the course.
  # @argument enrollment[type] [String] [StudentEnrollment|TeacherEnrollment|TaEnrollment|ObserverEnrollment] Enroll the user as a student, teacher, TA, or observer. If no value is given, 'StudentEnrollment' will be used.
  # @argument enrollment[enrollment_state] [String] [Optional, active|invited] [String] If set to 'active,' student will be immediately enrolled in the course. Otherwise they will be required to accept a course invitation. Default is 'invited.'
  # @argument enrollment[course_section_id] [Integer] [Optional] The ID of the course section to enroll the student in. If the section-specific URL is used, this argument is redundant and will be ignored
  # @argument enrollment[limit_privileges_to_course_section] [Boolean] [Optional] If a teacher or TA enrollment, teacher/TA will be restricted to the section given by course_section_id.
  # @argument enrollment[notify] [Boolean] [Optional] If false (0 or "false"), a notification will not be sent to the enrolled user. Notifications are sent by default.
  def create
    # error handling
    errors = []
    if params[:enrollment].blank?
      errors << @@errors[:missing_parameters] if params[:enrollment].blank?
    else
      errors << @@errors[:bad_type] if params[:enrollment][:type].present? && !@@valid_types.include?(params[:enrollment][:type])
      errors << @@errors[:missing_user_id] unless params[:enrollment][:user_id].present?
    end
    unless errors.blank?
      render(:json => { :message => errors.join(', ') }, :status => 403) && return
    end

    # create enrollment
    type = params[:enrollment].delete(:type)
    params[:enrollment][:no_notify] = true unless params[:enrollment][:notify].nil? && value_to_boolean(params[:enrollment][:notify])
    type = 'StudentEnrollment' unless @@valid_types.include?(type)
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
      render(:json => enrollment_json(@enrollment, @current_user, session).to_json) :
      render(:json => @enrollment.errors.to_json)
  end

  # @API Conclude an enrollment
  # Delete or conclude an enrollment.
  #
  # @argument task [conclude|delete] [String] The action to take on the enrollment.
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
      render :json => @enrollment.errors.to_json, :status => :bad_request
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
    if authorized_action(@context, @current_user, :read_roster)
      scope = @context.enrollments_visible_to(@current_user, :type => :all, :include_priors => true).scoped(scope_arguments)
      unless scope_arguments[:conditions].include?(:workflow_state)
        scope = scope.scoped(:conditions =>  ['enrollments.workflow_state NOT IN (?)', ['rejected', 'completed', 'deleted', 'inactive']])
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
                        :conditions => conditions_for_self))
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

    scope_arguments[:conditions].merge!({ 'enrollments.root_account_id' => approved_accounts })
    # by default, return active and invited courses. don't use the existing
    # current_and_invited_enrollments scope because it won't return enrollments
    # on unpublished courses.
    scope_arguments[:conditions][:workflow_state] ||= %w{active invited}

    user.enrollments.scoped(scope_arguments)
  end

  # Internal: Collect type, section, and state info from params and format them
  # for use in a request for the requester's own enrollments.
  #
  # Returns a hash or array.
  def conditions_for_self
    type, state = params.values_at(:type, :state)
    conditions  = [[], {}]

    if type.present?
      conditions[0] << 'enrollments.type IN (:type)'
      conditions[1][:type] = type
    end

    if state.present?
      state.map(&:to_sym).each do |s|
        conditions[0] << User.enrollment_conditions(s)
      end
    end

    if @section.present?
      conditions[0] << 'enrollments.course_section_id = :course_section_id'
      conditions[1][:course_section_id] = @section.id
    end

    conditions[0] = conditions[0].join(' AND ')
    conditions
  end
end
