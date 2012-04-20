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
    :missing_parameters => "No parameters given",
    :missing_user_id    => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment",
    :bad_type           => 'Invalid type'
  }
  @@valid_types = %w{StudentEnrollment TeacherEnrollment TaEnrollment ObserverEnrollment}

  include Api::V1::User
  #
  # @API
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
  # @response_field course_id The unique id of the course.
  # @response_field course_section_id The unique id of the user's section.
  # @response_field enrollment_state The state of the user's enrollment in the course.
  # @response_field limit_privileges_to_course_section User can only access his or her own course section.
  # @response_field root_account_id The unique id of the user's account.
  # @response_field type The type of the enrollment.
  # @response_field user_id The unique id of the user.
  # @response_field html_url The URL to the Canvas web UI page for this course enrollment.
  # @response_field grades[html_url] The URL to the Canvas web UI page for the user's grades, if this is a student enrollment.
  # @response_field user[id] The unique id of the user.
  # @response_field user[login_id] The unique login of the user.
  # @response_field user[name] The name of the user.
  # @response_field user[short_name] The short name of the user.
  # @response_field user[sortable_name] The sortable name of the user.
  #
  # @example_response
  #   [
  #     {
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
    scope_arguments = { :conditions => @conditions, :order => 'enrollments.type ASC, users.sortable_name ASC' }
    return unless enrollments = @context.is_a?(Course) ?
      course_index_enrollments(scope_arguments) :
      user_index_enrollments(scope_arguments)
    enrollments = Api.paginate(
      enrollments,
      self, send("api_v1_#{endpoint_scope}_enrollments_path"))
    includes = [:user] + Array(params[:include])
    render :json => enrollments.map { |e| enrollment_json(e, @current_user, session, includes) }
  end

  # @API
  # Create a new user enrollment for a course or section.
  #
  # @argument enrollment[user_id] [String] The ID of the user to be enrolled in the course.
  # @argument enrollment[type] [String] [StudentEnrollment|TeacherEnrollment|TaEnrollment|ObserverEnrollment] Enroll the user as a student, teacher, TA, or observer. If no value is given, 'StudentEnrollment' will be used.
  # @argument enrollment[enrollment_state] [String] [Optional, active|invited] [String] If set to 'active,' student will be immediately enrolled in the course. Otherwise they will receive an email invitation. Default is 'invited.'
  # @argument enrollment[course_section_id] [Integer] [Optional] The ID of the course section to enroll the student in. If the section-specific URL is used, this argument is redundant and will be ignored
  # @argument enrollment[limit_privileges_to_course_section] [Boolean] [Optional] If a teacher or TA enrollment, teacher/TA will be restricted to the section given by course_section_id.
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
    type = 'StudentEnrollment' unless @@valid_types.include?(type)
    unless @current_user.can_create_enrollment_for?(@context, session, type)
      render_unauthorized_action(@context) && return
    end
    params[:enrollment][:course_section_id] = @section.id if @section.present?
    if params[:enrollment][:course_section_id].present?
      params[:enrollment][:section] = @context.course_sections.active.find params[:enrollment].delete(:course_section_id)
    end
    user = api_find(User, params[:enrollment].delete(:user_id))
    @enrollment = @context.enroll_user(user, type, params[:enrollment])
    @enrollment.valid? ?
      render(:json => enrollment_json(@enrollment, @current_user, session).to_json) :
      render(:json => @enrollment.errors.to_json)
  end

  protected
  def course_index_enrollments(scope_arguments)
    if authorized_action(@context, @current_user, :read_roster)
      scope_arguments[:conditions].include?(:workflow_state) ?
        @context.enrollments.scoped(scope_arguments) :
        @context.current_enrollments.scoped(scope_arguments)
    else
      false
    end
  end

  def user_index_enrollments(scope_arguments)
    user = api_find(User, params[:user_id])
    # if user is requesting for themselves, just return all of their
    # enrollments without any extra checking.
    return user.current_enrollments if user == @current_user

    # otherwise check for read_roster rights on all of the requested
    # user's accounts
    approved_accounts = user.associated_root_accounts.inject([]) do |accounts, ra|
      accounts << ra.id if ra.grants_right?(@current_user, session, :read_roster)
      accounts
    end

    scope_arguments[:conditions].merge!({ 'enrollments.root_account_id' => approved_accounts })
    enrollments = scope_arguments[:conditions].include?(:workflow_state) ?
      user.enrollments.scoped(scope_arguments) :
      user.current_and_invited_enrollments.scoped(scope_arguments)

    if enrollments.count == 0 && user.current_enrollments.count != 0
      render_unauthorized_action(@user)
      return false
    else
      return enrollments
    end
  end
end
