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
    section_restricted_by_date? && section_is_ongoing?
  end

  def course_section
    @course_section ||= (assignment_overrides | student_sections).first || CourseSection.new
  end

  private

  attr_reader :course, :quiz, :user, :session, :remote_ip

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
    # Term  | Restricted Course  | Section  | Section Restr? | Restricted by date?
    # open  | open               | open     | false          | false
    # open  | open               | open     | true           | false
    # open  | open               | closed   | false          | false
    # open  | open               | closed   | true           | true
    # open  | closed             | open     | false          | true
    # open  | closed             | open     | true           | false
    # open  | closed             | closed   | false          | true
    # open  | closed             | closed   | true           | true
    # closed| open               | open     | false          | false
    # closed| open               | open     | true           | false
    # closed| open               | closed   | false          | false
    # closed| open               | closed   | true           | true
    # closed| closed             | open     | false          | true
    # closed| closed             | open     | true           | false
    # closed| closed             | closed   | false          | true
    # closed| closed             | closed   | true           | true

    return true if restricted_section_has_ended?
    return false if section_is_ongoing? && section_restricted_by_date?

    return true if restricted_course_has_ended?
    if term_has_ended? && !course_restricted_by_date?
      return true
    end
    false
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

  def assignment_overrides
    AssignmentOverride.where(quiz_id: quiz.id, set_type: CourseSection).map(&:set)
  end

  def restricted_section_has_ended?
    return false unless course_section.present?
    return false unless section_restricted_by_date?
    course_section.end_at && course_section.end_at < Time.zone.now
  end

  def section_is_ongoing?
    course_section.end_at && course_section.end_at >= Time.zone.now
  end

  def section_restricted_by_date?
    course_section.restrict_enrollments_to_section_dates
  end

  def course_has_ended?
    course.end_at && course.end_at <= Time.zone.now
  end

  def course_restricted_by_date?
    course && course.restrict_enrollments_to_course_dates
  end

  def restricted_course_has_ended?
    if course.restrict_enrollments_to_course_dates
      course.end_at ? course_has_ended? : term_has_ended?
    else
      false
    end
  end

  def inactive_non_admin?
    return false if user.new_record?
    inactive_enrollment? && user_cannot_not_read_as_admin?
  end

  def inactive_enrollment?
    course.enrollments.where(user_id: user.id).all?(&:inactive?)
  end

  def inactive_student_with_private_course?
    user && !user_is_active? && !course.is_public
  end

  def student_sections
    !user.new_record? && user.sections_for_course(course) || []
  end

  def term
    @term ||= course.enrollment_term || EnrollmentTerm.new
  end

  def term_has_ended?
    term.end_at && term.end_at <= Time.zone.now
  end

  def user_cannot_not_read_as_admin?
    !course.grants_right?(user, :read_as_admin)
  end

  def user_is_active?
    user.workflow_state.present? && user.workflow_state != 'deleted'
  end
end
