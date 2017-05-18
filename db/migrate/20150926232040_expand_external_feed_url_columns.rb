#
# Copyright (C) 2015 - present Instructure, Inc.
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

class ExpandExternalFeedUrlColumns < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    change_column :external_feed_entries, :url, :text
    change_column :external_feed_entries, :source_url, :text
    change_column :external_feed_entries, :author_url, :text
  end

  def self.down
    change_column :external_feed_entries, :url, :string
    change_column :external_feed_entries, :source_url, :string
    change_column :external_feed_entries, :author_url, :string
  end
end
