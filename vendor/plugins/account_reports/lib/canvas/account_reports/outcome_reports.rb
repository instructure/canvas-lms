#
# Copyright (C) 2013 Instructure, Inc.
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

  class OutcomeReports
    include Api
    include Canvas::AccountReports::ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
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

      if @account_report.has_parameter? "include_deleted"
        @include_deleted = @account_report.parameters["include_deleted"]
        @account_report.parameters["extra_text"] << I18n.t(
          'account_reports.grades.deleted', ' Include Deleted Objects: true;')
      end
      parameters = {
        :account_id => account.id,
        :root_account_id => root_account.id
      }
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
          AND ct.workflow_state <> 'deleted'
          AND (r.id IS NULL OR (r.artifact_type IS NOT NULL AND r.artifact_type <> 'Submission'))"
      )

      unless @include_deleted
        students = students.where("pseudonyms.workflow_state<>'deleted' AND c.workflow_state='available'")
      end

      students = add_course_sub_account_scope(students, 'c')
      students = add_term_scope(students, 'c')

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
          @total = students.count
          i = 0
          students.find_each do |row|
            row['assignment url'] =
              "https://#{host}" +
                "/courses/#{row['course id']}" +
                "/assignments/#{row['assignment id']}"
            row['submission date']=default_timezone_format(row['submission date'])
            csv << headers.map { |h| row[h] }

            if i % 5 == 0
              Shackles.activate(:master) do
                @account_report.update_attribute(:progress, (i.to_f/@total)*100)
              end
            end
            i += 1
          end
        end
        csv << ['No outcomes found'] if @total == 0
      end

      send_report(filename)
    end

    def outcome_order
      param = @account_report.has_parameter? 'order'
      param = param.downcase if param
      order_options = %w(users courses outcomes)
      select = order_options & [param]

      order_sql = {'users' => 'u.id, learning_outcomes.id, c.id',
                   'courses' => 'c.id, u.id, learning_outcomes.id',
                   'outcomes' => 'learning_outcomes.id, u.id, c.id'}
      if select.length == 1
        order = order_sql[select.first]
        @account_report.parameters["extra_text"] << " " << I18n.t(
          'account_reports.outcomes.order', "Order: %{order}", order: select.first)
      else
        order = ('u.id, learning_outcomes.id, c.id')
      end
      order
    end

    def outcome_results
      students = account.learning_outcomes.
        select(%{u.sortable_name                             AS "student name",
                 p.user_id                                   AS "student id",
                 p.sis_user_id                               AS "student sis id",
                 COALESCE(q.title, a.title)                  AS "assessment title",
                 COALESCE(q.id, a.id)                        AS "assessment id",
                 COALESCE(qs.finished_at, subs.submitted_at) AS "submission date",
                 COALESCE(qs.score, subs.score)              AS "submission score",
                 aq.name                                     AS "assessment question",
                 aq.id                                       AS "assessment question id",
                 learning_outcomes.short_description         AS "learning outcome name",
                 learning_outcomes.id                        AS "learning outcome id",
                 r.attempt                                   AS "attempt",
                 r.score                                     AS "outcome score",
                 c.name                                      AS "course name",
                 c.id                                        AS "course id",
                 c.sis_source_id                             AS "course sis id",
            CASE WHEN r.association_type = 'Quiz' THEN 'quiz'
                 WHEN ct.content_type = 'Assignment' THEN 'assignment'
                 END                                         AS "assessment type"}).
        joins("INNER JOIN learning_outcome_results r ON r.learning_outcome_id = learning_outcomes.id
               INNER JOIN content_tags ct ON r.content_tag_id = ct.id
               INNER JOIN users u ON u.id = r.user_id
               INNER JOIN pseudonyms p on p.user_id = r.user_id
               INNER JOIN courses c ON r.context_id = c.id
               LEFT OUTER JOIN quizzes q ON q.id = r.association_id
                 AND r.association_type = 'Quiz'
               LEFT OUTER JOIN assignments a ON a.id = ct.content_id
                 AND ct.content_type = 'Assignment'
               LEFT OUTER JOIN submissions subs ON subs.assignment_id = a.id
               LEFT OUTER JOIN quiz_submissions qs ON r.artifact_id = qs.id
                 AND r.artifact_type = 'QuizSubmission'
               LEFT OUTER JOIN assessment_questions aq ON aq.id = r.associated_asset_id
                 AND r.associated_asset_type = 'AssessmentQuestion'").
        where("ct.workflow_state <> 'deleted'
               AND (r.id IS NULL OR (r.artifact_type IS NOT NULL AND r.artifact_type <> 'Submission'))")

      unless @include_deleted
        students = students.where("p.workflow_state<>'deleted' AND c.workflow_state='available'")
      end

      students = add_term_scope(students, 'c')

      students = students.order(outcome_order)

      headers = ['student name', 'student id', 'student sis id',
                 'assessment title', 'assessment id', 'assessment type',
                 'submission date', 'submission score', 'learning outcome name',
                 'learning outcome id', 'attempt', 'outcome score',
                 'assessment question', 'assessment question id',
                 'course name', 'course id', 'course sis id']

      # Generate the CSV report
      filename = Canvas::AccountReports.generate_file(@account_report)
      CSV.open(filename, "w") do |csv|
        csv << headers
        Shackles.activate(:slave) do
          @total = students.count
          i = 0
          students.find_each do |row|
            row['submission date']=default_timezone_format(row['submission date'])

            csv << headers.map { |h| row[h] }

            if i % 5 == 0
              Shackles.activate(:master) do
                @account_report.update_attribute(:progress, (i.to_f/@total)*100)
              end
            end
            i += 1
          end
        end
        csv << ['No outcomes found'] if @total == 0
      end

      send_report(filename)
    end
  end

end
