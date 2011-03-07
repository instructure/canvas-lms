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

require 'action_controller/url_rewriter'
 
module ActionController
  class UrlRewriter
    
    # Add a secure option to the rewrite method.
    def rewrite_with_secure_option(options = {})
      secure = options.delete(:secure)
      if !secure.nil?
        if secure == true || secure == 1 || secure.to_s.downcase == "true"
          options.merge!({
            :only_path => false,
            :protocol => 'https'
          })
        else
          options.merge!({
            :only_path => false,
            :protocol => 'http'
          })
        end
      end
      
      rewrite_without_secure_option(options)
    end
    alias_method_chain :rewrite, :secure_option
  end
end