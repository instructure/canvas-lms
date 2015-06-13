# Copyright (C) 2013 Instructure, Inc.
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
  def self.reload!
    Setting.reset_cache!
    Canvas::RequestThrottle.reload!
    to_reload.each(&:call)
  end

  def self.on_reload(&block)
    to_reload << block
  end

  def self.trap_signal
    trap("HUP") do
      Rails.logger.info("Canvas::Reloader fired")
      Canvas::Reloader.reload!
    end
  end

  private
  def self.to_reload
    @to_reload ||= []
  end
end
