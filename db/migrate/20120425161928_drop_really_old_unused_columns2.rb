class DropReallyOldUnusedColumns2 < ActiveRecord::Migration
  tag :postdeploy

  disable_ddl_transaction!

  # cleanup for some legacy database schema that may not even exist for databases created post-OSS release
  def self.maybe_drop(table, column)
    remove_column(table, column) if self.connection.columns(table).map(&:name).include?(column.to_s)
  end

  def self.up
   maybe_drop :asset_user_accesses, :asset_access_stat_id

   maybe_drop :assignments, :minimum_required_blog_posts
   maybe_drop :assignments, :minimum_required_blog_comments
  end

  def self.down
  end
end
