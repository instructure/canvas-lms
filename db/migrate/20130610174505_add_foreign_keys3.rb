class AddForeignKeys3 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    add_foreign_key_if_not_exists :content_tags, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :content_tags, :context_modules, :delay_validation => true
    add_foreign_key_if_not_exists :context_external_tools, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :context_modules, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :course_sections, :enrollment_terms, :delay_validation => true
    add_foreign_key_if_not_exists :course_sections, :courses, :column => :nonxlist_course_id, :delay_validation => true
    add_foreign_key_if_not_exists :course_sections, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :courses, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :courses, :enrollment_terms, :delay_validation => true
    add_foreign_key_if_not_exists :courses, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :courses, :courses, :column => :template_course_id, :delay_validation => true
    add_foreign_key_if_not_exists :courses, :wikis, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :courses, :wikis
    remove_foreign_key_if_exists :courses, :column => :template_course_id
    remove_foreign_key_if_exists :courses, :column => :root_account_id
    remove_foreign_key_if_exists :courses, :enrollment_terms
    remove_foreign_key_if_exists :courses, :accounts
    remove_foreign_key_if_exists :course_sections, :column => :root_account_id
    remove_foreign_key_if_exists :course_sections, :column => :nonxlist_course_id
    remove_foreign_key_if_exists :course_sections, :enrollment_terms
    remove_foreign_key_if_exists :context_modules, :cloned_items
    remove_foreign_key_if_exists :context_external_tools, :cloned_items
    remove_foreign_key_if_exists :content_tags, :context_modules
    remove_foreign_key_if_exists :content_tags, :cloned_items
  end
end
