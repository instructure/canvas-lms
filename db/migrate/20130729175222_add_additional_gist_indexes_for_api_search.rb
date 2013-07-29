class AddAdditionalGistIndexesForApiSearch < ActiveRecord::Migration
  self.transactional = false
  tag :predeploy

  def self.up
    if is_postgres?
      connection.transaction(:requires_new => true) do
        begin
          execute('create extension if not exists pg_trgm;')
        rescue ActiveRecord::StatementInvalid
          raise ActiveRecord::Rollback
        end
      end

      if has_postgres_proc?('show_trgm')
        concurrently = " CONCURRENTLY" if connection.open_transactions == 0
        execute("create index#{concurrently} index_trgm_attachments_display_name on attachments USING gist(lower(display_name) gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_context_modules_name on context_modules USING gist(lower(name) gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_content_tags_title on content_tags USING gist(lower(title) gist_trgm_ops);")
      end
    end
  end

  def self.down
    if is_postgres?
      execute('drop index if exists index_trgm_attachments_display_name;')
      execute('drop index if exists index_trgm_context_modules_name;')
      execute('drop index if exists index_trgm_content_tags_title;')
    end
  end
end
