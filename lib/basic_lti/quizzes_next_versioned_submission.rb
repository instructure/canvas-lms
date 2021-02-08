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
  class QuizzesNextVersionedSubmission
    JSON_FIELDS = [
      :id, :grade, :score, :submitted_at, :assignment_id,
      :user_id, :submission_type, :workflow_state, :updated_at,
      :grade_matches_current_submission, :graded_at, :turnitin_data,
      :excused, :points_deducted, :grading_period_id, :late, :missing, :url
    ].freeze

    def initialize(assignment, user)
      @assignment = assignment
      @user = user
    end

    def commit_history(launch_url, grade, grader_id)
      return true if grading_period_closed?
      return false unless valid?(launch_url, grade)

      attempt = attempt_history_by_key(launch_url)
      grade, score = @assignment.compute_grade_and_score(grade, nil)
      # if score is not changed, stop creating a new version
      return true if attempt.present? &&
        score_equal?(score, grade, launch_url)
      save_submission!(launch_url, grade, score, grader_id)
      true
    end

    def revert_history(launch_url, grader_id)
      reverter = QuizzesNextSubmissionReverter.new(submission, launch_url, grader_id)
      reverter.revert_attempt
    end

    def with_params(params_hash)
      params.merge!(params_hash)
      self
    end

    def grade_history
      return @_grade_history unless @_grade_history.nil?
      # attempt submitted time should be submitted_at from the first version
      attempts = attempts_history.map do |attempt|
        last = attempt.last
        first = attempt.first
        last[:submitted_at] = first[:submitted_at]
        last[:score].blank? ? nil : last
      end
      @_grade_history = attempts.compact
    end

    private

    def score_equal?(score2, grade2, launch_url)
      # equal for float type
      # assume users don't care score diff of 0.000001
      score1 = submission.score
      grade1 = submission.grade
      score_equal = (score1.nil? && score2.nil?) || (score1.present? && score2.present? && (score1 - score2).abs < 0.000001)
      score_equal && (grade1 == grade2) && submission.url == launch_url
    end

    def grading_period_closed?
      !!(submission.grading_period&.closed?)
    end

    def valid?(launch_url, grade)
      launch_url.present? && grade.present?
    end

    def params
      @_params ||= {}
    end

    def save_submission!(launch_url, grade, score, grader_id)
      initialize_version
      with_versioning(launch_url) do |is_different_attempt|
        # Don't "resubmit" the submission if this is just a regrade
        submit_submission if is_different_attempt
        grade_submission(launch_url, grade, score, grader_id)
      end
    end

    def initialize_version
      return if submission.versions.present?
      # create a padding unsubmitted version for reopen request
      save_with_versioning
    end

    def with_versioning(launch_url)
      is_initial_unsubmitted_version = submission.versions.count == 1 && submission.submitted_at.blank?
      is_updatable_nil_version = !is_initial_unsubmitted_version && submission.submitted_at.blank?
      is_different_attempt = submission.url != launch_url
      # create a new version if the open (last) version is another attempt
      #   and the open version is not a nil version (excluding the first padding)

      save_with_versioning if !is_updatable_nil_version && is_different_attempt
      yield is_different_attempt
    end

    def submit_submission
      submission.submission_type = params[:submission_type] || 'basic_lti_launch'
      submission.submitted_at = params[:submitted_at] || Time.zone.now
      submission.graded_at = params[:graded_at] || Time.zone.now
      submission.grade_matches_current_submission = false
      # this step is important, to send user notifications
      # see SubmissionPolicy
      submission.workflow_state = 'submitted'
      submission.without_versioning(&:save!)
    end

    def grade_submission(launch_url, grade, score, grader_id)
      submission.grade = grade
      submission.score = score
      submission.graded_at = params[:graded_at] || Time.zone.now
      submission.grade_matches_current_submission = true
      submission.grader_id = grader_id
      submission.posted_at = submission.submitted_at unless submission.posted? || @assignment.post_manually?
      clear_cache
      submission.url = launch_url
      submission.save!
    end

    def save_with_versioning
      submission.with_versioning(:explicit => true) { submission.save! }
    end

    def clear_cache
      @_attempts_hash = nil
      @_attempts_history = nil
      @_grade_history = nil
    end

    def attempt_history_by_key(url)
      attempts_hash[url]
    end

    def submission
      @_submission ||=
        Submission.find_or_initialize_by(assignment: @assignment, user: @user)
    end

    def attempts_history
      @_attempts_history ||= attempts_hash.values
    end

    def attempts_hash
      @_attempts_hash ||= begin
        attempts = submission.versions.sort_by(&:created_at).each_with_object({}) do |v, a|
          h = YAML.safe_load(v.yaml).with_indifferent_access
          url = v.model.url
          next if url.blank? # exclude invalid versions (url is actual attempt identifier)
          h[:url] = url
          (a[url] = (a[url] || [])) << h.slice(*JSON_FIELDS)
        end

        # ruby hash will perserve insertion order
        sorted_list = attempts.keys.sort_by do |k|
          matches = k.match(/\?.*=(\d+)\&/)
          next 0 if matches.blank?
          matches.captures.first.to_i # ordered by the first lti parameter
        end
        sorted_list.each_with_object({}) { |k, a| a[k] = attempts[k] }
      end
    end
  end
end
