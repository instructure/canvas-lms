#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class DropReallyOldUnusedColumns2 < ActiveRecord::Migration[4.2]
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
