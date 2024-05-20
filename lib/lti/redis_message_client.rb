# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::RedisMessageClient
  TTL = 5.minutes
  LTI_1_3_PREFIX = "external_tool:id_token:"
  SESSIONLESS_LAUNCH_PREFIX = "external_tool:sessionless_launch:"

  def cache_launch(launch, context, prefix: LTI_1_3_PREFIX)
    return unless Canvas.redis_enabled?

    verifier = SecureRandom.hex(64)
    Canvas.redis.setex("#{context.class.name}:#{prefix}#{verifier}", TTL, launch.to_json)
    verifier
  end

  def fetch_and_delete_launch(context, verifier, prefix: LTI_1_3_PREFIX)
    return unless Canvas.redis_enabled?

    redis_key = "#{context.class.name}:#{prefix}#{verifier}"
    launch = Canvas.redis.get(redis_key)
    Canvas.redis.del(redis_key)
    launch
  end
end
