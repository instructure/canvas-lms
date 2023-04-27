# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe StreamItemInstance do
  describe ".update_all" do
    it "raises an exception to warn about necessary cache invalidation" do
      expect { StreamItemInstance.update_all }.to raise_error("Using update_all will break things, use update_all_with_invalidation instead.")
    end
  end

  describe ".update_all_with_invalidation" do
    it "invalidates stream item cache keys and runs batched updates" do
      # expect
      expect(StreamItemCache).to receive(:invalidate_context_stream_item_key).twice
      expect(StreamItemInstance).to receive(:in_batches).and_call_original
      # when
      StreamItemInstance.update_all_with_invalidation(["code_1", "code_2"],
                                                      "updates")
    end
  end
end
