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

require 'net/https'

class SSLCommon
  SSL_CA_PATH = "/etc/ssl/certs/"
  
  class <<self
    def get_http_conn(host, port, ssl)
      http = Net::HTTP.new(host, port)
      http.use_ssl = true if ssl
      if File.directory? SSL_CA_PATH
        http.ca_path = SSL_CA_PATH
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      http 
    end
    
    def post_form(url, form_data)
      url = URI.parse(url)
      http = self.get_http_conn(url.host, url.port, url.scheme == 'https')
      req = Net::HTTP::Post.new(url.path)
      req.form_data = form_data
      http.start {|http| http.request(req) }
    end
  end
end

