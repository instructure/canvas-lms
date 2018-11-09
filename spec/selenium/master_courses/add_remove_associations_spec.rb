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

require_relative '../common'
require_relative '../helpers/blueprint_common'


describe "master courses - add and remove course associations" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    # create the master course
    @master = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)

    # create some courses
    @master_course = course_factory(:active_all => true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master_course)
    @course0 = Course.create!(
      :account => @account, :name => "AlphaDog", :course_code => "CCC1", :sis_source_id => "SIS_A1"
    )
    @course0.offer!
    @course1 = Course.create!(
      :account => @account, :name => "AlphaMale", :course_code => "CCC2", :sis_source_id => "SIS_A2"
    )
    @course1.offer!
    c = Course.create!(
      :account => @account, :name => "Alphabet", :course_code => "CCC3", :sis_source_id => "SIS_A3"
    )
    c.offer!
    c = Course.create!(
      :account => @account, :name => "BetaCarotine", :course_code => "DDD4", :sis_source_id => "SIS_B4"
    )
    c.offer!
    c = Course.create!(
      :account => @account, :name => "BetaGetOuttaHere", :course_code => "DDD5", :sis_source_id => "SIS_B5"
    )
    c.offer!

    account_admin_user(active_all: true)
  end

  before :each do
    user_session(@admin)
  end

  it "should add associated courses", priority: "1", test_id: "3078972" do
    get "/courses/#{@master_course.id}"
    open_associations
    open_courses_list

    expect(available_courses_table).to be_displayed
    wait_for_ajaximations
    expect(f('.bca-associations-table').text).to eq('There are currently no associated courses.')

    courses = available_courses
    expect(courses.length).to eq(5)

    # add the first course in the list
    course0_id = courses[0].attribute('id')
    checkbox = f('label', courses[0])
    checkbox.click
    tobe = to_be_added
    expect(tobe.length).to eq(1)
    expect(tobe[0].attribute('id')).to eq(course0_id)

    # do it again
    course1_id = courses[1].attribute('id')
    checkbox = f('label', courses[1])
    checkbox.click
    tobe = to_be_added
    expect(tobe.length).to eq(2)
    expect(tobe[1].attribute('id')).to eq(course1_id)
    expect(current_associations_table).not_to contain_css('tr') # no current associations

    do_save
    minions = current_associations
    expect(minions.length).to eq(2)
    expect(minions[0].attribute('id')).to eq(course0_id)
    expect(minions[1].attribute('id')).to eq(course1_id)
  end

  it "should remove an associated course", priority: "1", test_id: "3077488" do
    @minion0 = @template.add_child_course!(@course0).child_course
    @minion1 = @template.add_child_course!(@course1).child_course

    get "/courses/#{@master_course.id}"
    driver.execute_script('ENV.flashAlertTimeout = 2000') # shorten flash alert timeout
    open_associations

    # sanity check
    minions = current_associations
    expect(minions.length).to eq(2)

    # remove course0
    the_x = f("form[data-course-id='#{@course0.id}'] button") # click 'x' next to course0
    the_x.click
    open_courses_list

    minions = current_associations
    expect(minions.length).to eq(1) # only 1 left
    expect(minions[0].attribute('id')).to eq("course_#{@course1.id}") # and it's course1
    do_save
    # wait for the flash message to disappear.
    # has the side-effect of waiting for the page to rerender with new data
    expect(f('#flashalert_message_holder')).not_to contain_css('.flashalert-message')

    # only course1 is left
    minions = current_associations
    expect(minions.length).to eq(1)
    expect(minions[0].attribute('id')).to eq("course_#{@course1.id}")
    # course0 is back in the available course list
    table = available_courses_table
    expect(f("#course_#{@course0.id}", table)).to be_displayed
  end

  it "should add and remove a to-be-added course", priority: "1", test_id: "3077487" do
    get "/courses/#{@master_course.id}"
    open_associations
    open_courses_list

    courses = available_courses
    course0_id = courses[0].attribute('id')
    course1_id = courses[1].attribute('id')

    # add the first two courses in the list
    f('label', courses[0]).click # click the checkbox
    f('label', courses[1]).click

    expect(to_be_added().length).to eq(2)
    tobetable = to_be_added_table
    expect(f("##{course0_id}", tobetable)).to be_displayed
    expect(f("##{course1_id}", tobetable)).to be_displayed

    # remove the first one
    tobe = to_be_added
    remove_me = tobe[0]
    remove_me_id = remove_me.attribute('id')
    leave_me = tobe[1]
    leave_me_id = leave_me.attribute('id')
    the_x = f('button', remove_me)
    the_x.click

    expect(to_be_added().length).to eq(1)
    expect(f("##{leave_me_id}", to_be_added_table)).to be_displayed
    expect(f("##{remove_me_id}", available_courses_table)).to be_displayed
  end
end
