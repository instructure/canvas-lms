class RemoveHideFromStudentsFromWikiPages < ActiveRecord::Migration
  tag :postdeploy

  def up
    remove_column :wiki_pages, :hide_from_students
  end

  def down
    add_column :wiki_pages, :hide_from_students, :boolean
  end
end
