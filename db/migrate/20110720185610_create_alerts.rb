class CreateAlerts < ActiveRecord::Migration
  def self.up
    create_table :alerts do |t|
      t.integer :context_id, :limit => 8
      t.string :context_type
      t.text :recipients
      t.integer :repetition

      t.timestamps
    end

    create_table :alert_criteria do |t|
      t.integer :alert_id, :limit => 8
      t.string :criterion_type
      t.float :threshold
    end
  end

  def self.down
    drop_table :alert_criteria
    drop_table :alerts
  end
end
