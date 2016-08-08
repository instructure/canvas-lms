module Quizzes
  class QuizOutcomeResultBuilder
    def initialize(quiz_submission)
      @qs = quiz_submission
    end

    def build_outcome_results(questions, alignments)
      return unless ['complete', 'graded'].include?(@qs.workflow_state)
      create_quiz_outcome_results(questions, alignments)
      questions.each do |question|
        alignments.each do |alignment|
          if alignment.content_id == question.assessment_question_bank_id
            create_outcome_question_result(question, alignment)
          end
        end
      end
    end
    private

    def create_outcome_question_result(question, alignment)
      # find or create the user's unique LearningOutcomeResult for this alignment
      # of the quiz question.
      quiz_result = alignment.learning_outcome_results.
        for_association(@qs.quiz).
        for_associated_asset(@qs.quiz).
        where(user_id: @qs.user.id).
        first_or_initialize

      # Create a question scoped outcome result linked to the quiz_result.
      question_result = quiz_result.learning_outcome_question_results.for_associated_asset(question).first_or_initialize

      # update the result with stuff from the quiz submission's question result
      cached_question = @qs.quiz_data.detect { |q| q[:assessment_question_id] == question.id }
      cached_answer = @qs.submission_data.detect { |q| q[:question_id] == cached_question[:id] }
      raise "Could not find valid question" unless cached_question
      raise "Could not find valid answer" unless cached_answer

      question_result.learning_outcome = quiz_result.learning_outcome

      # mastery
      question_result.score = cached_answer[:points]
      question_result.possible = cached_question['points_possible']
      question_result.calculate_percent!
      question_result.mastery = determine_mastery(question_result, alignment)

      # attempt
      question_result.attempt = @qs.attempt

      # title
      question_result.title = "#{@qs.user.name}, #{@qs.quiz.title}: #{cached_question[:name]}"

      question_result.submitted_at = @qs.finished_at
      question_result.assessed_at = Time.zone.now
      question_result.save_to_version(question_result.attempt)
      question_result
    end

    def create_quiz_outcome_results(questions, alignments)
      unique_alignments = alignments.uniq
      unique_alignments.map do |alignment|
        result = alignment.learning_outcome_results.
          for_association(@qs.quiz).
          for_associated_asset(@qs.quiz).
          where(user_id: @qs.user.id).
          first_or_initialize

        result.artifact = @qs
        result.context = @qs.quiz.context || alignment.context

        cached_questions_and_answers = questions.select do |question|
          question.assessment_question_bank_id == alignment.content_id
        end.map do |question|
          cached_question = @qs.quiz_data.detect { |q| q[:assessment_question_id] == question.id }
          cached_answer = @qs.submission_data.detect { |q| q[:question_id] == cached_question[:id] }
          raise "Could not find valid question" unless cached_question
          raise "Could not find valid answer" unless cached_answer
          [cached_question, cached_answer]
        end

        result.score = cached_questions_and_answers.map(&:last).
          map { |h| h[:points] }.
          inject(:+)
        result.possible = cached_questions_and_answers.map(&:first).
          map { |h| h['points_possible']}.
          inject(:+)

        result.calculate_percent!
        result.mastery = determine_mastery(result, alignment)
        result.attempt = @qs.attempt
        result.title = "#{@qs.user.name}, #{@qs.quiz.title}"
        result.assessed_at = Time.zone.now
        result.submitted_at = @qs.finished_at
        result.save_to_version(result.attempt)
        result
      end
    end

    def determine_mastery(result, alignment)
      if alignment.mastery_score && result.percent
        result.percent >= alignment.mastery_score
      end
    end
  end
end