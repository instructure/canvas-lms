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

describe "account admin terms" do
  include_context "in-process server selenium tests"

  def click_term_action_link(term_div, action_link_css)
    term_div.find_element(:css, action_link_css).click
  end

  def validate_term_display(term_div_index = 0, title = "Default Term", course_count = 1)
    term_header = ff(".term .header")[term_div_index]
    expect(term_header).to include_text(title)
    expect(term_header).to include_text("#{course_count} Course")

    # TODO: pend until a better solution is found to calculate user counts
    # expect(term_header).to include_text("#{user_count} User")
  end

  before do
    course_with_admin_logged_in
  end

  context "default term" do
    before do
      get "/accounts/#{Account.default.id}/terms"
      @default_term = ff(".term")[0]
    end

    it "validates default term" do
      validate_term_display
    end

    it "cancels editing" do
      click_term_action_link(@default_term, ".edit_term_link")
      f(".cancel_button").click
      wait_for_animations
      validate_term_display
      check_element_has_focus f(".edit_term_link", @default_term)
    end

    it "validates that you cannot delete a term with courses in it" do
      expect do
        click_term_action_link(@default_term, ".cant_delete_term_link")
        alert = driver.switch_to.alert
        expect(alert.text).to eq "You can't delete a term that still has classes in it."
        alert.accept
      end.not_to change(EnrollmentTerm, :count)
      validate_term_display
    end
  end

  context "not default term" do
    it "adds a new term" do
      new_term_name = "New Term"
      get "/accounts/#{Account.default.id}/terms"

      expect do
        f(".add_term_link").click
        replace_content(f("#enrollment_term_name_new"), new_term_name)
        replace_content(f("#enrollment_term_sis_source_id_new"), "(sis id goes here)")
        f(".submit_button").click
        wait_for_ajax_requests
      end.to change(EnrollmentTerm, :count).by(1)
      expect(ff(".term .header .name")[0].text).to eq new_term_name
      expect(ff(".term .header .sis_source_id")[0].text).to eq "(sis id goes here)"
      check_element_has_focus f("#term_#{EnrollmentTerm.last.id} .edit_term_link")
    end

    it "deletes a term" do
      term_name = "delete term"
      @course.root_account.enrollment_terms.create!(name: term_name)
      get "/accounts/#{Account.default.id}/terms"

      validate_term_display(0, term_name, 0)
      click_term_action_link(ff(".term")[0], ".delete_term_link")
      driver.switch_to.alert.accept
      wait_for_ajaximations
      expect(EnrollmentTerm.where(name: term_name).first.workflow_state).to eq "deleted"
      validate_term_display
      check_element_has_focus f(".cant_delete_term_link", @default_term)
    end

    it "cancels term creation and validate nothing was created" do
      get "/accounts/#{Account.default.id}/terms"

      expect do
        f(".add_term_link").click
        replace_content(f("#enrollment_term_name_new"), "false add")
        f(".cancel_button").click
      end.not_to change(EnrollmentTerm, :count)
      validate_term_display
      check_element_has_focus f(".add_term_link")
    end
  end

  context "with grading periods" do
    let(:account) { Account.default }

    before do
      admin_logged_in
    end

    context "with grading period set associated to a new term" do
      let(:term) { account.enrollment_terms.create! }
      let(:group) { Factories::GradingPeriodGroupHelper.new.create_for_account(account) }

      before do
        group.enrollment_terms = [term]
      end

      it "displays link to grading standards page", priority: "1" do
        get "/accounts/#{account.id}/terms"
        standards_url = "/accounts/#{account.id}/grading_standards"
        expect(fln(group.title).attribute("href")).to include(standards_url)
      end
    end
  end
end
