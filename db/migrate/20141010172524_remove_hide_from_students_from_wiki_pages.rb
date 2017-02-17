class RemoveHideFromStudentsFromWikiPages < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :wiki_pages, :hide_from_students
  end

  def down
    add_column :wiki_pages, :hide_from_students, :boolean
  end
end
