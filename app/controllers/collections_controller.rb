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
# @beta
#
# Collections are buckets of content that can be used to organize links to
# helpful resources. For instance, a user could create a collection storing a
# set of links to various web sites containing potential discussion questions.
#
# A user can have multiple collections, and each can be marked as private
# (viewable only to the user) or public (viewable by the world).
#
# A Collection object looks like:
#
#     !!!javascript
#     {
#       // The ID of the collection.
#       id: 5,
#
#       // The display name of the collection, set by the collection creator.
#       name: "My Collection",
#
#       // The visibility of the collection. If "public", the collection is visible to everybody.
#       // If "private", the collection is visible only to the creating user.
#       // The default is "private".
#       visibility: "public"
#     }
#
class CollectionsController < ApplicationController
  before_filter :require_context

  include Api::V1::Collection

  SETTABLE_ATTRIBUTES = %w(name visibility)

  # @API List collections
  #
  # Returns the visible collections for the given user, returned most-recently-created first.
  # If the given user is the current user, then all collections will be
  # returned, otherwise only public collections will be returned.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/users/self/collections
  #
  # @example_response
  #     [
  #       {
  #         id: 1,
  #         name: "My Collection",
  #         visibility: "public"
  #       },
  #       {
  #         id: 2,
  #         name: "My Personal Collection",
  #         visibility: "private"
  #       }
  #     ]
  def index
    collection_route = polymorphic_url([:api_v1, @context, :collections])
    scope = @context.collections.active.newest_first

    unless is_authorized_action?(@context.collections.new(:visibility => 'private'), @current_user, :read)
      scope = scope.public
    end

    @collections = Api.paginate(scope, self, collection_route)
    render :json => @collections.map { |c| collection_json(c, @current_user, session) }
  end

  # @API Get a single collection
  #
  # Returns information on an individual collection. If the collection is
  # private and the caller doesn't have read access, a 401 is returned.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/users/<user_id>/collections/<collection_id>
  #
  # @example_response
  #     {
  #       id: 1,
  #       name: "My Collection",
  #       visibility: "public"
  #     }
  def show
    @collection = find_collection
    if authorized_action(@collection, @current_user, :read)
      render :json => collection_json(@collection, @current_user, session)
    end
  end

  # @API Create a collection
  #
  # Creates a new collection. You can only create collections on your own user.
  #
  # @argument name
  # @argument visibility
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          -F name='My Collection' \ 
  #          -F visibility=public \ 
  #          https://<canvas>/api/v1/users/self/collections
  #
  # @example_response
  #     {
  #       id: 1,
  #       name: "My Collection",
  #       visibility: "public"
  #     }
  def create
    @collection = @context.collections.new(params.slice(*SETTABLE_ATTRIBUTES))
    if authorized_action(@collection, @current_user, :create)
      if @collection.save
        render :json => collection_json(@collection, @current_user, session)
      else
        render :json => @collection.errors, :status => :bad_request
      end
    end
  end

  # @API Edit a collection
  #
  # Modify an existing collection. You must have write access to the collection.
  #
  # Collection visibility cannot be modified once the collection is created.
  #
  # @argument name
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          -X PUT \ 
  #          -F name='My Edited Collection' \ 
  #          https://<canvas>/api/v1/users/self/collections/<collection_id>
  #
  # @example_response
  #     {
  #       id: 1,
  #       name: "My Edited Collection",
  #       visibility: "public"
  #     }
  def update
    @collection = find_collection
    if authorized_action(@collection, @current_user, :update)
      if @collection.update_attributes(params.slice(*SETTABLE_ATTRIBUTES))
        render :json => collection_json(@collection, @current_user, session)
      else
        render :json => @collection.errors, :status => :bad_request
      end
    end
  end

  # @API Delete a collection
  #
  # Deletes a collection and all contained collection items. You must
  # have write access to the collection.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          -X DELETE \ 
  #          https://<canvas>/api/v1/users/<user_id>/collections/<collection_id>
  #
  # @example_response
  #     {
  #       id: 1,
  #       name: "My Collection",
  #       visibility: "public"
  #     }
  def destroy
    @collection = find_collection
    if authorized_action(@collection, @current_user, :delete)
      if @collection.destroy
        render :json => collection_json(@collection, @current_user, session)
      else
        render :json => @collection.errors, :status => :bad_request
      end
    end
  end

  protected

  def find_collection
    @context.collections.active.find(params[:collection_id])
  end
end

