class FixUserActiveOnlyGistIndexFrd < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_trgm_users_short_name_active_only')}")
  end
end
