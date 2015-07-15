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

      if @account_report.has_parameter? "include_deleted"
        @include_deleted = @account_report.parameters["include_deleted"]
        add_extra_text(I18n.t('account_reports.grades.deleted',
                              'Include Deleted Objects: true;'))
      end

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
      students = root_account.pseudonyms.except(:includes).
        select("pseudonyms.id, u.name AS user_name, e.user_id, e.course_id,
                pseudonyms.sis_user_id, c.name AS course_name,
                c.sis_source_id AS course_sis_id, s.name AS section_name,
                e.course_section_id, s.sis_source_id AS section_sis_id,
                t.name AS term_name, t.id AS term_id,
                t.sis_source_id AS term_sis_id, e.computed_current_score,
                e.computed_final_score,
           CASE WHEN e.workflow_state = 'active' THEN 'active'
                WHEN e.workflow_state = 'completed' THEN 'concluded'
                WHEN e.workflow_state = 'deleted' THEN 'deleted' END AS enroll_state").
        order("t.id, c.id, e.id").
        joins("INNER JOIN #{User.quoted_table_name} u ON pseudonyms.user_id = u.id
               INNER JOIN #{Enrollment.quoted_table_name} e ON pseudonyms.user_id = e.user_id
                 AND e.type = 'StudentEnrollment'
               INNER JOIN #{Course.quoted_table_name} c ON c.id = e.course_id
               INNER JOIN #{EnrollmentTerm.quoted_table_name} t ON c.enrollment_term_id = t.id
               INNER JOIN #{CourseSection.quoted_table_name} s ON e.course_section_id = s.id")

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
           AND e.workflow_state IN ('active', 'completed')")
      end

      students = add_course_sub_account_scope(students, 'c')
      students = add_term_scope(students, 'c')

      file = AccountReports.generate_file(@account_report)
      CSV.open(file, "w") do |csv|
        headers = []

        headers << I18n.t('#account_reports.report_header_student_name', 'student name')
        headers << I18n.t('#account_reports.report_header_student_id', 'student id')
        headers << I18n.t('#account_reports.report_header_student_sis', 'student sis')
        headers << I18n.t('#account_reports.report_header_course', 'course')
        headers << I18n.t('#account_reports.report_header_course_id', 'course id')
        headers << I18n.t('#account_reports.report_header_course_sis', 'course sis')
        headers << I18n.t('#account_reports.report_header_section', 'section')
        headers << I18n.t('#account_reports.report_header_section_id', 'section id')
        headers << I18n.t('#account_reports.report_header_section_sis', 'section sis')
        headers << I18n.t('#account_reports.report_header_term', 'term')
        headers << I18n.t('#account_reports.report_header_term_id', 'term id')
        headers << I18n.t('#account_reports.report_header_term_sis', 'term sis')
        headers << I18n.t('#account_reports.report_header_current_score', 'current score')
        headers << I18n.t('#account_reports.report_header_final_score', 'final score')
        headers << I18n.t('#account_reports.report_header_enrollment_state', 'enrollment state')

        csv << headers

        Shackles.activate(:slave) do
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
            arr << student["computed_current_score"]
            arr << student["computed_final_score"]
            arr << student["enroll_state"]
            csv << arr
          end
        end
      end

      send_report(file)
    end
  end
end
