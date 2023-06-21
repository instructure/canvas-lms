# frozen_string_literal: true

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
#

class PageView
  class Pv4Client
    class Pv4Timeout < StandardError; end

    def initialize(uri, access_token)
      uri = URI.parse(uri) if uri.is_a?(String)
      @uri, @access_token = uri, access_token
    end

    PRECISION = 3

    def fetch(user_id,
              start_time: nil,
              end_time: Time.now.utc,
              last_page_view_id: nil,
              limit: nil)
      end_time ||= Time.now.utc
      start_time ||= Time.at(0).utc

      params = +"start_time=#{start_time.utc.iso8601(PRECISION)}"
      params << "&end_time=#{end_time.utc.iso8601(PRECISION)}"
      params << "&last_page_view_id=#{last_page_view_id}" if last_page_view_id
      params << "&limit=#{limit}" if limit
      response = CanvasHttp.get(
        @uri.merge("users/#{user_id}/page_views?#{params}").to_s,
        { "Authorization" => "Bearer #{@access_token}" }
      )

      json = JSON.parse(response.body)
      raise response.body unless json["page_views"]

      json["page_views"].map! do |pv|
        pv["session_id"] = pv.delete("sessionid")
        pv["url"] = "#{HostUrl.protocol}://#{pv.delete("vhost")}#{pv.delete("http_request")}"
        pv["context_id"] = pv.delete("canvas_context_id")
        pv["context_type"] = pv.delete("canvas_context_type")
        pv["updated_at"] = pv["created_at"] = pv.delete("timestamp")
        pv["user_agent"] = pv.delete("agent")
        pv["account_id"] = pv.delete("root_account_id")
        pv["remote_ip"] = pv.delete("client_ip")
        pv["render_time"] = pv.delete("microseconds").to_f / 1_000_000
        pv["http_method"].try(:downcase!)
        pv["developer_key_id"] = pv.delete("developer_key_id")

        PageView.from_attributes(pv)
      end
    rescue Net::ReadTimeout
      raise Pv4Timeout, "failed to load page view history due to service timeout"
    end

    def for_user(user_id, oldest: nil, newest: nil)
      bookmarker = Bookmarker.new(self)
      BookmarkedCollection.build(bookmarker) do |pager|
        bookmark = pager.current_bookmark
        if bookmark
          end_time, last_page_view_id = bookmark
          newest = Time.zone.parse(end_time)
        end
        pager.replace(fetch(user_id,
                            start_time: oldest,
                            end_time: newest,
                            last_page_view_id:,
                            limit: pager.per_page))
        pager.has_more! unless pager.empty?
        pager
      end
    end

    class Bookmarker
      def initialize(client)
        @client = client
      end

      def bookmark_for(pv)
        [pv&.created_at&.iso8601(PRECISION), pv&.request_id]
      end

      def validate(bookmark)
        bookmark.is_a?(Array) && bookmark.size == 2
      end
    end
  end
end
