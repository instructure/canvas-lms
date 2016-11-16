class CreateMasterContentTags < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :master_courses_master_content_tags do |t|
      t.integer :master_template_id, limit: 8, null: false

      # should we add a workflow state and make this soft-deletable? meh methinks
      # maybe someday if we decide to use these to define the template content aets

      t.string :content_type, null: false
      t.integer :content_id, limit: 8, null: false

      # here i was originally going to have a boolean column to keep track whether any changes had been made
      # since last export but i think i want to tie it directly to a master course 'migration'
      # to make it more robust against failure (i.e. we'll know that we'll need to re-export if the export failed)
      # so i'm going to add a column later when i have a new table
    end

    add_foreign_key :master_courses_master_content_tags, :master_courses_master_templates, column: "master_template_id"
    add_index :master_courses_master_content_tags, :master_template_id
    add_index :master_courses_master_content_tags, [:master_template_id, :content_type, :content_id], :unique => true,
      :name => "index_master_content_tags_on_template_id_and_content"
  end
end
