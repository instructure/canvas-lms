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

describe DataFixup::DeleteRedundantNewUserTutorialFeatureFlags do
  specs_require_sharding

  subject(:fixup) { operation_shard.activate { described_class.new } }

  let(:operation_shard) { @shard1 }

  around do |example|
    operation_shard.activate do
      example.run
    end
  end

  before do
    # Prevent actual sleeps when testing
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  describe "#run" do
    def execute_fixup
      fixup.run
      run_jobs
    end

    it "processes a batch of records" do
      users = []
      operation_shard.activate do
        2.times { |i| users << User.create!(name: "User #{i}") }
        users[0].feature_flags.create!(feature: "new_user_tutorial_on_off", state: "on")
        users[1].feature_flags.create!(feature: "new_user_tutorial_on_off", state: "off")
      end

      execute_fixup

      expect(users[0].feature_flags.where(feature: "new_user_tutorial_on_off").pluck(:state)).to eq([])
      expect(users[1].feature_flags.where(feature: "new_user_tutorial_on_off").pluck(:state)).to eq(["off"])
    end
  end
end
