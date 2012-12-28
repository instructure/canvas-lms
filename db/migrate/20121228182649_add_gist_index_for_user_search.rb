class AddGistIndexForUserSearch < ActiveRecord::Migration
  self.transactional = false
  tag :predeploy

  def self.up
    if is_postgres?
      execute('create extension if not exists pg_trgm;') rescue nil

      if has_postgres_proc?('show_trgm')
        execute('create index index_trgm_users_name on users USING gist(lower(name) gist_trgm_ops);')
        execute('create index index_trgm_pseudonyms_sis_user_id on pseudonyms USING gist(lower(sis_user_id) gist_trgm_ops);')
        execute('create index index_trgm_communication_channels_path on communication_channels USING gist(lower(path) gist_trgm_ops);')
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
