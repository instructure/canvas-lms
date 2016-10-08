class AddTableSubmissionVersions < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :submission_versions do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "version_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "assignment_id", :limit => 8
    end

    columns = case connection.adapter_name
    when 'PostgreSQL'
      [:context_id, :version_id, :user_id, :assignment_id]
    else
      [:context_id, :context_type, :version_id, :user_id, :assignment_id]
    end

    add_index :submission_versions, columns,
      :name => 'index_submission_versions',
      :where => "context_type='Course'",
      :unique => true
  end

  def self.down
    drop_table :submission_versions
  end
end
