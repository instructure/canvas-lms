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

shared_examples_for "statistics basic tests" do
  include_context "in-process server selenium tests"

  def item_lists
    ff(".item_list")
  end

  def validate_item_list(css, header_text)
    expect(f(css)).to include_text(header_text)
  end

  context "with admin initially logged in" do
    before do
      @course = Course.create!(name: "stats", account:)
      @course.start_at = Time.now
      @course.offer!
      admin_logged_in
    end

    it "validates recently created courses display" do
      skip("list is not available on sub account level") if account != Account.default
      get url
      validate_item_list(list_css[:created], @course.name)
    end

    it "validates recently started courses display" do
      skip("spec is broken on sub account level") if account != Account.default
      get url
      validate_item_list(list_css[:started], @course.name)
    end

    it "validates no info in list display" do
      get url
      validate_item_list(list_css[:ended], "None to show")
    end

    it "validates link works in list" do
      skip("spec is broken on sub account level") if account != Account.default
      get url
      expect_new_page_load { f(list_css[:started]).find_element(:css, ".header").click }
      expect(f("#breadcrumbs .home + li a")).to include_text(@course.name)
    end

    it "validates recently ended courses display" do
      skip("spec is broken on sub account level") if account != Account.default
      concluded_course = Course.create!(name: "concluded course", account:)
      concluded_course.update(conclude_at: 1.day.ago)
      get url
      validate_item_list(list_css[:ended], concluded_course.name)
    end
  end

  it "validates recently logged-in courses display" do
    course = Course.create!(name: "new course", account:)
    course.offer!
    student = user_factory(active_user: true)
    pseudonym = student.pseudonyms.create!(unique_id: "student@example.com", password: "asdfasdf", password_confirmation: "asdfasdf")
    course.enroll_user(student, "StudentEnrollment").accept!
    login_as(pseudonym.unique_id, "asdfasdf")
    admin_logged_in
    get url
    validate_item_list(list_css[:logged_in], student.name)
  end
end
