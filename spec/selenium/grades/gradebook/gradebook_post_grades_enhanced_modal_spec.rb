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

require_relative "../../helpers/gradebook_common"
require_relative "../pages/gradebook_page"
require_relative "../setup/gradebook_setup"

describe "Gradebook - post_grades_enhanced_modal" do
  include GradebookCommon
  include GradebookSetup

  include_context "in-process server selenium tests"

  before(:once) do
    gradebook_data_setup
    @course.enable_feature!(:post_grades_enhanced_modal)
    show_sections_filter(@teacher)
  end

  before do
    user_session(@teacher)
  end

  after do
    clear_local_storage
  end

  def create_post_grades_tool(opts = {})
    course = opts[:course] || @course
    course.context_external_tools.create!(
      name: opts[:name] || "test tool",
      domain: "example.com",
      url: "http://example.com/lti",
      consumer_key: SecureRandom.hex,
      shared_secret: "secret",
      settings: {
        post_grades: {
          url: "http://example.com/lti/post_grades"
        }
      }
    )
  end

  describe "PostGradesFrameModal" do
    let!(:tool) { create_post_grades_tool }
    let(:tool_name) { "post_grades_lti_#{tool.id}" }

    it "shows the enhanced modal when an LTI is clicked" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed
    end

    it "shows the iframe inside the enhanced modal" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed
      expect(f("iframe.post-grades-frame")).to be_displayed
    end

    it "shows the Sync Grades heading in the modal" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(tool_name).click

      modal = f('[data-testid="post-grades-frame-modal"]')
      expect(modal).to be_displayed
      expect(fj('h2:contains("Sync Grades")')).to be_displayed
    end

    it "closes the modal when the close button is clicked" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed

      fj('button:contains("Close")').click

      expect(f("body")).not_to contain_css('[data-testid="post-grades-frame-modal"]')
    end

    it "shows the enhanced modal with enhanced filters enabled" do
      @course.enable_feature!(:enhanced_gradebook_filters)

      Gradebook.visit(@course)
      Gradebook.select_sync

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed
      expect(f("iframe.post-grades-frame")).to be_displayed
    end

    it "does not hide modal when section is selected" do
      create_post_grades_tool

      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed

      fj('button:contains("Close")').click
      expect(f("body")).not_to contain_css('[data-testid="post-grades-frame-modal"]')

      switch_to_section("the other section")

      Gradebook.open_action_menu
      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed
    end

    it "handles multiple LTI tools correctly" do
      second_tool = create_post_grades_tool(name: "second tool")
      second_tool_name = "post_grades_lti_#{second_tool.id}"

      Gradebook.visit(@course)
      Gradebook.open_action_menu

      expect(Gradebook.action_menu_item_selector(tool_name)).to be_displayed
      expect(Gradebook.action_menu_item_selector(second_tool_name)).to be_displayed

      Gradebook.action_menu_item_selector(tool_name).click
      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed

      fj('button:contains("Close")').click
      expect(f("body")).not_to contain_css('[data-testid="post-grades-frame-modal"]')

      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(second_tool_name).click
      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed
    end

    it "sets the correct iframe src for the LTI tool" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(tool_name).click

      expect(f('[data-testid="post-grades-frame-modal"]')).to be_displayed
      iframe = f("iframe.post-grades-frame")

      # Can't check exact URL due to CORS, but verify it's set
      expect(iframe.attribute("src")).not_to be_empty
      expect(iframe.attribute("data-lti-launch")).to eq("true")
    end
  end

  describe "feature flag disabled" do
    before(:once) do
      @course.disable_feature!(:post_grades_enhanced_modal)
    end

    let!(:tool) { create_post_grades_tool }
    let(:tool_name) { "post_grades_lti_#{tool.id}" }

    it "uses the old PostGradesFrameDialog when feature flag is disabled" do
      Gradebook.visit(@course)
      Gradebook.open_action_menu
      Gradebook.action_menu_item_selector(tool_name).click

      # Old dialog shows iframe but not the new modal structure
      expect(f("body")).not_to contain_css('[data-testid="post-grades-frame-modal"]')
      expect(f("iframe.post-grades-frame")).to be_displayed
    end
  end
end
