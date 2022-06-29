# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../common"
require_relative "../helpers/calendar2_common"
require "rrule"

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:once) do
    Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
    Account.site_admin.enable_feature!(:calendar_series)
  end

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
    end

    context "event deleting", priority: "1" do
      before do
        today = Date.today
        start_at = Date.new(today.year, today.month, 15)
        create_calendar_event_series(@course, "event in a series", start_at)
      end

      it "deletes 'this event' from a series" do
        get "/calendar"

        events = ffj("#content .fc-event:visible:contains('event in a series')")
        expect(events.length).to eq 3

        events[1].click
        hover_and_click ".delete_event_link"
        event_series_this_event.click
        event_series_delete_button.click
        wait_for_ajax_requests
        expect(ffj("#content .fc-event:visible:contains('event in a series')").length).to eq 2

        # make sure it was actually deleted and not just removed from the interface
        get("/calendar")
        expect(ffj("#content .fc-event:visible:contains('event in a series')").length).to eq 2
      end

      it "deletes 'this event and all following' from a series" do
        get "/calendar"

        events = ffj("#content .fc-event:visible:contains('event in a series')")
        expect(events.length).to eq 3

        events[1].click
        hover_and_click ".delete_event_link"
        event_series_following_events.click
        event_series_delete_button.click
        wait_for_ajax_requests
        expect(ffj("#content .fc-event:visible:contains('event in a series')").length).to eq 1

        # make sure it was actually deleted and not just removed from the interface
        get("/calendar")
        expect(ffj("#content .fc-event:visible:contains('event in a series')").length).to eq 1
      end

      it "deletes 'all events' from a series" do
        get "/calendar"

        events = ffj("#content .fc-event:visible:contains('event in a series')")
        expect(events.length).to eq 3

        events[1].click
        hover_and_click ".delete_event_link"
        event_series_all_events.click
        event_series_delete_button.click
        wait_for_ajax_requests
        expect(f("#content")).not_to contain_jqcss(".fc-event:visible:contains('event in a series')")

        # make sure it was actually deleted and not just removed from the interface
        get("/calendar")
        expect(f("#content")).not_to contain_jqcss(".fc-event:visible:contains('event in a series')")
      end
    end
  end
end
