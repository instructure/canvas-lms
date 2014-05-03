class AddTeacherNotesToCustomColumns < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :custom_gradebook_columns, :teacher_notes, :boolean,
      :default => false,
      :after => :workflow_state
  end

  def self.down
    remove_column :custom_gradebook_columns, :teacher_notes
  end
end
