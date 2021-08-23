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

require 'securerandom'
require 'canvas_security'

# this adds the cookie_jar method to the
# action dispatch request, if it's not loaded
# then there is no "cookie_jar"
require 'action_dispatch/middleware/cookies'

module RequestContext
  ##
  # RequestContext::Generator is a rails middleware for making
  # sure every request into the app has a unique request id,
  # either provided in the "env" hash already from an HTTP header
  # (which must be properly signed to be valid), in the case of a request
  # initiating from another service inside the canvas ecosystem, or
  # generating a new one.  Either way we store that current request
  # on the current thread and other areas of the app can use this class to
  # read the current request ID without having to know the way it's stored.
  #
  # This also is a convenient place to add additional header info that
  # we want to leave with the response without having to pipe it through
  # every layer in between (see ".add_meta_header")
  class Generator
    def initialize(app)
      @app = app
    end

    def call(env)
      request_id = generate_request_id(env)

      # rack.session.options (where the session_id is saved by our session
      # store) isn't availalbe at this point in the middleware stack. It is
      # lazily loaded the first time the session is accessed, so we won't get
      # session_ids in the log on the very first request (usually loading the
      # login page).  It is written out to a cookie so that we can pick it up for
      # logs in subsequent requests. See RequestContextSession, we can't write it
      # to a cookie in this middleware because the cookie header has already been
      # written by the time this app.call returns.
      session_id = ActionDispatch::Request.new(env).cookie_jar[:log_session_id]
      meta_headers = +""
      Thread.current[:context] = {
        request_id:   request_id,
        session_id:   session_id,
        meta_headers: meta_headers,
      }

      # logged here to get as close to the beginning of the request being
      # processed as possible
      RequestContext::Generator.store_request_queue_time(env['HTTP_X_REQUEST_START'])

      status, headers, body = @app.call(env)

      # The session id may have been reset in the request, in which case
      # we want to log the new one,
      session_id = (env['rack.session.options'] || {})[:id]
      headers['X-Session-Id'] = session_id if session_id
      headers['X-Request-Context-Id'] = request_id
      headers['X-Canvas-Meta'] = meta_headers if meta_headers.present?

      [ status, headers, body ]
    end

    def self.request_id
      Thread.current[:context].try(:[], :request_id)
    end

    def self.add_meta_header(name, value)
      return if value.blank?
      meta_headers = Thread.current[:context].try(:[], :meta_headers)
      return if !meta_headers
      meta_headers << "#{name}=#{value};"
    end

    def self.store_interaction_seconds_update(token, interaction_seconds)
      data = CanvasSecurity::PageViewJwt.decode(token)
      if data
        self.add_meta_header("r", "#{data[:request_id]}|#{data[:created_at]}|#{interaction_seconds}")
      end
    end

    def self.store_request_queue_time(header_val)
      if header_val
        match = header_val.match(/t=(?<req_start>\d+)/)
        return unless match

        delta = (Time.now.utc.to_f * 1000000).to_i - match['req_start'].to_i
        RequestContext::Generator.add_meta_header("q", delta)
      end
    end

    def self.store_request_meta(request, context)
      self.add_meta_header("o", request.path_parameters[:controller])
      self.add_meta_header("n", request.path_parameters[:action])
      if context
        self.add_meta_header("t", context.class)
        self.add_meta_header("i", context.id)
      end
    end

    ##
    # store_page_view_meta takes a specific set of attributes
    # we care about from an interaction and maps them to pre-defined
    # single-character meta headers.  This can be read and consumed
    # by the logging pipeline downstream.
    #
    # PageView duck type:
    #   @field [Float] interaction_seconds
    #   @field [Boolean] participated?
    #   @field [Int] asset_user_access_id
    #   @field [DateTime] created_at
    #
    # @param [PageView] the bundle of attributes we want to map to meta headers
    def self.store_page_view_meta(page_view)
      self.add_meta_header("x", page_view.interaction_seconds)
      self.add_meta_header("p", page_view.participated? ? "t" : "f")
      self.add_meta_header("e", page_view.asset_user_access_id)
      self.add_meta_header("f", page_view.created_at.try(:utc).try(:iso8601, 2))
    end

    private
    def generate_request_id(env)
      if env['HTTP_X_REQUEST_CONTEXT_ID'] && env['HTTP_X_REQUEST_CONTEXT_SIGNATURE']
        request_context_id = CanvasSecurity.base64_decode(env['HTTP_X_REQUEST_CONTEXT_ID'])
        request_context_signature = CanvasSecurity.base64_decode(env['HTTP_X_REQUEST_CONTEXT_SIGNATURE'])
        if CanvasSecurity.verify_hmac_sha512(request_context_id, request_context_signature)
          return request_context_id
        else
          Rails.logger.info("ignoring X-Request-Context-Id header, signature could not be verified")
        end
      end
      SecureRandom.uuid
    end
  end
end
