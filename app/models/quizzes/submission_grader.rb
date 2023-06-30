# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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
module Quizzes
  class SubmissionGrader
    class AlreadyGradedError < RuntimeError; end

    def initialize(submission)
      @submission = submission
    end

    def grade_submission(opts = {})
      if @submission.submission_data.is_a?(Array)
        raise(AlreadyGradedError, "Can't grade an already-submitted submission: #{@submission.workflow_state} #{@submission.submission_data.class}")
      end

      @submission.manually_scored = false
      tally = 0
      user_answers = []
      data = @submission.submission_data || {}
      @submission.questions.each do |q|
        user_answer = self.class.score_question(q, data)
        user_answers << user_answer
        tally += (user_answer[:points] || 0).to_d if user_answer[:correct]
      end
      @submission.score = tally.to_d
      @submission.score = @submission.quiz.points_possible if @submission&.quiz&.graded_survey?
      @submission.submission_data = user_answers
      @submission.workflow_state = "complete"
      user_answers.each do |answer|
        if answer[:correct] == "undefined" && !@submission.quiz.survey?
          @submission.workflow_state = "pending_review"
        end
      end
      @submission.score_before_regrade = nil
      @submission.manually_unlocked = nil
      @submission.finished_at ||= opts[:finished_at] || Time.zone.now
      if @submission.quiz.for_assignment? && @submission.user_id
        assignment_submission = @submission.assignment.find_or_create_submission(@submission.user_id)
        @submission.submission = assignment_submission
      end
      @submission.with_versioning(true) do |s|
        original_score = s.kept_score
        original_workflow_state = s.workflow_state
        if s.save && outcomes_require_update(s, original_score, original_workflow_state)
          track_outcomes(s.attempt)
        end
      end
      @submission.context_module_action
      quiz = @submission.quiz
      previous_version = quiz.versions.where(number: @submission.quiz_version).first
      if previous_version && @submission.quiz_version != quiz.version_number
        quiz = previous_version.model.reload
      end

      # let's just write the options here in case we decide to do individual
      # submissions asynchronously later.
      options = {
        quiz:,
        # Leave version_number out for now as we may be passing the version
        # and we're not starting it as a delayed job
        # version_number: quiz.version_number,
        submissions: [@submission]
      }
      Quizzes::QuizRegrader::Regrader.regrade!(options)
    end

    def self.score_question(question, params)
      params = params.with_indifferent_access
      # TODO: undefined_if_blank - we need a better solution for the
      # following problem: since teachers can modify quizzes after students
      # have submitted (we warn them not to, but it is possible) we need
      # a good way to mark questions as needing attention for past submissions.
      # If a student already took the quiz and then a new question gets
      # added or the question answer they selected goes away, then the
      # the teacher gets the added burden of going back and manually assigning
      # scores for these questions per student.
      qq = Quizzes::QuizQuestion::Base.from_question_data(question)

      user_answer = qq.score_question(params)
      result = {
        correct: user_answer.correctness,
        points: user_answer.score,
        question_id: user_answer.question_id,
      }
      result[:answer_id] = user_answer.answer_id if user_answer.answer_id
      result.merge!(user_answer.answer_details)
      result
    end

    def outcomes_require_update(submission, original_score, original_workflow_state)
      submission.quiz.assignment? && kept_score_updating?(original_score, original_workflow_state)
    end

    def track_outcomes(attempt)
      return unless @submission.user_id

      versioned_submission = versioned_submission(@submission, attempt)
      question_ids = (versioned_submission&.quiz_data || []).filter_map { |q| q[:assessment_question_id] }.uniq
      questions, alignments = questions_and_alignments(question_ids)
      return if questions.empty? || alignments.empty?

      tagged_bank_ids = Set.new(alignments.map(&:content_id))
      question_ids = questions.select { |q| tagged_bank_ids.include?(q.assessment_question_bank_id) }
      delay_if_production.update_outcomes(question_ids, @submission.id, attempt) unless question_ids.empty?
    end

    def update_outcomes(question_ids, submission_id, attempt)
      questions, alignments = questions_and_alignments(question_ids)
      return if questions.empty? || alignments.empty?

      submission = Quizzes::QuizSubmission.find(submission_id)

      versioned_submission = versioned_submission(submission, attempt)
      builder = Quizzes::QuizOutcomeResultBuilder.new(versioned_submission)
      builder.build_outcome_results(questions, alignments)
    end

    private

    def versioned_submission(submission, attempt)
      (submission.attempt == attempt) ? submission : submission.versions.sort_by(&:created_at).map(&:model).reverse.detect { |s| s.attempt == attempt }
    end

    def kept_score_updating?(original_score, original_workflow_state)
      # three scoring policies exist, highest, latest, and avg.
      # for the latter two, the kept score is always updating and
      # we'll need this method to return true. if the method is highest,
      # the kept score only updates if it's higher than the original score
      # UNLESS the grade is updated via speedgrader.
      quiz = @submission.quiz

      # if the update is performed via speedgrader and the scoring policy is keep_highest
      # the method should return true. The current workflow state will be complete
      # and a submission grader_id will be present on the submission.
      return true if quiz.scoring_policy == "keep_highest" && @submission.grader_id.present? && @submission.workflow_state == "complete"

      return true if quiz.scoring_policy != "keep_highest" || quiz.points_possible.to_i == 0 || original_score.nil?
      # when a submission is pending review, no outcome results are generated.
      # if the submission transitions to completed, then we need this method
      # to return true, even if the kept score isn't changing, so outcome results are generated.
      return true if original_workflow_state == "pending_review" && @submission.workflow_state == "complete"

      @submission.kept_score && @submission.kept_score > original_score
    end

    def questions_and_alignments(question_ids)
      return [], [] if question_ids.empty?

      questions = AssessmentQuestion.where(id: question_ids).to_a
      bank_ids = questions.map(&:assessment_question_bank_id).uniq
      return questions, [] if bank_ids.empty?

      # equivalent to AssessmentQuestionBank#learning_outcome_alignments, but for multiple banks at once
      [questions,
       ContentTag.learning_outcome_alignments.active.where(
         content_type: "AssessmentQuestionBank",
         content_id: bank_ids
       )
                 .preload(:learning_outcome, :context).to_a]
    end
  end
end
