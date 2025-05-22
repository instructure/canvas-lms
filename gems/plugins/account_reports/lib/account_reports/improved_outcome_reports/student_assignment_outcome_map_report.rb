# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
  module ImprovedOutcomeReports
    class StudentAssignmentOutcomeMapReport < BaseOutcomeReport
      # Student Competency Report on UI

      HEADERS = [
        "student name",
        "student id",
        "student sis id",
        "assignment title",
        "assignment id",
        "submission date",
        "submission score",
        "learning outcome name",
        "learning outcome id",
        "attempt",
        "outcome score",
        "course name",
        "course id",
        "course sis id",
        "section name",
        "section id",
        "section sis id",
        "assignment url",
        "learning outcome friendly name",
        "learning outcome points possible",
        "learning outcome mastery score",
        "learning outcome mastered",
        "learning outcome rating",
        "learning outcome rating points",
        "learning outcome group title",
        "learning outcome group id",
        "account id",
        "account name",
        "enrollment state"
      ].freeze

      # returns rows for each assignment that is linked to an outcome,
      # whether or not it has been submitted or graded
      def generate
        write_outcomes_report(
          HEADERS,
          scope,
          { post_process_record: method(:post_process_record) }
        )
      end

      private

      def post_process_record(record_hash, cache)
        # It used to be an INNER JOIN with `accounts` table thus if acc_id is nil, or
        # account does not exist is invalid case (raise exception)

        acc_id = record_hash["account id"]
        raise ActiveRecord::RecordInvalid if acc_id.nil?

        account = cache.fetch(acc_id) { Account.find_by(id: acc_id) }
        raise ActiveRecord::RecordInvalid if account.nil?

        cache[account.id] = account
        record_hash.merge("account name" => account.name)
      end

      def scope
        parameters = {
          account_id: account.id,
          root_account_id: root_account.id
        }
        students = root_account.pseudonyms
                               .not_instructure_identity
                               .except(:preload)
                               .select(<<~SQL.squish)
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
                                 g.title                AS "learning outcome group title",
                                 g.id                   AS "learning outcome group id",
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
                                 c.account_id           AS "account id"
                               SQL
                               .joins(Pseudonym.send(:sanitize_sql, [<<~SQL.squish, parameters]))
                                 INNER JOIN #{User.quoted_table_name} u ON pseudonyms.user_id = u.id
                                 INNER JOIN (
                                   SELECT user_id, course_id, course_section_id, workflow_state
                                   FROM #{Enrollment.quoted_table_name}
                                   WHERE type = 'StudentEnrollment'
                                   AND root_account_id = :root_account_id
                                   #{"AND workflow_state <> 'deleted'" unless @include_deleted}
                                   GROUP BY user_id, course_id, course_section_id, workflow_state
                                 ) e ON pseudonyms.user_id = e.user_id
                                 INNER JOIN #{Course.quoted_table_name} c ON c.id = e.course_id
                                   AND c.root_account_id = :root_account_id
                                   AND c.account_id IS NOT NULL
                                 INNER JOIN #{CourseSection.quoted_table_name} s ON s.id = e.course_section_id
                                 INNER JOIN #{Assignment.quoted_table_name} a ON (a.context_id = c.id
                                                               AND a.context_type = 'Course'
                                                               AND a.type = 'Assignment'
                                                               #{"AND a.workflow_state <> 'deleted'" unless @include_deleted}
                                                               )
                                 INNER JOIN #{ContentTag.quoted_table_name} ct ON (ct.content_id = a.id
                                                                 AND ct.content_type = 'Assignment')
                                 INNER JOIN #{LearningOutcome.quoted_table_name} lo ON lo.id = ct.learning_outcome_id
                                 INNER JOIN #{ContentTag.quoted_table_name} lol ON lol.content_id = lo.id
                                   AND lol.context_id = :account_id
                                   AND lol.context_type = 'Account'
                                   AND lol.tag_type = 'learning_outcome_association'
                                   AND lol.workflow_state != 'deleted'
                                 INNER JOIN #{LearningOutcomeGroup.quoted_table_name} g ON g.id = lol.associated_asset_id
                                   AND lol.associated_asset_type = 'LearningOutcomeGroup'
                                   LEFT JOIN #{LearningOutcomeResult.quoted_table_name} r ON (r.user_id=pseudonyms.user_id
                                     AND r.content_tag_id = ct.id)
                                   LEFT JOIN #{Submission.quoted_table_name} sub ON sub.assignment_id = a.id
                                     AND sub.user_id = pseudonyms.user_id AND sub.workflow_state <> 'deleted'
                                     AND sub.workflow_state <> 'unsubmitted'
                               SQL
                               .where(<<~SQL.squish)
                                 ct.tag_type = 'learning_outcome' AND ct.workflow_state <> 'deleted'
                                 AND (r.id IS NULL OR (r.workflow_state <> 'deleted' AND r.artifact_type IS NOT NULL AND r.artifact_type <> 'Submission'))
                               SQL

        unless @include_deleted
          students = students.where("pseudonyms.workflow_state<>'deleted' AND c.workflow_state IN ('available', 'completed')")
        end

        students = add_course_sub_account_scope(students, "c")
        add_term_scope(students, "c")
      end
    end
  end
end
