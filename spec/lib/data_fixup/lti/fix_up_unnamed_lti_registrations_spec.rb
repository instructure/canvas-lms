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

describe DataFixup::Lti::FixUpUnnamedLtiRegistrations do
  describe "#run" do
    let(:account) { account_model }
    let(:user) { user_model }
    let(:dev_key_name) { "Developer Key Name" }

    it "updates name and nickname for 'Unnamed tool' registrations with blank admin_nickname" do
      registration = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: dev_key_name },
        registration_params: { name: "Unnamed tool", admin_nickname: nil }
      )

      DataFixup::Lti::FixUpUnnamedLtiRegistrations.run

      registration.reload
      expect(registration.name).to eq(dev_key_name)
    end

    it "updates only name for 'Unnamed tool' registrations with existing admin_nickname" do
      existing_nickname = "Existing Nickname"
      registration = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: dev_key_name },
        registration_params: { name: "Unnamed tool", admin_nickname: existing_nickname }
      )

      DataFixup::Lti::FixUpUnnamedLtiRegistrations.run

      registration.reload
      expect(registration.name).to eq(dev_key_name)
    end

    it "does not modify registrations that don't have 'Unnamed tool' as the name" do
      custom_name = "Custom Tool Name"
      custom_nickname = "Custom Nickname"
      registration = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: dev_key_name },
        registration_params: { name: custom_name, admin_nickname: custom_nickname }
      )

      DataFixup::Lti::FixUpUnnamedLtiRegistrations.run

      registration.reload
      expect(registration.name).to eq(custom_name)
    end

    it "skips developer keys with nil names" do
      registration = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: nil },
        registration_params: { name: "Unnamed tool", admin_nickname: nil }
      )

      DataFixup::Lti::FixUpUnnamedLtiRegistrations.run

      registration.reload
      expect(registration.name).to eq("Unnamed tool")
    end

    it "handles multiple registrations correctly" do
      # Registration that should have both name and nickname updated
      reg1 = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: dev_key_name },
        registration_params: { name: "Unnamed tool", admin_nickname: nil }
      )

      second_dev_key_name = "Second Developer Key Name"
      reg2 = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: second_dev_key_name },
        registration_params: { name: "Unnamed tool", admin_nickname: "Existing Nickname" }
      )

      custom_name = "Custom Tool Name"
      reg3 = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: dev_key_name },
        registration_params: { name: custom_name, admin_nickname: "Custom Nickname" }
      )

      reg4 = lti_registration_with_tool(
        account:,
        created_by: user,
        developer_key_params: { name: nil },
        registration_params: { name: "Unnamed tool", admin_nickname: nil }
      )

      DataFixup::Lti::FixUpUnnamedLtiRegistrations.run

      [reg1, reg2, reg3, reg4].each(&:reload)
      expect(reg1.name).to eq(dev_key_name)
      expect(reg2.name).to eq(second_dev_key_name)
      expect(reg3.name).to eq(custom_name)
      expect(reg4.name).to eq("Unnamed tool")
    end
  end
end
