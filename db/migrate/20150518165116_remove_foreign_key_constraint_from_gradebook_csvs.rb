class RemoveForeignKeyConstraintFromGradebookCsvs < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_foreign_key :gradebook_csvs, column: :attachment_id
  end

  def self.down
    add_foreign_key :gradebook_csvs, :attachments
  end
end
