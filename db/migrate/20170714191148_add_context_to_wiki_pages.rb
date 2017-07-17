class AddContextToWikiPages < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  tag :predeploy

  def change
    add_column :wiki_pages, :context_id, :integer, :limit => 8
    add_column :wiki_pages, :context_type, :string
    add_index :wiki_pages, [:context_id, :context_type], algorithm: :concurrently
  end
end
