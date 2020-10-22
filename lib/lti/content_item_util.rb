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
module Lti
  class ContentItemUtil
    attr_reader :content_item

    def initialize(ci)
      @content_item = ci
      @callback_url = content_item["confirmUrl"]
    end

    def success_callback
      callback(:post)
    end

    def failure_callback
      callback(:delete)
    end

    private

    def callback(method)
      CanvasHttp.delay(priority: Delayed::LOW_PRIORITY, max_attempts: 3).__send__(method, @callback_url) if @callback_url
    end

  end
end
