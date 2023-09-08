# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe "content security policy" do
  include_context "in-process server selenium tests"

  context "with csp enabled" do
    before(:once) do
      @csp_account = Account.create!(name: "csp account")
      @csp_account.enable_feature!(:javascript_csp)
      @csp_account.enable_csp!
      @csp_course = @csp_account.courses.create!(name: "csp course")
      @csp_user = User.create!(name: "csp user")
      @csp_user.accept_terms
      @csp_user.register!
      @csp_pseudonym = @csp_account.pseudonyms.create!(user: @csp_user, unique_id: "csp@example.com")
      @csp_course.enroll_user(@csp_user, "TeacherEnrollment", enrollment_state: "active")
    end

    before { create_session(@csp_pseudonym) }

    it "displays a flash alert for non-whitelisted iframe", :ignore_js_errors do
      @csp_course.wiki_pages.create!(title: "Page1", body: <<~HTML)
        <iframe
         width="560"
         height="315"
         src="https://www.youtube.com/embed/dQw4w9WgXcQ"
         frameborder="0"
         allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
         allowfullscreen>
        </iframe>
      HTML

      get "/courses/#{@csp_course.id}/pages/Page1/"

      expect_instui_flash_message "Content on this page violates the security policy, contact your admin for assistance."
    end

    it "does not display a flash alert for whitelisted iframe" do
      @csp_account.add_domain!("www.youtube.com")
      @csp_course.wiki_pages.create!(title: "Page1", body: <<~HTML)
        <iframe
         width="560"
         height="315"
         src="https://www.youtube.com/embed/dQw4w9WgXcQ"
         frameborder="0"
         allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
         allowfullscreen>
        </iframe>
      HTML

      get "/courses/#{@csp_course.id}/pages/Page1/"

      expect_no_instui_flash_message
    end
  end
end
