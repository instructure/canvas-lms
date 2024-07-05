# frozen_string_literal: true

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

require_relative "../common"

describe "cross-listing" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @course1       = @course
    @course2       = course_with_teacher(
      active_course: true,
      user: @user,
      active_enrollment: true
    ).course

    @course2.update_attribute(:name, "Course 2")
    @section = @course1.course_sections.first
    get "/courses/#{@course1.id}/sections/#{@section.id}"
  end

  it "allows cross-listing a section" do
    f(".crosslist_link").click
    form = f("#crosslist_course_form")
    submit_btn = form.find_element(:css, ".submit_button")
    expect(form).not_to be_nil
    expect(form.find_element(:css, ".submit_button")).to be_disabled

    course_id   = form.find_element(:id, "course_id")
    course_name = f("#course_autocomplete_name")

    # crosslist a valid course
    course_id.click
    course_id.clear
    course_id.send_keys(@course2.id.to_s, "\n")
    expect(course_name).to include_text(@course2.name)
    expect(form.find_element(:id, "course_autocomplete_id")).to have_attribute(:value, @course.id.to_s)
    expect(submit_btn).not_to have_class("disabled")
    submit_form(form)
    wait_for_ajaximations
    keep_trying_until { driver.current_url.match(%r{courses/#{@course2.id}}) }

    # verify teacher doesn't have de-crosslist privileges
    get "/courses/#{@course2.id}/sections/#{@section.id}"
    expect(f("#content")).not_to contain_css(".uncrosslist_link")

    # enroll teacher and de-crosslist
    @course1.enroll_teacher(@user).accept
    get "/courses/#{@course2.id}/sections/#{@section.id}"
    f(".uncrosslist_link").click
    expect(f("#uncrosslist_form")).to be_displayed
    submit_form("#uncrosslist_form")
    wait_for_ajaximations
    keep_trying_until { expect(driver.current_url).to match(%r{courses/#{@course1.id}}) }
  end

  it "does not allow cross-listing an invalid section" do
    f(".crosslist_link").click
    form = f("#crosslist_course_form")
    course_id   = form.find_element(:id, "course_id")
    course_name = f("#course_autocomplete_name")
    course_id.click
    course_id.send_keys "-1\n"
    expect(course_name).to include_text 'Course ID "-1" not authorized for cross-listing'
  end

  it "allows cross-listing a section redux" do
    # so, we have two courses with the teacher enrolled in both.
    course_with_teacher_logged_in
    course = @course
    other_course = course_with_teacher(active_course: true,
                                       user: @user,
                                       active_enrollment: true).course
    other_course.update_attribute(:name, "cool course")
    section = course.course_sections.first

    # we visit the first course's section. the teacher is enrolled in this
    # section. we're going to crosslist it.
    get "/courses/#{course.id}/sections/#{section.id}"
    f(".crosslist_link").click
    form = f("#crosslist_course_form")
    expect(form.find_element(:css, ".submit_button")).to be_disabled
    expect(form).not_to be_nil

    # let's try and crosslist an invalid course
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").send_keys("-1\n")
    expect(f("#course_autocomplete_name")).to include_text("Course ID \"-1\" not authorized for cross-listing")

    # k, let's crosslist to the other course
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").clear
    form.find_element(:css, "#course_id").send_keys(other_course.id.to_s, "\n")
    expect(f("#course_autocomplete_name")).to include_text other_course.name
    expect(form.find_element(:css, "#course_autocomplete_id")).to have_attribute(:value, other_course.id.to_s)

    # No idea why, but this next line can't seem to find the button correctly
    # expect(form.find_element(:css, ".submit_button")).to have_attribute(:disabled, 'false')

    submit_form(form)
    keep_trying_until { driver.current_url.match(%r{courses/#{other_course.id}}) }

    # yay, so, now the teacher is not enrolled in the first course (the section
    # they were enrolled in got moved). they don't have the rights to
    # uncrosslist.
    get "/courses/#{other_course.id}/sections/#{section.id}"
    expect(f("#content")).not_to contain_css(".uncrosslist_link")

    # enroll, and make sure the teacher can uncrosslist.
    course.enroll_teacher(@user).accept
    get "/courses/#{other_course.id}/sections/#{section.id}"
    f(".uncrosslist_link").click
    expect(f("#uncrosslist_form")).to be_displayed
    submit_form("#uncrosslist_form")
    keep_trying_until { driver.current_url.match(%r{courses/#{course.id}}) }
  end

  context "course search results" do
    it "displays course name and term name when course does not have SIS ID" do
      f(".crosslist_link").click

      # search for course
      search_field = f("#course_autocomplete_id_lookup")
      search_field.click
      search_field.clear
      search_field.send_keys(@course2.name)

      search_results = f("#ui-id-1")
      first_search_result = search_results.find_elements(tag_name: "li")[0]

      # Sample search result:
      # Course 2
      # Term: Default Term
      expect(first_search_result.text).to match(/#{@course2.name}\nTerm: #{@course2.enrollment_term.name}/)
    end

    it "displays course name, term name and SIS ID when course has SIS ID" do
      @course2.update_attribute(:sis_source_id, "123")
      f(".crosslist_link").click

      # search for course
      search_field = f("#course_autocomplete_id_lookup")
      search_field.click
      search_field.clear
      search_field.send_keys(@course2.name)

      search_results = f("#ui-id-1")
      first_search_result = search_results.find_elements(tag_name: "li")[0]

      # Sample search result:
      # Course 2
      # SID ID: 123 | Term: Default Term
      expect(first_search_result.text).to match(/#{@course2.name}\nSID ID: #{@course2.sis_source_id} | Term: #{@course2.enrollment_term.name}/)
    end
  end
end
