#
# Copyright (C) 2011 Instructure, Inc.
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

require 'nokogiri'

class BookmarkService < UserService
  include Delicious
  
  def post_bookmark(opts)
    url = opts[:url]
    return unless url
    title = opts[:title] || t(:default_title, "No Title")
    description = opts[:comments] || ""
    tags = opts[:tags] || ['instructure']
    begin
      if(self.service == 'delicious')
        delicious_post_bookmark(self, url, title, description, tags)
      elsif(self.service == 'diigo')
        Diigo::Connection.diigo_post_bookmark(self, url, title, description, tags)
      end
    rescue => e
      # Should probably save the data to try again if it fails... at least one more try
    end
  end
  
  def find_bookmarks(query)
    if self.service == 'diigo'
      last_get = Rails.cache.fetch('last_diigo_lookup') { Time.now - 60 }
      if Time.now - last_get < 8
        Rails.cache.write('last_diigo_lookup', Time.now)
        sleep Time.now - last_get
      end
      Rails.cache.write('last_diigo_lookup', Time.now)
    end
    bookmark_search(self, query)
  end

  def bookmark_search(service, query)
    bookmarks = []
    if service.service == 'diigo'
      data = Diigo::Connection.diigo_get_bookmarks(service)
      if data.class == Array and data.first.is_a?(Hash)
        data.each do |bookmark|
          bookmarks << {
            :title => bookmark['title'],
            :url => bookmark['url'],
            :description => bookmark['desc'],
            :tags => bookmark['tags'].split(/\s/).join(",")
          }
        end
      else
        bookmarks
      end
    elsif service.service == 'delicious'
      #This needs to be rewritten with new API and moved into a gem. (Currently not working and no way to test without updating the API.)
      url = "https://api.del.icio.us/v1/posts/all?tag=#{query}"
      http,request = delicious_generate_request(url, 'GET', service.service_user_name, service.decrypted_password)
      response = http.request(request)
      case response
      when Net::HTTPSuccess
        document = Nokogiri::XML(response.body)
        document.search('/posts/post').each do |post|
          bookmarks << {
            :title => post['description'],
            :url => post['href'],
            :description => post['description'],
            :tags => post['tags']
          }
        end
      else
        response.error!
      end
    end
    bookmarks
  end
end
