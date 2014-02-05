class QuizRegrader::Submission

  attr_reader :submission, :question_regrades

  def initialize(hash)
    @submission        = hash.fetch(:submission)
    @question_regrades = hash.fetch(:question_regrades)
  end

  def regrade!
    return unless answers_to_grade.size > 0

    # regrade all previous versions
    submission.attempts.last_versions.each do |version|
      QuizRegrader::AttemptVersion.new(
        :version           => version,
        :question_regrades => question_regrades).regrade!
    end

    # save this version
    rescored_submission.save_with_versioning!
  end

  def rescored_submission
    previous_score = submission.score_before_regrade || submission.score
    submission.score += answers_to_grade.map(&:regrade!).inject(&:+) || 0
    submission.score_before_regrade = previous_score
    submission.quiz_data = regraded_question_data
    submission
  end

  private

  def answers_to_grade
    @answers_to_grade ||= submitted_answers.map do |answer|
      QuizRegrader::Answer.new(answer, question_regrades[answer[:question_id]])
    end
  end

  def submitted_answers
    @submitted_answers ||= submission.submission_data.select do |answer|
      question_regrades[answer[:question_id]]
    end
  end

  def submitted_answer_ids
    @submitted_answer_ids ||= submitted_answers.map {|q| q[:question_id] }.to_set
  end

  def regraded_question_data
    submission.quiz_data.map do |question|
      id = question[:id]
      if submitted_answer_ids.include?(id)
        question.keep_if {|k, v| %w{id position published_at}.include?(k) }

        quiz_question = question_regrades[id].quiz_question
        data  = quiz_question.question_data
        group = quiz_question.quiz_group

        if group && group.pick_count
          data[:points_possible] = group.question_points
        end

        question.merge(data.to_hash)
      else
        question
      end
    end
  end
end
