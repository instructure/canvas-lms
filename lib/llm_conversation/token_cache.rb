# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module LlmConversation
  class TokenCache
    KEY_PREFIX = "llm_conversation_service:auth"
    TTL = 1.hour.to_i

    def self.get_api_token(account)
      if Canvas.redis_enabled?
        cached = Canvas.redis.get(cache_key(account))
        return cached if cached
      end

      token = account.settings.dig(:llm_conversation_service, :api_jwt_token)
      Canvas.redis.setex(cache_key(account), TTL, token) if Canvas.redis_enabled? && token.present?
      token
    end

    def self.set_api_token(account, token)
      return unless Canvas.redis_enabled? && token.present?

      Canvas.redis.setex(cache_key(account), TTL, token)
    end

    def self.invalidate(account)
      return unless Canvas.redis_enabled?

      Canvas.redis.del(cache_key(account))
    end

    def self.cache_key(account)
      "#{KEY_PREFIX}:#{account.global_id}:api_token"
    end
    private_class_method :cache_key
  end
end
