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

require 'account_reports/report_helper'


module AccountReports

  class OutcomeReports
    include ReportHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
      include_deleted_objects
    end

    def self.student_assignment_outcome_headers
       {
        'student name' => I18n.t('student name'),
        'student id' => I18n.t('student id'),
        'student sis id' => I18n.t('student sis id'),
        'assignment title' => I18n.t('assignment title'),
        'assignment id' => I18n.t('assignment id'),
        'submission date' => I18n.t('submission date'),
        'submission score' => I18n.t('submission score'),
        'learning outcome name' => I18n.t('learning outcome name'),
        'learning outcome id' => I18n.t('learning outcome id'),
        'attempt' => I18n.t('attempt'),
        'outcome score' => I18n.t('outcome score'),
        'course name' => I18n.t('course name'),
        'course id' => I18n.t('course id'),
        'course sis id' => I18n.t('course sis id'),
        'section name' => I18n.t('section name'),
        'section id' => I18n.t('section id'),
        'section sis id' => I18n.t('section sis id'),
        'assignment url' => I18n.t('assignment url'),
        'learning outcome friendly name' => I18n.t('learning outcome friendly name'),
        'learning outcome points possible' => I18n.t('learning outcome points possible'),
        'learning outcome mastery score' => I18n.t('learning outcome mastery score'),
        'learning outcome mastered' => I18n.t('learning outcome mastered'),
        'learning outcome rating' => I18n.t('learning outcome rating'),
        'learning outcome rating points' => I18n.t('learning outcome rating points'),
        'account id' => I18n.t('account id'),
        'account name' => I18n.t('account name'),
        'enrollment state' => I18n.t('enrollment state')
      }
    end

    # returns rows for each assignment that is linked to an outcome,
    # whether or not it has been submitted or graded
    def student_assignment_outcome_map
      write_outcomes_report(self.class.student_assignment_outcome_headers, student_assignment_outcome_map_scope)
    end

    def self.outcome_result_headers
      {
        'student name' => I18n.t('student name'),
        'student id' => I18n.t('student id'),
        'student sis id' => I18n.t('student sis id'),
        'assessment title' => I18n.t('assessment title'),
        'assessment id' => I18n.t('assessment id'),
        'assessment type' => I18n.t('assessment type'),
        'submission date' => I18n.t('submission date'),
        'submission score' => I18n.t('submission score'),
        'learning outcome name' => I18n.t('learning outcome name'),
        'learning outcome id' => I18n.t('learning outcome id'),
        'attempt' => I18n.t('attempt'),
        'outcome score' => I18n.t('outcome score'),
        'assessment question' => I18n.t('assessment question'),
        'assessment question id' => I18n.t('assessment question id'),
        'course name' => I18n.t('course name'),
        'course id' => I18n.t('course id'),
        'course sis id' => I18n.t('course sis id'),
        'section name' => I18n.t('section name'),
        'section id' => I18n.t('section id'),
        'section sis id' => I18n.t('section sis id'),
        'assignment url' => I18n.t('assignment url'),
        'learning outcome friendly name' => I18n.t('learning outcome friendly name'),
        'learning outcome points possible' => I18n.t('learning outcome points possible'),
        'learning outcome mastery score' => I18n.t('learning outcome mastery score'),
        'learning outcome mastered' => I18n.t('learning outcome mastered'),
        'learning outcome rating' => I18n.t('learning outcome rating'),
        'learning outcome rating points' => I18n.t('learning outcome rating points'),
        'account id' => I18n.t('account id'),
        'account name' => I18n.t('account name'),
        'enrollment state' => I18n.t('enrollment state')
      }
    end

    # returns rows for each assessed outcome result (or question result)
    def outcome_results
      write_outcomes_report(self.class.outcome_result_headers, outcome_results_scope)
    end

    private

    def student_assignment_outcome_map_scope
      parameters = {
        :account_id => account.id,
        :root_account_id => root_account.id
      }
      students = root_account.pseudonyms.except(:preload).
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
          lo.display_name        AS "learning outcome friendly name",
          lo.data                AS "learning outcome data",
          r.attempt              AS "attempt",
          r.hide_points          AS "learning outcome points hidden",
          r.score                AS "outcome score",
          r.possible             AS "learning outcome points possible",
          r.mastery              AS "learning outcome mastered",
          c.name                 AS "course name",
          c.id                   AS "course id",
          c.sis_source_id        AS "course sis id",
          s.name                 AS "section name",
          s.id                   AS "section id",
          s.sis_source_id        AS "section sis id",
          e.workflow_state       AS "enrollment state",
          lo.context_id          AS "outcome context id",
          lo.context_type        AS "outcome context type",
          acct.id                AS "account id",
          acct.name              AS "account name"}).
        joins(Pseudonym.send(:sanitize_sql, ["
          INNER JOIN #{User.quoted_table_name} u ON pseudonyms.user_id = u.id
          INNER JOIN (
            SELECT user_id, course_id, course_section_id, workflow_state
            FROM #{Enrollment.quoted_table_name}
            WHERE type = 'StudentEnrollment'
            AND root_account_id = :root_account_id
           " + (@include_deleted ? "" : "AND workflow_state <> 'deleted'") + "
            GROUP BY user_id, course_id, course_section_id, workflow_state
          ) e ON pseudonyms.user_id = e.user_id
          INNER JOIN #{Course.quoted_table_name} c ON c.id = e.course_id
            AND c.root_account_id = :root_account_id
          INNER JOIN #{Account.quoted_table_name} acct ON acct.id = c.account_id
          INNER JOIN #{CourseSection.quoted_table_name} s ON s.id = e.course_section_id
          INNER JOIN #{Assignment.quoted_table_name} a ON (a.context_id = c.id
                                       AND a.context_type = 'Course')
          INNER JOIN #{ContentTag.quoted_table_name} ct ON (ct.content_id = a.id
                                         AND ct.content_type = 'Assignment')
          INNER JOIN #{LearningOutcome.quoted_table_name} lo ON lo.id = ct.learning_outcome_id
          INNER JOIN #{ContentTag.quoted_table_name} lol ON lol.content_id = lo.id
            AND lol.context_id = :account_id
            AND lol.context_type = 'Account'
            AND lol.tag_type = 'learning_outcome_association'
            AND lol.workflow_state != 'deleted'
            LEFT JOIN #{LearningOutcomeResult.quoted_table_name} r ON (r.user_id=pseudonyms.user_id
              AND r.content_tag_id = ct.id)
            LEFT JOIN #{Submission.quoted_table_name} sub ON sub.assignment_id = a.id
              AND sub.user_id = pseudonyms.user_id AND sub.workflow_state <> 'deleted'
              AND sub.workflow_state <> 'unsubmitted'", parameters])).
          where("ct.tag_type = 'learning_outcome' AND ct.workflow_state <> 'deleted'
            AND (r.id IS NULL OR (r.artifact_type IS NOT NULL AND r.artifact_type <> 'Submission'))")

      unless @include_deleted
        students = students.where("pseudonyms.workflow_state<>'deleted' AND c.workflow_state='available'")
      end

      students = add_course_sub_account_scope(students, 'c')
      add_term_scope(students, 'c')
    end

    def outcome_results_scope
      students = account.learning_outcome_links.active.
        select(<<~SELECT).
          distinct on (#{outcome_order}, p.id, s.id, r.id, qr.id, q.id, a.id, subs.id, qs.id, aq.id)
          u.sortable_name                             AS "student name",
          p.user_id                                   AS "student id",
          p.sis_user_id                               AS "student sis id",
          a.id                                        AS "assignment id",
          COALESCE(q.title, a.title)                  AS "assessment title",
          COALESCE(q.id, a.id)                        AS "assessment id",
          COALESCE(qs.finished_at, subs.submitted_at) AS "submission date",
          COALESCE(qs.score, subs.score)              AS "submission score",
          aq.name                                     AS "assessment question",
          aq.id                                       AS "assessment question id",
          learning_outcomes.short_description         AS "learning outcome name",
          learning_outcomes.id                        AS "learning outcome id",
          learning_outcomes.display_name              AS "learning outcome friendly name",
          COALESCE(qr.possible, r.possible)           AS "learning outcome points possible",
          COALESCE(qr.mastery, r.mastery)             AS "learning outcome mastered",
          learning_outcomes.data                      AS "learning outcome data",
          COALESCE(qr.attempt, r.attempt)             AS "attempt",
          r.hide_points                               AS "learning outcome points hidden",
          COALESCE(qr.score, r.score)                 AS "outcome score",
          c.name                                      AS "course name",
          c.id                                        AS "course id",
          c.sis_source_id                             AS "course sis id",
          CASE WHEN r.association_type IN ('Quiz', 'Quizzes::Quiz') THEN 'quiz'
               WHEN ct.content_type = 'Assignment' THEN 'assignment'
          END                                         AS "assessment type",
          s.name                                      AS "section name",
          s.id                                        AS "section id",
          s.sis_source_id                             AS "section sis id",
          e.workflow_state                            AS "enrollment state",
          acct.id                                     AS "account id",
          acct.name                                   AS "account name"
        SELECT
        joins(<<~JOINS).
          INNER JOIN #{LearningOutcome.quoted_table_name} ON content_tags.content_id = learning_outcomes.id
            AND content_tags.content_type = 'LearningOutcome'
          INNER JOIN #{LearningOutcomeResult.quoted_table_name} r ON r.learning_outcome_id = learning_outcomes.id
          INNER JOIN #{ContentTag.quoted_table_name} ct ON r.content_tag_id = ct.id
          INNER JOIN #{User.quoted_table_name} u ON u.id = r.user_id
          INNER JOIN #{Pseudonym.quoted_table_name} p on p.user_id = r.user_id
          INNER JOIN #{Course.quoted_table_name} c ON r.context_id = c.id
          INNER JOIN #{Account.quoted_table_name} acct ON acct.id = c.account_id
          INNER JOIN #{Enrollment.quoted_table_name} e ON e.type = 'StudentEnrollment' and e.root_account_id = #{account.root_account.id}
            AND e.user_id = p.user_id AND e.course_id = c.id
            #{@include_deleted ? '' : "AND e.workflow_state <> 'deleted'"}
          INNER JOIN #{CourseSection.quoted_table_name} s ON e.course_section_id = s.id
          LEFT OUTER JOIN #{LearningOutcomeQuestionResult.quoted_table_name} qr on qr.learning_outcome_result_id = r.id
          LEFT OUTER JOIN #{Quizzes::Quiz.quoted_table_name} q ON q.id = r.association_id
           AND r.association_type IN ('Quiz', 'Quizzes::Quiz')
          LEFT OUTER JOIN #{Assignment.quoted_table_name} a ON (a.id = ct.content_id
           AND ct.content_type = 'Assignment') OR a.id = q.assignment_id
          LEFT OUTER JOIN #{Submission.quoted_table_name} subs ON subs.assignment_id = a.id
           AND subs.user_id = u.id AND subs.workflow_state <> 'deleted' AND subs.workflow_state <> 'unsubmitted'
          LEFT OUTER JOIN #{Quizzes::QuizSubmission.quoted_table_name} qs ON r.artifact_id = qs.id
           AND r.artifact_type IN ('QuizSubmission', 'Quizzes::QuizSubmission')
          LEFT OUTER JOIN #{AssessmentQuestion.quoted_table_name} aq ON aq.id = qr.associated_asset_id
           AND qr.associated_asset_type = 'AssessmentQuestion'
        JOINS
        where("ct.workflow_state <> 'deleted' AND r.artifact_type <> 'Submission'")

      unless @include_deleted
       students = students.where("p.workflow_state<>'deleted' AND c.workflow_state='available'")
      end

      students = join_course_sub_account_scope(account, students, 'c')
      students = add_term_scope(students, 'c')
      students.order(outcome_order)
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
        add_extra_text(I18n.t('account_reports.outcomes.order',
                              "Order: %{order}", order: select.first))
      else
        order = 'u.id, learning_outcomes.id, c.id'
      end
      order
    end

    def join_course_sub_account_scope(account, scope, table = 'courses')
      if account != account.root_account
        scope.joins(<<~JOINS)
          join #{CourseAccountAssociation.quoted_table_name} caa
            ON caa.account_id = #{account.id}
            AND caa.course_id = #{table}.id
            AND caa.course_section_id IS NULL
        JOINS
      else
        scope
      end
    end

    def write_outcomes_report(headers, scope)
      header_keys = headers.keys
      header_names = headers.values
      host = root_account.domain

      write_report header_names do |csv|
        total = scope.length
        Shackles.activate(:master) { AccountReport.where(id: @account_report.id).update_all(total_lines: total) }
        scope.each do |row|
          row = row.attributes.dup

          row['assignment url'] = "https://#{host}"
          row['assignment url'] << "/courses/#{row['course id']}"
          row['assignment url'] << "/assignments/#{row['assignment id']}"
          row['submission date'] = default_timezone_format(row['submission date'])
          add_outcomes_data(row)
          csv << header_keys.map { |h| row[h] }
        end
        csv << ['No outcomes found'] if total == 0
      end
    end

    def add_outcomes_data(row)
      row['learning outcome mastered'] = unless row['learning outcome mastered'].nil?
                                           row['learning outcome mastered'] ? 1 : 0
                                         end
      outcome_data = if row['learning outcome data'].present?
                       YAML.safe_load(row['learning outcome data'])[:rubric_criterion]
                     else
                       {}
                     end
      row['learning outcome mastery score'] = outcome_data[:mastery_points]

      score = row['outcome score']
      if score.present? && row['assessment_type'] != 'quiz'
        ratings = outcome_data[:ratings]&.sort_by { |r| r[:points] }&.reverse || []
        rating = ratings.detect { |r| r[:points] <= score } || {}
        row['learning outcome rating'] = rating[:description]

        if row['learning outcome points hidden'] == true
          row['outcome score'] = nil
          row['learning outcome rating points'] = nil
          row['learning outcome points possible'] = nil
          row['learning outcome mastery score'] = nil
        else
          row['learning outcome rating points'] = rating[:points]
        end
      end
    end
  end
end
