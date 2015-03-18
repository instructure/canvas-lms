module Quizzes
  class SubmissionGrader
    class AlreadyGradedError < RuntimeError; end
    def initialize(submission)
      @submission = submission
    end

    def grade_submission(opts={})
      if @submission.submission_data.is_a?(Array)
        raise(AlreadyGradedError,"Can't grade an already-submitted submission: #{@submission.workflow_state} #{@submission.submission_data.class.to_s}")
      end
      @submission.manually_scored = false
      tally = 0
      user_answers = []
      data = @submission.submission_data || {}
      @submission.questions_as_object.each do |q|
        user_answer = self.class.score_question(q, data)
        user_answers << user_answer
        tally += (user_answer[:points] || 0) if user_answer[:correct]
      end
      @submission.score = tally
      @submission.score = @submission.quiz.points_possible if @submission.quiz && @submission.quiz.graded_survey?
      @submission.submission_data = user_answers
      @submission.workflow_state = "complete"
      user_answers.each do |answer|
        if answer[:correct] == "undefined" && !@submission.quiz.survey?
          @submission.workflow_state = 'pending_review'
        end
      end
      @submission.score_before_regrade = nil
      @submission.finished_at = Time.now
      @submission.manually_unlocked = nil
      @submission.finished_at = opts[:finished_at] if opts[:finished_at]
      if @submission.quiz.for_assignment? && @submission.user_id
        assignment_submission = @submission.assignment.find_or_create_submission(@submission.user_id)
        @submission.submission = assignment_submission
      end
      @submission.with_versioning(true) do |s|
        s.save
      end
      @submission.context_module_action
      track_outcomes(@submission.attempt)
      quiz = @submission.quiz
      previous_version = quiz.versions.where(number: @submission.quiz_version).first
      if previous_version && @submission.quiz_version != quiz.version_number
        quiz = previous_version.model.reload
      end

      # let's just write the options here in case we decide to do individual
      # submissions asynchronously later.
      options = {
          quiz: quiz,
          # Leave version_number out for now as we may be passing the version
          # and we're not starting it as a delayed job
          # version_number: quiz.version_number,
          submissions: [@submission]
      }
      Quizzes::QuizRegrader::Regrader.regrade!(options)
    end

    def self.score_question(q, params)
      params = params.with_indifferent_access
      # TODO: undefined_if_blank - we need a better solution for the
      # following problem: since teachers can modify quizzes after students
      # have submitted (we warn them not to, but it is possible) we need
      # a good way to mark questions as needing attention for past submissions.
      # If a student already took the quiz and then a new question gets
      # added or the question answer they selected goes away, then the
      # the teacher gets the added burden of going back and manually assigning
      # scores for these questions per student.
      qq = Quizzes::QuizQuestion::Base.from_question_data(q)

      user_answer = qq.score_question(params)
      result = {
        :correct => user_answer.correctness,
        :points => user_answer.score,
        :question_id => user_answer.question_id,
      }
      result[:answer_id] = user_answer.answer_id if user_answer.answer_id
      result.merge!(user_answer.answer_details)
      return result
    end

    def track_outcomes(attempt)
      return unless @submission.user_id

      question_ids = (@submission.quiz_data || []).map { |q| q[:assessment_question_id] }.compact.uniq
      questions, alignments = questions_and_alignments(question_ids)
      return if questions.empty? || alignments.empty?

      tagged_bank_ids = Set.new(alignments.map(&:content_id))
      question_ids = questions.select { |q| tagged_bank_ids.include?(q.assessment_question_bank_id) }
      send_later_if_production(:update_outcomes_for_assessment_questions, question_ids, @submission.id, attempt) unless question_ids.empty?
    end

    def update_outcomes_for_assessment_questions(question_ids, submission_id, attempt)
      questions, alignments = questions_and_alignments(question_ids)
      return if questions.empty? || alignments.empty?

      submission = Quizzes::QuizSubmission.find(submission_id)
      versioned_submission = submission.attempt == attempt ? submission : submission.versions.sort_by(&:created_at).map(&:model).reverse.detect { |s| s.attempt == attempt }

      questions.each do |question|
        alignments.each do |alignment|
          if alignment.content_id == question.assessment_question_bank_id
            versioned_submission.create_outcome_result(question, alignment)
          end
        end
      end
    end

    private

    def questions_and_alignments(question_ids)
      return [], [] if question_ids.empty?

      questions = AssessmentQuestion.where(id: question_ids).to_a
      bank_ids = questions.map(&:assessment_question_bank_id).uniq
      return questions, [] if bank_ids.empty?

      # equivalent to AssessmentQuestionBank#learning_outcome_alignments, but for multiple banks at once
      return questions, ContentTag.learning_outcome_alignments.active.where(
          :content_type => 'AssessmentQuestionBank',
          :content_id => bank_ids).
          includes(:learning_outcome, :context).all
    end
  end
end
