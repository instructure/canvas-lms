class AddMoreGistIndexesForUserSearch < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres? && has_postgres_proc?('show_trgm')
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("create index#{concurrently} index_trgm_pseudonyms_unique_id ON pseudonyms USING gist(lower(unique_id) gist_trgm_ops);")
    end
  end

  def self.down
    if is_postgres?
      execute('drop index if exists index_trgm_pseudonyms_unique_id;')
    end
  end

end
