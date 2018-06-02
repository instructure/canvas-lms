#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/common')

describe "concluded/unconcluded" do
  include_context "in-process server selenium tests"

  before do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    @e = course_with_teacher :active_course => true,
                             :user => u,
                             :active_enrollment => true
    @e.save!

    user_model
    @student = @user
    @course.enroll_student(@student).accept
    @group = @course.assignment_groups.create!(:name => "default")
    @assignment = @course.assignments.create!(:submission_types => 'online_quiz', :title => 'quiz assignment', :assignment_group => @group)
    create_session(u.pseudonym)
  end

  it "should let the teacher edit the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajax_requests

    entry = f(".slick-cell.b2.f2")
    expect(entry).to be_displayed
    entry.click
    expect(entry.find_element(:css, ".gradebook-cell-editable")).to be_displayed
  end

  it "should not let the teacher edit the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.b2.f2")
    expect(entry).to be_displayed
    entry.click
    expect(entry.find_element(:css, ".gradebook-cell")).not_to have_class('gradebook-cell-editable')
  end

  it "should let the teacher add comments to the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.b2.f2")
    expect(entry).to be_displayed
    driver.execute_script("$('.slick-cell.b2.f2').mouseover();")
    entry.find_element(:css, ".gradebook-cell-comment").click
    wait_for_ajaximations
    expect(f(".submission_details_dialog")).to be_displayed
    expect(f(".submission_details_dialog #add_a_comment")).to be_displayed
  end

  it "should not let the teacher add comments to the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    entry = f(".slick-cell.b2.f2")
    expect(entry).to be_displayed
    driver.execute_script("$('.slick-cell.b2.f2').mouseover();")
    expect(entry.find_element(:css, ".gradebook-cell-comment")).not_to be_displayed
  end
end
