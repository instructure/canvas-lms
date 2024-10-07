# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

require "spec_helper"

describe DataFixup::RenameLtiScope do
  subject { DataFixup::RenameLtiScope.run(old_scope, new_scope) }

  let_once(:old_scope) { "https://canvas.instructure.com/lti/page_content/show" }
  let_once(:new_scope) { "https://canvas.instructure.com/lti/feature_flags/scope/show" }
  let(:devkey) do
    dev_key_model(
      {
        scopes: [
          "url:GET|/api/v1/users/:user_id/custom_data(/*scope)",
          "url:GET|/api/v1/users/:user_id/page_views",
          "url:GET|/api/v1/users/:user_id/profile",
          "url:GET|/api/v1/users/:user_id/avatars",
          "url:GET|/api/v1/users/self/course_nicknames",
          "url:GET|/api/v1/users/self/course_nicknames/:course_id"
        ],
      }
    )
  end
  let(:devkey13) do
    key = dev_key_model_1_3
    key.scopes.append(old_scope)
    key.tool_configuration.scopes = [old_scope]
    key.tool_configuration.save!
    key.save!
    key
  end

  it "does not alter other scopes" do
    devkey_expected_scopes = devkey.scopes.deep_dup
    subject
    expect(devkey.reload.scopes).to eq(devkey_expected_scopes)
  end

  it "alters expected scopes" do
    devkey13_expected_scopes = devkey13.scopes.map { |scope| (scope == old_scope) ? new_scope : scope }
    devkey13_tc_expected_scopes = devkey13.tool_configuration.settings["scopes"].map { |scope| (scope == old_scope) ? new_scope : scope }
    subject
    expect(devkey13.reload.scopes).to eq(devkey13_expected_scopes)
    expect(devkey13.tool_configuration.reload.settings["scopes"]).to eq(devkey13_tc_expected_scopes)
  end
end
