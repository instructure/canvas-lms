# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

require_relative "../common"
require "rotp"

describe "new login OTP page" do
  include_context "in-process server selenium tests"

  before do
    Account.default.enable_feature!(:login_registration_ui_identity)
  end

  it "prompts for OTP after login if MFA is required and user is configured" do
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    user = user_with_pseudonym(
      active_user: true,
      username: "tuwmfac",
      password: "CfWtyAWtwfQtHeGRTx9BnaU4N"
    )
    user.update!(
      otp_secret_key: ROTP::Base32.random,
      otp_communication_channel: user.communication_channels.sms.create!(path: "1234567890")
    )
    get "/login/canvas"
    f('[data-testid="username-input"]').send_keys(@pseudonym.unique_id)
    f('[data-testid="password-input"]').send_keys("CfWtyAWtwfQtHeGRTx9BnaU4N")
    f('[data-testid="login-button"]').click
    expect(f("h1").text).to include("Multi-Factor Authentication")
    expect(f('[data-testid="otp-input"]')).to be_displayed
  end

  it "shows an error when submitting OTP without a code" do
    user = user_with_pseudonym(
      active_user: true,
      username: "tuwmfac",
      password: "CfWtyAWtwfQtHeGRTx9BnaU4N"
    )
    user.update!(
      otp_secret_key: ROTP::Base32.random,
      otp_communication_channel: user.communication_channels.sms.create!(path: "1234567890")
    )
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    get "/login/canvas"
    f('[data-testid="username-input"]').send_keys(@pseudonym.unique_id)
    f('[data-testid="password-input"]').send_keys("CfWtyAWtwfQtHeGRTx9BnaU4N")
    f('[data-testid="login-button"]').click
    expect(f("h1").text).to include("Multi-Factor Authentication")
    f('[data-testid="verify-button"]').click
    error_el = fxpath("//*[text()='Please enter the code sent to your phone.']")
    expect(error_el).to be_displayed
  end

  it "shows an error when submitting an invalid OTP code" do
    user = user_with_pseudonym(
      active_user: true,
      username: "tuwmfac",
      password: "CfWtyAWtwfQtHeGRTx9BnaU4N"
    )
    user.update!(
      otp_secret_key: ROTP::Base32.random,
      otp_communication_channel: user.communication_channels.sms.create!(path: "1234567890")
    )
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    get "/login/canvas"
    f('[data-testid="username-input"]').send_keys(@pseudonym.unique_id)
    f('[data-testid="password-input"]').send_keys("CfWtyAWtwfQtHeGRTx9BnaU4N")
    f('[data-testid="login-button"]').click
    expect(f("h1").text).to include("Multi-Factor Authentication")
    f('[data-testid="otp-input"]').send_keys("000000")
    f('[data-testid="verify-button"]').click
    error = fxpath("//*[contains(text(), 'Invalid verification code')]")
    expect(error).to be_displayed
  end

  it "returns to login page when clicking Cancel on the OTP form" do
    user = user_with_pseudonym(
      active_user: true,
      username: "tuwmfac",
      password: "CfWtyAWtwfQtHeGRTx9BnaU4N"
    )
    user.update!(
      otp_secret_key: ROTP::Base32.random,
      otp_communication_channel: user.communication_channels.sms.create!(path: "1234567890")
    )
    Account.default.settings[:mfa_settings] = :required
    Account.default.save!
    get "/login/canvas"
    f('[data-testid="username-input"]').send_keys(@pseudonym.unique_id)
    f('[data-testid="password-input"]').send_keys("CfWtyAWtwfQtHeGRTx9BnaU4N")
    f('[data-testid="login-button"]').click
    expect(f("h1").text).to include("Multi-Factor Authentication")
    f('[data-testid="cancel-button"]').click
    expect(f("h1").text).to include("Welcome to Canvas")
  end
end
