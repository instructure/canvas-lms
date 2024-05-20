# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module AccountReports
  class GradeReports
    include ReportHelper

    def initialize(account_report, runner = nil)
      @account_report = account_report
      @include_deleted = value_to_boolean(account_report.parameters&.dig("include_deleted"))

      # we do not want to add extra_text more than one time.
      unless runner
        extra_text_term(@account_report)
        include_deleted_objects

        if @account_report.value_for_param("limiting_period")
          add_extra_text(I18n.t("account_reports.grades.limited",
                                "deleted objects limited by days specified;"))
        end
      end
    end

    # retrieve the list of courses for the account
    # get a list of all students for the course
    # get the current grade and final grade for the student in that course
    # each row should include:
    # - student name
    # - student id
    # - student sis id
    # - course name
    # - course id
    # - course sis id
    # - section name
    # - section id
    # - section sis id
    # - term name
    # - term id
    # - term sis id
    # - student current score
    # - student final score
    # - enrollment status
    def grade_export
      headers = []
      headers << "student name"
      headers << "student id"
      headers << "student sis"
      headers << "student integration id" if include_integration_id?
      headers << "course"
      headers << "course id"
      headers << "course sis"
      headers << "section"
      headers << "section id"
      headers << "section sis"
      headers << "term"
      headers << "term id"
      headers << "term sis"

      headers.concat(grading_field_headers)

      courses = root_account.all_courses
      courses = courses.where(enrollment_term_id: term) if term
      courses = add_course_sub_account_scope(courses)
      courses = courses.active unless @include_deleted
      total = courses.count
      courses.find_ids_in_batches(batch_size: 10_000) { |batch| create_report_runners(batch, total) } unless total == 0

      write_report_in_batches(headers)
    end

    def grade_export_runner(runner)
      students = student_grade_scope.where(course_id: runner.batch_items)

      students.preload(:root_account, :sis_pseudonym).find_in_batches do |student_chunk|
        users = student_chunk.filter_map { |e| User.new(id: e.user_id) }
        users.uniq!
        users_by_id = users.index_by(&:id)
        courses_by_id = Course.where(id: student_chunk.map(&:course_id)).preload(:grading_standard).index_by(&:id)

        pseudonyms = preload_logins_for_users(users, include_deleted: @include_deleted)
        student_chunk.each_with_index do |student, i|
          p = loaded_pseudonym(pseudonyms,
                               users_by_id[student.user_id],
                               include_deleted: @include_deleted,
                               enrollment: student)
          next unless p

          course = courses_by_id[student["course_id"]]
          arr = []
          arr << student["user_name"]
          arr << student["user_id"]
          arr << p.sis_user_id
          arr << p.integration_id if include_integration_id?
          arr << student["course_name"]
          arr << student["course_id"]
          arr << student["course_sis_id"]
          arr << student["section_name"]
          arr << student["course_section_id"]
          arr << student["section_sis_id"]
          arr << student["term_name"]
          arr << student["term_id"]
          arr << student["term_sis_id"]
          arr.concat(grading_field_values(student:, course:))
          add_report_row(row: arr, row_number: i, report_runner: runner)
        end
      end
    end

    def include_integration_id?
      @include_integration_id ||= root_account.settings[:include_integration_ids_in_gradebook_exports] == true
    end

    def mgp_grade_export
      terms = if @account_report.parameters[:enrollment_term_id].blank?
                root_account.enrollment_terms.active
              else
                root_account.enrollment_terms.where(id: @account_report.parameters[:enrollment_term_id])
              end

      courses = root_account.all_courses.order(:id)
      courses = courses.where(enrollment_term_id: terms)
      courses = add_course_sub_account_scope(courses)
      courses = courses.active unless @include_deleted
      total = courses.count

      term_reports = terms.each_with_object({}) do |term, reports|
        header = mgp_term_header(term)
        if header
          reports[term.name] = header
          courses.where(enrollment_term_id: term).find_ids_in_batches(batch_size: 10_000) { |batch| create_report_runners(batch, total) } unless total == 0
        else
          # for parallel reports we need to have at least runner to be able to finish the report
          @runner ||= @account_report.account_report_runners.create!
          reports[term.name] = [I18n.t("no grading periods configured for this term")]
        end
      end
      # if we made a runner for an empty term, we can mark it as completed.
      @runner&.complete
      write_report_in_batches([], files: term_reports)
    end

    def mgp_term_header(term)
      gp_set = term.grading_period_group
      return false unless gp_set

      headers = []
      headers << "student name"
      headers << "student id"
      headers << "student sis"
      headers << "student integration id" if include_integration_id?
      headers << "course"
      headers << "course id"
      headers << "course sis"
      headers << "section"
      headers << "section id"
      headers << "section sis"
      headers << "term"
      headers << "term id"
      headers << "term sis"
      headers << "grading period set"
      headers << "grading period set id"
      gp_set.grading_periods.active.order(:start_date).each do |gp|
        headers << "#{gp.title} grading period id"
        headers << "#{gp.title} current score"
        headers << "#{gp.title} final score"
        headers << "#{gp.title} unposted current score"
        headers << "#{gp.title} unposted final score"
        headers << "#{gp.title} override score" if include_override_score?
        headers << "#{gp.title} current grade"
        headers << "#{gp.title} final grade"
        headers << "#{gp.title} unposted current grade"
        headers << "#{gp.title} unposted final grade"
        headers << "#{gp.title} override grade" if include_override_score?
      end
      headers.concat(grading_field_headers)
    end

    def mgp_grade_export_runner(runner)
      term = root_account.enrollment_terms.where(id: root_account.all_courses.where(id: runner.batch_items.first).select(:enrollment_term_id)).take
      gp_set = term.grading_period_group
      grading_periods = gp_set.grading_periods.active.order(:start_date)
      return unless grading_periods

      students = student_grade_scope.where(course_id: runner.batch_items)
      courses_by_id = Course.where(id: runner.batch_items).preload(:grading_standard).index_by(&:id)
      students.where(course_id: runner.batch_items).preload(:root_account, :sis_pseudonym).find_in_batches do |student_chunk|
        users = student_chunk.filter_map { |e| User.new(id: e.user_id) }
        users.uniq!
        users_by_id = users.index_by(&:id)
        pseudonyms = preload_logins_for_users(users, include_deleted: @include_deleted)
        students_by_course = student_chunk.group_by(&:course_id)
        students_by_course.each_value do |course_students|
          scores = indexed_scores(course_students, grading_periods)
          course_students.each_with_index do |student, i|
            p = loaded_pseudonym(pseudonyms,
                                 users_by_id[student.user_id],
                                 include_deleted: @include_deleted,
                                 enrollment: student)
            next unless p

            course = courses_by_id[student["course_id"]]
            arr = []
            arr << student["user_name"]
            arr << student["user_id"]
            arr << p.sis_user_id
            arr << p.integration_id if include_integration_id?
            arr << student["course_name"]
            arr << student["course_id"]
            arr << student["course_sis_id"]
            arr << student["section_name"]
            arr << student["course_section_id"]
            arr << student["section_sis_id"]
            arr << student["term_name"]
            arr << student["term_id"]
            arr << student["term_sis_id"]
            arr << gp_set.title
            arr << gp_set.id

            grading_periods.each do |gp|
              scores_for_student = grading_period_scores_for_student(student, gp, scores)

              arr << gp.id
              arr.concat(grading_period_grading_field_values(scores_for_student:))
            end

            arr.concat(grading_field_values(student:, course:))
            add_report_row(row: arr, row_number: i, report_runner: runner, file: term.name)
          end
        end
      end
    end

    private

    def indexed_scores(students, grading_periods)
      Score.where(
        enrollment_id: students.map(&:enrollment_id),
        grading_period_id: grading_periods.map(&:id)
      ).active.select(
        :enrollment_id,
        :grading_period_id,
        :current_score,
        :final_score,
        :unposted_current_score,
        :unposted_final_score,
        :override_score
      ).index_by { |score| "#{score[:enrollment_id]}:#{score[:grading_period_id]}" }
    end

    def grading_period_scores_for_student(student, grading_period, scores)
      scores["#{student["enrollment_id"]}:#{grading_period.id}"] || {}
    end

    def student_grade_scope
      students = root_account.enrollments
                             .select("u.name AS user_name, enrollments.user_id, enrollments.course_id,
                c.name AS course_name,
                enrollments.root_account_id, enrollments.sis_pseudonym_id,
                c.sis_source_id AS course_sis_id, s.name AS section_name,
                enrollments.course_section_id, s.sis_source_id AS section_sis_id,
                enrollments.id AS enrollment_id,
                t.name AS term_name, t.id AS term_id,
                t.sis_source_id AS term_sis_id,
                sc.current_score,
                sc.final_score,
                sc.unposted_current_score,
                sc.unposted_final_score,
                sc.override_score,
           CASE WHEN enrollments.workflow_state = 'active' THEN 'active'
                WHEN enrollments.workflow_state = 'completed' THEN 'concluded'
                WHEN enrollments.workflow_state = 'inactive' THEN 'inactive'
                WHEN enrollments.workflow_state = 'deleted' THEN 'deleted' END AS enroll_state")
                             .order("t.id, c.id, enrollments.id")
                             .joins("INNER JOIN #{User.quoted_table_name} u ON enrollments.user_id = u.id
               INNER JOIN #{Course.quoted_table_name} c ON c.id = enrollments.course_id
               INNER JOIN #{EnrollmentTerm.quoted_table_name} t ON c.enrollment_term_id = t.id
               INNER JOIN #{CourseSection.quoted_table_name} s ON enrollments.course_section_id = s.id
               LEFT JOIN #{Score.quoted_table_name} sc ON sc.enrollment_id = enrollments.id AND sc.course_score IS TRUE")
                             .where("enrollments.type='StudentEnrollment'")

      if @include_deleted
        students = students.where("enrollments.workflow_state IN ('active', 'completed', 'inactive', 'deleted')")
        if @account_report.parameters.key? "limiting_period"
          limiting_period = @account_report.parameters["limiting_period"].to_i
          students = students.where("enrollments.workflow_state = 'active'
                                    OR c.conclude_at >= ?
                                    OR (enrollments.workflow_state IN ('inactive', 'deleted')
                                    AND enrollments.updated_at >= ?)",
                                    limiting_period.days.ago,
                                    limiting_period.days.ago)
        end
      else
        students = students.where(
          "c.workflow_state='available'
           AND enrollments.workflow_state IN ('active', 'completed')
           AND (sc.workflow_state IS DISTINCT FROM 'deleted')"
        )
      end
      students
    end

    def include_override_score?
      @account.feature_allowed?(:final_grades_override)
    end

    def grading_field_headers
      headers = []

      headers << "current score"
      headers << "final score"
      headers << "enrollment state"
      headers << "unposted current score"
      headers << "unposted final score"
      headers << "override score" if include_override_score?
      headers << "current grade"
      headers << "final grade"
      headers << "unposted current grade"
      headers << "unposted final grade"
      headers << "override grade" if include_override_score?

      headers
    end

    # We expect "student" to be an object of the sort returned by the query in student_grade_scope
    def grading_field_values(student:, course:)
      fields = []

      fields << student["current_score"]
      fields << student["final_score"]
      # enroll_state is sandwiched somewhat awkwardly in here but we don't want to change the
      # existing order of these columns
      fields << student["enroll_state"]
      fields << student["unposted_current_score"]
      fields << student["unposted_final_score"]
      fields << student["override_score"] if include_override_score?
      fields << course&.score_to_grade(student["current_score"])
      fields << course&.score_to_grade(student["final_score"])
      fields << course&.score_to_grade(student["unposted_current_score"])
      fields << course&.score_to_grade(student["unposted_final_score"])
      fields << course&.score_to_grade(student["override_score"]) if include_override_score?

      fields
    end

    def grading_period_grading_field_values(scores_for_student:)
      fields = []
      fields << scores_for_student[:current_score]
      fields << scores_for_student[:final_score]
      fields << scores_for_student[:unposted_current_score]
      fields << scores_for_student[:unposted_final_score]
      fields << scores_for_student[:override_score] if include_override_score?

      # scores_for_student is either an ersatz Score object (with the expected
      # methods but only a subset of fields) or an empty hash (if we're looking
      # at a student with no data in a given grading period). In the latter
      # case, don't try to calculate grades for scores that don't exist.
      if scores_for_student.respond_to?(:current_grade)
        fields << scores_for_student.current_grade
        fields << scores_for_student.final_grade
        fields << scores_for_student.unposted_current_grade
        fields << scores_for_student.unposted_final_grade
        fields << scores_for_student.override_grade if include_override_score?
      else
        buffer_field_count = include_override_score? ? 5 : 4
        fields.concat([nil] * buffer_field_count)
      end

      fields
    end
  end
end
