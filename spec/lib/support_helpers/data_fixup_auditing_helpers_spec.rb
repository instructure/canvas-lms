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

RSpec.describe "data fixup auditing shared context" do
  include_context "data fixup auditing"

  let(:dummy_fixup) do
    stub_const("AuditedDataFixup", Class.new(CanvasOperations::DataFixup) do
      self.mode = :individual_record
      self.record_changes = true
      self.progress_tracking = false

      scope { User.all }

      def process_record(user)
        "edited #{user.id}"
      end
    end)
  end

  it "populates data_fixup_audit_logs after running the fixup" do
    user = user_model
    user2 = user_model

    dummy_fixup.new.run

    expect(data_fixup_audit_logs.first).to include("edited #{user.id}").and(include("edited #{user2.id}"))
    expect(data_fixup_audit_logs(Shard.current.id)).to eq("edited #{user.id}\nedited #{user2.id}\n")
  end
end
