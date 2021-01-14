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

require_relative '../common'

describe "global announcements" do
  include_context "in-process server selenium tests"

  before :each do
    course_with_student_logged_in
  end

  it 'shows empty message for both tabs', ignore_js_errors: true do
    get '/account_notifications'
    expect(fj("#tab-currentTab[aria-selected='true']:contains('Current')")).to be
    expect(fj("span:contains('Active Announcements')")).to be_displayed
    expect(fj("span:contains('No announcements to display')")).to be_displayed
    past_tab = f("#tab-pastTab")
    past_tab.click
    expect(fj("span:contains('Announcements from the past four months')")).to be_displayed
    expect(fj("span:contains('No announcements to display')")).to be_displayed
  end

  it 'shows notifications', ignore_js_errors: true do
    account_notification(:start_at => 2.days.ago, :end_at => 5.days.from_now, :send_message => true)
    account_notification(:message => 'from the past', :start_at => 6.days.ago, :end_at => 5.days.ago, :send_message => true)
    get '/account_notifications'
    expect(fj("h2:contains('this is a subject')")).to be_displayed
    expect(fj("span:contains('hi there')")).to be_displayed
    f("#tab-pastTab").click
    expect(fj("span:contains('from the past')")).to be_displayed
  end
end
