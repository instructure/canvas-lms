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
# set of links to various web sites containing potential discussion questions,
# or members of a group could all contribute to a collection focused on
# potential assessment questions.
#
# A user/group can have multiple collections, and each can be marked as private
# (viewable only to the user/group) or public (viewable by the world).
#
# Group collections can only be created, updated, or deleted by group
# moderators.
#
# @object Collection
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
#       visibility: "public",
#
#       // Boolean indicating whether this user is following this collection.
#       followed_by_user: false,
#
#       // The number of people following this collection.
#       followers_count: 10,
#
#       // The number of items in this collection.
#       items_count: 7
#     }
#
class CollectionsController < ApplicationController
  before_filter :render_backbone_app_if_html_request
  before_filter :require_context, :only => [:index, :create]

  include Api::V1::Collection
  include Api::V1::UserFollow

  SETTABLE_ATTRIBUTES = %w(name visibility)

  # @API List user/group collections
  #
  # Returns the visible collections for the given group or user, returned
  # most-recently-created first.  If the given context is the current user or
  # a group to which the current user belongs, then all collections will be
  # returned, otherwise only public collections will be returned. In the former
  # case, if no collections exist for the context, a default, private
  # collection will be created and returned.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/users/self/collections
  #
  # @returns [Collection]
  def index
    collection_route = polymorphic_url([:api_v1, @context, :collections])
    scope = @context.collections.active.newest_first
    view_private = is_authorized_action?(@context.collections.new(:visibility => 'private'), @current_user, :read)

    ensure_default_collection_for(@context) if view_private

    unless view_private
      scope = scope.public
    end

    @collections = Api.paginate(scope, self, collection_route)
    render :json => collections_json(@collections, @current_user, session)
  end

  # @API List pinnable collections
  #
  # Returns the list of collections to which the current user has permission to
  # post.  For each possible collection context (the current user and each
  # community she belongs to) if no collections exist for the context,
  # a default, private collection will be created and included in the returned
  # list.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/collections
  #
  def list
    route = polymorphic_url([:api, :v1, :collections])

    # make sure there is a default colleciton for the current user and all
    # communities to which they belong
    ensure_default_collection_for(@current_user)
    current_communities = @current_user.current_groups.scoped(:joins => :group_category, :conditions => { :group_categories => { :role => 'communities' } }).all
    if current_communities.present?
      preload_groups_collections_counts(current_communities)
      current_communities.each{ |g| ensure_default_collection_for(g) }
    end

    scope = Collection.active.newest_first.scoped(:conditions => [<<-SQL, @current_user.id, current_communities.map(&:id)])
      (context_type='User' AND context_id=?) OR (context_type='Group' AND context_id IN (?))
    SQL

    @collections = Api.paginate(scope, self, route)
    render :json => collections_json(@collections, @current_user, session)
  end

  # @API Get a single collection
  #
  # Returns information on an individual collection. If the collection is
  # private and the caller doesn't have read access, a 401 is returned.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/collections/<collection_id>
  #
  # @returns Collection
  def show
    @collection = find_collection
    if authorized_action(@collection, @current_user, :read)
      render :json => collections_json([@collection], @current_user, session).first
    end
  end

  # @API Create a collection
  #
  # Creates a new collection. You can only create collections on your own user,
  # or on a group to which you belong.
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
  # @returns Collection
  def create
    @collection = @context.collections.new(params.slice(*SETTABLE_ATTRIBUTES))
    if authorized_action(@collection, @current_user, :create)
      if @collection.save
        render :json => collections_json([@collection], @current_user, session).first
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
  # @argument visibility The visibility of a "private" collection can be
  #     changed to "public". However, a "public" collection cannot be made
  #     "private" again.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          -X PUT \ 
  #          -F name='My Edited Collection' \ 
  #          https://<canvas>/api/v1/collections/<collection_id>
  #
  # @returns Collection
  def update
    @collection = find_collection
    if authorized_action(@collection, @current_user, :update)
      if @collection.update_attributes(params.slice(*SETTABLE_ATTRIBUTES))
        render :json => collections_json([@collection], @current_user, session).first
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
  #          https://<canvas>/api/v1/collections/<collection_id>
  #
  # @returns Collection
  def destroy
    @collection = find_collection
    if authorized_action(@collection, @current_user, :delete)
      if @collection.destroy
        render :json => collections_json([@collection], @current_user, session).first
      else
        render :json => @collection.errors, :status => :bad_request
      end
    end
  end

  # @API Follow a collection
  #
  # Follow this collection. If the current user is already following the
  # collection, nothing happens. The user must have permissions to view the
  # collection in order to follow it.
  #
  # Responds with a 401 if the user doesn't have permission to follow the
  # collection, or a 400 if the user can't follow the collection (if it's the
  # user's own collection, for example).
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/<collection_id>/followers/self \ 
  #          -X PUT \ 
  #          -H 'Content-Length: 0' \ 
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #     {
  #       following_user_id: 5,
  #       followed_collection_id: 6,
  #       created_at: <timestamp>
  #     }
  def follow
    @collection = find_collection
    if authorized_action(@collection, @current_user, :follow)
      user_follow = UserFollow.create_follow(@current_user, @collection)
      if !user_follow.new_record?
        render :json => user_follow_json(user_follow, @current_user, session)
      else
        render :json => user_follow.errors, :status => :bad_request
      end
    end
  end

  # @API Un-follow a collection
  #
  # Stop following this collection. If the current user is not already
  # following the collection, nothing happens.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/collections/<collection_id>/followers/self \ 
  #          -X DELETE \ 
  #          -H 'Authorization: Bearer <token>'
  def unfollow
    @collection = find_collection
    if authorized_action(@collection, @current_user, :follow)
      user_follow = @current_user.user_follows.find(:first, :conditions => { :followed_item_id => @collection.id, :followed_item_type => 'Collection' })
      user_follow.try(:destroy)
      render :json => { "ok" => true }
    end
  end

  protected

  def find_collection
    Collection.active.find(params[:collection_id])
  end

  def render_backbone_app_if_html_request
    if !api_request?
      render :template => "collections/collection_backbone_app"
      return false
    end
  end

  def ensure_default_collection_for(context)
    precount = @collections_counts.try(:[], context.id) if context.is_a?(Group)

    if (precount.present? && precount == 0) || (!precount.present? && context.collections.active.empty?)
      name = context.try(:default_collection_name)
      context.collections.create(:name => name, :visibility => 'private') if name
    end
  end

  def preload_groups_collections_counts(groups)
    counts_data = Collection.connection.execute(Collection.send(:sanitize_sql_array, [<<-SQL, groups.map(&:id)])).to_a
      SELECT context_id AS group_id, COUNT(*) AS collections_count 
      FROM collections 
      WHERE context_id IN (?) AND context_type='Group' AND workflow_state='active' 
      GROUP BY context_id
    SQL
    @collections_counts = {}
    counts_data.each do |cd| 
      @collections_counts[cd['group_id'].to_i] = cd['collections_count'].to_i
    end
  end
end
