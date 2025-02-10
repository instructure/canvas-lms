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

require_relative "../common"
require_relative "../helpers/eportfolios_common"

describe "eportfolios" do
  include_context "in-process server selenium tests"
  include EportfoliosCommon

  before do
    course_with_student_logged_in
    stub_rcs_config
  end

  it "validates creation and visibility of eportfolio" do
    get "/dashboard/eportfolios"
    f("#add_eportfolio_button").click

    # fill out form
    replace_content f("#eportfolio_name"), "student content"
    f('label[for="eportfolio_public"]').click
    expect_new_page_load { f("#eportfolio_submit").click }

    # validate eportfolio
    eportfolio = Eportfolio.find_by_name("student content")
    expect(eportfolio).to be_valid
    expect(eportfolio.public).to be_truthy
    expect(f("#content h2")).to include_text(I18n.t("headers.welcome", "Welcome to Your ePortfolio"))
  end

  context "eportfolio created with user" do
    before do
      eportfolio_model({ user: @user, name: "student content" })
    end

    it "starts the download of ePortfolio contents", priority: "1" do
      get "/eportfolios/#{@eportfolio.id}"
      f(".download_eportfolio_link").click
      expect(f("#export_progress")).to be_displayed
    end

    it "displays the eportfolio wizard", priority: "1" do
      get "/eportfolios/#{@eportfolio.id}"
      f(".wizard_popup_link").click
      wait_for_animations
      expect(f("#wizard_box")).to be_displayed
    end

    it "displays and hide eportfolio wizard", priority: "2" do
      get "/eportfolios/#{@eportfolio.id}"
      f(".wizard_popup_link").click
      wait_for_animations
      expect(f("#wizard_box")).to be_displayed
      f(".close_wizard_link").click
      wait_for_animations
      expect(f("#wizard_box")).not_to be_displayed
    end

    it "adds a page", priority: "1" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      add_eportfolio_page("test page name")
      wait_for_ajax_requests
      expect(pages.last).to include_text("test page name")
    end

    it "deletes a page", priority: "1" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      expect(f("body")).not_to contain_css("svg[role='img'] circle")

      # add a page
      add_eportfolio_page("page #1")

      # delete section using the settings menu
      page = pages.last
      delete_eportfolio_page(page)
      wait_for_ajax_requests

      # The last remaining section should not include the "Delete" action.
      expect(pages.length).to eq 1
      last_page = pages.last
      last_page.find("button").click
      expect(f("div[role='menu']")).not_to include_text("Delete")
    end

    it "reorders a page", :ignore_js_errors, priority: "1" do
      skip "FOO-3814 (10/6/2023)"
      get "/eportfolios/#{@eportfolio.id}"

      # add 3 pages
      (1..3).each do |s|
        add_eportfolio_page("page #{s}")
      end

      # move "page 1" to the bottom
      organize_pages
      page = pages[1]
      move_page_to_bottom(page)
      expect(pages.last.text).to eq page.text
    end

    it "adds a section", priority: "1" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      add_eportfolio_section("test section name")
      wait_for_ajax_requests
      expect(sections.last).to include_text("test section name")
    end

    it "deletes a section", priority: "1" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      expect(f("body")).not_to contain_css("svg[role='img'] circle")

      # add a section
      add_eportfolio_section("section #1")

      # delete section using the settings menu
      section = sections.last
      delete_eportfolio_section(section)
      wait_for_ajax_requests

      # The last remaining section should not include the "Delete" action.
      expect(sections.length).to eq 1
      last_section = sections.last
      last_section.find("button").click
      expect(f("div[role='menu']")).not_to include_text("Delete")
    end

    it "reorders a section", :ignore_js_errors, priority: "1" do
      skip "FOO-3814 (10/6/2023)"
      get "/eportfolios/#{@eportfolio.id}"

      # add a 3 sections
      (1..3).each do |s|
        add_eportfolio_section("section #{s}")
      end

      # move "section 1" to the bottom
      organize_sections
      section = sections[1]
      move_section_to_bottom(section)
      expect(sections.last.text).to eq section.text
    end

    it "edits ePortfolio settings", priority: "2" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      expect(f("body")).not_to contain_css("svg[role='img'] circle")
      f("button[data-testid='portfolio-settings']").click
      replace_content f("[data-testid='portfolio-name-field']"), "new ePortfolio name1"
      fj("button:contains('Save')").click
      @eportfolio.reload
      expect(@eportfolio.name).to include("new ePortfolio name1")
    end

    it "has a working flickr search dialog" do
      skip_if_chrome("fragile in chrome")
      get "/eportfolios/#{@eportfolio.id}"
      f("#page_list a.page_url").click
      expect(f("#page_list a.page_url")).to be_displayed
      f("#page_sidebar .edit_content_link").click
      expect(f(".add_content_link.add_rich_content_link")).to be_displayed
      f(".add_content_link.add_rich_content_link").click
      expect(f(".mce-container")).to be_displayed
      f(".mce-container div[aria-label='Embed Image']").click
      expect(f('a[href="#tabFlickr"]')).to be_displayed
      f('a[href="#tabFlickr"]').click
      expect(f("form.FindFlickrImageView")).to be_displayed
    end

    context "with submissions" do
      before do
        @assignment = @course.assignments.create!(
          title: "hardest assignment ever",
          submission_types: "online_url,online_upload"
        )
        @submission = @assignment.submit_homework(@student)
        @submission.submission_type = "online_url"
        @submission.save!
        get "/eportfolios/#{@eportfolio.id}"
      end

      it "create a page with a submission" do
        f("[data-testid='submission-modal-#{@submission.id}']").click
        expect(f("[data-testid='create-page-modal']")).to be_displayed
        f("[data-testid='create-page-button']").click
        expect(f("#content h2")).to include_text @assignment.name
        expect(f("#content form")).to include_text "This is my hardest assignment ever submission for Unnamed Course"
      end
    end

    it "deletes the ePortfolio", priority: "2" do
      get "/eportfolios/#{@eportfolio.id}"
      wait_for_ajax_requests
      f(".delete_eportfolio_link").click
      wait_for_ajaximations
      expect(f("#delete_eportfolio_form")).to be_displayed
      submit_form("#delete_eportfolio_form")
      f("#wrapper .eportfolios").click
      expect(f("#content")).not_to contain_css("#portfolio_#{@eportfolio.id}")
      expect(f("#add_eportfolio_button")).to be_displayed
      expect(Eportfolio.first.workflow_state).to eq "deleted"
    end

    it "clicks on all wizard options and validate the text" do
      get "/eportfolios/#{@eportfolio.id}"
      f(".wizard_popup_link").click
      wait_for_ajaximations
      options_text = {
        ".information_step" => "ePortfolios are a place to demonstrate your work.",
        ".portfolio_step" => "Sections are listed along the left side of the window",
        ".section_step" => "Sections have multiple pages",
        ".adding_submissions" => "You may have noticed at the bottom of this page is a list of recent submissions",
        ".edit_step" => "To change the settings for your ePortfolio",
        ".publish_step" => "Ready to get started?"
      }
      options_text.each do |option, text|
        f(option).click
        expect(f(".wizard_details .details")).to include_text text
      end
    end

    it "is viewable with a shared link" do
      destroy_session
      get "/eportfolios/#{@eportfolio.id}?verifier=#{@eportfolio.uuid}"
      expect(f("#content h2").text).to eq "page"
    end
  end
end

describe "eportfolios file upload" do
  include_context "in-process server selenium tests"

  before :once do
    @password = "asdfasdf"
    @student = user_with_pseudonym active_user: true,
                                   username: "student@example.com",
                                   password: @password
    @student.save!
    @course = course_factory active_course: true
    @course.enroll_student(@student).accept!
    @course.reload
    eportfolio_model({ user: @user, name: "student content" })
  end

  def test_file_upload
    _filename, fullpath, _data = get_file("testfile5.zip")
    f("#right-side .edit_content_link").click
    wait_for_ajaximations
    f(".add_file_link").click
    wait_for_animations
    fj(".file_upload:visible").send_keys(fullpath)
    wait_for_ajaximations
    f(".upload_file_button").click
    f("[data-testid='save-page']").click
  end

  def verify_file_upload
    download = fj("a.eportfolio_download:visible")
    expect(download).to be_displayed
    expect(download).to have_attribute("href", /files/)
  end

  it "uploads a file to the main page" do
    create_session(@student.pseudonym)
    get "/eportfolios/#{@eportfolio.id}?view=preview"
    test_file_upload
    verify_file_upload
  end

  it "uploads a file to an eportfolio section" do
    ec = @eportfolio.eportfolio_categories.create! name: "Something"
    create_session(@student.pseudonym)
    get "/eportfolios/#{@eportfolio.id}/#{ec.slug}"
    test_file_upload
    verify_file_upload
  end

  it "uploads a file to an eportfolio page" do
    ec = @eportfolio.eportfolio_categories.create! name: "Der Section"
    ep = ec.eportfolio_entries.create! eportfolio: @eportfolio, name: "Das Page"
    create_session(@student.pseudonym)
    get "/eportfolios/#{@eportfolio.id}/#{ec.slug}/#{ep.slug}"
    test_file_upload
    verify_file_upload
  end
end
