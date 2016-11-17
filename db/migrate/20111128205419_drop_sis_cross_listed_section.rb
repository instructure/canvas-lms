class DropSisCrossListedSection < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    remove_column :course_sections, :sis_cross_listed_section_id
    remove_column :course_sections, :sis_cross_listed_section_sis_batch_id
    drop_table :sis_cross_listed_sections
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
