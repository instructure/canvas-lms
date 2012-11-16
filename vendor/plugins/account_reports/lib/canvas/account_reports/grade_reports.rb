#
# Copyright (C) 2012 Instructure, Inc.
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

module Canvas::AccountReports

  class GradeReports
    include Api
    include Canvas::ReportHelpers::DateHelper

    def initialize(account_report)
      @account_report = account_report
      @account = @account_report.account
      @domain_root_account = @account.root_account
      @term = api_find(@account.enrollment_terms, @account_report.parameters["enrollment_term"]) if @account_report.parameters && @account_report.parameters["enrollment_term"].presence
    end

    # retrieve the list of students for all active courses
    # for each student, iterate through all applicable assignments
    # for each assignment, find the submission, then iterate through all
    #   outcome alignments and find the outcome result
    # for each student-assignment-outcome pairing, generate a row
    #   based on the found outcome result
    # each row should include:
    # - student name
    # - student id
    # - assignment title
    # - assignment id
    # - submission date
    # - assignment score
    # - learning outcome name
    # - learning outcome id
    # - outcome result score
    def student_assignment_outcome_map
      parameters = {
        :account_id => @account.id, 
        :root_account_id => @domain_root_account.id
      }
      students = Pseudonym.active.scoped(
        :select => %{
          u.sortable_name        AS "student name",
          pseudonyms.user_id     AS "student id",
          pseudonyms.sis_user_id AS "student sis id",
          a.title                AS "assignment title",
          a.id                   AS "assignment id",
          sub.submitted_at       AS "submission date",
          sub.score              AS "submission score",
          lo.short_description   AS "learning outcome name",
          lo.id                  AS "learning outcome id",
          lor.attempt            AS "attempt",
          lor.score              AS "outcome score",
          c.name                 AS "course name",
          c.id                   AS "course id",
          c.sis_source_id        AS "course sis id",
          lo.context_id          AS "outcome context id",
          lo.context_type        AS "outcome context type"},
        :joins => Pseudonym.send(:sanitize_sql, ["
          INNER JOIN users u ON pseudonyms.user_id = u.id
          INNER JOIN (
            SELECT user_id, course_id
            FROM enrollments
            WHERE workflow_state = 'active'
            AND type = 'StudentEnrollment'
            AND root_account_id = :root_account_id
            GROUP BY user_id, course_id
          ) e ON pseudonyms.user_id = e.user_id
          INNER JOIN courses c ON c.id = e.course_id
          INNER JOIN (
            SELECT course_id, account_id
            FROM course_account_associations
            WHERE account_id = :account_id
            GROUP BY course_id, account_id
          ) caa ON c.id = caa.course_id
          INNER JOIN assignments a ON (a.context_id = c.id AND a.context_type = 'Course')
          INNER JOIN content_tags ct ON (ct.content_id = a.id AND ct.content_type = 'Assignment')
          INNER JOIN learning_outcomes lo ON (
            lo.id = ct.learning_outcome_id
            AND lo.context_type = 'Account'
            AND lo.context_id = :account_id
          )
          LEFT JOIN learning_outcome_results lor ON (lor.user_id = pseudonyms.user_id AND lor.content_tag_id = ct.id)
          LEFT JOIN submissions sub ON sub.assignment_id = a.id
            AND sub.user_id = pseudonyms.user_id", parameters]),
        :conditions => ["
          c.workflow_state = 'available'
          AND ct.tag_type = 'learning_outcome'
          AND ct.workflow_state != 'deleted'
          AND pseudonyms.account_id = :root_account_id", parameters]
      )


      total = students.count
      i = 0
      host = @account.domain
      headers =
        ['student name', 'student id', 'student sis id', 'assignment title', 'assignment id',
         'submission date', 'submission score', 'learning outcome name', 'learning outcome id',
         'attempt', 'outcome score', 'course name', 'course id', 'course sis id', 'assignment url']

      # Generate the CSV report
      result = FasterCSV.generate do |csv|
        csv << headers
        students.find_each do |row|
          row['assignment url'] =
            "https://#{host}" +
              "/courses/#{row['course id']}" +
              "/assignments/#{row['assignment id']}"
          datetime = default_timezone_parse(row['submission date'], @account)
          row['submission date'] = default_timezone_format(datetime)
          csv << headers.map { |h| row[h] }
          if i % 5 == 0
            @account_report.update_attribute(:progress, (i.to_f/total)*100)
          end
          i += 1
        end
        csv << ['No outcomes found'] if total == 0
      end

      Canvas::AccountReports.message_recipient(
        @account_report,
        I18n.t(
          'account_reports.default.outcome.message',
          "Student-assignment-outcome mapping report successfully generated for %{account_name}",
          :account_name => @account.name),
        result)
      result
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

    def grade_export()
      term = @term
      name = term ? term.name : I18n.t('account_reports.default.all_terms', "All Terms")
      @account_report.parameters["extra_text"] = I18n.t('account_reports.default.extra_text', "For Term: %{term_name}", :term_name => name)
      students = StudentEnrollment.scoped(:include => {:course => :enrollment_term, :course_section => [], :user => :pseudonyms},
                                          :order => 'enrollment_terms.id, courses.id, enrollments.id',
                                          :conditions => {:root_account_id => @account.id,
                                                          'courses.workflow_state' => 'available', 'enrollments.workflow_state' => ['active', 'completed'] })
      students = students.scoped(:conditions => { 'courses.enrollment_term_id' => term}) if term

      result = FasterCSV.generate do |csv|
        csv << ['student name', 'student id', 'student sis', 'course', 'course id', 'course sis', 'section', 'section id', 'section sis', 'term', 'term id', 'term sis','current score', 'final score']
        students.find_each do |student|
          course = student.course
          course_section = student.course_section
          arr = []
          arr << student.user.name
          arr << student.user.id
          arr << student.user.sis_pseudonym_for(@account).try(:sis_user_id)
          arr << course.name
          arr << course.id
          arr << course.sis_source_id
          arr << course_section.name
          arr << course_section.id
          arr << course_section.sis_source_id
          arr << course.enrollment_term.name
          arr << course.enrollment_term.id
          arr << course.enrollment_term.sis_source_id
          arr << student.computed_current_score
          arr << student.computed_final_score
          csv << arr
        end
      end

      Canvas::AccountReports.message_recipient(@account_report, I18n.t('account_reports.default.grade.message',"Grade export successfully generated for term %{term_name}", :term_name => name), result)
      result
    end
  end
end
