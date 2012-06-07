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

module Api::V1::Collection
  include Api::V1::Json
  include Api::V1::User

  API_COLLECTION_JSON_OPTS = {
    :only => %w(id name visibility followers_count items_count),
  }

  API_COLLECTION_ITEM_JSON_OPTS = {
    :only => %w(id collection_id user_comment created_at),
  }

  API_COLLECTION_ITEM_DATA_JSON_OPTS = {
    :only => %w(item_type link_url root_item_id post_count upvote_count html_preview title description),
    :methods => %w(upvoted_by_user),
  }

  API_COLLECTION_ITEM_UPVOTE_JSON_OPTS = {
    :only => %w(user_id created_at),
  }

  def collections_json(collections, current_user, session)
    followed = ::UserFollow.followed_by_user(collections, current_user)

    collections.map do |collection|
      hash = api_json(collection, current_user, session, API_COLLECTION_JSON_OPTS)
      hash['followed_by_user'] = !!followed.include?(collection)
      hash
    end
  end

  def collection_items_json(items, current_user, session)
    # TODO: sharding
    CollectionItem.send(:preload_associations, items, { :collection_item_data => :image_attachment })

    CollectionItemData.load_upvoted_by_user(items.map(&:collection_item_data), current_user)

    items.map do |item|
      hash = api_json(item, current_user, session, API_COLLECTION_ITEM_JSON_OPTS)
      hash['user'] = user_display_json(item.user)
      hash['url'] = api_v1_collection_item_url(item)
      item_data = item.collection_item_data
      hash['image_pending'] = item_data.image_pending
      image = item_data.image_attachment
      hash['image_url'] = image && thumbnail_image_url(image, image.uuid, :size => CollectionItemData::THUMBNAIL_SIZE)
      hash.merge!(api_json(item_data, current_user, session, API_COLLECTION_ITEM_DATA_JSON_OPTS))
      hash
    end
  end

  def collection_item_upvote_json(item, upvote, current_user, session)
    api_json(upvote, current_user, session, API_COLLECTION_ITEM_UPVOTE_JSON_OPTS).merge(:item_id => item.id, :root_item_id => item.collection_item_data.root_item_id)
  end
end
