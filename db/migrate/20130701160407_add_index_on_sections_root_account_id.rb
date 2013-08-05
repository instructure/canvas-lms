class AddIndexOnSectionsRootAccountId < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    add_index :course_sections, :root_account_id, concurrently: true
  end

  def self.down
    remove_index :course_sections, :root_account_id
  end
end
