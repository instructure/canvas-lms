class RemoveUnneededGistIndexes < ActiveRecord::Migration
  tag :predeploy

  def self.up
    if is_postgres?
      execute('drop index if exists index_trgm_wiki_pages_title;')
      execute('drop index if exists index_trgm_context_external_tools_name;')
      execute('drop index if exists index_trgm_assignments_title;')
      execute('drop index if exists index_trgm_quizzes_title;')
      execute('drop index if exists index_trgm_discussion_topics_title;')
      execute('drop index if exists index_trgm_attachments_display_name;')
      execute('drop index if exists index_trgm_context_modules_name;')
      execute('drop index if exists index_trgm_content_tags_title;')
    end
  end

  def self.down
  end
end
