class AssignmentOverrideMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :assignment_overrides do |t|
      t.timestamps null: true

      # generic info
      t.integer  :assignment_id, :null => false, :limit => 8
      t.integer  :assignment_version, :null => false
      t.string   :set_type, :null => :false
      t.integer  :set_id, :limit => 8
      t.string   :title
      t.string   :workflow_state, :null => false

      # due at override
      t.boolean  :due_at_overridden, :default => false, :null => false
      t.datetime :due_at
      t.boolean  :all_day
      t.date     :all_day_date

      # unlock at override
      t.boolean  :unlock_at_overridden, :default => false, :null => false
      t.datetime :unlock_at

      # lock at override
      t.boolean  :lock_at_overridden, :default => false, :null => false
      t.datetime :lock_at
    end

    if connection.adapter_name =~ /\Apostgresql/i
      add_index :assignment_overrides, [:assignment_id, :set_type, :set_id],
        :name => 'index_assignment_overrides_on_assignment_and_set',
        :unique => true,
        :where => "workflow_state='active' and set_id is not null"
    else
      # can't enforce unique without conditions, since when set_type is 'adhoc'
      # and set_id null, there may be multiple overrides
      add_index :assignment_overrides, [:assignment_id, :set_type, :set_id],
        :name => 'index_assignment_overrides_on_assignment_and_set'
    end

    add_foreign_key :assignment_overrides, :assignments

    create_table :assignment_override_students do |t|
      t.timestamps null: true

      t.integer  :assignment_id, :null => false, :limit => 8
      t.integer  :assignment_override_id, :null => false, :limit => 8
      t.integer  :user_id, :null => false, :limit => 8
    end

    add_index :assignment_override_students, [:assignment_id, :user_id], :unique => true
    add_index :assignment_override_students, :assignment_override_id

    add_foreign_key :assignment_override_students, :assignments
    add_foreign_key :assignment_override_students, :assignment_overrides
    add_foreign_key :assignment_override_students, :users
  end

  def self.down
    drop_table :assignment_override_students
    drop_table :assignment_overrides
  end
end
