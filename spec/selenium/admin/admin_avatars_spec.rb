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
require_relative "../grades/pages/gradebook_page"
require_relative "../grades/pages/gradebook_cells_page"
require_relative "pages/student_context_tray_page"

# NOTE: We are aware that we're duplicating some unnecessary testcases, but this was the
# easiest way to review, and will be the easiest to remove after the feature flag is
# permanently removed. Testing both flag states is necessary during the transition phase.
shared_examples "admin avatars" do |ff_enabled|
  include_context "in-process server selenium tests"

  before :once do
    # Set feature flag state for the test run - this affects how the gradebook data is fetched, not the data setup
    if ff_enabled
      Account.site_admin.enable_feature!(:performance_improvements_for_gradebook)
    else
      Account.site_admin.disable_feature!(:performance_improvements_for_gradebook)
    end
  end

  before do
    course_with_admin_logged_in
    Account.default.enable_service(:avatars)
    Account.default.settings[:avatars] = "enabled_pending"
    Account.default.save!
  end

  def create_avatar_state(avatar_state = "submitted", avatar_image_url = "http://www.example.com")
    user = User.last
    user.avatar_image_url = avatar_image_url
    user.save!
    user.avatar_state = avatar_state
    user.save!
    get "/accounts/#{Account.default.id}/avatars"
    user
  end

  def verify_avatar_state(user, opts = {})
    if opts.empty?
      expect(f("#submitted_profile")).to include_text "Submitted 1"
      f("#submitted_profile").click
    else
      expect(f(opts.keys[0])).to include_text(opts.values[0])
      f(opts.keys[0]).click
    end
    expect(f("#avatars .name")).to include_text user.name
    expect(f(".avatar")).to have_attribute("style", /http/)
  end

  def lock_avatar(user, element)
    element.click
    f(".links .lock_avatar_link").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    expect(f(".links .unlock_avatar_link")).to be_displayed
    user.reload
    expect(user.avatar_state).to eq :locked
    user
  end

  it "verifies that the profile picture is submitted" do
    user = create_avatar_state
    verify_avatar_state(user)
  end

  it "verifies that the profile picture is reported" do
    user = create_avatar_state("reported")
    opts = { "#reported_profile" => "Reported 1" }
    verify_avatar_state(user, opts)
  end

  it "verifies that the profile picture is approved, re-reported" do
    user = create_avatar_state("re_reported")
    opts = { "#re_reported_profile" => "Re-Reported 1" }
    verify_avatar_state(user, opts)
  end

  it "verifies that all profile pictures are displayed" do
    user = create_avatar_state
    opts = { "#any_profile" => "All 1" }
    verify_avatar_state(user, opts)
  end

  it "locks the avatar state" do
    user = create_avatar_state
    lock_avatar(user, f("#any_profile"))
  end

  it "unlocks the avatar state" do
    user = create_avatar_state
    user = lock_avatar(user, f("#any_profile"))
    f(".links .unlock_avatar_link").click
    wait_for_ajax_requests
    user.reload
    expect(user.avatar_state).to eq :approved
    expect(f(".links .lock_avatar_link")).to be_displayed
  end

  it "approves un-approved avatar" do
    user = create_avatar_state
    expect(user.avatar_state).to eq :submitted
    f(".links .approve_avatar_link").click
    wait_for_ajax_requests
    user.reload
    expect(user.avatar_state).to eq :approved
    expect(f(".links .approve_avatar_link")).not_to be_displayed
  end

  it "deletes the avatar" do
    user = create_avatar_state
    f("#any_profile").click
    f(".links .reject_avatar_link").click
    driver.switch_to.alert.accept
    wait_for_ajax_requests
    user.reload
    expect(user.avatar_state).to eq :none
    expect(user.avatar_image_url).to be_nil
  end

  context "student tray in original gradebook" do
    include StudentContextTray

    before do
      @account = Account.default
      @student = student_in_course.user
      @student.avatar_image_url = "http://www.example.com"
      Gradebook.visit(@course)
      Gradebook::Cells.student_cell_name_link(@student).click
    end

    it "displays student avatar in tray", priority: "1" do
      wait_for_student_tray

      expect(student_avatar_link).to be_displayed
    end
  end
end

describe "admin avatars" do
  it_behaves_like "admin avatars", true
  it_behaves_like "admin avatars", false
end
