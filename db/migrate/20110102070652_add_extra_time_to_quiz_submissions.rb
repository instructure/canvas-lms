class AddExtraTimeToQuizSubmissions < ActiveRecord::Migration
  def self.up
    add_column :quiz_submissions, :extra_time, :integer
    add_column :quiz_submissions, :manually_unlocked, :boolean
  end

  def self.down
    remove_column :quiz_submissions, :extra_time
    remove_column :quiz_submissions, :manually_unlocked
  end
end
