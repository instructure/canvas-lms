#
# Copyright (C) 2011 Instructure, Inc.
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
  before_filter :require_context

  @@errors = {
    :missing_parameters => "No parameters given",
    :missing_user_id    => "Can't create an enrollment without a user. Include enrollment[user_id] to create an enrollment",
    :bad_type           => 'Invalid type'
  }
  @@valid_types = %w{StudentEnrollment TeacherEnrollment TaEnrollment ObserverEnrollment}

  include Api::V1::Enrollment
  #
  # @API
  # Return a list of all enrolled users in a course. Includes students,
  # teachers, TAs, and observers. Any enrollment types without members
  # are omitted.
  #
  # @argument type[] A list of enrollment types to return. Accepted values are 'StudentEnrollment', 'TeacherEnrollment', 'TaEnrollment', and 'ObserverEnrollment.' If omitted, all enrollment types are retuurned.
  #
  # @response_field id The unique identifier for the course member.
  # @response_field name The full course member name.
  # @response_field sis_user_id The SIS id for the user's primary pseudonym.
  #
  # @example_response
  # {
  #   "students": [ { "id": 1, "name": "Justin Bieber", "sortable_name": "Bieber, Justin", "short_name": "Justin B.", "login_id": "jbieber@example.com", "sis_user_id": null, "sis_login_id": null },
  #                 { "id": 2, "name": "Selena Gomez", "sortable_name": "Gomez, Selena", "short_name": "Selena G.", "login_id": "sgomez@example.com", "sis_user_id": "from-sis", "sis_login_id": "login-from-sis" }
  #               ],
  #   "teachers": [ { "id": 3, "name": "Señor Chang", "sortable_name": "Chang, Señor", "short_name": "S. Chang", "login_id": "changyourmind@example.com", "sis_user_id": null, "sis_login_id": null } ]
  # }
  def index
    get_context
    return unless authorized_action(@context, @current_user, :read_roster)
    conditions = {}.tap { |c| c[:type] = params[:type] if params[:type].present? }
    enrollments = Api.paginate(
      @context.current_enrollments.scoped(:include => :user, :conditions => conditions, :order => 'enrollments.type ASC, users.sortable_name ASC'),
      self, api_v1_enrollments_path)
    render :json => enrollments.map { |e| enrollment_json(e, @current_user, session, [:user]) }
  end

  # @API
  # Create a new user enrollment for a course.
  #
  # @argument enrollment[user_id] [String] The ID of the user to be enrolled in the course.
  # @argument enrollment[type] [String] [StudentEnrollment|TeacherEnrollment|TaEnrollment|ObserverEnrollment] Enroll the user as a student, teacher, TA, or observer. If no value is given, 'StudentEnrollment' will be used.
  # @argument enrollment[enrollment_state] [String] [Optional, active|invited] [String] If set to 'active,' student will be immediately enrolled in the course. Otherwise they will receive an email invitation. Default is 'invited.'
  # @argument enrollment[course_section_id] [Integer] [Optional] The ID of the course section to enroll the student in.
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

    # creat enrollment
    type = params[:enrollment].delete(:type)
    type = 'StudentEnrollment' unless @@valid_types.include?(type)
    unless @current_user.can_create_enrollment_for?(@context, session, type)
      render_unauthorized_action(@context) && return
    end
    if params[:enrollment][:course_section_id].present?
      params[:enrollment][:section] = @context.course_sections.active.find params[:enrollment].delete(:course_section_id)
    end
    user = api_find(User, params[:enrollment].delete(:user_id))
    @enrollment = @context.enroll_user(user, type, params[:enrollment])
    @enrollment.valid? ?
      render(:json => enrollment_json(@enrollment, @current_user, session).to_json) :
      render(:json => @enrollment.errors.to_json)
  end
end
