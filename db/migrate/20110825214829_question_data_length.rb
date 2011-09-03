class QuestionDataLength < ActiveRecord::Migration
  def self.up
    return unless adapter_name =~ /mysql/i # postgres/sqlite have no limit
    change_column :quiz_questions, :question_data, :text, :limit => 2**20
    change_column :assessment_questions, :question_data, :text, :limit => 2**20
  end

  def self.down
    return unless adapter_name =~ /mysql/i
    change_column :quiz_questions, :question_data, :text
    change_column :assessment_questions, :question_data, :text
  end
end
