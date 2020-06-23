#
# Copyright (C) 2019 - present Instructure, Inc.
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

# @API History
#
# @model HistoryEntry
#     {
#       "id": "HistoryEntry",
#       "description": "Information about a recently visited item or page in Canvas",
#       "required": ["asset_code","asset_name","visited_url","visited_at"],
#       "properties": {
#         "asset_code": {
#           "description": "The asset string for the item viewed",
#           "example": "assignment_123",
#           "type": "string"
#         },
#         "asset_name": {
#           "description": "The name of the item",
#           "example": "Test Assignment",
#           "type": "string"
#         },
#         "asset_icon": {
#           "description": "The icon type shown for the item. One of 'icon-announcement', 'icon-assignment', 'icon-calendar-month', 'icon-discussion', 'icon-document', 'icon-download', 'icon-gradebook', 'icon-home', 'icon-message', 'icon-module', 'icon-outcomes', 'icon-quiz', 'icon-user', 'icon-syllabus'",
#           "example": "icon-assignment",
#           "type": "string"
#         },
#         "context_type": {
#           "description": "The type of context of the item visited. One of 'Course', 'Group', 'User', or 'Account'",
#           "type": "string",
#           "example": "Course"
#         },
#         "context_id": {
#           "description": "The id of the context, if applicable",
#           "type": "integer",
#           "format": "int64",
#           "example": 123
#         },
#         "context_name": {
#           "description": "The name of the context",
#           "type": "string",
#           "example": "Something 101"
#         },
#         "visited_url": {
#           "description": "The URL of the item",
#           "example": "https://canvas.example.com/courses/123/assignments/456",
#           "type": "string"
#         },
#         "visited_at": {
#           "description": "When the page was visited",
#           "example": "2019-08-01T19:49:47Z",
#           "type": "datetime",
#           "format": "iso8601"
#         },
#         "interaction_seconds": {
#           "description": "The estimated time spent on the page in seconds",
#           "type": "integer",
#           "format": "int64",
#           "example": 400
#         }
#       }
#     }
#

class HistoryController < ApplicationController
  before_action :require_user

  include Api::V1::HistoryEntry

  # @API List recent history for a user
  # Return a paginated list of the user's recent history. History entries are returned in descending order,
  # newest to oldest. You may list history entries for yourself (use +self+ as the user_id), for a student you observe,
  # or for a user you manage as an administrator. Note that the +per_page+ pagination argument is not supported
  # and the number of history entries returned per page will vary.
  #
  # @returns [HistoryEntry]
  def index
    @user = api_find(User, params[:user_id])
    return render_unauthorized_action unless @user.grants_right?(@current_user, :read)

    # ignore provided per_page argument since we have to manually filter page views that contain asset_user_accesses
    # and the default page size may result in a lot of empty pages
    page_views = Api.paginate(@user.page_views(oldest: 3.weeks.ago),
                              self,
                              api_v1_user_history_url(user_id: @user.id),
                              per_page: 100,
                              total_entries: nil)
    page_views = page_views.to_a.select { |pv| pv.asset_user_access_id.present? && pv.real_user_id == @real_current_user&.id }

    auas = AssetUserAccess.where(id: page_views.map(&:asset_user_access_id)).preload(:context).to_a.index_by(&:id)

    render json: page_views.map { |pv| history_entry_json(pv, auas[pv.asset_user_access_id], @current_user, session) }
  end
end

