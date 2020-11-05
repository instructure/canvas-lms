# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../common')
require File.expand_path(File.dirname(__FILE__) + '/../../helpers/calendar2_common')

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:each) do
    Account.default.tap do |a|
      a.settings[:show_scheduler]   = true
      a.save!
    end
  end

  context "as a teacher" do
    before(:each) do
      course_with_teacher_logged_in
      stub_rcs_config
    end

    describe "main month calendar" do

      it "more options link on assignments should go to assignment edit page" do
        skip "fails on expect_new_page_lod, but works fine through website"
        name = 'super big assignment'
        create_middle_day_assignment(name)
        f('.fc-event.assignment').click
        hover_and_click '.edit_event_link'
        expect_new_page_load { hover_and_click '.more_options_link' }
        expect(find('#assignment_name').attribute(:value)).to include(name)
      end

      it "should publish a new assignment when toggle is clicked" do
        skip "fails on expect_new_page_lod, but works fine through website"
        create_published_middle_day_assignment
        f('.fc-event.assignment').click
        hover_and_click '.edit_event_link'
        expect_new_page_load { hover_and_click '.more_options_link' }
        expect(find('#assignment-draft-state')).not_to include_text("Not Published")
      end
    end
  end
end
