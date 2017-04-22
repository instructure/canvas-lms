class RemoveUnneededGistIndexes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if is_postgres?
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_wiki_pages_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_context_external_tools_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_assignments_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_quizzes_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_discussion_topics_title')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_attachments_display_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_context_modules_name')}")
      execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_content_tags_title')}")
    end
  end

  def self.down
  end
end
