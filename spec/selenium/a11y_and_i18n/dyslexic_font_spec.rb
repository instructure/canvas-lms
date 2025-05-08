# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe "using dyslexic friendly font" do
  include_context "in-process server selenium tests"

  before { course_with_student_logged_in(active_all: true) }

  context "WITHOUT use_dyslexic_font turned on" do
    it "specifies Lato Extended as the preferred font" do
      get "/"
      wait_for_dom_ready

      font_family = f("body").css_value("font-family")
      expect(font_family).to match(/^"Lato Extended/)
    end
  end

  context "WITH use_dyslexic_font turned on" do
    before { @user.enable_feature!(:use_dyslexic_font) }

    it "specifies OpenDyslexic as the preferred font" do
      get "/"
      wait_for_dom_ready

      font_family = f("body").css_value("font-family")
      expect(font_family).to match(/^OpenDyslexic/)
    end
  end
end
