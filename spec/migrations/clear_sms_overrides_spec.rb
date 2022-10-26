# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../../db/migrate/20210830223331_clear_sms_overrides"

describe ClearSmsOverrides do
  let(:migration) { described_class.new }

  it "clears the global setting" do
    Setting.set("allowed_sms_notification_categories", "foobar")

    expect do
      migration.change
    end.to change {
      Setting.get("allowed_sms_notification_categories", nil)
    }.from("foobar").to(nil)
  end

  it "queues sms settings to be cleared" do
    expect(DataFixup::ClearAccountSettings).to receive(:run).with([
                                                                    "allowed_sms_notification_categories",
                                                                    "allowed_sms_notification_types"
                                                                  ])

    migration.change
  end
end
