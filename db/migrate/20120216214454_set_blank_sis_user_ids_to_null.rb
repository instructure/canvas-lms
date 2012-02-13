class SetBlankSisUserIdsToNull < ActiveRecord::Migration
  def self.up
    Pseudonym.update_all({ :sis_user_id => nil }, :sis_user_id => '')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
