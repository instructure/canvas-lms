class AddGistIndexForWikiPageSearch < ActiveRecord::Migration
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
        execute("create index#{concurrently} index_trgm_wiki_pages_title on wiki_pages USING gist(lower(title) gist_trgm_ops);")
      end
    end
  end

  def self.down
    if is_postgres?
      execute('drop index if exists index_trgm_wiki_pages_title;')
    end
  end
end
