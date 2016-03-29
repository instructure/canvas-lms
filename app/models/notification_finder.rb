#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class NotificationFinder
  attr_reader :notifications

  def initialize(notifications = Notification.all_cached)
    refresh_cache(notifications)
  end

  def find_by_name(name)
    notifications[name]
  end

  alias :by_name :find_by_name

  def reset_cache
    @notifications = []
    true
  end

  def refresh_cache(notifications = Notification.all_cached)
    @notifications = notifications.index_by(&:name)
    @notifications.values.each(&:freeze)
    true
  end
end
