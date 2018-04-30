#
# Copyright (C) 2015 - present Instructure, Inc.
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
  include LocaleSelection

  # You may see a pattern in this file of things that look like `<< nil << nil`
  # to create 'buffer' cells for columns. Let's try to stop using that pattern
  # and instead define the number of 'buffer' columns here in the COLUMN_COUNTS hash.
  # Please leave a comment for each entry in COLUMN_COUNTS.
  COLUMN_COUNTS = {
    grading_standard: 4 # 'Current Grade', 'Final Grade', 'Unposted Current Grade', 'Unposted Final Grade'
  }.freeze

  def initialize(course, user, options = {})
    @course  = course
    @user    = user
    @options = options
  end

  def to_csv
    I18n.locale = @options[:locale] || infer_locale(
      context:      @course,
      user:         @user,
      root_account: @course.root_account
    )

    @options[:col_sep] ||= determine_column_separator
    @options[:encoding] ||= I18n.t('csv.encoding', 'UTF-8')

    # Wikipedia: Microsoft compilers and interpreters, and many pieces of software on Microsoft Windows such as
    # Notepad treat the BOM as a required magic number rather than use heuristics. These tools add a BOM when saving
    # text as UTF-8, and cannot interpret UTF-8 unless the BOM is present or the file contains only ASCII.
    # https://en.wikipedia.org/wiki/Byte_order_mark#UTF-8
    bom = include_bom?(@options[:encoding]) ? "\xEF\xBB\xBF" : ''
    csv_data.prepend(bom)
  end

  private

  def include_bom?(encoding)
    encoding == 'UTF-8' && @user.feature_enabled?(:include_byte_order_mark_in_gradebook_exports)
  end

  def buffer_columns(column_name, buffer_value=nil)
    column_count = COLUMN_COUNTS.fetch(column_name)
    Array.new(column_count, buffer_value)
  end

  def determine_column_separator
    return ';' if @user.feature_enabled?(:use_semi_colon_field_separators_in_gradebook_exports)
    return ',' unless @user.feature_enabled?(:autodetect_field_separators_for_gradebook_exports)

    I18n.t('number.format.separator', '.') == ',' ? ';' : ','
  end

  def csv_data
    enrollment_scope = @course.apply_enrollment_visibility(gradebook_enrollment_scope, @user, nil,
                                                           include: gradebook_includes).preload(:root_account, :sis_pseudonym)
    student_enrollments = enrollments_for_csv(enrollment_scope)

    student_section_names = {}
    student_enrollments.each do |enrollment|
      student_section_names[enrollment.user_id] ||= []
      student_section_names[enrollment.user_id] << (enrollment.course_section.display_name rescue nil)
    end

    # remove duplicate enrollments for students enrolled in multiple sections
    student_enrollments = student_enrollments.uniq(&:user_id)

    # TODO: Stop using the grade calculator and instead use the scores table entirely.
    # This cannot be done until we are storing points values in the scores table, which
    # will be implemented as part of GRADE-8.
    calc = GradeCalculator.new(student_enrollments.map(&:user_id), @course,
                               ignore_muted: false,
                               grading_period: grading_period)
    grades = calc.compute_scores

    submissions = {}
    calc.submissions.each { |s| submissions[[s.user_id, s.assignment_id]] = s }

    assignments = select_in_grading_period calc.assignments

    assignments = assignments.sort_by do |a|
      [a.assignment_group_id, a.position || 0, a.due_at || CanvasSort::Last, a.title]
    end
    groups = calc.groups

    read_only = I18n.t('csv.read_only_field', '(read only)')
    include_root_account = @course.root_account.trust_exists?
    should_show_totals = show_totals?
    include_sis_id = @options[:include_sis_id]

    CSV.generate(@options.slice(:encoding, :col_sep)) do |csv|
      # First row
      row = ["Student", "ID"]
      row << "SIS User ID" if include_sis_id
      row << "SIS Login ID"
      row << "Root Account" if include_sis_id && include_root_account
      row << "Section"
      row.concat assignments.map(&:title_with_id)

      if should_show_totals
        groups.each do |group|
          if include_points?
            row << "#{group.name} Current Points" << "#{group.name} Final Points"
          end
          row << "#{group.name} Current Score"
          row << "#{group.name} Unposted Current Score"
          row << "#{group.name} Final Score"
          row << "#{group.name} Unposted Final Score"
        end
        row << "Current Points" << "Final Points" if include_points?
        row << "Current Score" << "Unposted Current Score" << "Final Score" << "Unposted Final Score"
        if @course.grading_standard_enabled?
          row << "Current Grade" << "Unposted Current Grade" << "Final Grade" << "Unposted Final Grade"
        end
      end
      csv << row

      group_filler_length = groups.size * column_count_per_group

      # Possible muted row
      if assignments.any?(&:muted)
        # This is is not translated since we look for this exact string when we upload to gradebook.
        row = [nil, nil, nil, nil]
        if include_sis_id
          row << nil
          row << nil if include_root_account
        end

        row.concat(assignments.map { |a| 'Muted' if a.muted? })

        if should_show_totals
          row.concat([nil] * group_filler_length)
          row << nil << nil if include_points?
          row << nil << nil << nil << nil
        end

        row.concat(buffer_columns(:grading_standard)) if @course.grading_standard_enabled?
        csv << row
      end

      # Second Row
      row = ["    Points Possible", nil, nil, nil]
      if include_sis_id
        row << nil
        row << nil if include_root_account
      end
      row.concat(assignments.map{ |a| I18n.n(a.points_possible) })

      if should_show_totals
        row.concat([read_only] * group_filler_length)
        row << read_only << read_only if include_points?
        row << read_only << read_only << read_only << read_only
        row.concat(buffer_columns(:grading_standard, read_only)) if @course.grading_standard_enabled?
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
                I18n.n(submission.try(:score))
              end
            end
          end
          row = [student_name(student), student.id]
          pseudonym = SisPseudonym.for(student, student_enrollment, type: :implicit, require_sis: false)
          row << pseudonym.try(:sis_user_id) if include_sis_id
          row << pseudonym.try(:unique_id)
          row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_sis_id && include_root_account
          row << student_sections
          row.concat(student_submissions)

          if should_show_totals
            student_grades = grades.shift

            row += show_group_totals(student_enrollment, student_grades, groups)
            row += show_overall_totals(student_enrollment, student_grades)
          end

          csv << row
        end
      end
    end
  end

  def enrollments_for_csv(scope)
    # user: used for name in csv output
    # course_section: used for display_name in csv output
    # user > pseudonyms: used for sis_user_id/unique_id if options[:include_sis_id]
    # user > pseudonyms > account: used in SisPseudonym > works_for_account
    includes = {:user => {:pseudonyms => :account}, :course_section => [], :scores => []}

    enrollments = scope.preload(includes).eager_load(:user).order_by_sortable_name.to_a
    enrollments.partition { |e| e.type != "StudentViewEnrollment" }.flatten
  end

  def format_numbers(number)
    I18n.n(number)
  end

  def show_group_totals(student_enrollment, grade, groups)
    result = []

    groups.each do |group|
      if include_points?
        result << format_numbers(grade[:current_groups][group.id][:score])
        result << format_numbers(grade[:final_groups][group.id][:score])
      end

      result << format_numbers(student_enrollment.computed_current_score(assignment_group_id: group.id))
      result << format_numbers(student_enrollment.unposted_current_score(assignment_group_id: group.id))
      result << format_numbers(student_enrollment.computed_final_score(assignment_group_id: group.id))
      result << format_numbers(student_enrollment.unposted_final_score(assignment_group_id: group.id))
    end

    result
  end

  def show_overall_totals(student_enrollment, grade)
    result = []

    if include_points?
      result << format_numbers(grade[:current][:total])
      result << format_numbers(grade[:final][:total])
    end

    score_opts = grading_period ? { grading_period_id: grading_period.id } : Score.params_for_course
    result << format_numbers(student_enrollment.computed_current_score(score_opts))
    result << format_numbers(student_enrollment.unposted_current_score(score_opts))
    result << format_numbers(student_enrollment.computed_final_score(score_opts))
    result << format_numbers(student_enrollment.unposted_final_score(score_opts))

    if @course.grading_standard_enabled?
      result << student_enrollment.computed_current_grade(score_opts)
      result << student_enrollment.unposted_current_grade(score_opts)
      result << student_enrollment.computed_final_grade(score_opts)
      result << student_enrollment.unposted_final_grade(score_opts)
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

  def grading_period
    return @grading_period if defined? @grading_period

    @grading_period = nil
    # grading_period_id == 0 means no grading period selected
    if @options[:grading_period_id].to_i != 0
      @grading_period = GradingPeriod.for(@course).find_by(id: @options[:grading_period_id])
    end
  end

  def select_in_grading_period(assignments)
    if grading_period
      grading_period.assignments(assignments)
    else
      assignments
    end
  end

  def include_points?
    !@course.apply_group_weights?
  end

  def column_count_per_group
    include_points? ? 6 : 4
  end
  private :column_count_per_group
end
