class FixNeedNotifyIndexCondition < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  # this migration fixes a the bad index condition in AddNeedNotifyColumnToAttachments

  def self.up
    if connection.adapter_name =~ /\Apostgresql/i
      execute("DROP INDEX IF EXISTS index_attachments_on_need_notify")
      execute("CREATE INDEX CONCURRENTLY index_attachments_on_need_notify ON attachments(need_notify) WHERE need_notify")
    end
  end

  def self.down
    if connection.adapter_name =~ /\Apostgresql/i
      # before running this migration, the index was either nonexistent or useless
      # so we'll settle for nonexistent when rolling back; the behavior is the same
      execute("DROP INDEX index_attachments_on_need_notify")
    end
  end
end

