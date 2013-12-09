#
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

# Public: Delete old (> 90 days) records from delayed_messages table.
class DelayedMessageScrubber < MessageScrubber

  protected

  def filter_attribute
    'send_at'
  end

  def klass
    DelayedMessage
  end

  def limit_setting
    'delayed_message_scrubber_limit'
  end

  def limit_size
    90
  end
end
