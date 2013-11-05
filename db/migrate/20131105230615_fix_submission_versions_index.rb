class FixSubmissionVersionsIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL' && connection.select_value("SELECT 1 FROM pg_index WHERE indexrelid='index_submission_versions'::regclass AND NOT indisunique")
      add_index :submission_versions, [:context_id, :version_id, :user_id, :assignment_id],
                :name => 'index_submission_versions2',
                :where => { :context_type => 'Course' },
                :unique => true
      connection.execute("DROP INDEX IF EXISTS index_submission_versions")
      connection.execute("ALTER INDEX index_submission_versions2 RENAME TO index_submission_versions")
    end
  end
end
