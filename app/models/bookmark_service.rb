# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require "nokogiri"

class BookmarkService < UserService
  def post_bookmark(opts)
    url = opts[:url]
    return unless url

    title = opts[:title] || t(:default_title, "No Title")
    description = opts[:comments] || ""
    tags = opts[:tags] || ["instructure"]
    begin
      case service
      when "diigo"
        Diigo::Connection.diigo_post_bookmark(self, url, title, description, tags)
      else
        raise "Unknown bookmark service: #{service}"
      end
    rescue
      # Should probably save the data to try again if it fails... at least one more try
    end
  end

  def find_bookmarks
    if service == "diigo"
      last_get = Rails.cache.fetch("last_diigo_lookup") { Time.now - 60 }
      if Time.now - last_get < 8
        Rails.cache.write("last_diigo_lookup", Time.now)
        sleep Time.now - last_get
      end
      Rails.cache.write("last_diigo_lookup", Time.now)
    end
    bookmark_search(self)
  end

  def bookmark_search(service)
    bookmarks = []
    case service.service
    when "diigo"
      data = Diigo::Connection.diigo_get_bookmarks(service)
      if data.instance_of?(Array) && data.first.is_a?(Hash)
        data.each do |bookmark|
          bookmarks << {
            title: bookmark["title"],
            url: bookmark["url"],
            description: bookmark["desc"],
            tags: bookmark["tags"].split(/\s/).join(",")
          }
        end
      else
        bookmarks
      end
    else
      raise "Unknown bookmark service: #{service}"
    end
    bookmarks
  end
end
