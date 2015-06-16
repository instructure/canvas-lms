module Quizzes::QuizQuestionDataFixer
  # AssessmentQuestions updated after a certain commit lost all numerical values,
  # this tries to fix the bad data with data from quiz questions which weren't affected by this bug
  def self.fix_quiz_questions_with_bad_data
    seen_quizzes = {}
    # the commit that caused bad AssessmentQuestion data wasn't out until dec 22, 2011, so only try to fix AQs after that.
    AssessmentQuestion.where("updated_at > ? AND ((migration_id IS NULL) OR (migration_id IS NOT NULL AND question_data LIKE ?))",
                             Time.zone.parse("Dec 22, 2011"),
                             "%/files/%").find_each do |question|
                               begin
                                 data = question.question_data
                                 if data && data[:points_possible].nil? && data[:question_type] != "text_only_question"
                                   if good_data = find_good_data(question)
                                     good_data[:assessment_question_id] = question.id
                                     question.write_attribute(:question_data, good_data.to_hash)
                                     question.with_versioning(&:save)

                                     question.quiz_questions.active.each do |qq|
                                       if !is_valid_data(qq.question_data)
                                         if qq.quiz && qq.quiz.published_at && !seen_quizzes[qq.quiz_id]
                                           Rails.logger.info("The quiz #{qq.quiz_id} may need to be republished.")
                                           seen_quizzes[qq.quiz_id] = true
                                         end
                                         if pp = qq.question_data[:points_possible]
                                           qq.write_attribute(:question_data, good_data.merge({:points_possible => pp}).to_hash)
                                         else
                                           qq.write_attribute(:question_data, good_data.to_hash)
                                         end
                                         qq.save
                                       end
                                     end
                                   else
                                     Rails.logger.warn("Couldn't find clean data for #{question.id}, skipping fix.")
                                   end
                                 end
                               rescue
                                 Rails.logger.warn("Bad data for assessment question #{question.id}, skipping fix.")
                               end
                             end
  end

  def self.is_valid_data(data)
    return false unless data && data[:points_possible]

    if data[:answers]
      data[:answers].each do |a|
        return false if !a[:id]
      end
    end

    true
  end

  def self.find_good_data(aq)
    aq.versions.sort_by { |v| v.number }.reverse_each do |version|
      data = version.model.question_data
      return data if is_valid_data(data)
    end

    #try to find a good quiz question
    aq.quiz_questions.active.each do |qq|
      return qq.question_data if qq.question_data && is_valid_data(qq.question_data)
    end

    nil
  end

end
