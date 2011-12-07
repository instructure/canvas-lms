class DropSisCrossListedSection < ActiveRecord::Migration
  def self.up
    remove_column :course_sections, :sis_cross_listed_section_id
    remove_column :course_sections, :sis_cross_listed_section_sis_batch_id
    drop_table :sis_cross_listed_sections
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
