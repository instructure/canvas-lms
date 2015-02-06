class Quizzes::QuizQuestionBuilder
  # Draw a number of QuizQuestions from a QuizGroup.
  class GroupPool
    def initialize(questions, picked, &mark_picked)
      @questions = questions
      @picked = picked
      @mark_picked = mark_picked
    end

    def draw(quiz_id, count)
      # try picking as many questions as requested:
      questions = @questions.shuffle.slice(0, count)

      # and discard ones we already picked:
      questions.reject! { |q| @picked[:qq].include?(q[:id]) }

      @mark_picked.call(questions) if questions.any?

      # if we ended up with less questions than was requested, this gets tricky:
      # we need to pull as many more questions as needed (duplicates), and make
      # sure that we have distinct QuizQuestions that represent them.
      if questions.count < count
        duplicates = @questions.shuffle.slice(0, count - questions.count)
        sources = AssessmentQuestion.where({
          id: duplicates.map { |q| q[:assessment_question_id] }
        })

        duplicates = sources.map do |aq|
          aq.find_or_create_quiz_question(quiz_id, @picked[:qq])
        end

        @mark_picked.call(duplicates)
        questions.concat(duplicates.map(&:data))
      end

      questions
    end
  end
end