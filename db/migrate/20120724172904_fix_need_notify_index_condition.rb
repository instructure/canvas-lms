class FixNeedNotifyIndexCondition < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  # this migration fixes a the bad index condition in AddNeedNotifyColumnToAttachments

  def self.up
    if connection.adapter_name =~ /\Apostgresql/i
      execute("DROP INDEX IF EXISTS index_attachments_on_need_notify")
      add_index :attachments, :need_notify, :algorithm => :concurrently, :where => "need_notify"
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      # before running this migration, the index was either nonexistent or useless
      # so we'll settle for nonexistent when rolling back; the behavior is the same
      remove_index :attachments, :need_notify
    end
  end
end

