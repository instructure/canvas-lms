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
  class OutcomeReports
    include ReportHelper
    include CanvasOutcomesHelper

    def initialize(account_report)
      @account_report = account_report
      extra_text_term(@account_report)
      include_deleted_objects
    end

    def self.student_assignment_outcome_headers
      {
        "student name" => I18n.t("student name"),
        "student id" => I18n.t("student id"),
        "student sis id" => I18n.t("student sis id"),
        "assignment title" => I18n.t("assignment title"),
        "assignment id" => I18n.t("assignment id"),
        "submission date" => I18n.t("submission date"),
        "submission score" => I18n.t("submission score"),
        "learning outcome name" => I18n.t("learning outcome name"),
        "learning outcome id" => I18n.t("learning outcome id"),
        "attempt" => I18n.t("attempt"),
        "outcome score" => I18n.t("outcome score"),
        "course name" => I18n.t("course name"),
        "course id" => I18n.t("course id"),
        "course sis id" => I18n.t("course sis id"),
        "section name" => I18n.t("section name"),
        "section id" => I18n.t("section id"),
        "section sis id" => I18n.t("section sis id"),
        "assignment url" => I18n.t("assignment url"),
        "learning outcome friendly name" => I18n.t("learning outcome friendly name"),
        "learning outcome points possible" => I18n.t("learning outcome points possible"),
        "learning outcome mastery score" => I18n.t("learning outcome mastery score"),
        "learning outcome mastered" => I18n.t("learning outcome mastered"),
        "learning outcome rating" => I18n.t("learning outcome rating"),
        "learning outcome rating points" => I18n.t("learning outcome rating points"),
        "account id" => I18n.t("account id"),
        "account name" => I18n.t("account name"),
        "enrollment state" => I18n.t("enrollment state")
      }
    end

    # returns rows for each assignment that is linked to an outcome,
    # whether or not it has been submitted or graded
    def student_assignment_outcome_map
      write_outcomes_report(self.class.student_assignment_outcome_headers, student_assignment_outcome_map_scope)
    end

    def self.outcome_result_headers
      {
        "student name" => I18n.t("student name"),
        "student id" => I18n.t("student id"),
        "student sis id" => I18n.t("student sis id"),
        "assessment title" => I18n.t("assessment title"),
        "assessment id" => I18n.t("assessment id"),
        "assessment type" => I18n.t("assessment type"),
        "submission date" => I18n.t("submission date"),
        "submission score" => I18n.t("submission score"),
        "learning outcome name" => I18n.t("learning outcome name"),
        "learning outcome id" => I18n.t("learning outcome id"),
        "attempt" => I18n.t("attempt"),
        "outcome score" => I18n.t("outcome score"),
        "assessment question" => I18n.t("assessment question"),
        "assessment question id" => I18n.t("assessment question id"),
        "course name" => I18n.t("course name"),
        "course id" => I18n.t("course id"),
        "course sis id" => I18n.t("course sis id"),
        "section name" => I18n.t("section name"),
        "section id" => I18n.t("section id"),
        "section sis id" => I18n.t("section sis id"),
        "assignment url" => I18n.t("assignment url"),
        "learning outcome friendly name" => I18n.t("learning outcome friendly name"),
        "learning outcome points possible" => I18n.t("learning outcome points possible"),
        "learning outcome mastery score" => I18n.t("learning outcome mastery score"),
        "learning outcome mastered" => I18n.t("learning outcome mastered"),
        "learning outcome rating" => I18n.t("learning outcome rating"),
        "learning outcome rating points" => I18n.t("learning outcome rating points"),
        "account id" => I18n.t("account id"),
        "account name" => I18n.t("account name"),
        "enrollment state" => I18n.t("enrollment state")
      }
    end

    # returns rows for each assessed outcome result (or question result)
    def outcome_results
      # TODO: - Add this 3rd parameter as part of OUT-5167 and update write_outcomes_report to merge the two result sets
      # write_outcomes_report(self.class.outcome_result_headers, outcome_results_scope, outcomes_new_quiz_scope)
      write_outcomes_report(self.class.outcome_result_headers, outcome_results_scope)
    end

    private

    def student_assignment_outcome_map_scope
      parameters = {
        account_id: account.id,
        root_account_id: root_account.id
      }
      students = root_account.pseudonyms.except(:preload)
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
                               acct.name              AS "account name"
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

    def outcomes_new_quiz_scope
      students = account.learning_outcome_links.active
                        .select(<<~SQL.squish)
                          distinct on (#{outcome_order}, p.id, s.id, a.id)
                          u.sortable_name                             AS "student name",
                          u.uuid                                      AS "student uuid",
                          p.user_id                                   AS "student id",
                          p.sis_user_id                               AS "student sis id",
                          a.id                                        AS "assignment id",
                          a.title                                     AS "assessment title",
                          a.id                                        AS "assessment id",
                          learning_outcomes.short_description         AS "learning outcome name",
                          learning_outcomes.id                        AS "learning outcome id",
                          learning_outcomes.display_name              AS "learning outcome friendly name",
                          learning_outcomes.data                      AS "learning outcome data",
                          c.name                                      AS "course name",
                          c.id                                        AS "course id",
                          c.sis_source_id                             AS "course sis id",
                          'quiz'                                      AS "assessment type",
                          s.name                                      AS "section name",
                          s.id                                        AS "section id",
                          s.sis_source_id                             AS "section sis id",
                          e.workflow_state                            AS "enrollment state",
                          acct.id                                     AS "account id",
                          acct.name                                   AS "account name"
                        SQL
                        .joins(<<~SQL.squish)
                          INNER JOIN #{LearningOutcome.quoted_table_name} ON learning_outcomes.id = content_tags.content_id
                            AND content_tags.content_type = 'LearningOutcome'
                          INNER JOIN #{ContentTag.quoted_table_name} cct ON cct.content_id = content_tags.content_id AND cct.context_type = 'Course'
                          INNER JOIN #{Course.quoted_table_name} c ON cct.context_id = c.id
                          INNER JOIN #{Account.quoted_table_name} acct ON acct.id = c.account_id
                          INNER JOIN #{Enrollment.quoted_table_name} e ON e.type = 'StudentEnrollment' AND e.root_account_id = #{account.root_account.id}
                            AND e.course_id = c.id #{@include_deleted ? "" : "AND e.workflow_state <> 'deleted'"}
                          INNER JOIN #{User.quoted_table_name} u ON u.id = e.user_id
                          INNER JOIN #{Pseudonym.quoted_table_name} p on p.user_id = u.id
                          INNER JOIN #{CourseSection.quoted_table_name} s ON e.course_section_id = s.id
                          LEFT OUTER JOIN #{Assignment.quoted_table_name} a ON (a.context_id = c.id AND a.context_type = 'Course' AND a.submission_types = 'external_tool')
                        SQL

      unless @include_deleted
        students = students.where("p.workflow_state<>'deleted' AND c.workflow_state IN ('available', 'completed')")
      end

      students = join_course_sub_account_scope(account, students, "c")
      students = add_term_scope(students, "c")
      students.order(outcome_order)

      # We need to call the outcomes service once per course to get the authoritative results for each student. This
      # takes the results from the query above and transform it to a hash of course => (assignments, outcomes, students)
      # This hash will be used to call outcome service and the results from outcome service will be joined with the
      # results from the query.
      courses = {}
      students.each do |s|
        c_id = s["course id"]
        if courses.key?(c_id)
          course_map = courses[c_id]
          course_map[:assignment_ids].add(s["assignment id"])
          course_map[:outcome_ids].add(s["learning outcome id"])
          course_map[:uuids].add(s["student uuid"])
        else
          courses[c_id] = { course_id: c_id, assignment_ids: Set[s["assignment id"]], outcome_ids: Set[s["learning outcome id"]], uuids: Set[s["student uuid"]] }
        end
      end

      student_results = {}
      courses.each_value do |c|
        # There is no need to check if the feature flag :outcome_service_results_to_canvas is enabled for the
        # course because get_lmgb_results will return nil if it is not enabled
        course = Course.find(c[:course_id])
        assignment_ids = c[:assignment_ids].to_a.join(",")
        outcome_ids = c[:outcome_ids].to_a.join(",")
        uuids = c[:uuids].to_a.join(",")
        os_results = get_lmgb_results(course, assignment_ids, "canvas.assignment.quizzes", outcome_ids, uuids)
        next if os_results.nil?

        os_results.each do |r|
          composite_key = "#{c[:course_id]}_#{r["associated_asset_id"]}_#{r["external_outcome_id"]}_#{r["user_uuid"]}"
          if student_results.key?(composite_key)
            # This should not happen, but if it does we take the result that was submitted last.
            current_result = student_results[composite_key]
            if r["submitted_at"] > current_result["submitted_at"]
              student_results[composite_key] = r
            end
          else
            student_results[composite_key] = r
          end
        end
      end

      # TODO: - We are not .where("ct.workflow_state <> 'deleted' AND r.workflow_state <> 'deleted' AND r.artifact_type <> 'Submission'")
      #        - The artifact type is 'quizzes.quiz'
      # If there is not an entry in student_results, the student hasn't taken teh quiz yet and does not need to
      # be in the report.
      students.filter_map do |s|
        composite_key = "#{s["course id"]}_#{s["assignment id"]}_#{s["learning outcome id"]}_#{s["student uuid"]}"
        student_results.key?(composite_key) ? combine_result(s, student_results[composite_key]) : nil
      end
    end

    # TODO: - This method will be fully implemented as part of OUT-5167
    def combine_result(student, authoritative_results)
      student.attributes.merge(
        {
          "assessment title" => "",
          "assessment id" => authoritative_results["submitted_at"], # TODO: Should this be question id or quiz id?
          "submission date" => authoritative_results["submitted_at"],
          "submission score" => "",
          "assessment question" => "",
          "assessment question id" => "",
          "learning outcome points possible" => authoritative_results["points_possible"],
          "learning outcome mastered" => authoritative_results["mastery"],
          "attempt" => "", # TODO: do we need the most recent attempt.
          "learning outcome points hidden" => nil, # TODO: hide_points is a column on AR, but not populated
          "outcome score" => authoritative_results["points"], # TODO: is this the same as qr.score or r.score?
          "total percent outcome score" => authoritative_results["percent_score"]
        }
      )
    end

    def outcome_results_scope
      students = account.learning_outcome_links.active
                        .select(<<~SQL.squish)
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
                          r.percent                                   AS "total percent outcome score",
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
                        SQL
                        .joins(<<~SQL.squish)
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
                            #{@include_deleted ? "" : "AND e.workflow_state <> 'deleted'"}
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
                        SQL
                        .where("ct.workflow_state <> 'deleted' AND r.workflow_state <> 'deleted' AND r.artifact_type <> 'Submission'")

      unless @include_deleted
        students = students.where("p.workflow_state<>'deleted' AND c.workflow_state IN ('available', 'completed')")
      end

      students = join_course_sub_account_scope(account, students, "c")
      students = add_term_scope(students, "c")
      students.order(outcome_order)
    end

    def outcome_order
      param = @account_report.value_for_param("order")
      param = param.downcase if param
      order_options = %w[users courses outcomes]
      select = order_options & [param]

      order_sql = { "users" => "u.id, learning_outcomes.id, c.id",
                    "courses" => "c.id, u.id, learning_outcomes.id",
                    "outcomes" => "learning_outcomes.id, u.id, c.id" }
      if select.length == 1
        order = order_sql[select.first]
        add_extra_text(I18n.t("account_reports.outcomes.order",
                              "Order: %{order}", order: select.first))
      else
        order = "u.id, learning_outcomes.id, c.id"
      end
      order
    end

    def join_course_sub_account_scope(account, scope, table = "courses")
      if account == account.root_account
        scope
      else
        scope.joins(<<~SQL.squish)
          join #{CourseAccountAssociation.quoted_table_name} caa
            ON caa.account_id = #{account.id}
            AND caa.course_id = #{table}.id
            AND caa.course_section_id IS NULL
        SQL
      end
    end

    def write_outcomes_report(headers, scope, config_options = {})
      config_options[:empty_scope_message] ||= "No outcomes found"
      header_keys = headers.keys
      header_names = headers.values
      host = root_account.domain
      enable_i18n_features = true

      write_report header_names, enable_i18n_features do |csv|
        total = scope.length
        GuardRail.activate(:primary) { AccountReport.where(id: @account_report.id).update_all(total_lines: total) }
        scope.each do |row|
          row = row.attributes.dup

          row["assignment url"] = "https://#{host}" \
                                  "/courses/#{row["course id"]}" \
                                  "/assignments/#{row["assignment id"]}"
          row["submission date"] = default_timezone_format(row["submission date"])
          add_outcomes_data(row)
          csv << header_keys.map { |h| row[h] }
        end
        csv << [config_options[:empty_scope_message]] if total == 0
      end
    end

    def proficiency(course)
      result = {}
      proficiency = course.resolved_outcome_proficiency
      ratings = proficiency_ratings(proficiency)
      result[:mastery_points] = ratings.find { |rating| rating[:mastery] }[:points]
      result[:points_possible] = ratings.first[:points]
      result[:ratings] = ratings
      result
    end

    def proficiency_ratings(proficiency)
      proficiency.outcome_proficiency_ratings.map do |rating_obj|
        convert_rating(rating_obj)
      end
    end

    def convert_rating(rating_obj)
      {
        description: rating_obj.description,
        points: rating_obj.points,
        mastery: rating_obj.mastery
      }
    end

    def set_score(row, outcome_data)
      total_percent = row["total percent outcome score"]
      if total_percent.present?
        points_possible = outcome_data[:points_possible]
        points_possible = outcome_data[:mastery_points] if points_possible.zero?
        score = points_possible * total_percent
      else
        score = if row["outcome score"].nil? || row["learning outcome points possible"].nil?
                  nil
                else
                  (row["outcome score"] / row["learning outcome points possible"]) * outcome_data[:points_possible]
                end
      end
      score
    end

    def set_rating(row, score, outcome_data)
      ratings = outcome_data[:ratings]&.sort_by { |r| r[:points] }&.reverse || []
      rating = ratings.detect { |r| r[:points] <= score } || {}
      row["learning outcome rating"] = rating[:description]
      rating
    end

    def hide_points(row)
      row["outcome score"] = nil
      row["learning outcome rating points"] = nil
      row["learning outcome points possible"] = nil
      row["learning outcome mastery score"] = nil
    end

    def add_outcomes_data(row)
      row["learning outcome mastered"] = unless row["learning outcome mastered"].nil?
                                           row["learning outcome mastered"] ? 1 : 0
                                         end

      course = Course.find(row["course id"])
      outcome_data = if @account_report.account.root_account.feature_enabled?(:account_level_mastery_scales) && course.resolved_outcome_proficiency.present?
                       proficiency(course)
                     elsif row["learning outcome data"].present?
                       YAML.safe_load(row["learning outcome data"])[:rubric_criterion]
                     else
                       LearningOutcome.default_rubric_criterion
                     end
      row["learning outcome mastery score"] = outcome_data[:mastery_points]
      score = set_score(row, outcome_data)
      rating = set_rating(row, score, outcome_data) if score.present?
      if row["assessment type"] != "quiz" && @account_report.account.root_account.feature_enabled?(:account_level_mastery_scales)
        row["learning outcome points possible"] = outcome_data[:points_possible]
      end
      if row["learning outcome points hidden"]
        hide_points(row)
      elsif rating.present?
        row["learning outcome rating points"] = rating[:points]
      end
    end
  end
end
