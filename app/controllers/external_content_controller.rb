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
    normalize_deprecated_data!
    @retrieved_data = {}
    # TODO: poll for data if it's oembed
    if params[:service] == 'equella'
      params.each do |key, value|
        if key.to_s.match(/\Aeq_/)
          @retrieved_data[key.to_s.gsub(/\Aeq_/, "")] = value
        end
      end
    elsif params[:service] == 'external_tool_dialog' || params[:service] == 'external_tool_redirect'
      params[:return_type] = nil unless ['oembed', 'lti_launch_url', 'url', 'image_url', 'iframe', 'file'].include?(params[:return_type])
      @retrieved_data = params
      if @retrieved_data[:url] && ['oembed', 'lti_launch_url'].include?(params[:return_type])
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
    js_env(retrieved_data: (@retrieved_data || {}),
           service: params[:service])
  end

  def normalize_deprecated_data!
    params[:return_type] = params[:embed_type] if !params.key?(:return_type) && params.key?(:embed_type)

    return_types = {'basic_lti' => 'lti_launch_url', 'link' => 'url', 'image' => 'image_url'}
    params[:return_type] = return_types[params[:return_type]] if return_types.key? params[:return_type]

  end
  
  def oembed_retrieve
    endpoint = params[:endpoint]
    url = params[:url]
    uri = URI.parse(endpoint + (endpoint.match(/\?/) ? '&url=' : '?url=') + CGI.escape(url) + '&format=json')
    res = CanvasHttp.get(uri.to_s) rescue '{}'
    data = JSON.parse(res.body) rescue {}
    if data['type']
      if data['type'] == 'photo' && data['url'].try(:match, /^http/)
        @retrieved_data = {
          :return_type => 'image_url',
          :url => data['url'],
          :width => data['width'].to_i,   # width and height are required according to the spec
          :height => data['height'].to_i,
          :alt => data['title']
        }
      elsif data['type'] == 'link' && data['url'].try(:match, /^(http|https|mailto)/)
        @retrieved_data = {
          :return_type => 'url',
          :url => data['url'] || params[:url],
          :title => data['title'],
          :text => data['title']
        }
      elsif data['type'] == 'video' || data['type'] == 'rich'
        @retrieved_data = {
          :return_type => 'rich_content',
          :html => data['html']
        }
      end
    else
      @retrieved_data = {
        :embed_type => 'error',
        :message => t("#application.errors.invalid_oembed_url", "There was a problem retrieving this resource. The external tool provided invalid information about the resource.")
      }
    end
    render :json => @retrieved_data
  end

  # this is a simple LTI link selection extension example
  # it's used by the selenium specs, and can be useful to demonstrate link
  # selection and test configuration
  def selection_test
    @return_url = params[:launch_presentation_return_url]
    if @return_url
      uri = URI.parse(@return_url)
      @return_url = nil unless uri.is_a?(URI::HTTP)
    end
    if @return_url.blank?
      render :nothing => true, :status => 400
    end
    @headers = false
  end
  
  def cancel
    @headers = false
    js_env(service: params[:service])
  end
end
