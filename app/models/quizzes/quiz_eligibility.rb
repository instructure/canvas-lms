#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

# Models logic concerning eligibility to take a quiz
#
# The session Hash provided is modified in the call to
# #store_session_access_code: the session will have a new Hash stored under the
# key :quiz_access_code, which will contain quiz ID => access code mappings.
class Quizzes::QuizEligibility
  def initialize(args = {})
    @course      = args[:course]
    @quiz        = args[:quiz]
    @user        = args[:user] || User.new
    @session     = args[:session] || {}
    @remote_ip   = args[:remote_ip]

    store_session_access_code(args[:access_code]) if args[:access_code]
  end

  def potentially_eligible?
    return true if quiz.grants_right?(user, session, :manage)
    return false unless course
    return false if inactive_student_with_private_course?
    !(course_restrictions_apply? || user_restrictions_apply?)
  end

  def eligible?
    potentially_eligible? && !quiz_restrictions_apply?
  end

  def declined_reason_renders
    return :access_code if need_access_code?
    return :invalid_ip  if invalid_ip?
  end

  def locked?
    return false unless quiz_locked?
    !quiz.grants_right?(user, session, :update)
  end

  def section_dates_currently_apply?
    active_sections = student_sections.select{|s| restricted?(s) && active?(s)}
    @active_sections_max_end_at = active_sections.map(&:end_at).compact.max if active_sections.present?
    active_sections.present?
  end

  def active_sections_max_end_at
    section_dates_currently_apply? if @active_sections_max_end_at.nil?
    @active_sections_max_end_at
  end

  private

  attr_reader :course, :quiz, :user, :session, :remote_ip

  def active?(section)
    now = Time.zone.now
    (section.start_at.nil? || section.start_at <= now) && (section.end_at.nil? || section.end_at >= now)
  end

  def restricted?(section)
    #  Restrictions aren't applicable if date boundries are not set
    return false unless section.start_at && section.end_at
    case section
    when Course
      !!section.restrict_enrollments_to_course_dates
    when CourseSection
      !!section.restrict_enrollments_to_section_dates
    end
  end

  def course_restrictions_apply?
    locked? || restricted_by_date?
  end

  def user_restrictions_apply?
    inactive_non_admin? || !quiz.grants_right?(user, session, :submit)
  end

  def quiz_restrictions_apply?
    need_access_code? || invalid_ip?
  end

  def restricted_by_date?
    # First check if any of the assignment overides are active
    assignment_override_sections.each{|ao| return false if active?(ao)}

    # Term dates override any others unless course date restrictions or
    # section date restrictions are selected.  Section dates override course
    # dates if section date restrictions apply

    any_section_restriction = false

    term_active = active?(term)

    course_restricted = restricted?(course)
    course_active = active?(course)

    student_sections.each do |section|
      section_restricted = restricted?(section)
      section_active = active?(section)

      any_section_restriction = true if section_restricted

      # if there is a section restriction and the user is in an active section
      return false if section_restricted && section_active
    end

    # he's in a section that's restricted, but not one that's active; it's restricted
    return true if any_section_restriction

    return !course_active if course_restricted

    # fall back to the term if there aren't any other restrictions
    !term_active
  end

  def store_session_access_code(access_code)
    session[:quiz_access_code] ||= {}
    session[:quiz_access_code][quiz.id] = access_code
  end

  def need_access_code?
    quiz.access_code.present? && !access_code_correct?
  end

  def access_code_correct?
    Hash(session[:quiz_access_code])[quiz.id] == quiz.access_code
  end

  def invalid_ip?
    quiz.ip_filter && !quiz.valid_ip?(remote_ip)
  end

  def quiz_locked?
    quiz.locked_for?(user, check_policies: true, deep_check_if_needed: true)
  rescue NoMethodError # Occurs when quiz is nil
    false
  end

  def assignment_override_sections
    AssignmentOverride.where(quiz_id: quiz.id, set_type: CourseSection).map(&:set) & student_sections
  end

  def inactive_non_admin?
    return false if user.new_record?
    inactive_enrollment? && user_cannot_not_read_as_admin?
  end

  def inactive_enrollment?
    course.enrollments.where(user_id: user.id).preload(:enrollment_state).all?(&:inactive?)
  end

  def inactive_student_with_private_course?
    user && !user_is_active? && !course.is_public
  end

  def student_sections
    @student_sections ||= !user.new_record? && user.sections_for_course(course) || []
  end

  def term
    @term ||= course.enrollment_term || EnrollmentTerm.new
  end

  def user_cannot_not_read_as_admin?
    !course.grants_right?(user, :read_as_admin)
  end

  def user_is_active?
    user.workflow_state.present? && user.workflow_state != 'deleted'
  end
end
