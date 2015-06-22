class AddGistIndexForUserSearch < ActiveRecord::Migration
  disable_ddl_transaction!
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

      if (schema = connection.extension_installed?(:pg_trgm))
        concurrently = " CONCURRENTLY" if connection.open_transactions == 0
        execute("create index#{concurrently} index_trgm_users_name on users USING gist(lower(name) #{schema}.gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_pseudonyms_sis_user_id on pseudonyms USING gist(lower(sis_user_id) #{schema}.gist_trgm_ops);")
        execute("create index#{concurrently} index_trgm_communication_channels_path on communication_channels USING gist(lower(path) #{schema}.gist_trgm_ops);")
      end
    end
  end

  def self.down
    if is_postgres?
      execute('drop index if exists index_trgm_users_name;')
      execute('drop index if exists index_trgm_pseudonyms_sis_user_id;')
      execute('drop index if exists index_trgm_communication_channels_path;')
    end
  end
end
