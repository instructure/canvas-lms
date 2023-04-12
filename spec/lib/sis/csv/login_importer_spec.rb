# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe SIS::CSV::LoginImporter do
  before :once do
    account_model
    process_csv_data_cleanly(
      "user_id,integration_id,login_id,first_name,last_name,email,status",
      "user_1,int1,user1,User,Uno,user@example.com,active"
    )
  end

  let(:user) { CommunicationChannel.by_path("user@example.com").first.user }

  it "creates new logins on existing users" do
    process_csv_data_cleanly(
      "user_id,login_id,existing_user_id,email",
      "user_1b,user1b,user_1,userb@example.com"
    )
    expect(user.reload.pseudonyms.count).to be(2)
    expect(user.communication_channels.count).to be(2)
  end

  it "finds login within authentication providers" do
    @account.authentication_providers.create!(auth_type: "google")
    # same login_id, on same user with different auth provider.
    process_csv_data_cleanly(
      "user_id,login_id,existing_user_id,email,status,authentication_provider_id",
      "user_1b,user1,user_1,user1@example.com,active,google"
    )
    p = @account.pseudonyms.active.where(sis_user_id: "user_1").first
    expect(p.user.pseudonyms.active.where(unique_id: "user1", account: @account).count).to eq(2)
  end

  it "creates new logins on existing users with integration_id" do
    process_csv_data_cleanly(
      "user_id,login_id,existing_integration_id,email",
      "user_1b,user1b,int1,userb@example.com"
    )
    expect(user.reload.pseudonyms.count).to be(2)
    expect(user.communication_channels.count).to be(2)
  end

  it "creates new logins on existing users with canvas id" do
    process_csv_data_cleanly(
      "user_id,login_id,existing_canvas_user_id,email",
      "user_1b,user1b,#{user.id},userb@example.com"
    )
    expect(user.reload.pseudonyms.count).to be(2)
    expect(user.communication_channels.count).to be(2)
  end

  it "fails when no found user" do
    importer = process_csv_data(
      "user_id,login_id,existing_canvas_user_id,email",
      "user_1b,user1b,not an id,userb@example.com"
    )
    expect(importer.errors.map(&:last).first).to include("Could not find the existing user for login with SIS ID user_1b, skipping")
    expect(user.reload.pseudonyms.count).to be(1)
    expect(user.communication_channels.count).to be(1)
  end

  it "fails when existing user identifiers are invalid" do
    importer = process_csv_data(
      "user_id,login_id,existing_user_id,existing_integration_id,email",
      "user_1b,user1b,user_1,oops,userb@example.com"
    )
    expect(importer.errors.map(&:last).first).to include("An existing user does not match existing user ids provided for login with SIS ID user_1b, skipping")
    expect(user.reload.pseudonyms.count).to be(1)
    expect(user.communication_channels.count).to be(1)
  end

  it "fails when login is already taken" do
    importer = process_csv_data(
      "user_id,login_id,existing_user_id,existing_integration_id,email",
      "user_1,user1,user_1,oops,userb@example.com"
    )
    expect(importer.errors.map(&:last).first).to include("An existing Canvas user with the SIS ID user_1 or login of user1 already exists, skipping")
    expect(user.reload.pseudonyms.count).to be(1)
    expect(user.communication_channels.count).to be(1)
  end

  it "fails for nil existing user_id" do
    importer = process_csv_data(
      "user_id,login_id,existing_user_id,email",
      "user_1b,user1b,,userb@example.com"
    )
    expect(importer.errors.map(&:last).first).to include("No existing user provided for login with SIS ID user_1b")
    expect(user.reload.pseudonyms.count).to be(1)
    expect(user.communication_channels.count).to be(1)
  end
end
