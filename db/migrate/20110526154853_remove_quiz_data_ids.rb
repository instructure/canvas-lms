# some cloned quiz questions mistakenly have the old question id saved to the data hash, causing issues when trying to edit.
class RemoveQuizDataIds < ActiveRecord::Migration[4.2]
  tag :predeploy

  class QuizQuestionDataMigrationARShim < ActiveRecord::Base
    self.table_name = "quiz_questions"
    serialize :question_data
  end

  def self.up
    QuizQuestionDataMigrationARShim.find_each do |qq|
      data = qq.question_data
      if data.is_a?(Hash) && data[:id].present? && data[:id] != qq.id
        data[:id] = qq.id
        qq.save
      end
    end
  end

  def self.down
  end
end
