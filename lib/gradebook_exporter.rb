#
# Copyright (C) 2015 Instructure, Inc.
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

class GradebookExporter
  include GradebookSettingsHelpers

  def initialize(course, user, options = {})
    @course  = course
    @user    = user
    @options = options
  end

  def to_csv
    enrollment_scope = @course.apply_enrollment_visibility(gradebook_enrollment_scope, @user, nil,
                                                           include: gradebook_includes)
    student_enrollments = enrollments_for_csv(enrollment_scope)

    student_section_names = {}
    student_enrollments.each do |enrollment|
      student_section_names[enrollment.user_id] ||= []
      student_section_names[enrollment.user_id] << (enrollment.course_section.display_name rescue nil)
    end

    # remove duplicate enrollments for students enrolled in multiple sections
    student_enrollments = student_enrollments.uniq(&:user_id)

    # grading_period_id == 0 means no grading period selected
    unless @options[:grading_period_id].try(:to_i) == 0
      grading_period = GradingPeriod.for(@course).find_by(id: @options[:grading_period_id])
    end

    calc = GradeCalculator.new(student_enrollments.map(&:user_id), @course,
                               ignore_muted: false,
                               grading_period: grading_period)
    grades = calc.compute_scores

    submissions = {}
    calc.submissions.each { |s| submissions[[s.user_id, s.assignment_id]] = s }

    assignments = select_in_grading_period calc.assignments, grading_period

    assignments = assignments.sort_by do |a|
      [a.assignment_group_id, a.position || 0, a.due_at || CanvasSort::Last, a.title]
    end
    groups = calc.groups

    read_only = I18n.t('csv.read_only_field', '(read only)')
    include_root_account = @course.root_account.trust_exists?
    should_show_totals = show_totals?
    include_sis_id = @options[:include_sis_id]
    CSV.generate do |csv|
      # First row
      row = ["Student", "ID"]
      row << "SIS User ID" if include_sis_id
      row << "SIS Login ID"
      row << "Root Account" if include_sis_id && include_root_account
      row << "Section"
      row.concat assignments.map(&:title_with_id)
      include_points = !@course.apply_group_weights?

      if should_show_totals
        groups.each do |group|
          if include_points
            row << "#{group.name} Current Points" << "#{group.name} Final Points"
          end
          row << "#{group.name} Current Score" << "#{group.name} Final Score"
        end
        row << "Current Points" << "Final Points" if include_points
        row << "Current Score" << "Final Score"
        if @course.grading_standard_enabled?
          row << "Current Grade" << "Final Grade"
        end
      end
      csv << row

      group_filler_length = groups.size * (include_points ? 4 : 2)

      # Possible muted row
      if assignments.any?(&:muted)
        # This is is not translated since we look for this exact string when we upload to gradebook.
        row = [nil, nil, nil, nil]
        row << nil if include_sis_id
        row.concat(assignments.map { |a| 'Muted' if a.muted? })

        if should_show_totals
          row.concat([nil] * group_filler_length)
          row << nil << nil if include_points
          row << nil << nil
        end

        row << nil if @course.grading_standard_enabled?
        csv << row
      end

      # Second Row
      row = ["    Points Possible", nil, nil, nil]
      if include_sis_id
        row << nil
        row << nil if include_root_account
      end
      row.concat assignments.map(&:points_possible)

      if should_show_totals
        row.concat([read_only] * group_filler_length)
        row << read_only << read_only if include_points
        row << read_only << read_only
        row << read_only if @course.grading_standard_enabled?
      end
      csv << row

      student_enrollments.each_slice(100) do |student_enrollments_batch|

        visible_assignments = AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(
          user_id: student_enrollments_batch.map(&:user_id),
          course_id: @course.id
        )

        student_enrollments_batch.each do |student_enrollment|
          student = student_enrollment.user
          student_sections = student_section_names[student.id].sort.to_sentence
          student_submissions = assignments.map do |a|
            if visible_assignments[student.id] && !visible_assignments[student.id].include?(a.id)
              "N/A"
            else
              submission = submissions[[student.id, a.id]]
              if submission.try(:excused?)
                "EX"
              elsif a.grading_type == "gpa_scale" && submission.try(:score)
                a.score_to_grade(submission.score)
              else
                submission.try(:score)
              end
            end
          end
          row = [student_name(student), student.id]
          pseudonym = SisPseudonym.for(student, @course, include_root_account)
          row << pseudonym.try(:sis_user_id) if include_sis_id
          pseudonym ||= student.find_pseudonym_for_account(@course.root_account, include_root_account)
          row << pseudonym.try(:unique_id)
          row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_sis_id && include_root_account
          row << student_sections
          row.concat(student_submissions)

          if should_show_totals
            row += show_totals(grades.shift, groups, include_points)
          end

          csv << row
        end
      end
    end
  end

  private

  def enrollments_for_csv(scope)
    # user: used for name in csv output
    # course_section: used for display_name in csv output
    # user > pseudonyms: used for sis_user_id/unique_id if options[:include_sis_id]
    # user > pseudonyms > account: used in find_pseudonym_for_account > works_for_account
    includes = {:user => {:pseudonyms => :account}, :course_section => []}

    enrollments = scope.preload(includes).eager_load(:user).order_by_sortable_name.to_a
    enrollments.partition { |e| e.type != "StudentViewEnrollment" }.flatten
  end

  def show_totals(grade, groups, include_points)
    result = []

    groups.each do |group|
      if include_points
        result << grade[:current_groups][group.id][:score]
        result << grade[:final_groups][group.id][:score]
      end

      result << grade[:current_groups][group.id][:grade]
      result << grade[:final_groups][group.id][:grade]
    end

    if include_points
      result << grade[:current][:total]
      result << grade[:final][:total]
    end

    result << grade[:current][:grade]
    result << grade[:final][:grade]

    if @course.grading_standard_enabled?
      result << @course.score_to_grade(grade[:current][:grade])
      result << @course.score_to_grade(grade[:final][:grade])
    end
    result
  end

  def show_totals?
    return true unless @course.grading_periods?
    return true if @options[:grading_period_id].try(:to_i) != 0

    @course.display_totals_for_all_grading_periods?
  end

  STARTS_WITH_EQUAL = /^\s*=/

  # Returns the student name to use for the export.  If the name
  # starts with =, quote it so anyone pulling the data into Excel
  # doesn't have a formula execute.
  def student_name(student)
    name = @course.list_students_by_sortable_name? ? student.sortable_name : student.name
    name = "=\"#{name}\"" if name =~ STARTS_WITH_EQUAL
    name
  end

  def select_in_grading_period(assignments, grading_period)
    if grading_period
      grading_period.assignments(assignments)
    else
      assignments
    end
  end
end
