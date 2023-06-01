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
    JSON_FIELDS = %i[
      id
      grade
      score
      submitted_at
      assignment_id
      user_id
      submission_type
      workflow_state
      updated_at
      grade_matches_current_submission
      graded_at
      turnitin_data
      excused
      points_deducted
      grading_period_id
      late
      missing
      url
    ].freeze

    def initialize(assignment, user, prioritize_non_tool_grade: false, needs_additional_review: false)
      @assignment = assignment
      @user = user
      @prioritize_non_tool_grade = prioritize_non_tool_grade
      @needs_additional_review = needs_additional_review
    end

    def active?
      !submission.deleted?
    end

    def commit_history(launch_url, grade, grader_id)
      return true if grading_period_closed?
      return false unless valid?(launch_url, grade)

      attempt = attempt_history_by_key(launch_url)
      grade, score = @assignment.compute_grade_and_score(grade, nil)
      # if score is not changed, stop creating a new version
      return true if attempt.present? &&
                     score_equal?(score, grade, launch_url) &&
                     # Don't return without creating a new version
                     # if a grader just completed manually scoring
                     # all quiz items that required additional review
                     !additional_review_complete?(submission)

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
        (last[:score].blank? && last[:workflow_state] != "graded") ? nil : last
      end
      @_grade_history = attempts.compact
    end

    private

    def workflow_state_for(submission_record)
      # Quizzes indicated the quiz session contains items that are not auto-
      # gradable. Set workflow state to pending_review to indicate manual
      # grading is needed
      return Submission.workflow_states.pending_review if @needs_additional_review

      # The submission previously was in a pending_review state, but all
      # items that required manual grading have been scored. Set workflow_state
      # to submitted and let the Submission#inferred_workflow_state method handle
      # selecting the correct state
      return Submission.workflow_states.submitted if additional_review_complete?(submission_record)

      submission_record.workflow_state
    end

    def additional_review_complete?(submission_record)
      !@needs_additional_review && submission_record.pending_review?
    end

    def score_equal?(score2, grade2, launch_url)
      # equal for float type
      # assume users don't care score diff of 0.000001
      score1 = submission.score
      grade1 = submission.grade
      score_equal = (score1.nil? && score2.nil?) || (score1.present? && score2.present? && (score1 - score2).abs < 0.000001)
      score_equal && (grade1 == grade2) && submission.url == launch_url
    end

    def grading_period_closed?
      !!submission.grading_period&.closed?
    end

    def valid?(launch_url, grade)
      launch_url.present? && grade.present?
    end

    def params
      @_params ||= {}
    end

    def save_submission!(launch_url, grade, score, grader_id)
      initialize_version

      if new_submission?(launch_url)
        initialize_submission

        # it will notify students with 'Assignment Submitted' *or* 'Assignment Resubmitted' notification
        # see SubmissionPolicy#should_dispatch_assignment_submitted? and SubmissionPolicy#should_dispatch_assignment_resubmitted?
        save_without_versioning

        grade_submission(launch_url, grade, score, grader_id)

        # at this point the submission is ready to be versioned
        save_with_versioning
      else
        # teacher regrading only, it won't notify students with 'Assignment Submitted' and 'Assignment Resubmitted' notifications
        grade_submission(launch_url, grade, score, grader_id)
        submission.save!
      end
    end

    # create a padding unsubmitted version for reopen request
    def initialize_version
      return if submission.versions.present?

      save_with_versioning
    end

    def initialize_submission
      submission.submission_type = params[:submission_type] || "basic_lti_launch"
      submission.submitted_at = params[:submitted_at] || Time.zone.now
      submission.graded_at = params[:graded_at] || Time.zone.now
      submission.grade_matches_current_submission = false
      # this step is important to send user notifications
      # see SubmissionPolicy
      submission.workflow_state = "submitted"
    end

    def grade_submission(launch_url, grade, score, grader_id)
      BasicOutcomes::LtiResponse.ensure_score_update_possible(submission:, prioritize_non_tool_grade: prioritize_non_tool_grade?) do
        submission.grade = grade
        submission.score = score
        submission.graded_at = params[:graded_at] || Time.zone.now
        submission.grade_matches_current_submission = true
        submission.grader_id = grader_id
        submission.posted_at = submission.submitted_at unless submission.posted? || @assignment.post_manually?
        submission.workflow_state = workflow_state_for(submission)
      end
      clear_cache
      # We always want to update the launch_url to match what new quizzes is laying down.
      submission.url = launch_url
    end

    def save_with_versioning
      submission.with_versioning(explicit: true) { submission.save! }
    end

    def save_without_versioning
      submission.without_versioning(&:save!)
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
          matches = k.match(/\?.*=(\d+)&/)
          next 0 if matches.blank?

          matches.captures.first.to_i # ordered by the first lti parameter
        end
        sorted_list.index_with { |k| attempts[k] }
      end
    end

    def prioritize_non_tool_grade?
      @prioritize_non_tool_grade
    end

    def new_submission?(launch_url)
      submission.url != launch_url
    end
  end
end
