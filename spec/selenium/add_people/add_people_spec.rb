# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require "rubygems"
require_relative "../common"

describe "add_people" do
  include_context "in-process server selenium tests"
  let(:enrollee_count) { 0 }

  context "as a teacher" do
    before do
      course_with_teacher_logged_in
      4.times { |i| add_section("Section #{i}") }
      user_with_pseudonym(name: "Foo Foo", active_user: true, username: "foo", account: @account)
      user_with_pseudonym(name: "Foo Bar", active_user: true, username: "bar", account: @account)
    end

    # this is one giant test because it has to walk through the panels of a
    # modal dialog, and "it" tests throw an exception if they don't include
    # a get(url) call, which would break the flow of the test.
    it "adds a couple users" do
      get "/courses/#{@course.id}/users"

      # get the number of people in the class when we start, so we know
      # how many should be there when we've added some more
      enrollee_count = ff("tbody.collectionViewItems tr").length

      # open the add people modal dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed
      expect(f("#application")).to have_attribute("aria-hidden", "true")

      # can't click the 'login id' radio button directly, since it's covered
      # with inst-ui prettiness and selenium won't allow it.
      # Click on it's label instead
      f("[for='peoplesearch_radio_unique_id']").click

      # search for some logins
      replace_content(f(".addpeople__peoplesearch textarea"), "foo,bar,baz")

      # click next button
      f("#addpeople_next").click

      # the validation issues panel is displayed
      expect(f(".addpeople__peoplevalidationissues")).to be_displayed

      # there should be 1 row in the missing table (baz)
      expect(ff(".addpeople__peoplevalidationissues tbody tr")).to have_size(1)

      # click the next button
      f("#addpeople_next").click

      # there should be 2 rows in the ready to add table (foo, bar)
      expect(ff(".addpeople__peoplereadylist tbody tr")).to have_size(2)

      # force next button into view, then click it
      f("#addpeople_next").click

      # the modal dialog should close
      expect(f("body")).not_to contain_css(".addpeople")

      # there should be 2 more people in this course
      expect(ff("tbody.collectionViewItems tr")).to have_size(enrollee_count + 2)
    end

    it "tells our user when not adding any users to the course" do
      get "/courses/#{@course.id}/users"

      # open the dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed

      # search for some gibberish
      replace_content(f(".addpeople__peoplesearch textarea"), "jibberish@example.com")

      # click next button
      f("#addpeople_next").click

      # the validation issues panel is displayed
      expect(f(".addpeople__peoplevalidationissues")).to be_displayed

      # click the next button
      f("#addpeople_next").click

      # the people ready panel is displayed
      people_ready_panel = f(".addpeople__peoplereadylist")
      expect(people_ready_panel).to be_displayed

      # no table
      expect(f("body")).not_to contain_css(".addpeople__peoplereadylist table")

      # the message_user_path
      msg = fj(".addpeople__peoplereadylist:contains('No users were selected to add to the course')")
      expect(msg).to be_displayed
    end

    it "includes only manageable roles (non-granular)" do
      @course.root_account.disable_feature!(:granular_permissions_manage_users)
      @course.account.role_overrides.create! role: teacher_role,
                                             permission: :manage_students,
                                             enabled: false
      get "/courses/#{@course.id}/users"
      f("#addUsers").click
      expect(INSTUI_Select_options("#peoplesearch_select_role").map(&:text)).not_to include "Student"
    end

    it "includes only manageable roles (granular)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_users)
      @course.account.role_overrides.create! role: teacher_role,
                                             permission: :add_student_to_course,
                                             enabled: false
      get "/courses/#{@course.id}/users"
      f("#addUsers").click
      expect(INSTUI_Select_options("#peoplesearch_select_role").map(&:text)).not_to include "Student"
    end

    it "has a working checkbox after cancelling and reopening" do
      get "/courses/#{@course.id}/users"

      # open the dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed

      # check the checkbox
      f('label[for="limit_privileges_to_course_section"]').click
      expect(f("#limit_privileges_to_course_section")).to be_selected

      # cancel the dialog
      f("#addpeople_cancel").click
      expect(f("body")).not_to contain_css(".addpeople")

      # reopen the dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed

      # check the checkbox again
      f('label[for="limit_privileges_to_course_section"]').click
      expect(f("#limit_privileges_to_course_section")).to be_selected
    end

    # tests that INSTUI fixed a bug in Select that would close the Modal
    # when the user uses 'esc' to close the options dropdown
    it "does not close the modal on 'escape'ing from role Select options" do
      get "/courses/#{@course.id}/users"

      # open the add people modal dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed

      # expand the roles
      roleselect = f("#peoplesearch_select_role")
      roleselect.click
      option_list_id = roleselect.attribute("aria-controls")
      expect(f("body")).to contain_css("##{option_list_id}")

      roleselect.send_keys(:escape)
      expect(f("body")).not_to contain_css("##{option_list_id}")

      expect(f(".addpeople")).to be_displayed # still
    end
  end

  context("as an admin") do
    before do
      course_with_admin_logged_in
    end

    # CNVS-35149
    it "includes select all for missing users" do
      get "/courses/#{@course.id}/users"

      # open the add people modal dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed

      # search for some emails
      replace_content(f(".addpeople__peoplesearch textarea"),
                      'Z User <zuser@example.com>, yuser@example.com, "User, X" <xuser@example.com>')

      # click next button
      f("#addpeople_next").click

      # the validation issues panel is displayed
      expect(f(".peoplevalidationissues__missing")).to be_displayed

      # click the select all checkbox
      f('label[for="missing_users_select_all"]').click

      # all the checkboxes are checket
      ff(".peoplevalidationissues__missing input[type='checkbox']").each do |checkbox|
        expect(checkbox.attribute("checked")).to eq("true")
      end

      # uncheck the first name
      f(".peoplevalidationissues__missing tbody label").click

      # select all should be unchecked
      expect(f("#missing_users_select_all").attribute("checked")).to be_nil

      # re-check the first name
      f(".peoplevalidationissues__missing tbody label").click

      # select all is checked
      expect(f("#missing_users_select_all").attribute("checked")).to eq("true")

      # uncheck all
      f('label[for="missing_users_select_all"]').click

      # none of the name checkboxes are checked
      ff(".peoplevalidationissues__missing input[type='checkbox']").each do |checkbox|
        expect(checkbox.attribute("checked")).to be_nil
      end
    end

    it "includes invite users without names" do
      get "/courses/#{@course.id}/users"
      # open the add people modal dialog
      f("a#addUsers").click
      expect(f(".addpeople")).to be_displayed

      # search for some emails
      replace_content(f(".addpeople__peoplesearch textarea"),
                      'Z User <zuser@example.com>, yuser@example.com, "User, X" <xuser@example.com>')
      # sleep 1 - works with this
      # click next button
      f("#addpeople_next").click

      # the validation issues panel is displayed
      expect(f(".peoplevalidationissues__missing")).to be_displayed

      # click the select all checkbox
      f('label[for="missing_users_select_all"]').click

      # all the name textboxes should be displayed
      expect(ff('.peoplevalidationissues__missing tbody input[type="text"][name="name"]')).to have_size(3)

      # the Next button is enabled, click it
      f("#addpeople_next").click

      expect(f(".addpeople__peoplereadylist")).to be_displayed

      names = ff(".addpeople__peoplereadylist tbody tr th:first-child")
      expect(names).to have_size(3)

      # Z and X have names, y has email copied to name
      expect(names[0].text).to eq("Z User")
      expect(names[1].text).to eq("yuser@example.com")
      expect(names[2].text).to eq("User, X")
    end
  end
end
