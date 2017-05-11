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

class AddUniqueIndexToDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :discussion_topics, [:context_id, :context_type, :root_topic_id], :unique => true, :algorithm => :concurrently, :name => "index_discussion_topics_unique_subtopic_per_context"
    remove_index :discussion_topics, :name => "index_discussion_topics_on_context_id_and_context_type"
  end

  def self.down
    add_index :discussion_topics, [:context_id, :context_type], :algorithm => :concurrently, :name => "index_discussion_topics_on_context_id_and_context_type"
    remove_index :discussion_topics, :name => "index_discussion_topics_unique_subtopic_per_context"
  end
end
