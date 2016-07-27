#
# Copyright (C) 2011 - 2016 Instructure, Inc.
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
module Lti
  class MessageAuthenticator
    CACHE_KEY_PREFIX = 'lti_nonce_'
    NONCE_EXPIRATION = 10.minutes

    def initialize(launch_url, params)
      @params = params.with_indifferent_access
      @launch_url = launch_url
      @version = @params[:lti_version]
      @nonce = @params[:oauth_nonce]
      @oauth_consumer_key = @params[:oauth_consumer_key]
    end

    def valid?
      @valid ||= begin
        valid = lti_message_authenticator.valid_signature?
        valid &&= @params[:oauth_timestamp].to_i > NONCE_EXPIRATION.ago.to_i
        valid &&= !Rails.cache.exist?(cache_key)
        Rails.cache.write(cache_key, 'OK', expires_in: NONCE_EXPIRATION) if valid
        valid
      end
    end

    def message
      lti_message_authenticator.message
    end

    private

    def lti_message_authenticator
      @lti_message_authenticator ||= IMS::LTI::Services::MessageAuthenticator.new(@launch_url, @params, shared_secret)
    end

    def shared_secret
      @shared_secret ||=
        if @version.strip == 'LTI-1p0'
          tool = ContextExternalTool.where(consumer_key: @params[:oauth_consumer_key]).first
          tool && tool.shared_secret
        end
    end

    def cache_key
      "#{CACHE_KEY_PREFIX}_#{@oauth_consumer_key}_#{@nonce}"
    end

  end
end