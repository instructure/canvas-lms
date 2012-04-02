class ReassociateConversationAttachments < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = false

  def self.up
    temp_table_options = adapter_name =~ /mysql/i ? 'engine=innodb' : 'AS'

    execute <<-SQL
      CREATE TEMPORARY TABLE _conversation_message_attachments #{temp_table_options}
      SELECT cm.id AS conversation_message_id, author_id, a.id AS attachment_id
      FROM conversation_messages cm, attachments a
      WHERE cm.id = a.context_id AND a.context_type = 'ConversationMessage'
    SQL
    add_index :_conversation_message_attachments, :conversation_message_id, :name => '_cma_cmid_index'
    add_index :_conversation_message_attachments, :attachment_id, :name => '_cma_aid_index'
    execute "ANALYZE _conversation_message_attachments" if adapter_name =~ /postgres/i

    # make sure users w/ conversation attachments have root folders
    execute <<-SQL
      INSERT INTO folders(context_id, context_type, name, full_name, workflow_state)
      SELECT DISTINCT author_id, 'User', 'my files', 'my files', 'visible'
      FROM _conversation_message_attachments
      WHERE NOT EXISTS (SELECT 1 FROM folders WHERE context_id = author_id AND context_type = 'User' AND name = 'my files')
    SQL

    # and conversation attachment folders
    execute <<-SQL
      INSERT INTO folders(context_id, context_type, name, full_name, workflow_state, parent_folder_id)
      SELECT DISTINCT author_id, 'User', 'conversation attachments', 'conversation attachments', 'visible', folders.id
      FROM _conversation_message_attachments, folders
      WHERE folders.context_id = author_id AND folders.context_type = 'User'
        AND NOT EXISTS (SELECT 1 FROM folders WHERE context_id = author_id AND context_type = 'User' AND name = 'conversation attachments')
    SQL

    execute <<-SQL
      INSERT INTO attachment_associations(attachment_id, context_id, context_type)
      SELECT attachment_id, conversation_message_id, 'ConversationMessage'
      FROM _conversation_message_attachments
    SQL

    cmas = connection.select_all("SELECT * FROM _conversation_message_attachments")
    cmas.map{ |r| r['conversation_message_id'] }.uniq.each_slice(1000) do |ids|
      execute <<-SQL
        UPDATE conversation_messages
        SET attachment_ids = (
          SELECT #{connection.func(:group_concat, :attachment_id, ',')}
          FROM _conversation_message_attachments
          WHERE conversation_message_id = conversation_messages.id
        )
        WHERE id IN (#{ids.join(', ')})
      SQL
      
    end
    cmas.map{ |r| r['attachment_id'] }.each_slice(1000) do |ids|
      case adapter_name
        when /mysql/i
          execute <<-SQL
            UPDATE attachments, _conversation_message_attachments
            SET context_type = 'User',
              context_id = _conversation_message_attachments.author_id,
              folder_id = (SELECT f.id FROM folders f WHERE f.name = 'conversation attachments' AND f.context_type = 'User' AND f.context_id = _conversation_message_attachments.author_id LIMIT 1)
            WHERE context_type = 'ConversationMessage'
              AND attachments.id = _conversation_message_attachments.attachment_id
              AND attachments.id IN (#{ids.join(', ')})
          SQL
        when /postgres/i
          execute <<-SQL
            UPDATE attachments
            SET context_type = 'User',
              context_id = _conversation_message_attachments.author_id,
              folder_id = (SELECT f.id FROM folders f WHERE f.name = 'conversation attachments' AND f.context_type = 'User' AND f.context_id = _conversation_message_attachments.author_id LIMIT 1)
            FROM _conversation_message_attachments
            WHERE context_type = 'ConversationMessage'
              AND attachments.id = _conversation_message_attachments.attachment_id
              AND attachments.id IN (#{ids.join(', ')})
          SQL
        else
          execute <<-SQL
            UPDATE attachments
            SET context_type = 'User',
              context_id = (SELECT author_id FROM _conversation_message_attachments WHERE attachment_id = attachments.id),
              folder_id = (SELECT f.id FROM folders f, _conversation_message_attachments cma WHERE f.name = 'conversation attachments' AND f.context_type = 'User' AND f.context_id = cma.author_id AND cma.attachment_id = attachments.id LIMIT 1)
            WHERE context_type = 'ConversationMessage'
              AND id IN (SELECT attachment_id FROM _conversation_message_attachments)
              AND attachments.id IN (#{ids.join(', ')})
          SQL
      end
    end
    execute "DROP TABLE _conversation_message_attachments"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
