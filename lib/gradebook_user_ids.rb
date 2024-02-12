# frozen_string_literal: true

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
    settings = (user.get_preference(:gradebook_settings, course.global_id) || {}).with_indifferent_access
    @course = course
    @user = user
    @include_inactive = settings[:show_inactive_enrollments] == "true"
    @include_concluded = settings[:show_concluded_enrollments] == "true"
    @column = settings[:sort_rows_by_column_id] || "student"
    @sort_by = settings[:sort_rows_by_setting_key] || "name"
    @selected_grading_period_id = settings.dig(:filter_columns_by, :grading_period_id)
    @selected_section_id = settings.dig(:filter_rows_by, :section_id)
    @selected_student_group_ids = settings.dig(:filter_rows_by, :student_group_ids)
    @selected_student_group_id = settings.dig(:filter_rows_by, :student_group_id)
    @direction = settings[:sort_rows_by_direction] || "ascending"
  end

  def user_ids
    case @column
    when "student"
      sort_by_student_field
    when /assignment_\d+$/
      assignment_id = @column[/\d+$/]
      case @sort_by
      when "grade"
        sort_by_assignment_grade(assignment_id)
      when "missing"
        sort_by_assignment_missing(assignment_id)
      when "late"
        sort_by_assignment_late(assignment_id)
      when "excused"
        sort_by_assignment_excused(assignment_id)
      when "unposted"
        sort_by_assignment_unposted(assignment_id)
      end
    when /^assignment_group_\d+$/
      assignment_id = @column[/\d+$/]
      sort_by_assignment_group(assignment_id)
    when "total_grade"
      sort_by_total_grade
    when "student_firstname"
      sort_by_student_first_name
    else
      sort_by_student_name
    end
  end

  private

  def sort_by_student_field
    if ["name", "sortable_name"].include?(@sort_by) || !pseudonym_sort_field
      sort_by_student_name
    else
      sort_by_pseudonym_field
    end
  end

  def sort_by_student_name
    students
      .order(Arel.sql("enrollments.type = 'StudentViewEnrollment'"))
      .order_by_sortable_name(direction: @direction.to_sym)
      .pluck(:id)
      .uniq
  end

  def sort_by_student_first_name
    students
      .order(Arel.sql("enrollments.type = 'StudentViewEnrollment'"))
      .order_by_name(direction: @direction.to_sym, table: "users")
      .pluck(:id)
      .uniq
  end

  def sort_by_pseudonym_field
    sort_column = Pseudonym.best_unicode_collation_key("pseudonyms.#{pseudonym_sort_field}")

    students.joins("LEFT JOIN #{Pseudonym.quoted_table_name} ON pseudonyms.user_id=users.id AND
                    pseudonyms.workflow_state <> 'deleted'")
            .order(Arel.sql("#{sort_column} #{sort_direction} NULLS LAST"))
            .order(Arel.sql("pseudonyms.id IS NULL"))
            .order(Arel.sql("users.id #{sort_direction}"))
            .pluck(:id)
            .uniq
  end

  def pseudonym_sort_field
    # The sort keys integration_id and sis_user_id map to columns in Pseudonym,
    # while login_id needs to be changed to unique_id
    {
      "login_id" => "unique_id",
      "sis_user_id" => "sis_user_id",
      "integration_id" => "integration_id"
    }.with_indifferent_access[@sort_by]
  end

  def sort_by_assignment_grade(assignment_id)
    students
      .joins("LEFT JOIN #{Submission.quoted_table_name} ON submissions.user_id=users.id AND
             submissions.workflow_state<>'deleted' AND
             submissions.assignment_id=#{Submission.connection.quote(assignment_id)}")
      .order(Arel.sql("enrollments.type = 'StudentViewEnrollment'"))
      .order(Arel.sql("submissions.score #{sort_direction} NULLS LAST"))
      .order(Arel.sql("submissions.id IS NULL"))
      .order_by_sortable_name(direction: @direction.to_sym)
      .pluck(:id)
      .uniq
  end

  def sort_by_assignment_missing(assignment_id)
    sort_user_ids(Submission.missing.where(assignment_id:))
  end

  def sort_by_assignment_excused(assignment_id)
    sort_user_ids(Submission.excused.where(assignment_id:))
  end

  def sort_by_assignment_unposted(assignment_id)
    sort_user_ids(Submission.graded.unposted.where(assignment_id:))
  end

  def sort_by_assignment_late(assignment_id)
    sort_user_ids(Submission.late.where(assignment_id:))
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
    workflow_states << :completed if @include_concluded || @course.completed?
    student_enrollments = @course.enrollments.where(
      workflow_state: workflow_states,
      type: [:StudentEnrollment, :StudentViewEnrollment]
    )

    @course.apply_enrollment_visibility(student_enrollments, @user, nil, include: workflow_states)
  end

  def students
    # Because of AR internals (https://github.com/rails/rails/issues/32598),
    # we avoid using Arel left_joins here so that sort_by_scores will have
    # Enrollment defined.
    students = User
               .joins("LEFT JOIN #{Enrollment.quoted_table_name} ON enrollments.user_id=users.id")
               .merge(student_enrollments_scope)

    multiselect_filters_enabled = Account.site_admin.feature_enabled?(:multiselect_gradebook_filters)
    if multiselect_filters_enabled && student_group_ids.present?
      students_in_groups(students, student_group_ids)
    elsif !multiselect_filters_enabled && student_group_id.present?
      students_in_groups(students, student_group_id)
    else
      students
    end
  end

  def students_in_groups(students, group_id_or_group_ids)
    students.joins(group_memberships: :group)
            .where(group_memberships: { group: group_id_or_group_ids, workflow_state: :accepted })
            .merge(Group.active)
  end

  def sort_by_scores(type = :total_grade, id = nil)
    score_scope = case type
                  when :assignment_group
                    "scores.assignment_group_id=#{Score.connection.quote(id)}"
                  when :grading_period
                    "scores.grading_period_id=#{Score.connection.quote(id)}"
                  else
                    "scores.course_score IS TRUE"
                  end

    # Without doing the score conditions in the join, we lose data. For
    # example, we might lose concluded enrollments who don't have a Score.
    students.joins("LEFT JOIN #{Score.quoted_table_name} ON scores.enrollment_id=enrollments.id AND
                scores.workflow_state='active' AND #{score_scope}")
            .order(Arel.sql("enrollments.type = 'StudentViewEnrollment'"))
            .order(Arel.sql("scores.unposted_current_score #{sort_direction} NULLS LAST"))
            .order_by_sortable_name(direction: @direction.to_sym)
            .pluck(:id).uniq
  end

  def sort_direction
    (@direction == "ascending") ? :asc : :desc
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
    return nil if @selected_section_id.nil? || @selected_section_id == "null" || @selected_section_id == "0"

    @selected_section_id
  end

  def student_group_id
    return nil if @selected_student_group_id.nil? || ["0", "null"].include?(@selected_student_group_id)

    active_groups_exist?(@selected_student_group_id) ? @selected_student_group_id : nil
  end

  def student_group_ids
    @student_group_ids ||= if @selected_student_group_ids.blank? || !active_groups_exist?(@selected_student_group_ids)
                             []
                           else
                             @selected_student_group_ids
                           end
  end

  def active_groups_exist?(id_or_ids)
    Group.active.where(id: id_or_ids).exists?
  end
end
