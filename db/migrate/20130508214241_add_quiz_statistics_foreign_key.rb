class AddQuizStatisticsForeignKey < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_foreign_key :quiz_statistics, :quizzes
  end

  def self.down
    remove_foreign_key :quiz_statistics, :quizzes
  end
end
