class AddCloneToWikiPages < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :wiki_pages, :clone_of_id, :integer
    add_column :assignments, :clone_of_id, :integer
    add_column :quizzes, :clone_of_id, :integer
  end
end
