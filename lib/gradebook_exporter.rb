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
    grading_standard: ["Current Grade", "Unposted Current Grade", "Final Grade", "Unposted Final Grade"].freeze,
    override_score: ["Override Score"].freeze,
    override_grade: ["Override Grade"].freeze,
    override_status: ["Override Status"].freeze,
    points: ["Current Points", "Final Points"].freeze,
    total_scores: ["Current Score", "Unposted Current Score", "Final Score", "Unposted Final Score"].freeze
  }.freeze

  def initialize(course, user, options = {})
    @course  = course
    @user    = user
    @options = options
  end

  def to_csv
    I18n.with_locale(@options[:locale] || infer_locale(
      context: @course,
      user: @user,
      root_account: @course.root_account
    )) do
      @options = CSVWithI18n.csv_i18n_settings(@user, @options)
      csv_data
    end
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

  def update_completion(completion)
    progress = @options[:progress]
    progress&.update_completion!(completion)
  end

  def buffer_columns(column_name, buffer_value = nil)
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
    update_completion(10)

    student_section_names = {}
    student_enrollments.each do |enrollment|
      student_section_names[enrollment.user_id] ||= []
      student_section_names[enrollment.user_id] << (enrollment.course_section.display_name rescue nil)
    end

    # remove duplicate enrollments for students enrolled in multiple sections
    student_enrollments = if @options[:current_view]
                            student_order = @options[:student_order].map(&:to_i)
                            student_enrollments.select { |s| student_order.include?(s[:user_id]) }.uniq(&:user_id)
                          else
                            student_enrollments.uniq(&:user_id)
                          end

    # TODO: Stop using the grade calculator and instead use the scores table entirely.
    # This cannot be done until we are storing points values in the scores table, which
    # will be implemented as part of GRADE-8.
    calc = GradeCalculator.new(
      student_enrollments.map(&:user_id),
      @course,
      ignore_muted: false,
      grading_period:
    )

    submissions = {}
    calc.submissions.each { |s| submissions[[s.user_id, s.assignment_id]] = s }
    assignments = if @options[:current_view]
                    calc.gradable_assignments.select { |a| @options[:assignment_order].include?(a[:id]) }
                  else
                    calc.gradable_assignments
                  end

    update_completion(20)
    Assignment.preload_unposted_anonymous_submissions(assignments)

    ActiveRecord::Associations.preload(assignments, :assignment_group)
    assignments = sort_assignments(assignments)

    groups = calc.groups

    read_only = I18n.t("csv.read_only_field", "(read only)")
    include_root_account = @course.root_account.trust_exists?
    should_show_totals = show_totals?
    include_sis_id = @options[:include_sis_id]

    update_completion(30)
    CSVWithI18n.generate(**@options.slice(:encoding, :col_sep, :include_bom)) do |csv|
      # First row
      header = @options[:show_student_first_last_name] ? ["LastName", "FirstName"] : ["Student"]
      header << "ID"
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
          header.concat(buffer_column_headers(:override_status)) if custom_statuses_enabled?
        end
      end
      csv << header

      group_filler_length = groups.size * column_count_per_group

      update_completion(50)
      # Possible "hidden" (muted or manual posting) row
      if assignments.any? { |assignment| show_as_hidden?(assignment) }
        row = [nil, nil, nil, nil]
        row << nil if @options[:show_student_first_last_name]
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

          row.concat(buffer_columns(:grading_standard)) if @course.grading_standard_enabled?
          if include_final_grade_override?
            row.concat(buffer_columns(:override_score))
            row.concat(buffer_columns(:override_grade)) if @course.grading_standard_enabled?
            row.concat(buffer_columns(:override_status)) if custom_statuses_enabled?
          end
        end

        lengths_match = header.length == row.length
        raise "column lengths don't match" if !lengths_match && !Rails.env.production?

        csv << row
      end

      # Second Row
      row = ["    Points Possible", nil, nil, nil]
      row << nil if @options[:show_student_first_last_name]
      if include_sis_id
        row << nil
        row << nil if show_integration_id?
        row << nil if include_root_account
      end

      # Custom Columns
      custom_gradebook_columns.each do |column|
        row << (column.read_only? ? read_only : nil)
      end

      row.concat(assignments.map { |a| format_numbers(a.points_possible) })

      if should_show_totals
        row.concat([read_only] * group_filler_length)
        row << read_only << read_only if include_points?
        row << read_only << read_only << read_only << read_only
        row.concat(buffer_columns(:grading_standard, read_only)) if @course.grading_standard_enabled?
        if include_final_grade_override?
          row.concat(buffer_columns(:override_score))

          # Override Grade is always read-only
          row.concat(buffer_columns(:override_grade, read_only)) if @course.grading_standard_enabled?
          row.concat(buffer_columns(:override_status)) if custom_statuses_enabled?
        end
      end

      csv << row

      lengths_match = header.length == row.length
      raise "column lengths don't match" if !lengths_match && !Rails.env.production?

      total_batches = (student_enrollments.length / 100.0).ceil
      batch_completion_increase = 40.0 / total_batches
      current_completion = 50

      # Rest of the Rows
      student_enrollments.each_slice(100) do |student_enrollments_batch|
        progress = @options[:progress]
        progress&.reload
        return if progress&.failed?

        student_ids = student_enrollments_batch.map(&:user_id)

        visible_assignments = @course.submissions
                                     .active
                                     .where(user_id: student_ids.uniq)
                                     .pluck(:assignment_id, :user_id)
                                     .each_with_object(Hash.new { |hash, key| hash[key] = Set.new }) do |ids, reducer|
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
          row = if @options[:show_student_first_last_name]
                  [student_name(student.last_name), student_name(student.first_name)]
                else
                  [student_name(student.sortable_name)]
                end
          row << student.id
          pseudonym = SisPseudonym.for(student, student_enrollment, type: :implicit, require_sis: false, root_account: @course.root_account)
          row << pseudonym&.sis_user_id if include_sis_id
          row << pseudonym&.unique_id
          row << pseudonym&.integration_id if include_sis_id && show_integration_id?
          row << (pseudonym && HostUrl.context_host(pseudonym.account)) if include_sis_id && include_root_account
          row << student_sections

          # Custom Columns Data
          custom_gradebook_columns.each do |column|
            row << custom_column_data[student.id]&.find { |datum| column.id == datum.custom_gradebook_column_id }&.content
          end

          row.concat(student_submissions)

          if should_show_totals
            row += show_group_totals(student_enrollment, groups)
            row += show_overall_totals(student_enrollment)
          end

          csv << row
        end

        current_completion += batch_completion_increase
        update_completion(current_completion)
      end
    end
  end

  def sort_assignments(assignments)
    assignment_order = @options[:assignment_order]
    if assignment_order.present?
      id_to_index = assignment_order.each_with_object({}).with_index { |(id, hash), index| hash[id] = index }
      assignments.sort! do |a1, a2|
        index1 = id_to_index[a1.id]
        index2 = id_to_index[a2.id]

        if index1 == index2
          a1.id <=> a2.id
        elsif !index1 || !index2
          index1 ? -1 : 1
        else
          index1 <=> index2
        end
      end
    else
      assignments.sort_by! do |a|
        [a.assignment_group.position, a.position || 0, a.due_at || CanvasSort::Last, a.title]
      end
    end
  end

  def show_integration_id?
    @show_integration_id ||= @course.root_account.settings[:include_integration_ids_in_gradebook_exports] == true
  end

  def enrollments_for_csv(scope)
    # user: used for name in csv output
    # course_section: used for display_name in csv output
    # user > pseudonyms: used for sis_user_id/unique_id if options[:include_sis_id]
    # user > pseudonyms > account: used in SisPseudonym > works_for_account
    includes = { user: { pseudonyms: :account }, course_section: [], scores: [] }

    enrollments = scope.preload(includes).eager_load(:user).order_by_sortable_name.to_a
    enrollments.each { |e| e.course = @course }
    enrollments.partition { |e| e.type != "StudentViewEnrollment" }.flatten
  end

  def format_numbers(number)
    # Always pass a precision value so that I18n.n doesn't try to add thousands
    # separators. 2 is the maximum number of digits we display in the front end.
    I18n.n(number, precision: 2)
  end

  def show_group_totals(student_enrollment, groups)
    result = []

    groups.each do |group|
      if include_points?
        result << format_numbers(student_enrollment.computed_current_points(assignment_group_id: group.id))
        result << format_numbers(student_enrollment.computed_final_points(assignment_group_id: group.id))
      end

      result << format_numbers(student_enrollment.computed_current_score(assignment_group_id: group.id))
      result << format_numbers(student_enrollment.unposted_current_score(assignment_group_id: group.id))
      result << format_numbers(student_enrollment.computed_final_score(assignment_group_id: group.id))
      result << format_numbers(student_enrollment.unposted_final_score(assignment_group_id: group.id))
    end

    result
  end

  def show_overall_totals(student_enrollment)
    result = []
    score_opts = grading_period ? { grading_period_id: grading_period.id } : Score.params_for_course

    if include_points?
      result << format_numbers(student_enrollment.computed_current_points(score_opts))
      result << format_numbers(student_enrollment.computed_final_points(score_opts))
    end

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
      score = student_enrollment.find_score(score_opts)
      result << student_enrollment.override_score(score:)
      result << student_enrollment.override_grade(score:) if @course.grading_standard_enabled?
      result << custom_status(score) if custom_statuses_enabled?
    end

    result
  end

  def show_totals?
    # show totals if the course is not using grading periods
    return true unless @course.grading_periods?

    # show totals if we're exporting the gradebook for a specific grading period
    return true if filter_by_grading_period?

    # otherwise, show or hide totals based on the "Display Totals for All Grading
    # Periods" option.
    @course.display_totals_for_all_grading_periods?
  end

  STARTS_WITH_EQUAL = /^\s*=/

  # Returns the student name to use for the export.  If the name
  # starts with =, quote it so anyone pulling the data into Excel
  # doesn't have a formula execute.
  def student_name(name)
    name = "=\"#{name}\"" if name.match?(STARTS_WITH_EQUAL)
    name
  end

  def grading_period
    return @grading_period if defined? @grading_period

    @grading_period = nil
    # grading_period_id == 0 means no grading period selected
    if filter_by_grading_period?
      @grading_period = GradingPeriod.for(@course).find_by(id: @options[:grading_period_id])
    end
  end

  def filter_by_grading_period?
    gp_id = @options[:grading_period_id]
    @options[:current_view].present? && gp_id.present? && gp_id.to_i != 0
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

  def custom_status(score)
    score&.custom_grade_status_id && custom_statuses[score.custom_grade_status_id]
  end

  def custom_statuses
    @custom_statuses ||= @course.custom_grade_statuses.pluck(:id, :name).to_h
  end

  def custom_statuses_enabled?
    return @custom_statuses_enabled if defined?(@custom_statuses_enabled)

    @custom_statuses_enabled = Account.site_admin.feature_enabled?(:custom_gradebook_statuses)
  end
end
