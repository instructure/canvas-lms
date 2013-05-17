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
    case connection.adapter_name
    when 'PostgreSQL'
      connection.execute(
        "CREATE INDEX index_submission_versions " +
        "ON submission_versions (context_id, version_id, user_id, assignment_id) " +
        "WHERE context_type = 'Course'")
    else
      add_index :submission_versions,
        [:context_id, :context_type, :version_id, :user_id, :assignment_id],
        :name => 'index_submission_versions',
        :unique => true
    end
  end

  def self.down
    drop_table :submission_versions
  end
end
