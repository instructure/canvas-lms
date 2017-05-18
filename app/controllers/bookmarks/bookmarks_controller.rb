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

# @API Bookmarks
#
# @model Bookmark
#     {
#       "id": "Bookmark",
#       "description": "",
#       "properties": {
#         "id": {
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "example": "Biology 101",
#           "type": "string"
#         },
#         "url": {
#           "example": "/courses/1",
#           "type": "string"
#         },
#         "position": {
#           "example": 1,
#           "type": "integer"
#         },
#         "data": {
#           "example": { "active_tab": 1 },
#           "type": "object"
#         }
#       }
#     }
class Bookmarks::BookmarksController < ApplicationController
  before_action :require_user
  before_action :find_bookmark, :only => [:show, :update, :destroy]

  # @API List bookmarks
  # Returns the list of bookmarks.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/bookmarks' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns [Bookmark]
  def index
    @bookmarks = Bookmarks::Bookmark.where(user_id: user_id).order(:position)
    @bookmarks = Api.paginate(@bookmarks, self, api_v1_bookmarks_url)
    render json: @bookmarks.as_json
  end

  # @API Create bookmark
  # Creates a bookmark.
  #
  # @argument name [String]
  #   The name of the bookmark
  #
  # @argument url [String]
  #   The url of the bookmark
  #
  # @argument position [Integer]
  #   The position of the bookmark. Defaults to the bottom.
  #
  # @argument data
  #   The data associated with the bookmark
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/bookmarks' \
  #        -F 'name=Biology 101' \
  #        -F 'url=/courses/1' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns Bookmark
  def create
    if (@bookmark = Bookmarks::Bookmark.create(valid_params)) && set_position
      show
    else
      render_errors
    end
  end

  # @API Get bookmark
  # Returns the details for a bookmark.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/bookmarks/1' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns Bookmark
  def show
    render json: @bookmark.as_json
  end

  # @API Update bookmark
  # Updates a bookmark
  #
  # @argument name [String]
  #   The name of the bookmark
  #
  # @argument url [String]
  #   The url of the bookmark
  #
  # @argument position [Integer]
  #   The position of the bookmark. Defaults to the bottom.
  #
  # @argument data
  #   The data associated with the bookmark
  #
  # @example_request
  #
  #   curl -X PUT 'https://<canvas>/api/v1/users/self/bookmarks/1' \
  #        -F 'name=Biology 101' \
  #        -F 'url=/courses/1' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @returns Folder
  def update
    if @bookmark.update_attributes(valid_params) && set_position
      show
    else
      render_errors
    end
  end

  # @API Delete bookmark
  # Deletes a bookmark
  #
  # @example_request
  #   curl -X DELETE 'https://<canvas>/api/v1/users/self/bookmarks/1' \
  #        -H 'Authorization: Bearer <token>'
  def destroy
    if @bookmark.destroy
      show
    else
      render_errors
    end
  end

  private

  def user_id
    @current_user.id
  end

  def find_bookmark
    unless (@bookmark = Bookmarks::Bookmark.where(id: params[:id], user_id: user_id).first)
      head 404
    end
  end

  def valid_params
    params.permit(:name, :url, data: strong_anything).merge(user_id: user_id)
  end

  def set_position
    params[:position] ? @bookmark.insert_at(params[:position].to_i) : true
  end

  def render_errors
    render :json => {errors: @bookmark.errors}, :status => :bad_request
  end
end
