class AddEmptyTags < ActiveRecord::Migration
  def self.up
    execute "UPDATE conversations SET tags = '' WHERE tags IS NULL"
    execute "UPDATE conversation_participants SET tags = '' WHERE tags IS NULL"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
