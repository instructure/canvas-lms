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

class ExternalContentController < ApplicationController
  protect_from_forgery :except => [:selection_test]
  def success
    @retrieved_data = {}
    # TODO: poll for data if it's oembed
    if params[:service] == 'equella'
      params.each do |key, value|
        if key.to_s.match(/\Aeq_/)
          @retrieved_data[key.to_s.gsub(/\Aeq_/, "")] = value
        end
      end
    elsif params[:service] == 'external_tool'
      params[:embed_type] = nil unless ['basic_lti', 'link', 'image', 'iframe'].include?(params[:embed_type])
      @retrieved_data = request.query_parameters
      if @retrieved_data[:url]
        begin
          uri = URI.parse(@retrieved_data[:url])
          unless uri.scheme
            value = "http://#{value}"
            uri = URI.parse(value)
          end
          @retrieved_data[:url] = uri.to_s
        rescue URI::InvalidURIError
          @retrieved_data[:url] = nil
        end
      end
    end
    @headers = false
  end
  
  def selection_test
    @headers = false
  end
  
  def cancel
    @headers = false
  end
end
