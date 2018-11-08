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
    # rubocop:disable Naming/MethodName
    def handle_replaceResult(tool, _course, assignment, user)
      self.body = "<replaceResultResponse />"
      return true unless valid_request?(assignment)

      quiz_lti_submission = QuizzesNextVersionedSubmission.new(assignment, user)
      quiz_lti_submission.
        with_params(
          submission_type: 'basic_lti_launch',
          submitted_at: submitted_at_date
        ).
        commit_history(result_data_launch_url, grade, -tool.id)
    end
    # rubocop:enable Naming/MethodName

    private

    def error_message(message)
      self.code_major = 'failure'
      self.description = message
    end

    def submitted_at_date
      return nil if submission_submitted_at.blank?
      @_submitted_at_date ||= Time.zone.parse(submission_submitted_at)
    end

    def grade
      return raw_score if raw_score.present?
      return nil unless valid_percentage_score?
      "#{round_if_whole(percentage_score * 100)}%"
    end

    def raw_score
      Float(self.result_total_score)
    rescue
      nil
    end

    def percentage_score
      Float(self.result_score)
    rescue
      nil
    end

    def valid_request?(assignment)
      valid_score? && valid_points_possible?(assignment)
    end

    def valid_score?
      if raw_score.blank? && percentage_score.blank?
        error_message(I18n.t('lib.basic_lti.no_score', "No score given"))
        return false
      end
      return true if raw_score.present?
      valid_percentage_score?
    end

    def valid_percentage_score?
      return false if percentage_score.blank?
      unless (0.0..1.0).cover?(percentage_score)
        error_message(I18n.t('lib.basic_lti.bad_score', "Score is not between 0 and 1"))
        return false
      end
      true
    end

    def valid_points_possible?(assignment)
      return true if assignment.grading_type == "pass_fail" || assignment.points_possible.present?
      error_message(I18n.t('lib.basic_lti.no_points_possible', 'Assignment has no points possible.'))
      false
    end
  end
end
