# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module VisibilityHelpers
  module Common
    def service_cache_fetch(service:, course_ids: nil, user_ids: nil, additional_ids: nil, include_concluded: true, &)
      key = service_cache_key(service:, course_ids:, user_ids:, additional_ids:, include_concluded:)
      Rails.cache.fetch(key, expires_in: VisibilityHelpers::CacheSettings.ttl, &)
    end

    private

    def sanitize_and_stringify_ids(ids)
      return "nil" if ids.nil?

      Array(ids).map { |id| id.respond_to?(:id) ? id.id : id }.sort.join(",")
    end

    def service_cache_key(service:, course_ids: nil, user_ids: nil, additional_ids: nil, include_concluded: true)
      # Sometimes we get ids, sometimes we get full AR objects, let's sanitize
      c = sanitize_and_stringify_ids(course_ids)
      u = sanitize_and_stringify_ids(user_ids)
      a = sanitize_and_stringify_ids(additional_ids)
      Digest::SHA256.hexdigest("#{service}:#{Shard.current.id}:c#{c}:u#{u}:a#{a}:i#{include_concluded}")
    end
  end
end
