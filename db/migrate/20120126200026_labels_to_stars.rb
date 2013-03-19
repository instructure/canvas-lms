class LabelsToStars < ActiveRecord::Migration
  def self.up
    ConversationParticipant.where("label IS NOT NULL").update_all(:label => 'starred')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
