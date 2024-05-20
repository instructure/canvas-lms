# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe "profile faculty journal" do
  include_context "in-process server selenium tests"

  before do
    course_with_teacher_logged_in
    @course.account.update_attribute(:enable_user_notes, true)
    @student = user_factory(name: "first student")
    @course.enroll_student(@student).update_attribute(:workflow_state, "active")
    @first_user_note = UserNote.create!(
      creator: @teacher,
      user: @student,
      root_account_id: Account.default.id,
      title: "this is a user note for #{@student.name}",
      note: "#{@student.name} is an excellent student"
    )
    Account.site_admin.disable_feature!(:deprecate_faculty_journal)
    @teacher.set_preference(:suppress_faculty_journal_deprecation_notice, true)
  end

  it "checks the Journal messages for correct info" do
    get "/users/#{@student.id}/user_notes"
    expect(fj("div.title:contains('#{@first_user_note.title}')")).to be_present
    time = format_time_for_view(@first_user_note.updated_at)
    expect(f(".creator_name")).to include_text(@teacher.name)
    expect(f(".creator_name")).to include_text(time)
    expect(fj("div.user_note_content:contains('#{@first_user_note.note}')")).to be_present
  end

  it "allows an teacher to delete a Journal message" do
    get "/users/#{@student.id}/user_notes"
    f(".delete_link").click
    driver.switch_to.alert.accept
    wait_for_ajaximations
    expect(f(".title.subject").text).to eq("")
    expect(@student.user_notes.last.workflow_state).to eq "deleted"
  end

  it "allows a new entry by an teacher", priority: "1" do
    get "/users/#{@student.id}/user_notes"
    f("#new_user_note_button").click
    wait_for_ajaximations # wait for the form to `.slideDown()`
    replace_content(f("#user_note_title"), "FJ Title 2")
    replace_content(f("textarea"), "FJ Body text 2")
    f(".send_button").click
    wait_for_ajaximations
    expect(UserNote.last.title).to eq("FJ Title 2")
    expect(UserNote.last.note).to eq("FJ Body text 2")
  end

  it "shows a deprecation alert and modal until suppressed" do
    @teacher.set_preference(:suppress_faculty_journal_deprecation_notice, false)
    get "/users/#{@student.id}/user_notes"
    expect(f("body")).to include_text("Faculty Journal has been deprecated!")
    f("input[type=checkbox] + label").click
    fj("button:contains('I Understand')").click
    expect(f("body")).not_to include_text("Faculty Journal has been deprecated!")
    expect(f("body")).to include_text("Faculty Journal will be discontinued on June 15, 2024.")
    driver.navigate.refresh
    expect(f("body")).to include_text("Faculty Journal will be discontinued on June 15, 2024.")
    expect(f("body")).not_to include_text("Faculty Journal has been deprecated!")
  end
end
