class CreateUsageRights < ActiveRecord::Migration
  tag :predeploy

  def up
    create_table :usage_rights do |t|
      t.integer :context_id, :limit => 8, null: false
      t.string :context_type, null: false
      t.string :use_justification, null: false
      t.string :license, null: false
      t.text :legal_copyright
    end
    add_index :usage_rights, [:context_id, :context_type], name: 'usage_rights_context_idx'

    add_column :attachments, :usage_rights_id, :integer, :limit => 8
    add_foreign_key :attachments, :usage_rights, column: :usage_rights_id
  end

  def down
    remove_foreign_key :attachments, column: :usage_rights_id
    remove_column :attachments, :usage_rights_id
    drop_table :usage_rights
  end
end

