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
require 'ims/lti'

IMS::LTI::Models::ContentItems::ContentItem.add_attribute :canvas_url, json_key: 'canvasURL'

class ExternalContentController < ApplicationController
  protect_from_forgery :except => [:selection_test, :success], with: :exception

  def success
    normalize_deprecated_data!
    @retrieved_data = {}
    if params[:service] == 'equella'
      params.each do |key, value|
        if key.to_s.match(/\Aeq_/)
          @retrieved_data[key.to_s.gsub(/\Aeq_/, "")] = value
        end
      end
    elsif params[:return_type] == 'oembed'
      js_env(oembed: {endpoint: params[:endpoint], url: params[:url]})
    elsif params[:service] == 'external_tool_dialog'
      get_context
      @retrieved_data = content_items_for_canvas
    elsif params[:service] == 'external_tool_redirect'
      @hide_message = true if params[:service] == 'external_tool_redirect'
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
        rescue URI::Error
          @retrieved_data[:url] = nil
        end
      end
    end
    if params[:id]
      message_auth = Lti::MessageAuthenticator.new(request.original_url, request.GET.merge(request.POST))
      render_unauthorized_action and return unless message_auth.valid?
      render_unauthorized_action and return unless json_data[:content_item_id] == params[:id]
      render_unauthorized_action and return unless json_data[:oauth_consumer_key] == params[:oauth_consumer_key]
    end
    @headers = false
    js_env(retrieved_data: (@retrieved_data || {}), lti_response_messages: lti_response_messages,
           service: params[:service], service_id: params[:id])
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
    begin
      res = CanvasHttp.get(uri.to_s)
      data = JSON.parse(res.body)
      content_item = Lti::ContentItemConverter.convert_oembed(data)
    rescue StandardError
      content_item = {}
    end
    render :json => [content_item]
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

  def content_items_for_canvas
    content_item_selection.map do |item|
      item.placement_advice ||= default_placement_advice
      if item.type == IMS::LTI::Models::ContentItems::LtiLinkItem::TYPE
        launch_url = item.url || json_data[:default_launch_url]
        url_gen_params = {url: launch_url}

        displays = {'iframe' => 'borderless', 'window' => 'borderless'}
        url_gen_params[:display] =
          displays[item.placement_advice.presentation_document_target]

        item.canvas_url = named_context_url(@context, :retrieve_context_external_tools_path, url_gen_params)
      end
      item
    end
  end

  private
  def content_item_selection
    if params[:lti_message_type]
      message = IMS::LTI::Models::Messages::Message.generate(request.GET && request.POST)
      message.content_items
    else
      filtered_params = params.select { |k, _| %w(url text title return_type content_type height width).include? k }.with_indifferent_access
      [Lti::ContentItemConverter.convert_resource_selection(filtered_params)]
    end
  end

  def lti_response_messages
    @lti_response_messages ||= (
      response_messages = {}

      lti_msg = param_if_set "lti_msg"
      lti_log = param_if_set "lti_log"
      lti_errormsg = param_if_set("lti_errormsg") {|error_msg| logger.warn error_msg}
      lti_errorlog = param_if_set("lti_errorlog") {|error_log| logger.warn error_log}

      response_messages[:lti_msg] = lti_msg if lti_msg
      response_messages[:lti_log] = lti_log if lti_log
      response_messages[:lti_errormsg] = lti_errormsg if lti_errormsg
      response_messages[:lti_errorlog] = lti_errorlog if lti_errorlog
      response_messages
    )
  end

  def param_if_set(param_key)
    param_value = params[param_key] && !params[param_key].empty? && params[param_key]
    if param_value && block_given?
      yield param_value
    end
    param_value
  end

  def default_placement_advice
    IMS::LTI::Models::ContentItemPlacement.new(
        presentation_document_target: 'default',
        display_height: 600,
        display_width: 800
    )
  end

  def json_data
    @json_data ||= ((params[:data] && Canvas::Security.decode_jwt(params[:data])) || {}).with_indifferent_access
  end

end
