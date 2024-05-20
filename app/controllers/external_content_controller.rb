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
require "ims/lti"

IMS::LTI::Models::ContentItems::ContentItem.add_attribute :canvas_url, json_key: "canvasURL"

class ExternalContentController < ApplicationController
  include Lti::Concerns::Oembed
  include Lti::Concerns::ParentFrame

  protect_from_forgery except: [:selection_test, :success], with: :exception

  before_action :require_user, only: :oembed_retrieve
  before_action :check_disable_oembed_retrieve_feature_flag, only: :oembed_retrieve
  before_action :validate_oembed_token!, only: :oembed_retrieve

  rescue_from Lti::Concerns::Oembed::OembedAuthorizationError do |error|
    render json: { message: error.message }, status: :unauthorized
  end

  rescue_from JSON::JWT::InvalidFormat do
    head :bad_request
  end

  def success
    normalize_deprecated_data!
    @retrieved_data = {}
    if params[:service] == "equella"
      params.each do |key, value|
        if key.to_s.start_with?("eq_")
          @retrieved_data[key.to_s.delete_prefix("eq_")] = value
        end
      end
    elsif params[:return_type] == "oembed"
      js_env(oembed: { endpoint: params[:endpoint], url: params[:url] })
      @oembed_token = params[:oembed_token]
    elsif params[:service] == "external_tool_dialog"
      get_context
      @retrieved_data = content_items_for_canvas
    elsif params[:service] == "external_tool_redirect"
      @hide_message = true
      params[:return_type] = nil unless %w[oembed lti_launch_url url image_url iframe file].include?(params[:return_type])
      @retrieved_data = params
      if @retrieved_data[:url] && ["oembed", "lti_launch_url"].include?(params[:return_type])
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

    js_env({
             retrieved_data: @retrieved_data || {},
             lti_response_messages:,
             service: params[:service],
             service_id: params[:id],
             message: param_if_set(:lti_msg),
             log: param_if_set(:lti_log),
             error_message: param_if_set(:lti_errormsg),
             error_log: param_if_set(:lti_errorlog)
           })
    if parent_frame_origin
      js_env({ DEEP_LINKING_POST_MESSAGE_ORIGIN: parent_frame_origin }, true)
      set_extra_csp_frame_ancestor!
    end
  end

  def normalize_deprecated_data!
    params[:return_type] = params[:embed_type] if !params.key?(:return_type) && params.key?(:embed_type)

    return_types = { "basic_lti" => "lti_launch_url", "link" => "url", "image" => "image_url" }
    params[:return_type] = return_types[params[:return_type]] if return_types.key? params[:return_type]
  end

  def check_disable_oembed_retrieve_feature_flag
    if @domain_root_account.feature_enabled?(:disable_oembed_retrieve)
      render json: { message: "This endpoint is no longer supported." }, status: :gone
    end
  end

  def oembed_retrieve
    begin
      res = CanvasHttp.get(oembed_object_uri.to_s)
      data = JSON.parse(res.body)
      content_item = Lti::ContentItemConverter.convert_oembed(data)
    rescue
      content_item = {}
    end
    render json: [content_item]
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
      head :bad_request
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
        url_gen_params = { url: launch_url }

        displays = { "iframe" => "borderless", "window" => "borderless" }
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
      filtered_params = params.permit(*%w[url text title return_type content_type height width])
      [Lti::ContentItemConverter.convert_resource_selection(filtered_params)]
    end
  end

  def lti_response_messages
    @lti_response_messages ||= begin
      response_messages = {}

      lti_msg = param_if_set "lti_msg"
      lti_log = param_if_set "lti_log"
      lti_errormsg = param_if_set("lti_errormsg") { |error_msg| logger.warn error_msg }
      lti_errorlog = param_if_set("lti_errorlog") { |error_log| logger.warn error_log }

      response_messages[:lti_msg] = lti_msg if lti_msg
      response_messages[:lti_log] = lti_log if lti_log
      response_messages[:lti_errormsg] = lti_errormsg if lti_errormsg
      response_messages[:lti_errorlog] = lti_errorlog if lti_errorlog
      response_messages
    end
  end

  def param_if_set(param_key)
    param_value = params[param_key].present? && params[param_key]
    param_value = param_value.to_s if param_value
    if param_value && block_given?
      yield param_value
    end
    param_value
  end

  def default_placement_advice
    IMS::LTI::Models::ContentItemPlacement.new(
      presentation_document_target: "default",
      display_height: 600,
      display_width: 800
    )
  end

  def json_data
    @json_data ||= ((params[:data] && Canvas::Security.decode_jwt(params[:data])) || {}).with_indifferent_access
  end
end
