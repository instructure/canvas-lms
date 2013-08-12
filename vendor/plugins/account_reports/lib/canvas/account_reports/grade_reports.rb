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
    include Canvas::AccountReports::ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)

      if @account_report.has_parameter? "include_deleted"
        @include_deleted = @account_report.parameters["include_deleted"]
        @account_report.parameters["extra_text"] << I18n.t(
          'account_reports.grades.deleted', ' Include Deleted Objects: true;')
      end
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
        :account_id => account.id,
        :root_account_id => root_account.id
      }
      # believe it or not, we need two scopes here, one before the .active,
      # in order to exclude the pesky :user that is included by default in
      # the Account#pseudonyms association, and one after the .active, to
      # actually perform the query.
      students = root_account.pseudonyms.except(:includes).
        select(%{
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
          r.attempt              AS "attempt",
          r.score                AS "outcome score",
          c.name                 AS "course name",
          c.id                   AS "course id",
          c.sis_source_id        AS "course sis id",
          s.name                 AS "section name",
          s.id                   AS "section id",
          s.sis_source_id        AS "section sis id",
          lo.context_id          AS "outcome context id",
          lo.context_type        AS "outcome context type"}).
        joins(Pseudonym.send(:sanitize_sql, ["
          INNER JOIN users u ON pseudonyms.user_id = u.id
          INNER JOIN (
            SELECT user_id, course_id, course_section_id
            FROM enrollments
            WHERE type = 'StudentEnrollment'
            AND root_account_id = :root_account_id
	    " + (@include_deleted ? "" : "AND workflow_state = 'active'") + "
            GROUP BY user_id, course_id, course_section_id
          ) e ON pseudonyms.user_id = e.user_id
          INNER JOIN courses c ON c.id = e.course_id
            AND c.root_account_id = :root_account_id
          INNER JOIN course_sections s ON s.id = e.course_section_id
          INNER JOIN assignments a ON (a.context_id = c.id
                                       AND a.context_type = 'Course')
          INNER JOIN content_tags ct ON (ct.content_id = a.id
                                         AND ct.content_type = 'Assignment')
          INNER JOIN learning_outcomes lo ON (
            lo.id = ct.learning_outcome_id
            AND lo.context_type = 'Account'
            AND lo.context_id = :account_id
          )
          LEFT JOIN learning_outcome_results r ON (r.user_id=pseudonyms.user_id
                                                   AND r.content_tag_id = ct.id)
          LEFT JOIN submissions sub ON sub.assignment_id = a.id
            AND sub.user_id = pseudonyms.user_id", parameters])).
        where("
          ct.tag_type = 'learning_outcome'
          AND ct.workflow_state <> 'deleted'"
      )

      unless @include_deleted
        students = students.where("pseudonyms.workflow_state<>'deleted' AND c.workflow_state='available'")
      end

      students = add_course_sub_account_scope(students, 'c')
      students = add_term_scope(students, 'c')

      total = students.count
      i = 0
      host = root_account.domain
      headers = ['student name', 'student id', 'student sis id',
                 'assignment title', 'assignment id', 'submission date',
                 'submission score', 'learning outcome name',
                 'learning outcome id', 'attempt', 'outcome score',
                 'course name', 'course id', 'course sis id', 'section name',
                 'section id', 'section sis id', 'assignment url']

      # Generate the CSV report
      filename = Canvas::AccountReports.generate_file(@account_report)
      CSV.open(filename, "w") do |csv|
        csv << headers
        Shackles.activate(:slave) do
          students.find_each do |row|
            row['assignment url'] =
              "https://#{host}" +
                "/courses/#{row['course id']}" +
                "/assignments/#{row['assignment id']}"
            row['submission date']=default_timezone_format(row['submission date'])
            csv << headers.map { |h| row[h] }
            if i % 5 == 0
              @account_report.update_attribute(:progress, (i.to_f/total)*100)
            end
            i += 1
          end
        end
        csv << ['No outcomes found'] if total == 0
      end

      send_report(filename)
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
        joins("INNER JOIN users u ON pseudonyms.user_id = u.id
               INNER JOIN enrollments e ON pseudonyms.user_id = e.user_id
                 AND e.type = 'StudentEnrollment'
               INNER JOIN courses c ON c.id = e.course_id
               INNER JOIN enrollment_terms t ON c.enrollment_term_id = t.id
               INNER JOIN course_sections s ON e.course_section_id = s.id")

      if @include_deleted
        students = students.where("e.workflow_state IN ('active', 'completed', 'deleted')")
      else
        students = students.where(
          "pseudonyms.workflow_state<>'deleted'
	     AND c.workflow_state='available'
	     AND e.workflow_state IN ('active', 'completed')")
      end

      students = add_course_sub_account_scope(students, 'c')
      students = add_term_scope(students, 'c')

      file = Canvas::AccountReports.generate_file(@account_report)
      CSV.open(file, "w") do |csv|
        csv << ['student name', 'student id', 'student sis', 'course',
                'course id', 'course sis', 'section', 'section id',
                'section sis', 'term', 'term id', 'term sis', 'current score',
                'final score', 'enrollment state']
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
