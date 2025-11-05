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

require_relative "../../../spec_helper"

describe Utils::InstStatsdUtils::Tags do
  describe(".tags_for") do
    subject(:tags) { described_class.tags_for(Shard.current) }

    it "includes a cluster tag" do
      expect(tags[:cluster]).to eq "test"
    end

    context "when a value is nil" do
      before do
        allow(Shard.current.database_server).to receive(:id).and_return(nil)
      end

      it "does not include the tag" do
        expect(tags).to eq({})
      end
    end
  end
end
