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
#

require_relative "../views_helper"

describe "pseudonyms/confirm_change_password" do
  it "renders" do
    user_factory
    assign(:user, @user)
    assign(:current_user, @user)
    assign(:pseudonym, @user.pseudonyms.create!(unique_id: "unique@example.com", password: "asdfaabb", password_confirmation: "asdfaabb"))
    assign(:password_pseudonyms, @user.pseudonyms)
    assign(:cc, communication_channel(@user, { username: "unique@example.com" }))
    render "pseudonyms/confirm_change_password"
    expect(response).not_to be_nil
  end
end
