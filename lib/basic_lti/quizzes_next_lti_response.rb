# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module BasicLTI
  class QuizzesNextLtiResponse < BasicLTI::BasicOutcomes::LtiResponse
    protected

    # this is an override of parent method
    def handle_replace_result(tool, assignment, user)
      self.body = "<replaceResultResponse />"

      assignment.ensure_points_possible!

      return true unless valid_request?(assignment)

      quiz_lti_submission = QuizzesNextVersionedSubmission.new(
        assignment,
        user,
        prioritize_non_tool_grade: prioritize_non_tool_grade?,
        needs_additional_review: needs_additional_review?
      )

      quiz_lti_submission = quiz_lti_submission
                            .with_params(
                              submission_type: "basic_lti_launch",
                              submitted_at: submitted_at_date,
                              graded_at: graded_at_date
                            )

      unless quiz_lti_submission.active?
        return report_failure(:submission_deleted, I18n.t("Submission is deleted and cannot be modified."))
      end

      if submission_reopened?
        return begin
          quiz_lti_submission.revert_history(result_url, -tool.id)
        rescue ActiveRecord::RecordInvalid => e
          report_failure(:submission_revert_failed, e.record.errors.full_messages.join(", "))
        end
      end

      begin
        quiz_lti_submission.commit_history(result_url, grade(assignment.grading_type), -tool.id)
      rescue ActiveRecord::RecordInvalid => e
        report_failure(:submission_save_failed, e.record.errors.full_messages.join(", "))
      end
    end

    private

    # this is an override of parent method
    def request_type
      :quizzes
    end

    def report_failure(code, message)
      self.code_major = "failure"
      self.description = message
      self.error_code = code
      true # signals to caller that request has been handled successfully
    end

    def result_url
      result_data_launch_url || result_data_url
    end

    def submitted_at_date
      submitted_at = submission_submitted_at
      submitted_at.present? ? Time.zone.parse(submitted_at) : nil
    end

    def graded_at_date
      graded_at = result_data_text_json&.dig(:graded_at)
      graded_at.present? ? Time.zone.parse(graded_at) : nil
    end

    def result_data_text_json
      return nil if result_data_text.blank?

      json = JSON.parse(result_data_text)
      json.with_indifferent_access
    rescue JSON::ParserError
      nil
    end

    def submission_reopened?
      json = result_data_text_json
      return false if json.blank?

      json[:reopened]
    end

    def grade(grading_type)
      return (((raw_score || percentage_score) > 0) ? "pass" : "fail") if grading_type == "pass_fail" && (raw_score || percentage_score)
      return raw_score if raw_score.present?
      return nil unless valid_percentage_score?

      "#{round_if_whole(percentage_score * 100)}%"
    end

    def raw_score
      Float(result_total_score)
    rescue
      nil
    end

    def percentage_score
      Float(result_score)
    rescue
      nil
    end

    def valid_request?(assignment)
      valid_score? && valid_points_possible?(assignment)
    end

    def valid_score?
      # don't check score for reopen requests
      return true if submission_reopened?

      if raw_score.blank? && percentage_score.blank?
        report_failure(:no_score, I18n.t("lib.basic_lti.no_score", "No score given"))
        return false
      end
      return true if raw_score.present?

      valid_percentage_score?
    end

    def valid_percentage_score?
      return false if percentage_score.blank?

      unless (0.0..1.0).cover?(percentage_score)
        report_failure(:bad_score, I18n.t("lib.basic_lti.bad_score", "Score is not between 0 and 1"))
        return false
      end
      true
    end

    def valid_points_possible?(assignment)
      # Any time an assignment has points_possible, we can handle
      # submiting a score to it
      return true if assignment.points_possible.present?

      # Additinally, we can handle interpreting the score for the tool
      # as a pass/fail score
      return true if assignment.grading_type == "pass_fail"

      # We don't know how to give a score for the assignment's combination of grading_type and points_possible
      report_failure(:no_points_possible, I18n.t("lib.basic_lti.no_points_possible", "Assignment has no points possible."))
      false
    end
  end
end
