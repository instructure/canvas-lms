module DataFixup::PopulateConversationRootAccountIds

  def self.run
    conn = Conversation.connection
    adapter_name = conn.adapter_name.downcase
    cmocs = []

    # we'll be populating root_account_ids from ConversationMessage#context_id,
    # since that already tracks the root account id. but there are some
    # exceptions where it's currently null, so we need to fix them first...
    Conversation.transaction do
      # old context messages (before conversations)
      temp_table_options = adapter_name =~ /mysql/ ? 'engine=innodb' : 'AS'
      root_account_id_default = adapter_name =~ /postgres/ ? "CAST(0 AS BIGINT)" : "0"
      conn.execute <<-SQL
        CREATE TEMPORARY TABLE _conversation_message_old_contexts #{temp_table_options}
        SELECT m.id AS conversation_message_id, cm.context_type, cm.context_id, #{root_account_id_default} AS root_account_id
          FROM conversation_messages m, context_messages cm
          WHERE m.context_message_id IS NOT NULL AND m.context_message_id = cm.id AND m.context_id IS NULL
      SQL
      conn.add_index :_conversation_message_old_contexts, :conversation_message_id, :name => '_cmoc_cmid_index'
      conn.execute "ANALYZE _conversation_message_old_contexts" if adapter_name =~ /postgres/
  
      conn.execute <<-SQL
        UPDATE _conversation_message_old_contexts
        SET root_account_id = (
          SELECT root_account_id
          FROM courses
          WHERE id = _conversation_message_old_contexts.context_id
        )
        WHERE context_type = 'Course'
      SQL
  
      conn.execute <<-SQL
        UPDATE _conversation_message_old_contexts
        SET root_account_id = (
          SELECT root_account_id
          FROM groups
          WHERE groups.id = _conversation_message_old_contexts.context_id
        )
        WHERE context_type = 'Group'
      SQL
  
      cmocs = conn.select_all("SELECT conversation_message_id, root_account_id FROM _conversation_message_old_contexts WHERE root_account_id IS NOT NULL ORDER BY conversation_message_id")

      conn.execute "DROP TABLE _conversation_message_old_contexts"
    end

    cmocs.each_slice(1000) do |rows|
      conn.execute <<-SQL
        UPDATE conversation_messages
        SET context_type = 'Account',
          context_id = CASE id #{rows.map{ |r| "WHEN #{r['conversation_message_id']} THEN #{r['root_account_id']} "}.join} END
        WHERE
          id IN (#{rows.map{ |r| r['conversation_message_id'] }.join(', ')})
      SQL
    end

    # submission comments
    cmscs = conn.select_all("SELECT id FROM conversation_messages WHERE context_id IS NULL AND asset_id IS NOT NULL AND asset_type = 'Submission' ORDER BY id")
    cmscs.map{ |r| r['id'] }.each_slice(1000) do |ids|
      conn.execute <<-SQL
        UPDATE conversation_messages
        SET context_type = 'Account',
          context_id = (
            SELECT root_account_id
            FROM submissions s, assignments a, courses c
            WHERE s.id = asset_id AND a.id = assignment_id
              AND a.context_type = 'Course' AND a.context_id = c.id
          )
        WHERE
          id IN (#{ids.join(', ')})
      SQL
    end

    # in case there was any garbage data (like an assignment w/o a course, or a context message that couldn't link back to an account)
    conn.execute "UPDATE conversation_messages SET context_type = NULL WHERE context_type IS NOT NULL AND context_id IS NULL"

    convos = conn.select_all("SELECT id FROM conversations ORDER BY id")
    convos.map{ |r| r['id'] }.each_slice(1000) do |ids|
      case adapter_name
        when /mysql/
          conn.execute <<-SQL
            UPDATE conversations
            SET root_account_ids = (
              SELECT GROUP_CONCAT(DISTINCT context_id ORDER BY context_id SEPARATOR ',')
              FROM conversation_messages
              WHERE conversation_id = conversations.id
                AND context_id IS NOT NULL
            )
            WHERE id IN (#{ids.join(', ')})
          SQL
        when /postgres/
          conn.execute <<-SQL
            UPDATE conversations
            SET root_account_ids = (
              SELECT STRING_AGG(context_id::TEXT, ',' ORDER BY context_id)
              FROM (
                SELECT DISTINCT context_id FROM conversation_messages
                WHERE conversation_id = conversations.id
                  AND context_id IS NOT NULL
              ) ids
            )
            WHERE id IN (#{ids.join(', ')})
          SQL
        else
          conn.execute <<-SQL
            UPDATE conversations
            SET root_account_ids = (
              SELECT GROUP_CONCAT(DISTINCT context_id)
              FROM conversation_messages
              WHERE conversation_id = conversations.id
                AND context_id IS NOT NULL
            )
            WHERE id IN (#{ids.join(', ')})
          SQL
    
          # any w/ multiple accounts will have to be reordered in ruby
          Conversation.where(Conversation.wildcard(:root_account_ids, ',')).find_each do |c|
            c.root_account_ids = c.root_account_ids # does a reorder
            c.save if c.root_account_ids_changed?
          end
      end
    end
  end
end