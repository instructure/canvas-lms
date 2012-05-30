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

# @API Collections
#
# Collections contain Collection Items, which are links to content. There are
# different types of items for links to different types of data.
#
# Collection items can be cloned from other collection items. This way the
# original source of the item can be tracked, and a count of "re-posts" can be
# kept on each item to track popularity. Note that depending on where the
# original item came from, a user may be able to view the cloned item but not
# the original item.
#
# A collection item also has a Discussion Topic associated with it, which can be
# used for comments on the item. See the Discussion Topic API for details on
# querying and adding to a discussion. The scope for the discussion topic will
# be the collection item, and the id of the topic is "self". For example, the
# DiscussionTopicsApiController#view endpoint looks like this:
#
#     /api/v1/collection_items/<id>/discussion_topics/self/view
#
# A Collection Item object looks like:
#
#     !!!javascript
#     {
#       // The ID of the collection item.
#       id: 7,
#
#       // The ID of the collection that this item belongs to.
#       collection_id: 2,
#
#       // The ID of the user that created the collection item.
#       user_id: 37,
#
#       // The type of the item.
#       // The only type currently defined is "url", but api consumers should
#       // expect new types to be returned in the future and handle that
#       // appropriately (even if it means just ignoring the item).
#       item_type: "url",
#
#       // The link to the item. For item type of "url", this is the entire
#       // contents of the collection item. For other item types, this may be a
#       // web preview or other representation of the item data.
#       link_url: "https://example.com/some/path",
#
#       // The number of posts of this item, including the original. This count
#       // is shared between the original item and all clones.
#       post_count: 2,
#
#       // The number of users who have voted up this item. This count is
#       // shared between the original item and all clones.
#       upvote_count: 3,
#
#       // Boolean indicating whether this user has upvoted this item (or any of its clones)
#       upvoted_by_user: false,
#
#       // If this item was cloned from another item, this will be the ID of
#       // the first, original item that all clones are derived from.
#       // In other words, if item 7 was cloned from item 5, and
#       // 5 was cloned from item 3, and 3 is the original, then the
#       // root_item_id of items 7, 5 and 3 will all be 3.
#       root_item_id: 3,
#
#       // An image representation of the collection item. This will be in a
#       // common web format such as png or jpeg. The resolution and geometry may depend on
#       // the item, but Canvas will attempt to make it 640 pixels wide
#       // when possible.
#       image_url: "https://<canvas>/files/item_image.png",
#
#       // If true, the image for this item is still being processed and
#       // image_url will be null. Check back later.
#       // If image_url is null but image_pending is false, the item has no image.
#       image_pending: false,
#
#       // The user-provided description of the item. This is plain text.
#       description: "some block of plain text",
#
#       // A snippet of HTML that can be used as an in-line preview of the
#       // item. For example, a link to a youtube page may have an iframe inline
#       // embed of the video.
#       // If no preview is available, this field will be null.
#       html_preview: "<iframe>...</iframe>",
#
#       // The API URL for this item. Used to clone the collection item.
#       url: "https://<canvas>/api/v1/collections/items/7"
#     }
class CollectionItemsController < ApplicationController
  before_filter :require_collection, :only => [:index, :create]

  include Api::V1::Collection

  # @API List collection items
  #
  # @subtopic Collection Items
  #
  # Returns the collection items in a collection, most-recently-created first.
  # The user must have read access to the collection.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/<collection_id>/items \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     [
  #       {
  #          id: 7,
  #          collection_id: 2,
  #          item_type: "url",
  #          link_url: "https://example.com/some/path",
  #          post_count: 2,
  #          upvote_count: 3,
  #          upvoted_by_user: false,
  #          root_item_id: 3,
  #          image_url: "https://<canvas>/files/item_image.png",
  #          description: "some block of plain text",
  #          url: "https://<canvas>/api/v1/collections/items/7"
  #       }
  #     ]
  def index
    pagination_route = api_v1_collection_items_list_url(@collection)
    if authorized_action(@collection, @current_user, :read)
      @items = Api.paginate(@collection.collection_items.active.newest_first, self, pagination_route)
      render :json => collection_items_json(@items, @current_user, session)
    end
  end

  # @API Get an individual collection item
  #
  # @subtopic Collection Items
  #
  # Returns an individual collection item. The user must have read access to the collection.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/items/<item_id> \ 
  #     -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #        id: 7,
  #        collection_id: 2,
  #        item_type: "url",
  #        link_url: "https://example.com/some/path",
  #        post_count: 2,
  #        upvote_count: 3,
  #        upvoted_by_user: false,
  #        root_item_id: 3,
  #        image_url: "https://<canvas>/files/item_image.png",
  #        description: "some block of plain text",
  #        url: "https://<canvas>/api/v1/collections/items/7"
  #     }
  def show
    find_item_and_collection
    if authorized_action(@item, @current_user, :read)
      render :json => collection_items_json([@item], @current_user, session).first
    end
  end

  ITEM_SETTABLE_ATTRIBUTES = %w(description)

  # @API Create or clone a collection item
  #
  # @subtopic Collection Items
  #
  # Create a new item in this collection. You can also clone an existing item
  # from another collection.
  #
  # @argument link_url The URL of the item to add. This can be any HTTP or
  #   HTTPS address. The item_type will be determined by the link_url that is passed in.
  #
  #   To clone an existing item, pass in the url to that item as returned in
  #   the JSON response in the "url" field.
  #
  # @argument description The plain-text description of the item.
  #
  # @argument image_url The URL of the image to use for this item. If no image
  #   url is provided, canvas will try to automatically determine an image
  #   representation for the link. This parameter is ignored if the new item is
  #   a clone of an existing item.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/<collection_id>/items \ 
  #          -F link_url="http://www.google.com/" \ 
  #          -F description="lmgtfy" \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/<collection_id>/items \ 
  #          -F link_url="https://<canvas>/api/v1/collections/items/3" \ 
  #          -F description="clone of some other item" \ 
  #          -H 'Authorization: Bearer <token>'
  #
  def create
    @item = @collection.collection_items.new(:user => @current_user)
    if authorized_action(@item, @current_user, :create)
      item_data = CollectionItemData.data_for_url(params[:link_url] || "", @current_user)
      return render_unauthorized_action unless item_data
      item_data.image_url = params[:image_url] if item_data.new_record?
      @item.collection_item_data = item_data
      @item.attributes = params.slice(*ITEM_SETTABLE_ATTRIBUTES)

      if @item.errors.empty? && @item.save
        @item.reload # have to reload to get the updated data after the triggers have run
        render :json => collection_items_json([@item], @current_user, session).first
      else
        render :json => @item.errors, :status => :bad_request
      end
    end
  end

  # @API Edit a collection item
  #
  # @subtopic Collection Items
  #
  # Change a collection item's mutable attributes.
  #
  # @argument description
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collectionss/items/<item_id> \ 
  #          -X PUT \ 
  #          -F description='edited description' \ 
  #          -H 'Authorization: Bearer <token>'
  #
  def update
    find_item_and_collection
    if authorized_action(@item, @current_user, :update)
      if @item.update_attributes(params.slice(*ITEM_SETTABLE_ATTRIBUTES))
        render :json => collection_items_json([@item], @current_user, session).first
      else
        render :json => @item.errors, :status => :bad_request
      end
    end
  end

  # @API Delete a collection item
  #
  # @subtopic Collection Items
  #
  # Delete a collection item from the collection. This will not delete any
  # clones of the item in other collections.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/items/<item_id> \ 
  #          -X DELETE \ 
  #          -H 'Authorization: Bearer <token>'
  def destroy
    find_item_and_collection
    if authorized_action(@item, @current_user, :delete)
      if @item.destroy
        render :json => collection_items_json([@item], @current_user, session).first
      else
        render :json => @item.errors, :status => :bad_request
      end
    end
  end

  # @API Upvote an item
  #
  # @subtopic Collection Items
  #
  # Upvote a collection item. If the current user has already upvoted the item,
  # nothing happens and the existing upvote data is returned. Upvotes are
  # shared between the root item and all clones, so if the user has already
  # upvoted another clone of the item, nothing happens.
  #
  # The upvoted_by_user field on the CollectionItem response data can be used
  # to determine if the user has already upvoted the item.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/items/<item_id>/upvote \ 
  #          -X PUT \ 
  #          -H 'Content-Length: 0' \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       item_id: 7,
  #       root_item_id: 3,
  #       user_id: 2,
  #       created_at: "2012-05-03T18:12:18Z",
  #     }
  def upvote
    find_item_and_collection
    if authorized_action(@item, @current_user, :read)
      @upvote = find_upvote
      @upvote ||= @item.collection_item_data.collection_item_upvotes.create!({ :user => @current_user })
      render :json => collection_item_upvote_json(@item, @upvote, @current_user, session)
    end
  end

  # @API De-upvote an item
  #
  # @subtopic Collection Items
  #
  # Remove the current user's upvote of an item. This is a no-op if the user
  # has not upvoted this item.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/items/<item_id>/upvote \ 
  #          -X DELETE \ 
  #          -H 'Authorization: Bearer <token>'
  def remove_upvote
    find_item_and_collection
    if authorized_action(@item, @current_user, :read)
      @upvote = find_upvote
      if @upvote
        @upvote.destroy
      end
      render :json => { "ok" => true }
    end
  end

  # non-api action, canvas uses this internally to pull the information about the linked url
  # currently this uses embed.ly
  #
  # for apps other than canvas that create collection items, we'll still use
  # embed.ly in the back-end to get the embed data, and an image url if none is
  # given. but that'll happen when creating the item, rather than before.
  def link_data
    if @current_user
      data = Canvas::Embedly.new(params[:url])
      # if embedly returns any kind of error, we return a data response with
      # all fields set to null
      render :json => data
    else
      render :nothing => true, :status => :unauthorized
    end
  end

  def new
    render :layout => 'bare'
  end

  protected

  def require_collection
    @collection = Collection.active.find(params[:collection_id])
  end

  def find_item_and_collection
    @item = CollectionItem.active.find(params[:item_id])
    @collection = @item.active_collection
  end

  def find_upvote
    @item.collection_item_data.collection_item_upvotes.find_by_user_id(@current_user.id)
  end
end
