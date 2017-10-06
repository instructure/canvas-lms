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

# Traps SIGHUP to clear the Setting cache and other associated caches, without requiring a full restart of
# Canvas
module Canvas::Reloader
  class << self
    attr_reader :pending_reload

    def reload!
      Rails.logger.info("Canvas::Reloader fired")
      @pending_reload = false
      Setting.reset_cache!
      RequestThrottle.reload!
      to_reload.each do |block|
        begin
          block.call
        rescue => e
          Canvas::Errors.capture_exception(:reloader, e)
        end
      end
    end

    def on_reload(&block)
      to_reload << block
    end

    def trap_signal
      trap("HUP") do
        @pending_reload = true
      end
    end

    private

    def to_reload
      @to_reload ||= []
    end
  end
end
