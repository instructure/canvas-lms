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

describe "Permission Registry" do
  before :all do
    @original_permission = Permissions.instance_variable_get(:@permissions)
  end

  after do
    Permissions.instance_variable_set(:@permissions, @original_permission)
  end

  before do
    Permissions.instance_variable_set(:@permissions, nil)
  end

  it "registers the correct permissions" do
    Rails.application.config.to_prepare_blocks.each(&:call)

    registered_permissions = Permissions.retrieve

    expect(registered_permissions[:become_user]).to include(
      label: an_instance_of(Proc),
      label_v2: an_instance_of(Proc),
      account_only: :root,
      true_for: %w[AccountAdmin],
      available_to: %w[AccountAdmin AccountMembership]
    )
  end

  it "calls Permissions.retrieve after initialization" do
    expect(Permissions).to receive(:retrieve).and_call_original

    Rails.application.config.after_initialize { Permissions.retrieve.freeze }
  end

  it "freezes the retrieved permissions" do
    allow(Permissions).to receive(:retrieve).and_return({ some_permission: "value" })

    Rails.application.config.after_initialize { Permissions.retrieve.freeze }

    expect(Permissions.retrieve).to be_frozen
  end
end
