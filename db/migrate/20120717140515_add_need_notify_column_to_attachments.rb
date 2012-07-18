class AddNeedNotifyColumnToAttachments < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_column :attachments, :need_notify, :boolean
    Attachment.reset_column_information
    if connection.adapter_name =~ /\Apostgresql/i
      execute('CREATE INDEX CONCURRENTLY "index_attachments_on_need_notify" ON attachments(need_notify) WHERE need_notify IS NOT NULL')
    else
      add_index :attachments, [:need_notify], :name => "index_attachments_on_need_notify"
    end
  end

  def self.down
    remove_column :attachments, :need_notify
    remove_index :attachments, :name => "index_attachments_on_need_notify"
  end
end
