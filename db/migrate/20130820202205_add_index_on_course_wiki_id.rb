class AddIndexOnCourseWikiId < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :courses, :wiki_id, algorithm: :concurrently, where: "wiki_id IS NOT NULL"
    if connection.adapter_name == 'PostgreSQL'
      remove_index :groups, :wiki_id
      add_index :groups, :wiki_id, algorithm: :concurrently, where: "wiki_id IS NOT NULL"
    end
  end

  def self.down
    remove_index :courses, :wiki_id
    if connection.adapter_name == 'PostgreSQL'
      remove_index :groups, :wiki_id
      add_index :groups, :wiki_id
    end
  end
end
