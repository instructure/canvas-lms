#
# Copyright (C) 2012 Instructure, Inc.
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
#

class CollectionItemUpvote < ActiveRecord::Base
  belongs_to :collection_item_data
  belongs_to :user

  attr_accessible :collection_item_data, :user

  validates_presence_of :collection_item_data, :user
  attr_readonly :collection_item_data_id, :user_id

  after_create :update_upvote_count
  after_destroy :update_upvote_count

  # upvotes get saved to the user's shard, and then increment the counter
  # stored on the collection_item_data, wherever it may live
  set_shard_override do |record|
    record.user.shard
  end

  def update_upvote_count
    increment = 0
    if self.id_changed?
      # was a new record
      increment = 1
    elsif self.destroyed?
      increment = -1
    end

    if increment != 0
      collection_item_data.shard.activate do
        collection_item_data.class.update_all(['upvote_count = upvote_count + ?', increment], :id => collection_item_data.id)
      end
    end
  end
end
