class AddIndexOnCourseWikiId < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :courses, :wiki_id, concurrently: true, conditions: "wiki_id IS NOT NULL"
    remove_index :groups, :wiki_id
    add_index :groups, :wiki_id, concurrently: true, conditions: "wiki_id IS NOT NULL"
  end

  def self.down
    remove_index :courses, :wiki_id
    remove_index :groups, :wiki_id
    add_index :groups, :wiki_id
  end
end
