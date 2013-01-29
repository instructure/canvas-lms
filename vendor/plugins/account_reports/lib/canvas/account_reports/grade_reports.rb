#
# Copyright (C) 2012 - 2013 Instructure, Inc.
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
      @term = api_find(@domain_root_account.enrollment_terms, @account_report.parameters["enrollment_term"]) if @account_report.has_parameter? "enrollment_term"
      @include_deleted = @account_report.parameters["include_deleted"]  if @account_report.has_parameter? "include_deleted"
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
      # believe it or not, we need two scopes here, one before the .active,
      # in order to exclude the pesky :user that is included by default in
      # the Account#pseudonyms association, and one after the .active, to
      # actually perform the query.
      students = @domain_root_account.pseudonyms.
        scoped(:include => { :exclude => :user }).scoped(
        :select => %{
          pseudonyms.id,
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
            WHERE type = 'StudentEnrollment'
            AND root_account_id = :root_account_id
            " + (@include_deleted ? "" :"AND workflow_state = 'active'") + "
            GROUP BY user_id, course_id
          ) e ON pseudonyms.user_id = e.user_id
          INNER JOIN courses c ON c.id = e.course_id
            AND c .root_account_id = :root_account_id
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
        :conditions => "
          ct.tag_type = 'learning_outcome'
          AND ct.workflow_state != 'deleted'"
      )
      students = students.scoped(:conditions => "pseudonyms.workflow_state != 'deleted'
                                                 AND c.workflow_state = 'available'") unless @include_deleted
      students = students.scoped(:conditions => ["c.enrollment_term_id=?", @term.id]) if @term
      if @account.id != @domain_root_account.id
        students = students.scoped(:conditions => ["EXISTS (SELECT course_id
                                                            FROM course_account_associations caa
                                                            WHERE caa.account_id = ?
                                                            AND caa.course_id=c.id
                                                            )", @account.id])
      end

      total = students.count
      i = 0
      host = @account.domain
      headers =
        ['student name', 'student id', 'student sis id', 'assignment title', 'assignment id',
         'submission date', 'submission score', 'learning outcome name', 'learning outcome id',
         'attempt', 'outcome score', 'course name', 'course id', 'course sis id', 'assignment url']

      # Generate the CSV report
      filename = Canvas::AccountReports.generate_file(@account_report)
      FasterCSV.open(filename, "w") do |csv|
        csv << headers
        students.find_each do |row|
          row['assignment url'] =
            "https://#{host}" +
              "/courses/#{row['course id']}" +
              "/assignments/#{row['assignment id']}"
          row['submission date'] = default_timezone_format(row['submission date'])
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
        filename)
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
      name = @term ? @term.name : I18n.t('account_reports.default.all_terms', "All Terms")
      parameters = {
        :account_id => @account.id,
        :root_account_id => @domain_root_account.id
      }
      @account_report.parameters["extra_text"] = I18n.t('account_reports.default.extra_text', "For Term: %{term_name}", :term_name => name)
      students = @domain_root_account.pseudonyms.scoped(:include => { :exclude => :user }).scoped(
        :select => "pseudonyms.id, u.name AS user_name, enrollments.user_id, pseudonyms.sis_user_id, courses.name AS course_name,
                    enrollments.course_id, courses.sis_source_id AS course_sis_id, course_sections.name AS section_name,
                    enrollments.course_section_id, course_sections.sis_source_id AS section_sis_id,
                    enrollment_terms.name AS term_name, enrollment_terms.id AS term_id,
                    enrollment_terms.sis_source_id AS term_sis_id, enrollments.computed_current_score,
                    enrollments.computed_final_score",
        :joins => Pseudonym.send(:sanitize_sql, ["INNER JOIN users u ON pseudonyms.user_id = u.id
                                                  INNER JOIN enrollments ON pseudonyms.user_id = enrollments.user_id
                                                    AND enrollments.type = 'StudentEnrollment'
                                                  INNER JOIN courses ON courses.id = enrollments.course_id
                                                  INNER JOIN course_sections ON enrollments.course_section_id = course_sections.id
                                                  INNER JOIN enrollment_terms ON courses.enrollment_term_id = enrollment_terms.id", parameters]))
      students = students.scoped(:conditions => ["courses.enrollment_term_id=?", @term.id]) if @term
      students = students.scoped(:conditions => "pseudonyms.workflow_state != 'deleted'
                                                 AND courses.workflow_state = 'available'
                                                 AND enrollments.workflow_state IN ('active', 'completed')") unless @include_deleted
      if @account.id != @domain_root_account.id
        students = students.scoped(:conditions => ["EXISTS (SELECT course_section_id, account_id
                                                            FROM course_account_associations caa
                                                            WHERE caa.account_id = ?
                                                            AND caa.course_section_id=course_sections.id
                                                            )", @account.id])
      end
      filename = Canvas::AccountReports.generate_file(@account_report)
      FasterCSV.open(filename, "w") do |csv|
        csv << ['student name', 'student id', 'student sis', 'course', 'course id', 'course sis', 'section',
                'section id', 'section sis', 'term', 'term id', 'term sis','current score', 'final score']
        students.find_each do |student|
          arr = []
          arr << student.user_name
          arr << student.user_id
          arr << student.sis_user_id
          arr << student.course_name
          arr << student.course_id
          arr << student.course_sis_id
          arr << student.section_name
          arr << student.course_section_id
          arr << student.section_sis_id
          arr << student.term_name
          arr << student.term_id
          arr << student.term_sis_id
          arr << student.computed_current_score
          arr << student.computed_final_score
          csv << arr
        end
      end

      Canvas::AccountReports.message_recipient(@account_report, I18n.t('account_reports.default.grade.message',"Grade export successfully generated for term %{term_name}", :term_name => name), filename)
    end
  end
end
