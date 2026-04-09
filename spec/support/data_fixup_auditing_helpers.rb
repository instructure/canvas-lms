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

# Shared context for specs that exercise CanvasOperations::DataFixup auditing.
#
# Stubs Attachments::Storage.store_for_attachment (which requires InstFS and
# does not work in the test environment) and captures each chunk written so
# specs can assert on audit output without needing real file storage.
#
# Usage:
#   include_context "data fixup auditing"
#
#   it "records changes" do
#     subject # run your fixup
#     expect(data_fixup_audit_logs).to include("some logged text")
#   end

module Helpers
  def data_fixup_audit_logs(shard_id = nil)
    return data_fixup_audit_logs_per_shard[shard_id].join if shard_id

    data_fixup_audit_logs_per_shard.values.map(&:join)
  end
end

RSpec.shared_context "data fixup auditing" do
  let(:data_fixup_audit_logs_per_shard) { {} }

  before do
    allow(Attachments::Storage).to receive(:store_for_attachment) do |_attachment, data|
      data_fixup_audit_logs_per_shard[Shard.current.id] ||= []
      data_fixup_audit_logs_per_shard[Shard.current.id] << data.read
    end
  end
end
