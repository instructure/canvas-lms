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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/eportfolios_common')

describe "add content box" do
  include_context "in-process server selenium tests"
  include EportfoliosCommon

  before(:each) do
    course_with_student_logged_in
    enable_all_rcs @course.account
    stub_rcs_config
    @assignment = @course.assignments.create(:name => 'new assignment')
    @assignment.submit_homework(@student)
    attachment_model(:context => @student)
    eportfolio_model({:user => @user, :name => "student content"})
    get "/eportfolios/#{@eportfolio.id}?view=preview"
    f("#right-side .edit_content_link").click
    wait_for_ajaximations
  end

  it "should add rich text content" do
    # skip 'failing RCS selenium test. when CNVS-37278 is fixed/worked on, this skip should be removed.'
    f(".add_rich_content_link").click
    type_in_tiny "textarea", "hello student"
    submit_form(".form_content")
    wait_for_ajax_requests
    entry_verifier ({:section_type => "rich_text", :content => "hello student"})
    expect(f("#page_content .section_content")).to include_text("hello student")
  end

  it "should add a user file" do
    expect(f('.add_file_link')).to be_displayed
    f('.add_file_link').click
    wait_for_ajaximations
    fj('.file_list:visible .sign:visible').click
    wait_for_ajaximations # my files
    file = fj('li.file .text:visible')
    expect(file).to include_text @attachment.filename
    wait_for_ajaximations
    file.click
    f('.upload_file_button').click
    wait_for_ajaximations
    download = fj('.eportfolio_download:visible')
    expect(download).to be_present
    expect(download).to include_text @attachment.filename
    submit_form('.form_content')
    wait_for_ajaximations
    expect(f('.section.read_only')).to include_text @attachment.filename
    refresh_page
    expect(f('.section.read_only')).to include_text @attachment.filename
  end

  context "adding html content" do
    before(:each) do
      @html_content="<strong>student</strong>"
      f(".add_html_link").click
      wait_for_ajaximations
      f("#edit_page_section_0").send_keys(@html_content)
    end

    def add_html
      submit_form(".form_content")
    end

    def put_comment_in_html
      allow_comments = "#eportfolio_entry_allow_comments"
      f(allow_comments).click
      expect(is_checked(allow_comments)).to be_truthy
      comment_public="#eportfolio_entry_show_comments"
      f(comment_public).click
      expect(is_checked(comment_public)).to be_truthy
      submit_form(".form_content")
      wait_for_ajaximations
      expect(f(".section_content strong").text).to eq "student"
      entry_verifier({:section_type => "html", :content => @html_content})
      refresh_page
      f("#page_comment_message").send_keys("hi student")
      submit_form("#add_page_comment_form")
      wait_for_ajax_requests
      expect(f("#page_comments .message")).to include_text("hi student")
      expect(@eportfolio_entry.page_comments[0].message).to eq "hi student"
    end

    it "should verify that the html is there" do
      add_html
      expect(f(".section_content strong").text).to eq "student"
      entry_verifier({:section_type => "html", :content => @html_content})
    end

    it "should put comment in html" do
      put_comment_in_html
    end

    it "should delete the html content" do
      add_html
      entry_verifier({:section_type => "html", :content => @html_content})
      f("#right-side .edit_content_link").click
      hover_and_click("#page_section_0 .delete_page_section_link")
      accept_alert
      wait_for_ajaximations
      submit_form(".form_content")
      wait_for_ajaximations
      expect(@eportfolio.eportfolio_entries.first.content[0]).to eq "No Content Added Yet"
      expect(f("#content")).not_to contain_css("#edit_page_section_0")
    end

    it "should delete html comment" do
      put_comment_in_html
      expect(PageComment.count).to be > 0
      f(".delete_comment_link").click
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(f("#content")).not_to contain_css("#page_comments .message")
      expect(PageComment.count).to eq 0
    end
  end
end
