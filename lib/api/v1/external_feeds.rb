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

module Api::V1::ExternalFeeds
  include Api::V1::Json

  API_ALLOWED_EXTERNAL_FEED_PARAMS = %w{url header_match verbosity}
  API_EXPOSED_EXTERNAL_FEED_PARAMS = %w(id url header_match created_at verbosity)

  def external_feeds_api_json(external_feeds, context, user, session)
    external_feeds.map do |external_feed|
      external_feed_api_json(external_feed, context, user, session)
    end
  end

  def external_feed_api_json(external_feed, context, user, session)
    options = { :only => API_EXPOSED_EXTERNAL_FEED_PARAMS,
                :methods => [:display_name]}

    api_json(external_feed, user, session, options).tap do |json|
      json.merge! :external_feed_entries_count => external_feed.external_feed_entries.size
    end

  end

  def create_api_external_feed(context, feed_params, user)
    feed = context.external_feeds.build(feed_params.slice(*API_ALLOWED_EXTERNAL_FEED_PARAMS))
    feed.user = user
    feed
  end

end
