#
# Copyright (C) 2013 - present Instructure, Inc.
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

class AddGistIndexesForDiscussionTopicSearch < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!
  tag :predeploy
  def self.up
    if (schema = connection.extension_installed?(:pg_trgm))
      add_index :discussion_topics, "LOWER(title) #{schema}.gist_trgm_ops", name: "index_trgm_discussion_topics_title", using: :gist, algorithm: :concurrently
    end
  end

  def self.down
    remove_index :discussion_topics, name: 'index_trgm_discussion_topics_title'
  end
end
