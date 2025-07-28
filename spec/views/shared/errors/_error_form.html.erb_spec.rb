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

require_relative "../../views_helper"

describe "shared/errors/_error_form" do
  it "renders" do
    course_with_student
    view_context
    render partial: "shared/errors/error_form"
    expect(response).not_to be_nil
    expect(response).to include("error[user_roles]")
  end

  it "renders captcha when user is not logged in" do
    view_context(current_user: nil)
    allow_any_instance_of(ApplicationController).to receive(:captcha_site_key).and_return("test_key")
    render partial: "shared/errors/error_form"
    expect(response).to include("g-recaptcha")
  end
end
