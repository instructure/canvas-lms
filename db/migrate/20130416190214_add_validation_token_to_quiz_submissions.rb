class AddValidationTokenToQuizSubmissions < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :quiz_submissions, :validation_token, :string
  end

  def self.down
    remove_column :quiz_submissions, :validation_token
  end
end
