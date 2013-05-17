class MessageMigration < ActiveRecord::Migration
  def self.up
    add_index :conversation_message_participants, [:conversation_participant_id, :conversation_message_id], :name => :index_cmp_on_cpi_and_cmi
    add_index :inbox_items, [:asset_type, :asset_id]

    # for bringing over attachments and tracking deleted inbox_items
    # the other new columns get removed at the end of the migration, we'll keep this one for now
    # in case we need to track/fix any issues post migration
    add_column :conversation_messages, :context_message_id, :integer, :limit => 8

    return if Rails.env.test?

    unless connection.adapter_name =~ /postgres|mysql/i
      $stderr.puts "don't know how to migrate conversation data for #{connection.adapter_name}!"
      return
    end

    mysql = %w{MySQL Mysql2}.include?(connection.adapter_name)
    table_opts = mysql ? 'engine=innodb' : 'AS'

    # for grouping messages into conversations
    #   private: list of participant ids <= 2
    #   group: root_context_message_id + list of participant ids (if the list changes, it's a different conversation)
    add_column :conversations, :migration_signature, :text

    # helper column for merging into existing private conversations
    add_column :conversations, :tmp_private_hash, :string

    # from context_message, will get rolled up into conversation_participant
    add_column :conversation_message_participants, :unread, :boolean

    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_messages #{table_opts}
      SELECT
        id,
        user_id AS author_id,
        created_at,
        CASE WHEN subject IS NULL OR LOWER(SUBSTR(subject, 1, 4)) = 're: ' THEN body ELSE subject || #{connection.quote("\n\n")} || body END AS body,
        COALESCE(root_context_message_id, id) AS root_context_message_id,
        media_comment_id,
        media_comment_type,
        ''#{mysql ? '' : '::TEXT'} AS signature
      FROM
        context_messages
    SQL
    change_column :__migrated_messages, :signature, :text if mysql
    add_index :__migrated_messages, :id

    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_message_participants #{table_opts}
      SELECT DISTINCT
        context_message_id AS migrated_message_id,
        user_id
      FROM
        context_message_participants
    SQL
    add_index :__migrated_message_participants, :migrated_message_id, :name => :index_mmp_on_message_id

    if mysql
      execute  <<-SQL
        CREATE TEMPORARY TABLE __migrated_message_participant_strings #{table_opts}
        SELECT migrated_message_id, GROUP_CONCAT(DISTINCT user_id ORDER BY user_id) AS participants, COUNT(DISTINCT user_id) <= 2 AS private
        FROM __migrated_message_participants
        GROUP BY migrated_message_id
      SQL
    else
      execute <<-SQL
        CREATE TEMPORARY TABLE __migrated_message_participant_strings #{table_opts}
        SELECT migrated_message_id, STRING_AGG(user_id::TEXT, ',') AS participants, COUNT(DISTINCT user_id) <= 2 AS private
        FROM (
          SELECT DISTINCT migrated_message_id, user_id
          FROM __migrated_message_participants
          ORDER BY migrated_message_id, user_id
        ) p
        GROUP BY migrated_message_id
      SQL
    end
    add_index :__migrated_message_participant_strings, :migrated_message_id, :name => :index_mmps_on_migrated_message_id

    execute <<-SQL
      UPDATE __migrated_messages #{mysql ? ", __migrated_message_participant_strings" : ""}
      SET signature = CASE WHEN private THEN '' ELSE root_context_message_id || ':' END || participants
      #{mysql ? "" : " FROM __migrated_message_participant_strings"}
      WHERE migrated_message_id = __migrated_messages.id
    SQL
    if mysql
      execute "CREATE INDEX index___migrated_messages_on_signature ON __migrated_messages (signature(767))"
    else
      add_index :__migrated_messages, :signature
    end

    execute <<-SQL
      INSERT INTO conversations(migration_signature, has_attachments, has_media_objects)
      SELECT DISTINCT signature, FALSE, FALSE
      FROM __migrated_messages
    SQL
    if mysql
      execute "CREATE INDEX index_conversations_on_migration_signature ON conversations (migration_signature(767))"
    else
      add_index :conversations, :migration_signature
    end

    if mysql
      execute <<-SQL
        UPDATE conversations
        SET tmp_private_hash = SHA(migration_signature)
        WHERE migration_signature REGEXP '^[0-9]+(,[0-9]+)?$'
      SQL
    else
      Conversation.find_each(:conditions => "migration_signature ~ E'^[0-9]+(,[0-9]+)?$'", :batch_size => 10000) do |conversation|
        conversation.update_attribute :tmp_private_hash, Digest::SHA1.hexdigest(conversation.migration_signature)
      end
    end
    add_index :conversations, :tmp_private_hash

    # in case any private conversations already exist...
    execute <<-SQL
      UPDATE conversations #{mysql ? ", conversations c2" : ""}
      SET #{mysql ? "conversations." : ""}migration_signature = c2.migration_signature
      #{mysql ? "" : " FROM conversations c2"}
      WHERE conversations.private_hash = c2.tmp_private_hash
    SQL
    execute <<-SQL
      CREATE TEMPORARY TABLE __existing_private_conversations #{table_opts}
      SELECT private_hash FROM conversations WHERE private_hash IS NOT NULL
    SQL
    execute <<-SQL
      DELETE FROM conversations WHERE tmp_private_hash IN (SELECT private_hash FROM __existing_private_conversations)
    SQL

    # create participants for any group conversations or *new* private conversations
    remove_index :conversation_participants, :column => [:user_id, :last_message_at]
    add_index :conversation_participants, :user_id # temporary for better insert speeds (and to prevent people hitting new messaging from killing the db)
    subquery = mysql ?
      "SELECT signature, id FROM __migrated_messages GROUP BY signature ORDER BY signature, id DESC" :
      "SELECT DISTINCT ON (signature) signature, id FROM __migrated_messages ORDER BY signature, id DESC"
    execute <<-SQL
      INSERT INTO conversation_participants(conversation_id, user_id, subscribed, workflow_state, has_attachments, has_media_objects)
      SELECT c.id, mp.user_id, TRUE, 'read', FALSE, FALSE
      FROM __migrated_message_participants mp,
        (#{subquery}) AS m,
        conversations c
      WHERE migrated_message_id = m.id
        AND migration_signature = signature
        AND private_hash IS NULL
    SQL
    # make sure new private conversations have their hash set
    execute <<-SQL
      UPDATE conversations
      SET private_hash = tmp_private_hash
      WHERE tmp_private_hash IS NOT NULL
    SQL

    execute <<-SQL
      INSERT INTO conversation_messages(conversation_id, author_id, created_at, generated, body, media_comment_id, media_comment_type, context_message_id)
      SELECT
        conversations.id,
        author_id,
        created_at,
        FALSE,
        body,
        media_comment_id,
        media_comment_type,
        __migrated_messages.id
      FROM
        __migrated_messages, conversations
      WHERE
        signature = migration_signature
    SQL


    # make messages visible to users
    execute <<-SQL
      INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id, unread)
      SELECT
        cm.id,
        cp.id,
        ii.workflow_state = 'unread'
      FROM
        conversation_messages cm,
        conversation_participants cp,
        inbox_items ii
      WHERE
        cm.conversation_id = cp.conversation_id
        AND ii.asset_id = cm.context_message_id
        AND ii.asset_type = 'ContextMessage'
        AND ii.user_id = cp.user_id
        AND ii.workflow_state <> 'deleted'
    SQL

    # make sure senders can see their sent items (they don't normally get an inbox_item, unless explicitly added as a recipient)
    execute <<-SQL
      INSERT INTO conversation_message_participants(conversation_message_id, conversation_participant_id, unread)
      SELECT
        cm.id,
        cp.id,
        FALSE
      FROM
        conversation_messages cm
      INNER JOIN
        conversation_participants cp ON cm.conversation_id = cp.conversation_id AND cm.author_id = cp.user_id
      LEFT JOIN
        conversation_message_participants existing ON existing.conversation_message_id = cm.id AND existing.conversation_participant_id = cp.id
      WHERE
        cm.context_message_id IS NOT NULL
        AND existing.id IS NULL
    SQL

    # hide inbox_items from the users
    execute "UPDATE inbox_items SET workflow_state = 'retired' WHERE asset_type IN ('ContextMessage', 'SubmissionComment') AND workflow_state = 'read'"
    execute "UPDATE inbox_items SET workflow_state = 'retired_unread' WHERE asset_type IN ('ContextMessage', 'SubmissionComment') AND workflow_state = 'unread'"


    execute <<-SQL
      UPDATE conversation_participants
      SET workflow_state = 'unread'
      WHERE EXISTS (SELECT 1 FROM conversation_message_participants WHERE conversation_participants.id = conversation_participant_id AND unread LIMIT 1)
    SQL


    # attachments
    execute <<-SQL
      UPDATE attachments #{mysql ? ', conversation_messages' : ''}
      SET context_id = conversation_messages.id, context_type = 'ConversationMessage'
      #{mysql ? '' : 'FROM conversation_messages'}
      WHERE attachments.context_type = 'ContextMessage' AND conversation_messages.context_message_id = attachments.context_id
    SQL

    execute <<-SQL
      UPDATE conversation_participants
      SET has_attachments = TRUE
      WHERE id IN (
        SELECT conversation_participant_id
        FROM conversation_message_participants cmp, attachments a
        WHERE
          a.context_type = 'ConversationMessage'
          AND a.context_id = conversation_message_id
      )
    SQL

    execute <<-SQL
      UPDATE conversations
      SET has_attachments = TRUE
      WHERE id IN (
        SELECT conversation_id
        FROM conversation_messages cm, attachments a
        WHERE
          a.context_type = 'ConversationMessage'
          AND a.context_id = cm.id
      )
    SQL


    # audio comments
    execute <<-SQL
      UPDATE conversation_participants
      SET has_media_objects = TRUE
      WHERE id IN (
        SELECT conversation_participant_id
        FROM conversation_message_participants cmp, conversation_messages cm
        WHERE cmp.conversation_message_id = cm.id AND media_comment_id IS NOT NULL
      )
    SQL

    execute <<-SQL
      UPDATE conversations
      SET has_media_objects = TRUE
      WHERE id IN (
        SELECT conversation_id
        FROM conversation_messages
        WHERE media_comment_id IS NOT NULL
      )
    SQL

    # cached stats
    execute <<-SQL
      CREATE TEMPORARY TABLE __migrated_conversation_stats #{table_opts}
      SELECT
        conversation_participant_id,
        COUNT(*) AS message_count,
        MAX(cm.created_at) AS last_message_at,
        MAX(CASE WHEN cm.author_id = cp.user_id THEN cm.created_at ELSE NULL END) AS last_authored_at
      FROM conversation_message_participants cmp, conversation_messages cm, conversation_participants cp
      WHERE conversation_message_id = cm.id AND conversation_participant_id = cp.id
      GROUP BY conversation_participant_id
    SQL
    add_index :__migrated_conversation_stats, :conversation_participant_id, :name => :index_mcs_on_cpi

    execute <<-SQL
      UPDATE conversation_participants #{mysql ? ', __migrated_conversation_stats' : ''}
      SET #{mysql ? 'conversation_participants.' : ''}message_count = __migrated_conversation_stats.message_count,
        #{mysql ? 'conversation_participants.' : ''}last_message_at = __migrated_conversation_stats.last_message_at,
        #{mysql ? 'conversation_participants.' : ''}last_authored_at = __migrated_conversation_stats.last_authored_at
      #{mysql ? '' : 'FROM __migrated_conversation_stats'}
      WHERE conversation_participants.id = conversation_participant_id
    SQL
    if mysql
      execute <<-SQL
        ALTER TABLE conversation_participants
        ADD INDEX index_conversation_participants_on_user_id_and_last_message_at (user_id, last_message_at),
        DROP INDEX index_conversation_participants_on_user_id
      SQL
    else
      add_index :conversation_participants, [:user_id, :last_message_at]
      remove_index :conversation_participants, :column => :user_id
    end

    if mysql
      execute <<-SQL
        UPDATE users, (SELECT COUNT(*) AS unread_count, user_id FROM conversation_participants WHERE workflow_state = 'unread' GROUP BY user_id) AS counts
        SET unread_conversations_count = unread_count
        WHERE user_id = users.id
      SQL
    else
      execute <<-SQL
        UPDATE users
        SET unread_conversations_count = (SELECT COUNT(*) FROM conversation_participants WHERE workflow_state = 'unread' AND user_id = users.id)
      SQL
    end

    remove_column :conversations, :migration_signature
    remove_column :conversations, :tmp_private_hash
    remove_column :conversation_message_participants, :unread

    execute "DROP TABLE __migrated_messages"
    execute "DROP TABLE __migrated_message_participants"
    execute "DROP TABLE __migrated_message_participant_strings"
    execute "DROP TABLE __existing_private_conversations"
    execute "DROP TABLE __migrated_conversation_stats"
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
