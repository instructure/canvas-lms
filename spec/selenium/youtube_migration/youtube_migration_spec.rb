# frozen_string_literal: true

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

describe "youtube migration", :ignore_js_errors do
  include_context "in-process server selenium tests"

  describe "overlay on RCE youtube embeds" do
    let(:youtube_src) { "https://www.youtube.com/embed/example_video_id" }
    let(:youtube_body) { "<iframe src=\"#{youtube_src}\"</iframe>" }
    let(:wiki_page) { @course.wiki_pages.create!(title: "Foo", body: youtube_body) }
    let(:feature_flag) { :youtube_overlay }

    before do
      stub_rcs_config
    end

    shared_examples "overlay visibility" do
      context "when FF is off" do
        before do
          Account.site_admin.disable_feature!(feature_flag)
        end

        it "should not show overlay" do
          get "/courses/#{@course.id}/pages/#{wiki_page.title}"
          wait_for_ajax_requests
          expect(f("iframe[src=\"#{youtube_src}\"]")).to be_displayed
          expect { f("[data-test-id='youtube-migration-close-overlay']") }.to raise_error(Selenium::WebDriver::Error::NoSuchElementError)
        end
      end

      context "when FF is on" do
        before do
          Account.site_admin.enable_feature!(feature_flag)
        end

        it "should show overlay" do
          get "/courses/#{@course.id}/pages/#{wiki_page.title}"
          wait_for_ajax_requests
          expect(f("iframe[src=\"#{youtube_src}\"]")).to be_displayed
          expect(f("[data-test-id='youtube-migration-close-overlay']")).to be_displayed
        end
      end
    end

    context "teacher" do
      before do
        course_with_teacher_logged_in
      end

      it_behaves_like "overlay visibility"
    end

    context "student" do
      before do
        course_with_student_logged_in
      end

      it_behaves_like "overlay visibility"
    end
  end
end
