# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# This would normally be in an initializer, but
# other initialization processes can depend on it.
# By putting it in this module we can invoke it from
# an initializer in config/initializers and also from application.rb to force
# it to run early in the init order.
class CanvasCacheInit
  def self.apply!
    unless CanvasCache.settings_store(true) == Setting
      # to avoid having to pull this out as a full engine yet.
      # we may extract Setting into an engine or an abstract gem
      # or something, for now this pattern breaks the explicit dependency.
      CanvasCache.settings_store = Setting

      # It would be great to pull out Canvas::Errors as a gem, and we should do so.
      # The problem is it has a dependency on RequestContextGenerator, which
      # has a dependency on Canvas::Security, which has a dependency on
      # our caching, and so we have to break the chain somewhere.  We're starting
      # with the caching.  TODO: Once canvas errors is out on it's own we can let
      # CanvasCache take a dependency on it directly and forego this injection.
      CanvasCache.on_captured_error = ->(e){ Canvas::Errors.capture_exception(:redis, e, :warn) }
    end
  end
end