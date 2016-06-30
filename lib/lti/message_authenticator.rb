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
    attr_reader :message

    CACHE_KEY_PREFIX = 'lti_nonce_'
    NONCE_EXPIRATION = 10.minutes

    def initialize(launch_url, params)
      @message = IMS::LTI::Models::Messages::Message.generate(params)
      @version = @message.lti_version
      @message.launch_url = launch_url
    end

    def valid?
      @valid ||= begin
        valid = message.valid_signature?(shared_secret)
        valid &&= message.oauth_timestamp.to_i > NONCE_EXPIRATION.ago.to_i
        valid &&= !Rails.cache.exist?(cache_key)
        Rails.cache.write(cache_key, message.oauth_consumer_key, expires_in: NONCE_EXPIRATION) if valid
        valid
      end
    end

    private

    def shared_secret
      @shared_secret ||=
        if @version.strip == 'LTI-1p0'
          tool = ContextExternalTool.where(consumer_key: message.oauth_consumer_key).first
          tool && tool.shared_secret
        end
    end

    def cache_key
      CACHE_KEY_PREFIX+@message.oauth_nonce
    end

  end
end