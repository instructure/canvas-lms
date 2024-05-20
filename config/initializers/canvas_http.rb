# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

CanvasHttp.logger = -> { Rails.logger }

module CanvasHttpInitializer
  def self.configure_circuit_breaker!
    # need some place to store circuit breaker information so we don't
    # have to have each process store it's own circuit breaker
    # state
    CanvasHttp::CircuitBreaker.redis = lambda do
      return MultiCache.cache.redis if MultiCache.cache.respond_to?(:redis)
      return Canvas.redis if Canvas.redis_enabled?

      nil
    end
  end
end

CanvasHttpInitializer.configure_circuit_breaker!
