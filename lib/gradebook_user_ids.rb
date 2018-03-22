#
# Copyright (C) 2017 - present Instructure, Inc.
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

class GradebookUserIds
  def initialize(course, user)
    settings = (user.preferences.dig(:gradebook_settings, course.id) || {}).with_indifferent_access
    @course = course
    @user = user
    @include_inactive = settings[:show_inactive_enrollments] == "true"
    @include_concluded = settings[:show_concluded_enrollments] == "true"
    @column = settings[:sort_rows_by_column_id] || "student"
    @sort_by = settings[:sort_rows_by_setting_key] || "name"
    @selected_grading_period_id = settings.dig(:filter_columns_by, :grading_period_id)
    @selected_section_id = settings.dig(:filter_rows_by, :section_id)
    @direction = settings[:sort_rows_by_direction] || "ascending"
  end

  def user_ids
    if @column == "student"
      sort_by_student_name
    elsif @column =~ /assignment_\d+$/
      assignment_id = @column[/\d+$/]
      send("sort_by_assignment_#{@sort_by}", assignment_id)
    elsif @column =~ /^assignment_group_\d+$/
      assignment_id = @column[/\d+$/]
      sort_by_assignment_group(assignment_id)
    elsif @column == "total_grade"
      sort_by_total_grade
    else
      sort_by_student_name
    end
  end

  private

  def sort_by_student_name
    students.
      order("#{Enrollment.table_name}.type = 'StudentViewEnrollment'").
      order_by_sortable_name(direction: @direction.to_sym).
      pluck(:id).
      uniq
  end

  def sort_by_assignment_grade(assignment_id)
    students.
      joins("LEFT JOIN #{Submission.quoted_table_name} ON submissions.user_id=users.id AND
             submissions.workflow_state<>'deleted' AND
             submissions.assignment_id=#{Submission.connection.quote(assignment_id)}").
      order("#{Enrollment.table_name}.type = 'StudentViewEnrollment'").
      order("#{Submission.table_name}.score #{sort_direction} NULLS LAST").
      order("#{Submission.table_name}.id IS NULL").
      order_by_sortable_name(direction: @direction.to_sym).
      pluck(:id).
      uniq
  end

  def sort_by_assignment_missing(assignment_id)
    sort_user_ids(Submission.missing.where(assignment_id: assignment_id))
  end

  def sort_by_assignment_late(assignment_id)
    sort_user_ids(Submission.late.where(assignment_id: assignment_id))
  end

  def sort_by_total_grade
    grading_period_id ? sort_by_scores(:grading_period, grading_period_id) : sort_by_scores(:total_grade)
  end

  def sort_by_assignment_group(assignment_group_id)
    sort_by_scores(:assignment_group, assignment_group_id)
  end

  def all_user_ids
    @all_user_ids ||= students.order_by_sortable_name(direction: @direction.to_sym).pluck(:id).uniq
  end

  def all_user_ids_index
    @all_user_ids_index ||= index_user_ids(all_user_ids)
  end

  def fake_user_ids
    student_enrollments_scope.where(type: "StudentViewEnrollment").pluck(:user_id).uniq
  end

  def sorted_fake_user_ids
    @sorted_fake_user_ids ||= sort_using_index(fake_user_ids, all_user_ids_index)
  end

  def sorted_real_user_ids
    @sorted_real_user_ids ||= sort_using_index(all_user_ids - sorted_fake_user_ids, all_user_ids_index)
  end

  def real_user_ids_from_submissions(submissions)
    submissions.where(user_id: sorted_real_user_ids).pluck(:user_id)
  end

  def sorted_real_user_ids_from_submissions(submissions)
    sort_using_index(real_user_ids_from_submissions(submissions), all_user_ids_index)
  end

  def sort_user_ids(submissions)
    sorted_real_user_ids_from_submissions(submissions).concat(sorted_real_user_ids, sorted_fake_user_ids).uniq
  end

  def index_user_ids(user_ids)
    user_ids_index = {}
    # Traverse the array once and cache all indexes so we don't incur traversal costs at the end
    user_ids.each_with_index { |item, idx| user_ids_index[item] = idx }
    user_ids_index
  end

  def sort_using_index(user_ids, user_ids_index)
    user_ids.sort_by { |item| user_ids_index[item] }
  end

  def student_enrollments_scope
    workflow_states = [:active, :invited]
    workflow_states << :inactive if @include_inactive
    workflow_states << :completed if @include_concluded || @course.concluded?
    student_enrollments = @course.enrollments.where(
      workflow_state: workflow_states,
      type: [:StudentEnrollment, :StudentViewEnrollment]
    )

    section_ids = section_id ? [section_id] : nil
    @course.apply_enrollment_visibility(student_enrollments, @user, section_ids, include: workflow_states)
  end

  def students
    User.left_joins(:enrollments).merge(student_enrollments_scope)
  end

  def sort_by_scores(type = :total_grade, id = nil)
    score_scope = if type == :assignment_group
      "scores.assignment_group_id=#{Score.connection.quote(id)}"
    elsif type == :grading_period
      "scores.grading_period_id=#{Score.connection.quote(id)}"
    else
      "scores.course_score IS TRUE"
    end

    # In this query we need to jump through enrollments to go see if
    # there are scores for the user. Because of some AR internal
    # stuff, if we did students.joins("LEFT JOIN scores ON
    # enrollments.id=scores.enrollment_id AND ...") as you'd expect,
    # it plops the new join before the enrollments join and the
    # database gets angry because it doesn't know what what this
    # "enrollments" we're querying against is. Because of this, we
    # have to WET up the method and hand do the enrollment join
    # here. Without doing the score conditions in the join, we lose
    # data, so it has to be this way... For example, we might lose
    # concluded enrollments who don't have a Score.
    #
    # That is a super long way of saying, make sure this stays in sync
    # with what happens in the students method above in regards to
    # enrollments and enrollments scoping.
    User.joins("LEFT JOIN #{Enrollment.quoted_table_name} on users.id=enrollments.user_id
                LEFT JOIN #{Score.quoted_table_name} ON scores.enrollment_id=enrollments.id AND
                scores.workflow_state='active' AND #{score_scope}").
      merge(student_enrollments_scope).
      order("#{Enrollment.table_name}.type = 'StudentViewEnrollment'").
      order("#{Score.table_name}.unposted_current_score #{sort_direction} NULLS LAST").
      order_by_sortable_name(direction: @direction.to_sym).
      pluck(:id).uniq
  end

  def sort_direction
    @direction == "ascending" ? :asc : :desc
  end

  def grading_period_id
    return nil unless @course.grading_periods?
    return nil if @selected_grading_period_id == "0"

    if @selected_grading_period_id.nil? || @selected_grading_period_id == "null"
      GradingPeriod.current_period_for(@course)&.id
    else
      @selected_grading_period_id
    end
  end

  def section_id
    return nil if @selected_section_id.nil? || @selected_section_id == "null" || @section_section_id == "0"
    @selected_section_id
  end
end
