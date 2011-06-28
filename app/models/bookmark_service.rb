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

class BookmarkService < UserService
  include DeliciousDiigo
  
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
        diigo_post_bookmark(self, url, title, description, tags)
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
end
