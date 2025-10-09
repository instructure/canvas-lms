# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "shared_examples_common"

# ======================================================================================================================
# Shared Examples
# ======================================================================================================================

shared_examples "profile_settings_page" do
  include SharedExamplesCommon

  it "gives option to change profile pic", priority: "2" do
    enable_avatars(false)
    get "/profile/settings"
    driver.action.move_to(f(".avatar.profile_pic_link.none")).perform
    wait_for_ajaximations

    # We want to make sure the pencil icon is visible
    expect(fj(".avatar.profile_pic_link.none:contains('Click to change profile picture')")).to be_displayed
  end
end

shared_examples "profile_user_about_page" do
  include SharedExamplesCommon

  it "gives option to change profile pic", priority: "2" do
    enable_avatars(false)
    get "/about/#{@user.id}"

    driver.action.move_to(f(".profile-edit-link")).perform
    wait_for_ajaximations

    # We are checking the title in this tooltip like we do in the one above,
    # given the same limitation.
    expect(f(".btn.btn-small.profile-edit-link")).to be_displayed
  end
end

shared_examples "user settings page change pic window" do
  include SharedExamplesCommon

  it "allows user to click to change profile pic", priority: "1" do
    enable_avatars(true)
    get "/profile/settings"

    f(".avatar.profile_pic_link.none").click
    wait_for_ajaximations

    # Modal is open
    expect(f("[data-testid='avatar-modal']")).to be_truthy

    # There is a default gray image placeholder for picture
    expect(f("[data-testid='upload-panel'] .select-photo-link")).to include_text("choose a picture")

    f("[data-testid='avatar-type-select']").click
    wait_for_ajaximations

    # There are 'Upload Picture' and 'From Gravatar' buttons
    expect(f("#upload-option")).to include_text("Upload a Picture")
    expect(f("#gravatar-option")).to include_text("From Gravatar")
  end
end

shared_examples "with gravatar settings" do
  include SharedExamplesCommon

  it "does not allow user to see gravatar when disabled", priority: "1" do
    enable_avatars(false)
    get "/profile/settings"

    f(".avatar.profile_pic_link.none").click
    wait_for_ajaximations

    f("[data-testid='avatar-type-select']").click
    wait_for_ajaximations

    expect(f("body")).not_to contain_css("#gravatar-option")
  end
end

shared_examples "user settings change pic cancel" do
  include SharedExamplesCommon

  it "closes window when cancel button is pressed", priority: "1" do
    enable_avatars(false)
    get "/profile/settings"

    f(".avatar.profile_pic_link.none").click
    wait_for_ajaximations

    expect(f("[data-testid='avatar-modal']")).to be_truthy

    f("[data-testid='close-modal-button']").click
    wait_for_ajaximations

    expect(f("body")).not_to contain_css("[data-testid='avatar-modal']")
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================
shared_context "profile common" do
  def enable_avatars(withGravatar)
    a = Account.default.reload
    a.enable_service("avatars")
    a.settings[:enable_profiles] = true
    a.settings[:enable_gravatar] = withGravatar
    a.save!
    a
  end
end
