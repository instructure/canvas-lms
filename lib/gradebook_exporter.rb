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
  include GradebookTransformer

  def initialize(course, options = {})
    @course  = course
    @options = options
  end

  def to_csv
    student_enrollments = enrollments_for_csv(enrollments_scope, @options)

    student_section_names = {}
    student_enrollments.each do |enrollment|
      student_section_names[enrollment.user_id] ||= []
      student_section_names[enrollment.user_id] << (enrollment.course_section.display_name rescue nil)
    end
    # remove duplicate enrollments for students enrolled in multiple sections
    student_enrollments = student_enrollments.uniq(&:user_id)

    calc = GradeCalculator.new(student_enrollments.map(&:user_id), @course, :ignore_muted => false)
    grades = calc.compute_scores

    submissions = {}
    calc.submissions.each { |s| submissions[[s.user_id, s.assignment_id]] = s }

    assignments = select_in_current_grading_periods calc.assignments, @course

    assignments = assignments.sort_by do |a|
      [a.assignment_group_id, a.position, a.due_at || CanvasSort::Last, a.title]
    end
    groups = calc.groups

    read_only = I18n.t('csv.read_only_field', '(read only)')
    include_root_account = @course.root_account.trust_exists?
    CSV.generate do |csv|
      # First row
      row = ["Student", "ID"]
      if @options[:include_sis_id]
        row << "SIS User ID" << "SIS Login ID"
        row << "Root Account" if include_root_account
      end
      row << "Section"
      row.concat assignments.map(&:title_with_id)
      include_points = !@course.apply_group_weights?
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
      csv << row

      group_filler_length = groups.size * (include_points ? 4 : 2)

      # Possible muted row
      if assignments.any?(&:muted)
        # This is is not translated since we look for this exact string when we upload to gradebook.
        row = [nil, nil, nil]
        row << nil << nil if @options[:include_sis_id]
        row.concat(assignments.map { |a| 'Muted' if a.muted? })
        row.concat([nil] * group_filler_length)
        row << nil << nil if include_points
        row << nil << nil
        row << nil if @course.grading_standard_enabled?
        csv << row
      end

      # Second Row
      row = ["    Points Possible", nil, nil]
      row << nil << nil if @options[:include_sis_id]
      row << nil if @options[:include_sis_id] && include_root_account
      row.concat assignments.map(&:points_possible)
      row.concat([read_only] * group_filler_length)
      row << read_only << read_only if include_points
      row << read_only << read_only
      row << read_only if @course.grading_standard_enabled?
      csv << row

      student_enrollments.each_slice(100) do |student_enrollments_batch|

        da_enabled = @course.feature_enabled?(:differentiated_assignments)
        if da_enabled
          visible_assignments = AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(
            user_id: student_enrollments_batch.map(&:user_id),
            course_id: @course.id
          )
        end

        student_enrollments_batch.each do |student_enrollment|
          student = student_enrollment.user
          student_sections = student_section_names[student.id].sort.to_sentence
          student_submissions = assignments.map do |a|
            if da_enabled && visible_assignments[student.id] && !visible_assignments[student.id].include?(a.id)
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
          row = [student.send(name_method), student.id]
          if @options[:include_sis_id]
            pseudonym = SisPseudonym.for(student, @course, include_root_account)
            row << pseudonym.try(:sis_user_id)
            pseudonym ||= student.find_pseudonym_for_account(@course.root_account, include_root_account)
            row << pseudonym.try(:unique_id)
            row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_root_account
          end

          row << student_sections
          row.concat(student_submissions)

          (current_info, current_group_info),
            (final_info, final_group_info) = grades.shift
          groups.each do |g|
            row << current_group_info[g.id][:score] << final_group_info[g.id][:score] if include_points
            row << current_group_info[g.id][:grade] << final_group_info[g.id][:grade]
          end
          row << current_info[:total] << final_info[:total] if include_points
          row << current_info[:grade] << final_info[:grade]
          if @course.grading_standard_enabled?
            row << @course.score_to_grade(current_info[:grade])
            row << @course.score_to_grade(final_info[:grade])
          end
          csv << row
        end
      end
    end
  end

  private
  def enrollments_for_csv(scope, options={})
    # user: used for name in csv output
    # course_section: used for display_name in csv output
    # user > pseudonyms: used for sis_user_id/unique_id if options[:include_sis_id]
    # user > pseudonyms > account: used in find_pseudonym_for_account > works_for_account
    includes = [:user, :course_section]
    includes = {:user => {:pseudonyms => :account}, :course_section => []} if options[:include_sis_id]

    enrollments = scope.includes(includes).order_by_sortable_name.to_a
    enrollments.partition { |e| e.type != "StudentViewEnrollment" }.flatten
  end

  def enrollments_scope
    if @options[:user]
      enrollment_opts = @options.slice(:include_priors)
      @course.enrollments_visible_to(@options[:user], enrollment_opts)
    elsif @options[:include_priors]
      @course.all_student_enrollments
    else
      @course.student_enrollments
    end
  end

  def name_method
    @course.list_students_by_sortable_name? ? :sortable_name : :name
  end
end
