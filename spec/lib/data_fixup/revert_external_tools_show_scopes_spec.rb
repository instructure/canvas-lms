# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe DataFixup::RevertExternalToolsShowScopes do
  specs_require_sharding

  subject(:fixup) { operation_shard.activate { described_class.new } }

  let(:operation_shard) { @shard1 }

  around do |example|
    operation_shard.activate do
      example.run
    end
  end

  before do
    operation_shard.activate do
      account = account_model
      @developer_key = DeveloperKey.create!(account:)
      @developer_key.scopes = [
        "url:GET|/api/v1/courses/:course_id/external_tools/:external_tool_id(/*full_path)",
        "url:GET|/api/v1/accounts/:account_id/external_tools/:external_tool_id(/*full_path)",
        "url:POST|/api/v1/courses/:course_id/external_tools"
      ]
      # Skipping validations to avoid triggering scope validation errors
      @developer_key.save(validate: false)
    end

    # Prevent actual sleeps when testing testing
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  describe "#run" do
    def execute_fixup
      fixup.run
      run_jobs
    end

    it "processes a batch of records" do
      expect { execute_fixup }.to change { @developer_key.reload.scopes }
        .from([
                "url:GET|/api/v1/courses/:course_id/external_tools/:external_tool_id(/*full_path)",
                "url:GET|/api/v1/accounts/:account_id/external_tools/:external_tool_id(/*full_path)",
                "url:POST|/api/v1/courses/:course_id/external_tools"
              ])
        .to([
              "url:GET|/api/v1/courses/:course_id/external_tools/:external_tool_id",
              "url:GET|/api/v1/accounts/:account_id/external_tools/:external_tool_id",
              "url:POST|/api/v1/courses/:course_id/external_tools"
            ])
    end
  end
end
