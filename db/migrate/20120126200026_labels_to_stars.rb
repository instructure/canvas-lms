class LabelsToStars < ActiveRecord::Migration
  def self.up
    ConversationParticipant.update_all("label = 'starred'", "label IS NOT NULL")
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
