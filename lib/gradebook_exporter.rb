# frozen_string_literal: true

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
  # and instead define the 'buffer' columns here in the BUFFER_COLUMN_DEFINITIONS
  # hash. Use the buffer_columns and buffer_column_headers methods to populate the
  # relevant rows.
  BUFFER_COLUMN_DEFINITIONS = {
    grading_standard: ['Current Grade', 'Unposted Current Grade', 'Final Grade', 'Unposted Final Grade'].freeze,
    override_score: ['Override Score'].freeze,
    override_grade: ['Override Grade'].freeze,
    points: ['Current Points', 'Final Points'].freeze,
    total_scores: ['Current Score', 'Unposted Current Score', 'Final Score', 'Unposted Final Score'].freeze
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

    @options = CsvWithI18n.csv_i18n_settings(@user, @options)
    csv_data
  end

  private

  def buffer_column_headers(column_name, assignment_group: nil)
    # Possible output formats:
    #  Current Score [no assignment group and no grading period]
    #  Assignment Group 1 Current Score [assignment group, no grading period]
    #  Current Score (Fall 2020) [grading period, no assignment group]
    #  Assignment Group 1 Current Score (Fall 2020) [both assignment group and grading period]
    BUFFER_COLUMN_DEFINITIONS.fetch(column_name).map do |column|
      name_tokens = [column]
      name_tokens.prepend(assignment_group.name) if assignment_group.present?
      name_tokens.append("(#{grading_period.title})") if grading_period.present?

      name_tokens.join(" ")
    end
  end

  def buffer_columns(column_name, buffer_value=nil)
    column_count = BUFFER_COLUMN_DEFINITIONS.fetch(column_name).length
    Array.new(column_count, buffer_value)
  end

  def csv_data
    enrollment_scope = @course.apply_enrollment_visibility(
      gradebook_enrollment_scope(user: @user, course: @course),
      @user,
      nil,
      include: gradebook_includes(user: @user, course: @course)
    ).preload(:root_account, :sis_pseudonym)
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
    calc = GradeCalculator.new(
      student_enrollments.map(&:user_id),
      @course,
      ignore_muted: false,
      grading_period: grading_period
    )
    grades = calc.compute_scores

    submissions = {}
    calc.submissions.each { |s| submissions[[s.user_id, s.assignment_id]] = s }

    assignments = select_in_grading_period calc.gradable_assignments
    Assignment.preload_unposted_anonymous_submissions(assignments)

    ActiveRecord::Associations::Preloader.new.preload(assignments, :assignment_group)
    assignments = sort_assignments(assignments)

    groups = calc.groups

    read_only = I18n.t('csv.read_only_field', '(read only)')
    include_root_account = @course.root_account.trust_exists?
    should_show_totals = show_totals?
    include_sis_id = @options[:include_sis_id]

    CsvWithI18n.generate(**@options.slice(:encoding, :col_sep, :include_bom)) do |csv|
      # First row
      header = ["Student", "ID"]
      header << "SIS User ID" if include_sis_id
      header << "SIS Login ID"
      header << "Integration ID" if include_sis_id && show_integration_id?
      header << "Root Account" if include_sis_id && include_root_account
      header << "Section"

      custom_gradebook_columns.each do |column|
        header << column.title
      end

      header.concat assignments.map(&:title_with_id)

      if should_show_totals
        groups.each do |group|
          header.concat(buffer_column_headers(:points, assignment_group: group)) if include_points?
          header.concat(buffer_column_headers(:total_scores, assignment_group: group))
        end

        header.concat(buffer_column_headers(:points)) if include_points?
        header.concat(buffer_column_headers(:total_scores))
        header.concat(buffer_column_headers(:grading_standard)) if @course.grading_standard_enabled?

        if include_final_grade_override?
          header.concat(buffer_column_headers(:override_score))
          header.concat(buffer_column_headers(:override_grade)) if @course.grading_standard_enabled?
        end
      end
      csv << header

      group_filler_length = groups.size * column_count_per_group

      # Possible "hidden" (muted or manual posting) row
      if assignments.any? { |assignment| show_as_hidden?(assignment) }
        row = [nil, nil, nil, nil]
        if include_sis_id
          row << nil
          row << nil if show_integration_id?
          row << nil if include_root_account
        end

        # Custom Columns
        custom_gradebook_columns.count.times do
          row << nil
        end

        hidden_assignments_text = assignments.map { |assignment| hidden_assignment_text(assignment) }
        row.concat(hidden_assignments_text)

        if should_show_totals
          row.concat([nil] * group_filler_length)
          row.concat(buffer_columns(:points)) if include_points?
          row.concat(buffer_columns(:total_scores))
        end

        row.concat(buffer_columns(:grading_standard)) if @course.grading_standard_enabled?
        if include_final_grade_override?
          row.concat(buffer_columns(:override_score))
          row.concat(buffer_columns(:override_grade)) if @course.grading_standard_enabled?
        end

        lengths_match = header.length == row.length
        raise "column lengths don't match" if !lengths_match && !Rails.env.production?
        csv << row
      end

      # Second Row
      row = ["    Points Possible", nil, nil, nil]
      if include_sis_id
        row << nil
        row << nil if show_integration_id?
        row << nil if include_root_account
      end

      # Custom Columns
      custom_gradebook_columns.each do |column|
        row << (column.read_only? ? read_only : nil)
      end

      row.concat(assignments.map{ |a| format_numbers(a.points_possible) })

      if should_show_totals
        row.concat([read_only] * group_filler_length)
        row << read_only << read_only if include_points?
        row << read_only << read_only << read_only << read_only
        row.concat(buffer_columns(:grading_standard, read_only)) if @course.grading_standard_enabled?
        if include_final_grade_override?
          allow_importing = Account.site_admin.feature_enabled?(:import_override_scores_in_gradebook)
          # Override Score is not read-only if the user can import changes
          row.concat(buffer_columns(:override_score, allow_importing ? nil : read_only))

          # Override Grade is always read-only
          row.concat(buffer_columns(:override_grade, read_only)) if @course.grading_standard_enabled?
        end
      end

      csv << row

      lengths_match = header.length == row.length
      raise "column lengths don't match" if !lengths_match && !Rails.env.production?

      # Rest of the Rows
      student_enrollments.each_slice(100) do |student_enrollments_batch|

        student_ids = student_enrollments_batch.map(&:user_id)

        visible_assignments = @course.submissions.
          active.
          where(user_id: student_ids.uniq).
          pluck(:assignment_id, :user_id).
          each_with_object(Hash.new {|hash, key| hash[key] = Set.new}) do |ids, reducer|
            assignment_key = ids.first
            student_key = ids.second
            reducer[assignment_key].add(student_key)
          end

        # Custom Columns, custom_column_data are hashes
        custom_column_data = CustomGradebookColumnDatum.where(
          custom_gradebook_column: custom_gradebook_columns,
          user_id: student_ids
        ).group_by(&:user_id)

        student_enrollments_batch.each do |student_enrollment|
          student = student_enrollment.user
          student_sections = student_section_names[student.id].sort.to_sentence
          student_submissions = assignments.map do |a|
            if visible_assignments[a.id].include?(student.id) && !a.unposted_anonymous_submissions?
              submission = submissions[[student.id, a.id]]
              if submission.try(:excused?)
                "EX"
              elsif a.grading_type == "gpa_scale" && submission.try(:score)
                a.score_to_grade(submission.score)
              else
                format_numbers(submission.try(:score))
              end
            else
              "N/A"
            end
          end
          row = [student_name(student), student.id]
          pseudonym = SisPseudonym.for(student, student_enrollment, type: :implicit, require_sis: false, root_account: @course.root_account)
          row << pseudonym&.sis_user_id if include_sis_id
          row << pseudonym&.unique_id
          row << pseudonym&.integration_id if include_sis_id && show_integration_id?
          row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_sis_id && include_root_account
          row << student_sections

          # Custom Columns Data
          custom_gradebook_columns.each do |column|
            row << custom_column_data[student.id]&.find {|datum| column.id == datum.custom_gradebook_column_id}&.content
          end

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

  def sort_assignments(assignments)
    feature_enabled = Account.site_admin.feature_enabled?(:gradebook_csv_export_order_matches_gradebook_grid)
    column_order_preferences = @user.get_preference(:gradebook_column_order, @course.global_id)&.fetch(:customOrder, {})

    unless feature_enabled && column_order_preferences.present?

      assignments.sort_by! do |a|
        [a.assignment_group.position, a.position || 0, a.due_at || CanvasSort::Last, a.title]
      end
      return assignments
    end

    preference_indices = {}
    column_order_preferences.each_with_index do |preference, idx|
      # skip assignment groups and totals
      next unless preference =~ /assignment_\d+$/

      assignment_id = preference.split('_')[-1].to_i
      preference_indices[assignment_id] = idx
    end

    # put assignments in their preferred idx
    # preferences that correspond to deleted assignments will
    # leave 'nil' in the corresponding slot of assignments_by_custom_order,
    # so we compact at the end
    assignments_by_custom_order = Array.new(column_order_preferences.length)
    assignments_missing_preference = []
    assignments.each do |assignment|
      idx = preference_indices[assignment.id]
      if idx
        assignments_by_custom_order[idx] = assignment
      else
        # the assignment didn't have a preference listed
        assignments_missing_preference << assignment
      end
    end
    assignments_missing_preference.sort_by!(&:created_at)
    assignments_by_custom_order.compact.concat(assignments_missing_preference)
  end

  def show_integration_id?
    @show_integration_id ||= @course.root_account.settings[:include_integration_ids_in_gradebook_exports] == true
  end

  def enrollments_for_csv(scope)
    # user: used for name in csv output
    # course_section: used for display_name in csv output
    # user > pseudonyms: used for sis_user_id/unique_id if options[:include_sis_id]
    # user > pseudonyms > account: used in SisPseudonym > works_for_account
    includes = {:user => {:pseudonyms => :account}, :course_section => [], :scores => []}

    enrollments = scope.preload(includes).eager_load(:user).order_by_sortable_name.to_a
    enrollments.each { |e| e.course = @course }
    enrollments.partition { |e| e.type != "StudentViewEnrollment" }.flatten
  end

  def format_numbers(number)
    # Always pass a precision value so that I18n.n doesn't try to add thousands
    # separators. 2 is the maximum number of digits we display in the front end.
    I18n.n(number, precision: 2)
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

    if include_final_grade_override?
      result << student_enrollment.override_score(score_opts)
      result << student_enrollment.override_grade(score_opts) if @course.grading_standard_enabled?
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
    name = student.sortable_name
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

  def custom_gradebook_columns
    @custom_gradebook_columns ||= @course.custom_gradebook_columns.active.to_a
  end

  def select_in_grading_period(assignments)
    if grading_period
      grading_period.assignments(@course, assignments)
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

  def include_final_grade_override?
    @course.allow_final_grade_override?
  end

  def show_as_hidden?(assignment)
    assignment.post_manually?
  end

  def hidden_assignment_text(assignment)
    return nil unless show_as_hidden?(assignment)

    # We don't translate "Manual Posting" since we look for this exact string when we upload to gradebook.
    if assignment.unposted_anonymous_submissions?
      I18n.t("%{manual_posting} (scores hidden from instructors)", { manual_posting: "Manual Posting" })
    else
      "Manual Posting"
    end
  end
end
