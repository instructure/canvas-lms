class CreateDelayedJobsTestStory < ActiveRecord::Migration
  def self.up
    if Rails.env.test?
      create_table :stories do |table|
        table.string :text
      end
    end
  end

  def self.down
    if Rails.env.test?
      drop_table :stories
    end
  end
end
