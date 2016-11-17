class OutcomeLinks < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :outcome_links do |t|

      t.integer  :learning_outcome_group_id, null: false, limit: 8
      t.integer  :learning_outcome_id, null: false, limit: 8
      t.string   :workflow_state, null: false
      t.boolean  :use_default_scale, default: true, null: false
      t.timestamps null: false
    end

    add_foreign_key :outcome_links, :learning_outcomes
    add_foreign_key :outcome_links, :learning_outcome_groups
  end

  def self.down
    drop_table :outcome_links
  end
end
