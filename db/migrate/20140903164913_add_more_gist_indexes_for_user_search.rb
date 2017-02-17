class AddMoreGistIndexesForUserSearch < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :predeploy

  def self.up
    if is_postgres? && (schema = connection.extension_installed?(:pg_trgm))
      concurrently = " CONCURRENTLY" if connection.open_transactions == 0
      execute("create index#{concurrently} index_trgm_pseudonyms_unique_id ON #{Pseudonym.quoted_table_name} USING gist(lower(unique_id) #{schema}.gist_trgm_ops);")
    end
  end

  def self.down
    if is_postgres?
      execute('drop index if exists index_trgm_pseudonyms_unique_id;')
    end
  end

end
