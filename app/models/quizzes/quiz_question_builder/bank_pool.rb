class Quizzes::QuizQuestionBuilder
  # Draw a number of QuizQuestions from an AssessmentQuestionBank.
  class BankPool
    def initialize(bank, picked, &mark_picked)
      @bank = bank
      @picked = picked
      @mark_picked = mark_picked
    end

    def draw(quiz_id, quiz_group_id, count)
      questions = @bank.select_for_submission(quiz_id, quiz_group_id, count, @picked[:aq])
      @mark_picked.call(questions)

      duplicate_index = 1
      while questions.count < count
        remaining_picks = count - questions.count
        duplicated = @bank.select_for_submission(quiz_id, quiz_group_id, remaining_picks, [], duplicate_index)
        break if duplicated.empty?
        duplicate_index += 1
        @mark_picked.call(duplicated)
        questions.concat(duplicated)
      end

      questions.map(&:data)
    end
  end
end