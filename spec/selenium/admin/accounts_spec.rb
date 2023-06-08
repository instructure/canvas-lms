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

describe "account" do
  include_context "in-process server selenium tests"

  before do
    course_with_admin_logged_in
  end

  def verify_displayed_term_dates(term, dates)
    dates.each do |en_type, date|
      expect(term.find_element(:css, ".#{en_type}_dates .start_date .show_term").text).to match(/#{date[0]}/)
      expect(term.find_element(:css, ".#{en_type}_dates .end_date .show_term").text).to match(/#{date[1]}/)
    end
  end

  describe "term create/update" do
    it "is able to add a term" do
      get "/accounts/#{Account.default.id}/terms"
      f(".add_term_link").click
      wait_for_ajaximations

      f("#enrollment_term_name_new").send_keys("some name")
      f("#enrollment_term_sis_source_id_new").send_keys("some id")

      f("#term_new .general_dates .start_date .edit_term input").send_keys("2011-07-01")
      f("#term_new .general_dates .end_date .edit_term input").send_keys("2011-07-31")

      f(".submit_button").click
      wait_for_ajaximations

      term = Account.default.enrollment_terms.last
      expect(term.name).to eq "some name"
      expect(term.sis_source_id).to eq "some id"

      expect(term.start_at).to eq Date.parse("2011-07-01")
      expect(term.end_at).to eq Date.parse("2011-07-31")
    end

    it "general term dates", priority: 1 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f(".edit_term_link").click
      f(".editing_term .general_dates .start_date .edit_term input").send_keys("2011-07-01")
      f(".editing_term .general_dates .end_date .edit_term input").send_keys("2011-07-31")
      f(".submit_button").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
                                    general: ["Jul 1", "Jul 31"],
                                    student_enrollment: ["term start", "term end"],
                                    teacher_enrollment: ["whenever", "term end"],
                                    ta_enrollment: ["whenever", "term end"]
                                  })
    end

    it "student enrollment dates", priority: 1 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f(".edit_term_link").click
      f(".editing_term .student_enrollment_dates .start_date .edit_term input").send_keys("2011-07-02")
      f(".editing_term .student_enrollment_dates .end_date .edit_term input").send_keys("2011-07-30")
      f(".submit_button").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
                                    general: ["whenever", "whenever"],
                                    student_enrollment: ["Jul 2", "Jul 30"],
                                    teacher_enrollment: ["whenever", "term end"],
                                    ta_enrollment: ["whenever", "term end"]
                                  })
    end

    it "teacher enrollment dates", priority: 1 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f(".edit_term_link").click
      f(".editing_term .teacher_enrollment_dates .start_date .edit_term input").send_keys("2011-07-03")
      f(".editing_term .teacher_enrollment_dates .end_date .edit_term input").send_keys("2011-07-29")
      f(".submit_button").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
                                    general: ["whenever", "whenever"],
                                    student_enrollment: ["term start", "term end"],
                                    teacher_enrollment: ["Jul 3", "Jul 29"],
                                    ta_enrollment: ["whenever", "term end"]
                                  })
    end

    it "ta enrollment dates", priority: 1 do
      get "/accounts/#{Account.default.id}/terms"
      term = f("tr.term")
      f(".edit_term_link").click
      f(".editing_term .ta_enrollment_dates .start_date .edit_term input").send_keys("2011-07-04")
      f(".editing_term .ta_enrollment_dates .end_date .edit_term input").send_keys("2011-07-28")
      f(".submit_button").click
      expect(term).not_to have_class("editing_term")
      verify_displayed_term_dates(term, {
                                    general: ["whenever", "whenever"],
                                    student_enrollment: ["term start", "term end"],
                                    teacher_enrollment: ["whenever", "term end"],
                                    ta_enrollment: ["Jul 4", "Jul 28"]
                                  })
    end
  end

  describe "user details view" do
    def create_sub_account(name = "sub_account", parent_account = Account.default)
      Account.create(name:, parent_account:)
    end

    it "is able to view user details from parent account" do
      user_non_root = user_factory
      create_sub_account.account_users.create!(user: user_non_root)
      get "/accounts/#{Account.default.id}/users/#{user_non_root.id}"
      # verify user details displayed properly
      expect(f(".accounts .unstyled_list li")).to include_text("sub_account")
    end
  end
end
