# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before do
    course_with_teacher_logged_in
  end

  context "12-hour" do
    it "shows assignment in 12-hour time", priority: "1" do
      create_course_assignment
      get "/calendar2"
      expect(f(".fc-time")).to include_text("9p")
    end

    it "shows event in 12-hour time", priority: "1" do
      create_course_event
      get "/calendar2"
      expect(f(".fc-time")).to include_text("9p")
    end
  end

  context "24-hour" do
    before do
      Account.default.tap do |a|
        a.default_locale = "en-GB"
        a.save!
      end
    end

    it "shows assignment in 24-hour time", priority: "1" do
      skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
      create_course_assignment
      get "/calendar2"
      expect(f(".fc-time")).to include_text("21")
    end

    it "shows event in 24-hour time", priority: "1" do
      skip("RAILS_LOAD_ALL_LOCALES=true") unless ENV["RAILS_LOAD_ALL_LOCALES"]
      create_course_event
      get "/calendar2"
      expect(f(".fc-time")).to include_text("21")
    end
  end
end
