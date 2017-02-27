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

# @API Announcement External Feeds
#
# External feeds represent RSS feeds that can be attached to a Course or Group,
# in order to automatically create announcements for each new item in
# the feed.
#
# @model ExternalFeed
#     {
#       "id": "ExternalFeed",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The ID of the feed",
#           "example": 5,
#           "type": "integer"
#         },
#         "display_name": {
#           "description": "The title of the feed, pulled from the feed itself. If the feed hasn't yet been pulled, a temporary name will be synthesized based on the URL",
#           "example": "My Blog",
#           "type": "string"
#         },
#         "url": {
#           "description": "The HTTP/HTTPS URL to the feed",
#           "example": "http://example.com/myblog.rss",
#           "type": "string"
#         },
#         "header_match": {
#           "description": "If not null, only feed entries whose title contains this string will trigger new posts in Canvas",
#           "example": "pattern",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "When this external feed was added to Canvas",
#           "example": "2012-06-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "verbosity": {
#           "description": "The verbosity setting determines how much of the feed's content is imported into Canvas as part of the posting. 'link_only' means that only the title and a link to the item. 'truncate' means that a summary of the first portion of the item body will be used. 'full' means that the full item body will be used.",
#           "example": "truncate",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "link_only",
#               "truncate",
#               "full"
#             ]
#           }
#         }
#       }
#     }
#
class ExternalFeedsController < ApplicationController
  include Api::V1::ExternalFeeds

  before_action :require_context

  # @API List external feeds
  #
  # Returns the list of External Feeds this course or group.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/external_feeds \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [ExternalFeed]
  def index
    if authorized_action(@context.announcements.temp_record, @current_user, :create)
      api_route = polymorphic_url([:api, :v1, @context, :external_feeds])
      @feeds = Api.paginate(@context.external_feeds.order(:id), self, api_route)
      render :json => external_feeds_api_json(@feeds, @context, @current_user, session)
    end
  end

  # @API Create an external feed
  #
  # Create a new external feed for the course or group.
  #
  # @argument url [Required, String]
  #   The url to the external rss or atom feed
  #
  # @argument header_match [Boolean]
  #   If given, only feed entries that contain this string in their title will be imported
  #
  # @argument verbosity [String, "full"|"truncate"|"link_only"]
  #   Defaults to "full"
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/external_feeds \
  #         -F url='http://example.com/rss.xml' \
  #         -F header_match='news flash!' \
  #         -F verbosity='full' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns ExternalFeed
  def create
    if authorized_action(@context.announcements.temp_record, @current_user, :create)
      @feed = create_api_external_feed(@context, params, @current_user)
      if @feed.save
        render :json => external_feed_api_json(@feed, @context, @current_user, session)
      else
        render :json => @feed.errors, :status => :bad_request
      end
    end
  end

  # @API Delete an external feed
  #
  # Deletes the external feed.
  #
  # @example_request
  #     curl -X DELETE https://<canvas>/api/v1/courses/<course_id>/external_feeds/<feed_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns ExternalFeed
  def destroy
    if authorized_action(@context.announcements.temp_record, @current_user, :create)
      @feed = @context.external_feeds.find(params[:external_feed_id])
      if @feed.destroy
        render :json => external_feed_api_json(@feed, @context, @current_user, session)
      else
        render :json => @feed.errors, :status => :bad_request
      end
    end
  end

end
