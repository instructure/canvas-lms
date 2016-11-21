class AddAssignmentToWikiPage < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :wiki_pages, :assignment_id, :integer, :limit => 8
    add_column :wiki_pages, :old_assignment_id, :integer, :limit => 8
    add_index :wiki_pages, [:assignment_id]
    add_index :wiki_pages, [:old_assignment_id]
    add_foreign_key :wiki_pages, :assignments
    add_foreign_key :wiki_pages, :assignments, column: :old_assignment_id
  end
end
