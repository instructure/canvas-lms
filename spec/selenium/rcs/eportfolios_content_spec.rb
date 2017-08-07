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
end
