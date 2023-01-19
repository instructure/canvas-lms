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
    ORDER_OPTIONS = %w[users courses outcomes].freeze
    ORDER_SQL = { "users" => "u.id, learning_outcomes.id, c.id",
                  "courses" => "c.id, u.id, learning_outcomes.id",
                  "outcomes" => "learning_outcomes.id, u.id, c.id" }.freeze
    include ReportHelper
    include CanvasOutcomesHelper
    include OutcomesServiceAuthoritativeResultsHelper

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
      # Add text to the report description if user supplied ordering parameter
      add_outcome_order_text
      config_options = { new_quizzes_scope: outcomes_new_quiz_scope }
      write_outcomes_report(self.class.outcome_result_headers, outcome_results_scope, config_options)
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
      return [] unless account.feature_enabled?(:outcome_service_results_to_canvas)

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
                          subs.submitted_at                           AS "submission date",
                          subs.score                                  AS "submission score",
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
                          LEFT OUTER JOIN #{Assignment.quoted_table_name} a ON (a.context_id = c.id AND a.context_type = 'Course'
                           AND a.submission_types = 'external_tool' AND a.workflow_state <> 'deleted')
                          LEFT OUTER JOIN #{Submission.quoted_table_name} subs ON subs.assignment_id = a.id
                           AND subs.user_id = u.id AND subs.workflow_state <> 'deleted' AND subs.workflow_state <> 'unsubmitted'
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
          composite_key = "#{c[:course_id]}_#{r[:associated_asset_id]}_#{r[:external_outcome_id]}_#{r[:user_uuid]}"
          if student_results.key?(composite_key)
            # This should not happen, but if it does we take the result that was submitted last.
            current_result = student_results[composite_key]
            if r[:submitted_at] > current_result[:submitted_at]
              student_results[composite_key] = r
            end
          else
            student_results[composite_key] = r
          end
        end
      end

      # If there is not an entry in student_results, the student hasn't taken the quiz yet and does not need to
      # be in the report.
      results = []
      students.each do |s|
        composite_key = "#{s["course id"]}_#{s["assignment id"]}_#{s["learning outcome id"]}_#{s["student uuid"]}"
        results.concat(combine_result(s, student_results[composite_key])) if student_results.key?(composite_key)
      end
      results
    end

    def combine_result(student, authoritative_results)
      learning_outcome_result = convert_to_learning_outcome_result(authoritative_results)
      base_student = student.attributes.merge(
        {
          "learning outcome mastered" => learning_outcome_result.mastery,
          "learning outcome points hidden" => nil, # TODO: hide_points is a column on AR, but not populated
          "total percent outcome score" => learning_outcome_result.percent,

          # If the outcome is aligned with individual questions, these values will be overwritten by
          # data on the attempt meta data
          "learning outcome points possible" => learning_outcome_result.possible,
          "outcome score" => learning_outcome_result.score,

          # We only care about the most recent attempt. The attempt column is equal to number of attempts
          "attempt" => authoritative_results[:attempts]&.length
        }
      )

      # If there are no attempts, do not include the result in the report. If there are multiple attempts, we only
      # include the most recent one in the report. To determine the most recent attempt, we use the submitted_At
      # attribute, but historically, that field was not populated in outcome service. We will use it if we have it,
      # but if it is missing, we will fallback to created_at. Using the created_at is technically not correct, but
      # is the better than nothing. submitted
      results = []
      attempt = authoritative_results[:attempts]&.max_by { |a| a[:submitted_at] || a[:created_at] }
      return results if attempt.nil?

      meta_data = attempt[:metadata]
      if meta_data.nil?
        results.push(base_student)
      else
        question_metadata = meta_data[:question_metadata]

        # Assessment title and id are populated from the canvas Assignment record. In the future, we can get this from
        # the quiz_metadata on the attempt. If/When we do this, we will need to change the metadata format of the quiz
        # to always include quiz id and title. See comment on https://instructure.atlassian.net/browse/OUT-5292
        if question_metadata.blank?
          results.push(base_student)
        else
          question_metadata.each do |question|
            question_row = base_student.clone
            learning_outcome_question_result = metadata_to_outcome_question_result(
              learning_outcome_result,
              question,
              question_row["attempt"]
            )

            question_row["assessment question id"] = question[:quiz_item_id]
            question_row["assessment question"] = question[:quiz_item_title]
            question_row["learning outcome points possible"] = learning_outcome_question_result.possible
            question_row["outcome score"] = learning_outcome_question_result.score
            question_row["learning outcome mastered"] = learning_outcome_question_result.mastery

            # We do not want to set the "total percent outcome score" to learning_outcome_question_result.percent
            # because that is the percentage the student got on the individual question. "total percent outcome score"
            # was set based of learning_outcome_result.percent (see above), which takes into account all the questions
            # aligned with this same outcome. "total percent outcome score" is what is used to determine
            # "learning outcome rating" and "learning outcome rating points". This is weird because
            # "learning outcome mastered" is set based off the learning_outcome_question_result.mastery, so
            # it's possible for "learning outcome mastered" to be 0, but "learning outcome mastered" to
            # be "Exceeds Mastery". The reason for this behavior is to mimic what is in the existing report. In the
            # future we will reevaluate what columns are in this report.
            results.push(question_row)
          end
        end
      end
      results
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

    def determine_order_key
      param = @account_report.value_for_param("order")
      param = param.downcase if param
      select = ORDER_OPTIONS & [param]
      select.first if select.length == 1
    end

    def add_outcome_order_text
      order = determine_order_key
      if order
        add_extra_text(I18n.t("account_reports.outcomes.order", "Order: %{order}", order: order))
      end
    end

    def outcome_order
      order_key = determine_order_key
      order = "u.id, learning_outcomes.id, c.id"
      order = ORDER_SQL[order_key] if order_key
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

    def map_order_to_columns(outcome_order)
      column_mapping = { "u.id" => "student id",
                         "c.id" => "course id",
                         "learning_outcomes.id" => "learning outcome id" }
      outcome_order.split(",").map do |x|
        column_mapping[x.strip]
      end
    end

    def canvas_next?(canvas_scope, canvas_index, os_scope, os_index)
      return false if canvas_index >= canvas_scope.length
      return true if os_index >= os_scope.length

      order = map_order_to_columns(outcome_order)

      canvas = canvas_scope[canvas_index]
      os = os_scope[os_index]
      order.each do |column|
        if canvas[column] != os[column]
          return canvas[column] < os[column]
        end
      end
      # default is to return true causing canvas data to appear before OS data
      # we will only default to this if all the oder columns are equal
      true
    end

    def write_outcomes_report(headers, canvas_scope, config_options = {})
      config_options[:empty_scope_message] ||= "No outcomes found"
      config_options[:new_quizzes_scope] ||= []
      header_keys = headers.keys
      header_names = headers.values
      host = root_account.domain
      enable_i18n_features = true

      os_scope = config_options[:new_quizzes_scope]

      write_report header_names, enable_i18n_features do |csv|
        total = canvas_scope.length + os_scope.length
        GuardRail.activate(:primary) { AccountReport.where(id: @account_report.id).update_all(total_lines: total) }

        canvas_index = 0
        os_index = 0
        while canvas_index < canvas_scope.length || os_index < os_scope.length
          if canvas_next?(canvas_scope, canvas_index, os_scope, os_index)
            row = canvas_scope[canvas_index].attributes.dup
            canvas_index += 1
          else
            row = os_scope[os_index]
            os_index += 1
          end

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
