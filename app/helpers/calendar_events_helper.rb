#
# Copyright (C) 2011 Instructure, Inc.
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

module CalendarEventsHelper

  # Return the user to a "return_to" path or to the calendar with specific dates used.
  #
  # ==== Options
  # * <tt>:context</tt> - The context to use (i.e. course) for focusing/limiting the
  #                       events for display.
  # * <tt>:event</tt> - A CalendarEvent instance from which the event's dates should
  #                     be used to specify which month/year to display.
  #
  def return_to_calendar(options = {})
    cal_options = {}
    event = options.delete(:event)
    if event
      cal_options[:anchor] = {:month => (event.try_rescue(:start_at).try_rescue(:month)),
                              :year => (event.try_rescue(:start_at).try_rescue(:year))}.to_json
    end
    # Use a explicit "return_to" option first, absent that, use calendar_url_for
    clean_return_to(
        params[:return_to] && params[:return_to].match(/calendar/) && params[:return_to]) ||
        calendar_url_for(options[:context], cal_options)
  end

end
