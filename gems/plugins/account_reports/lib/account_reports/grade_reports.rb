#
# Copyright (C) 2012 - 2014 Instructure, Inc.
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

require 'account_reports/report_helper'

module AccountReports

  class GradeReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
      include_deleted_objects

      if @account_report.has_parameter? "limiting_period"
        add_extra_text(I18n.t('account_reports.grades.limited',
                              'deleted objects limited by days specified;'))
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

    def grade_export()
      students = student_grade_scope
      students = add_term_scope(students, 'c')

      headers = []
      headers << I18n.t('student name')
      headers << I18n.t('student id')
      headers << I18n.t('student sis')
      headers << I18n.t('course')
      headers << I18n.t('course id')
      headers << I18n.t('course sis')
      headers << I18n.t('section')
      headers << I18n.t('section id')
      headers << I18n.t('section sis')
      headers << I18n.t('term')
      headers << I18n.t('term id')
      headers << I18n.t('term sis')
      headers << I18n.t('current score')
      headers << I18n.t('final score')
      headers << I18n.t('enrollment state')

      write_report headers do |csv|

        students.find_each do |student|
          arr = []
          arr << student["user_name"]
          arr << student["user_id"]
          arr << student["sis_user_id"]
          arr << student["course_name"]
          arr << student["course_id"]
          arr << student["course_sis_id"]
          arr << student["section_name"]
          arr << student["course_section_id"]
          arr << student["section_sis_id"]
          arr << student["term_name"]
          arr << student["term_id"]
          arr << student["term_sis_id"]
          arr << student["current_score"]
          arr << student["final_score"]
          arr << student["enroll_state"]
          csv << arr
        end
      end
    end

    def mgp_grade_export
      terms = @account_report.parameters[:enrollment_term_id].blank? ?
        root_account.enrollment_terms.active :
        root_account.enrollment_terms.where(id: @account_report.parameters[:enrollment_term_id])

      term_reports = terms.reduce({}) do |reports, term|
        reports[term.name] = mgp_term_csv(term)
        reports
      end

      send_report(term_reports)
    end

    def mgp_term_csv(term)
      students = student_grade_scope
      students = students.where(c: {enrollment_term_id: term})

      gp_set = term.grading_period_group
      unless gp_set
        not_found = Tempfile.open(%w[not-found csv])
        not_found.puts I18n.t("no grading periods configured for this term")
        not_found.close
        return not_found
      end
      grading_periods = gp_set.grading_periods.active.order(:start_date)

      headers = []
      headers << I18n.t('student name')
      headers << I18n.t('student id')
      headers << I18n.t('student sis')
      headers << I18n.t('course')
      headers << I18n.t('course id')
      headers << I18n.t('course sis')
      headers << I18n.t('section')
      headers << I18n.t('section id')
      headers << I18n.t('section sis')
      headers << I18n.t('term')
      headers << I18n.t('term id')
      headers << I18n.t('term sis')
      headers << I18n.t('grading period set')
      headers << I18n.t('grading period set id')
      grading_periods.each { |gp|
        headers << I18n.t('%{name} grading period id', name: gp.title)
        headers << I18n.t('%{name} current score', name: gp.title)
        headers << I18n.t('%{name} final score', name: gp.title)
      }
      headers << I18n.t('current score')
      headers << I18n.t('final score')
      headers << I18n.t('enrollment state')

      firstpass_file = generate_and_run_report(nil, 'firstpass.csv') do |csv|
        students.find_in_batches do |student_chunk|
          # loading students/courses in chunks to avoid unnecessarily
          # re-loading assignments/etc. in the grade calculator
          students_by_course = student_chunk.group_by { |x| x.course_id }

          students_by_course.each do |course_id, course_students|
            course_students.each do |student|
              arr = []
              arr << student["user_name"]
              arr << student["user_id"]
              arr << student["sis_user_id"]
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
                arr << gp.id
                # Putting placeholders there to be replaced after expensive grade calculation
                arr << nil
                arr << nil
              end
              arr << student["current_score"]
              arr << student["final_score"]
              arr << student["enroll_state"]
              csv << arr
            end
          end
        end
      end

      generate_and_run_report headers do |report_csv|
        read_csv_in_chunks(firstpass_file) do |rows|
          rows_by_course = rows.group_by { |arr| arr[4].to_i  }
          courses_by_id = Course.find(rows_by_course.keys).index_by(&:id)

          rows_by_course.each do |course_id, course_rows|
            grading_period_grades = grading_periods.reduce({}) do |h,gp|
              h[gp] = GradeCalculator.new(course_rows.map { |arr| arr[1] },
                                          courses_by_id[course_id],
                                          grading_period: gp).compute_scores
              h
            end

            course_rows.each do |row|
              column = 13
              grading_period_grades.each do |gp, grades|
                row_grades = grades.shift
                # this accounts for gp.id and moves us to where we want
                # to drop our grades data.
                column += 2
                row[column] = row_grades[:current][:grade]
                column += 1
                row[column] = row_grades[:final][:grade]
              end
            end
          end

          rows.each { |r| report_csv << r }
        end
      end
    end

    private

    def student_grade_scope
      students = root_account.pseudonyms.except(:preload).
        select("pseudonyms.id, u.name AS user_name, e.user_id, e.course_id,
                pseudonyms.sis_user_id, c.name AS course_name,
                c.sis_source_id AS course_sis_id, s.name AS section_name,
                e.course_section_id, s.sis_source_id AS section_sis_id,
                t.name AS term_name, t.id AS term_id,
                t.sis_source_id AS term_sis_id,
                sc.current_score,
                sc.final_score,
           CASE WHEN e.workflow_state = 'active' THEN 'active'
                WHEN e.workflow_state = 'completed' THEN 'concluded'
                WHEN e.workflow_state = 'deleted' THEN 'deleted' END AS enroll_state").
        order("t.id, c.id, e.id").
        joins("INNER JOIN #{User.quoted_table_name} u ON pseudonyms.user_id = u.id
               INNER JOIN #{Enrollment.quoted_table_name} e ON pseudonyms.user_id = e.user_id
                 AND e.type = 'StudentEnrollment'
               INNER JOIN #{Course.quoted_table_name} c ON c.id = e.course_id
               INNER JOIN #{EnrollmentTerm.quoted_table_name} t ON c.enrollment_term_id = t.id
               INNER JOIN #{CourseSection.quoted_table_name} s ON e.course_section_id = s.id
               LEFT JOIN #{Score.quoted_table_name} sc ON sc.enrollment_id = e.id AND sc.grading_period_id IS NULL")

      if @include_deleted
        students = students.where("e.workflow_state IN ('active', 'completed', 'deleted')")
        if @account_report.parameters.has_key? 'limiting_period'
          limiting_period = @account_report.parameters['limiting_period'].to_i
          students = students.where("e.workflow_state = 'active'
                                    OR c.conclude_at >= ?
                                    OR (e.workflow_state = 'deleted'
                                    AND e.updated_at >= ?)",
                                    limiting_period.days.ago, limiting_period.days.ago)
        end
      else
        students = students.where(
          "pseudonyms.workflow_state<>'deleted'
           AND c.workflow_state='available'
           AND e.workflow_state IN ('active', 'completed')
           AND sc.workflow_state <> 'deleted'")
      end

      students = add_course_sub_account_scope(students, 'c')
    end
  end
end
