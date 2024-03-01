# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe "external tool assignments" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @t1 = factory_with_protected_attributes(@course.context_external_tools, url: "http://www.justanexamplenotarealwebsite.com/tool1", domain: "justanexamplenotarealwebsite.com", shared_secret: "test123", consumer_key: "test123", name: "tool 1")
    @t2 = factory_with_protected_attributes(@course.context_external_tools, url: "http://www.justanexamplenotarealwebsite.com/tool2", domain: "justanexamplenotarealwebsite.com", shared_secret: "test123", consumer_key: "test123", name: "tool 2")
  end

  it "allows creating through index", priority: "2" do
    @course.root_account.enable_feature!(:instui_nav)
    get "/courses/#{@course.id}/assignments"
    expect_no_flash_message :error
    # create assignment
    f(".add_assignment").click
    f(".ui-datepicker-trigger").click
    f('.create_assignment_dialog input[name="name"]').send_keys("test1")
    datepicker = datepicker_next
    datepicker.find_element(:css, ".ui-datepicker-ok").click
    replace_content(f('.create_assignment_dialog input[name="points_possible"]'), "5")
    click_option('.create_assignment_dialog select[name="submission_types"]', "External Tool")
    f(".create_assignment").click
    wait_for_ajaximations

    a = @course.assignments.reload.last
    expect(a).to be_present
    expect(a.submission_types).to eq "external_tool"
  end

  it "allows creating through the 'More Options' link", priority: "2" do
    get "/courses/#{@course.id}/assignments"

    # create assignment
    f(".add_assignment").click
    expect_new_page_load { f(".more_options").click }

    f("#assignment_name").send_keys("test1")
    click_option("#assignment_submission_type", "External Tool")
    f("#assignment_external_tool_tag_attributes_url_find").click

    fj("#context_external_tools_select td .tools .tool:first-child:visible").click
    wait_for_ajaximations
    expect(f("#context_external_tools_select input#external_tool_create_url")).to have_attribute("value", @t1.url)

    ff("#context_external_tools_select td .tools .tool")[1].click
    expect(f("#context_external_tools_select input#external_tool_create_url")).to have_attribute("value", @t2.url)

    f(".add_item_button.ui-button").click

    expect(f("#assignment_external_tool_tag_attributes_url")).to have_attribute("value", @t2.url)
    f("#edit_assignment_form button[type='submit']").click

    keep_trying_until do # timing issues require waiting
      expect(@course.assignments.reload.last).to be_present
    end

    a = @course.assignments.reload.last
    expect(a).to be_present
    expect(a.submission_types).to eq "external_tool"
    expect(a.external_tool_tag).to be_present
    expect(a.external_tool_tag.url).to eq @t2.url
    expect(a.external_tool_tag.new_tab).to be_falsey
  end

  it "allows editing", priority: "2" do
    a = assignment_model(course: @course, title: "test2", submission_types: "external_tool")
    a.create_external_tool_tag(url: @t1.url)
    a.external_tool_tag.update_attribute(:content_type, "ContextExternalTool")

    get "/courses/#{@course.id}/assignments/#{a.id}/edit"
    # don't display dialog on page load, since url isn't blank
    expect(f("#context_external_tools_select")).not_to be_displayed
    f("#assignment_external_tool_tag_attributes_url_find").click
    ff("#context_external_tools_select td .tools .tool")[0].click
    expect(f("#context_external_tools_select input#external_tool_create_url")).to have_attribute("value", @t1.url)
    f(".add_item_button.ui-button").click
    expect(f("#assignment_external_tool_tag_attributes_url")).to have_attribute("value", @t1.url)
    f("#edit_assignment_form button[type='submit']").click

    keep_trying_until do # timing issues require waiting
      a.reload
      expect(a.submission_types).to eq "external_tool"
    end

    expect(a.external_tool_tag).to be_present
    expect(a.external_tool_tag.url).to eq @t1.url
  end

  it "shows module sequence even without module_item_id param" do
    skip "EVAL-2593 (8/25/22)"

    allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
    allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
    a = assignment_model(course: @course, title: "test2", submission_types: "external_tool")
    a.create_external_tool_tag(url: @t1.url)
    a.external_tool_tag.update_attribute(:content_type, "ContextExternalTool")

    mod = @course.context_modules.create!
    mod.add_item(id: a.id, type: "assignment")
    page = @course.wiki_pages.create!(title: "wiki title")
    mod.add_item(id: page.id, type: "wiki_page")

    student_in_course(course: @course, active_all: true)
    user_session(@student)

    get "/courses/#{@course.id}/assignments/#{a.id}"
    expect(f(".module-sequence-footer-button--next")).to be_displayed
  end

  context "submission type selection placement" do
    before do
      [@t1, @t2].each do |tool|
        tool.submission_type_selection = { text: "link to #{tool.name} or whatever" }
        tool.save!
      end
      Setting.set("submission_type_selection_allowed_launch_domains", "justanexamplenotarealwebsite.com")
    end

    after do
      Setting.remove("submission_type_selection_allowed_launch_domains")
    end

    it "is able to select the tool directly from the submission type drop-down" do
      get "/courses/#{@course.id}/assignments/new"

      click_option("#assignment_submission_type", @t1.name) # should use the tool name for drop-down
      button = f("#assignment_submission_type_selection_launch_button")

      expect(button).to be_displayed
      expect(button.text).to include("link to #{@t1.name} or whatever") # the launch button uses the placement text

      click_option("#assignment_submission_type", @t2.name)
      expect(button.text).to include("link to #{@t2.name} or whatever") # the launch button uses the placement text

      f("#assignment_name").send_keys("some title")
      f(".btn-primary[type=\"submit\"]").click
      wait_for_ajaximations
      assmt = @course.assignments.last
      expect(assmt.submission_types).to eq "external_tool"
      expect(assmt.external_tool_tag.content).to eq @t2
      expect(assmt.external_tool_tag.url).to eq @t2.url
    end

    it "shows the tool as selected when editing a saved configured assignment" do
      assmt = @course.assignments.create!(title: "blah",
                                          submission_types: "external_tool",
                                          external_tool_tag_attributes: { content: @t1, url: @t1.url })
      get "/courses/#{@course.id}/assignments/#{assmt.id}/edit"
      selected = first_selected_option(f("#assignment_submission_type"))
      expect(selected.text.strip).to eq @t1.name
      button = f("#assignment_submission_type_selection_launch_button")
      expect(button).to be_displayed
      expect(button.text).to include("link to #{@t1.name} or whatever") # the launch button uses the placement text
    end

    it "displays external data for mastery connect" do
      ext_data = {
        key: "https://canvas.instructure.com/lti/mastery_connect_assessment",
        points: 10,
        objectives: "6.R.P.A.1, 6.R.P.A.2",
        trackerName: "My Tracker Name",
        studentCount: 15,
        trackerAlignment: "6th grade Math"
      }
      a = assignment_model(
        course: @course,
        title: "test1",
        submission_types: "external_tool",
        external_tool_tag_attributes: { content: @t1, url: @t1.url, external_data: ext_data.to_json }
      )

      get "/courses/#{@course.id}/assignments/#{a.id}/edit"

      expect(f("#mc_external_data_assessment").text).to eq(a.name)
      expect(f("#mc_external_data_points").text).to eq("#{ext_data[:points]} Points")
      expect(f("#mc_external_data_objectives").text).to eq(ext_data[:objectives])
      expect(f("#mc_external_data_tracker").text).to eq(ext_data[:trackerName])
      expect(f("#mc_external_data_tracker_alignment").text).to eq(ext_data[:trackerAlignment])
      expect(f("#mc_external_data_students").text).to eq("#{ext_data[:studentCount]} Students")
    end

    it "is bring up modal when submission type link is clicked" do
      get "/courses/#{@course.id}/assignments/new"
      click_option("#assignment_submission_type", @t1.name) # should use the tool name for drop-down
      f("#assignment_submission_type_selection_launch_button").click
      expect(fxpath("//span[@aria-label = 'Launch External Tool']//h2").text).to include("link to #{@t1.name} or whatever")

      close_button_selector = "//span[@aria-label = 'Launch External Tool']//button[//*[text() = 'Close']]"
      close_button = fxpath(close_button_selector)
      close_button.click
      expect(element_exists?(close_button_selector, true)).to be(false)
    end

    context "when editing an assignment created by an external tool" do
      let(:dev_key) do
        key = DeveloperKey.new(account: @course.account)
        key.generate_rsa_keypair!
        key.save!
        key.developer_key_account_bindings.first.update!(
          workflow_state: "on"
        )
        key
      end
      let(:tool) do
        @course.context_external_tools.create!(
          context: @course.account,
          consumer_key: "key",
          shared_secret: "secret",
          name: "test tool",
          domain: "https://www.tool.com",
          url: "https://www.tool.com/launch?deep_link_location=xyz",
          lti_version: "1.3",
          workflow_state: "public",
          developer_key: dev_key
        )
      end

      before do
        tool.submission_type_selection = {
          enabled: true,
          placement: "submission_type_selection",
          message_type: "LtiDeepLinkingRequest",
          target_link_uri: "http://www.tool.com/launch?placement=submission_type_selection",
        }
        tool.assignment_selection = {
          enabled: true,
          placement: "assignment_selection",
          message_type: "LtiDeepLinkingRequest",
          target_link_uri: "http://www.tool.com/launch?placement=assignment_selection",
        }
        tool.save!
      end

      it "does not reset the tool url" do
        assignment = @course.assignments.create!(
          submission_types: "external_tool",
          external_tool_tag_attributes: { content: tool, url: tool.url },
          points_possible: "10"
        )
        get "/courses/#{@course.id}/assignments/#{assignment.id}/edit"
        f('label[for="assignment_external_tool_tag_attributes_new_tab"]').click
        f('button[type="submit"]').click

        expect(assignment.external_tool_tag.url).to eq("https://www.tool.com/launch?deep_link_location=xyz")
        expect(assignment.lti_resource_links[0].url).to eq("https://www.tool.com/launch?deep_link_location=xyz")
      end
    end
  end
end
