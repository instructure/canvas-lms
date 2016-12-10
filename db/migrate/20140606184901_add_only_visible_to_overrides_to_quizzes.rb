class AddOnlyVisibleToOverridesToQuizzes < ActiveRecord::Migration[4.2]
 tag :predeploy

  def self.up
    add_column :quizzes, :only_visible_to_overrides, :boolean
  end

  def self.down
    remove_column :quizzes, :only_visible_to_overrides
  end
end
