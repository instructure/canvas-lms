# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require "net/http"
require "json"
require "uri"

module LlmConversation
  class HttpClient
    def initialize(account: nil, use_initial_token: false)
      @base_url = resolve_base_url
      @account = account
      @v2_auth = account&.feature_enabled?(:ai_experiences_v2_auth)

      if use_initial_token && @account.present? && !@v2_auth
        raise LlmConversation::Errors::ConversationError,
              "Cannot use initial token: account does not have ai_experiences_v2_auth enabled"
      end

      @bearer_token = if use_initial_token
                        Rails.application.credentials.dig(:llm_conversation_service, :initial_token)
                      elsif @v2_auth
                        LlmConversation::TokenCache.get_api_token(@account)
                      else
                        Rails.application.credentials.llm_conversation_bearer_token
                      end
    end

    def get(path)
      request(:get, path)
    end

    def post(path, payload: nil)
      request(:post, path, payload:)
    end

    def patch(path, payload: nil)
      request(:patch, path, payload:)
    end

    def delete(path)
      request(:delete, path)
    end

    private

    def refresh_v2_token!
      refresh_token = @account.settings.dig(:llm_conversation_service, :refresh_jwt_token)
      raise LlmConversation::Errors::ConversationError, "No refresh token available for account" if refresh_token.blank?

      uri = URI("#{@base_url}/token/refresh")
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme.casecmp?("https")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      req = Net::HTTP::Post.new(uri.request_uri,
                                "Content-Type" => "application/json",
                                "Authorization" => "Bearer #{refresh_token}",
                                "x-account-id" => @account.uuid)

      response = http.request(req)
      raise LlmConversation::Errors::ConversationError, "Token refresh failed" unless response.is_a?(Net::HTTPSuccess)

      result = JSON.parse(response.body)
      new_api_token = result["api_token"]
      new_refresh_token = result["refresh_token"]

      @account.settings[:llm_conversation_service] = {
        api_jwt_token: new_api_token,
        refresh_jwt_token: new_refresh_token
      }
      @account.save!

      LlmConversation::TokenCache.set_api_token(@account, new_api_token)
      @bearer_token = new_api_token
    end

    def resolve_base_url
      region = ApplicationController.region
      test_cluster = ApplicationController.test_cluster_name

      url = if test_cluster.present? && region.present?
              Setting.get("llm_conversation_base_url_beta_#{region}", nil)
            elsif region.present?
              Setting.get("llm_conversation_base_url_#{region}", nil)
            else
              Setting.get("llm_conversation_base_url", nil)
            end

      raise LlmConversation::Errors::ConversationError, base_url_error_message(region, test_cluster) if url.nil?

      url
    end

    def base_url_error_message(region, test_cluster)
      if test_cluster.present? && region.present?
        "None of llm_conversation_base_url_beta_#{region}, llm_conversation_base_url_#{region}, or llm_conversation_base_url setting is configured"
      elsif region.present?
        "Neither llm_conversation_base_url_#{region} nor llm_conversation_base_url setting is configured"
      else
        "llm_conversation_base_url setting is not configured"
      end
    end

    def request(method, path, payload: nil)
      raise LlmConversation::Errors::ConversationError, "Bearer token not configured for LLM Conversation Service" if @bearer_token.nil?

      uri = URI("#{@base_url}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme.casecmp?("https")
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{@bearer_token}",
        "x-account-id" => @account&.uuid
      }

      req = case method
            when :get
              Net::HTTP::Get.new(uri.request_uri, headers)
            when :post
              r = Net::HTTP::Post.new(uri.request_uri, headers)
              r.body = payload.to_json if payload
              r
            when :patch
              r = Net::HTTP::Patch.new(uri.request_uri, headers)
              r.body = payload.to_json if payload
              r
            when :delete
              Net::HTTP::Delete.new(uri.request_uri, headers)
            end

      response = http.request(req)

      unless response.is_a?(Net::HTTPSuccess)
        if response.is_a?(Net::HTTPUnauthorized) && @v2_auth
          refresh_v2_token!
          return request(method, path, payload:)
        end

        begin
          error_json = JSON.parse(response.body)
          error_detail = error_json["message"] || error_json["error"] || response.body
        rescue JSON::ParserError
          error_detail = response.body
        end

        raise LlmConversation::Errors::ConflictError, error_detail if response.is_a?(Net::HTTPConflict)

        raise LlmConversation::Errors::ConversationError, error_detail
      end

      response.body.present? ? JSON.parse(response.body) : nil
    rescue LlmConversation::Errors::ConversationError
      raise
    rescue Timeout::Error,
           SocketError,
           SystemCallError,
           OpenSSL::SSL::SSLError,
           JSON::ParserError,
           EOFError,
           Net::HTTPBadResponse,
           Net::ProtocolError => e
      raise LlmConversation::Errors::ConversationError, e.message
    end
  end
end
