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

  trigger.after(:insert) do
    <<-SQL
    UPDATE collection_item_datas
    SET upvote_count = upvote_count + 1
    WHERE id = NEW.collection_item_data_id;
    SQL
  end

  trigger.after(:delete) do
    <<-SQL
    UPDATE collection_item_datas
    SET upvote_count = upvote_count - 1
    WHERE id = OLD.collection_item_data_id;
    SQL
  end
end
