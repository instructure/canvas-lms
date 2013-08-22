class AddGistIndexesForApiSearch < ActiveRecord::Migration
  self.transactional = false
  tag :postdeploy

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
        execute("create index#{concurrently} index_trgm_context_external_tools_name on context_external_tools USING gist(lower(name) gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_assignments_title on assignments USING gist(lower(title) gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_quizzes_title on quizzes USING gist(lower(title) gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_discussion_topics_title on discussion_topics USING gist(lower(title) gist_trgm_ops);")
      end
    end
  end

  def self.down
    if is_postgres?
      execute('drop index if exists index_trgm_context_external_tools_name;')
      execute('drop index if exists index_trgm_assignments_title;')
      execute('drop index if exists index_trgm_quizzes_title;')
      execute('drop index if exists index_trgm_discussion_topics_title;')
    end
  end
end
