# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

require_relative "report_spec_helper"

describe AccountReports::DeveloperKeyReports do
  include ReportSpecHelper

  subject do
    first_key
    second_key
    site_admin_key
    read_report(report_type, report_opts)
  end

  let_once(:account) { Account.default }
  let_once(:first_key) do
    dk = dev_key_model({ scopes: [
                           "url:GET|/api/v1/users/:user_id/custom_data(/*scope)",
                           "url:GET|/api/v1/users/:user_id/page_views",
                           "url:GET|/api/v1/users/:user_id/profile",
                           "url:GET|/api/v1/users/:user_id/avatars",
                           "url:GET|/api/v1/users/self/course_nicknames",
                           "url:GET|/api/v1/users/self/course_nicknames/:course_id"
                         ],
                         name: "First Key",
                         account: })
    enable_developer_key_account_binding! dk
    dk
  end
  let_once(:second_key) do
    dk = dev_key_model_1_3({ name: "Second Key",
                             public_jwk_url: "http://test.com/jwks",
                             account: })
    disable_developer_key_account_binding! dk
    dk
  end
  let_once(:site_admin_key) do
    dk = dev_key_model({ name: "Site Admin Key" })
    disable_developer_key_account_binding! dk
    dk
  end
  let_once(:report_type) { "developer_key_report_csv" }
  let_once(:expected_keys) { [first_key, second_key] }
  let_once(:report_opts) do
    {
      order: 0,
      account:
    }
  end
  let(:expected_result) do
    [

      [
        first_key.global_id,
        first_key.name,
        false,
        first_key.email,
        "API Key",
        "None",
        "On",
        first_key.scopes
      ].map(&:to_s),
      [
        second_key.global_id,
        second_key.name,
        false,
        second_key.email,
        "LTI Key",
        second_key.tool_configuration.placements.pluck("placement"),
        "Off",
        second_key.scopes
      ].map(&:to_s)

    ]
  end

  it "runs on a root account" do
    expect(subject).to eq(expected_result)
  end

  context "the first key isn't marked as visible" do
    before do
      first_key.update!(visible: false)
    end

    it "still returns the first key" do
      expect(subject).to eq(expected_result)
    end
  end

  context "the site_admin key is now visible" do
    let(:expected_result) do
      er = super()
      er.append(
        [
          site_admin_key.global_id,
          site_admin_key.name,
          true,
          site_admin_key.email,
          "API Key",
          "None",
          "Off",
          "All"
        ].map(&:to_s)
      )
    end

    before do
      site_admin_key.update!(visible: true)
    end

    it "includes the inherited key" do
      expect(subject).to eq(expected_result)
    end

    context "the site_admin key is set to on" do
      before do
        site_admin_key.developer_key_account_bindings.first.update!(account: Account.site_admin, workflow_state: "on")
      end

      it "shows the key status as 'On'" do
        # See the DeveloperKeyReports::DEV_KEY_REPORT_HEADERS constant to see what info
        # goes where on each row.
        expect(subject.find { |row| row[0] == site_admin_key.global_id.to_s }[6]).to eq("On")
      end
    end
  end
end
