class SetBlankSisUserIdsToNull < ActiveRecord::Migration
  def self.up
    Pseudonym.where(:sis_user_id => '').update_all(:sis_user_id => nil)
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
