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

describe Canvas::CrossRegionQueryMetrics do
  specs_require_sharding

  it "emits a metric when a cross-region query is made" do
    @shard1.activate do
      # make sure schema is loaded; we care in production, but not for counting a single
      # occurence in this test
      User.count

      db = @shard1.database_server
      allow(db).to receive_messages(in_current_region?: false, region: "us-west-2")
      allow(DatabaseServer).to receive(:find).with(db.id).and_return(db)
      allow(DatabaseServer).to receive(:find).and_call_original
      allow(Switchman).to receive(:region).and_return("us-east-1")
      allow(Shard.current).to receive(:database_server).and_return(db)
      expect(InstStatsd::Statsd).to receive(:distributed_increment).with(
        "cross_region_queries",
        tags: {
          source_region: "us-east-1",
          target_region: "us-west-2",
          cluster: db.id
        }
      )
      User.count
    end
  end

  it "does not emit a metric for a cross-region query to the default shard" do
    db = @shard1.database_server
    allow(db).to receive_messages(in_current_region?: false)
    allow(DatabaseServer).to receive(:find).with(db.id).and_return(db)
    allow(DatabaseServer).to receive(:find).and_call_original
    allow(Shard.current).to receive(:database_server).and_return(db)
    expect(InstStatsd::Statsd).not_to receive(:distributed_increment)
    User.count
  end

  it "does not emit a metric for a same-region query" do
    expect(InstStatsd::Statsd).not_to receive(:distributed_increment)
    User.count
  end

  it "can be ignored" do
    @shard1.activate do
      # make sure schema is loaded; we care in production, but not for counting a single
      # occurence in this test
      User.count

      db = @shard1.database_server
      allow(db).to receive_messages(in_current_region?: false, region: "us-west-2")
      allow(DatabaseServer).to receive(:find).with(db.id).and_return(db)
      allow(DatabaseServer).to receive(:find).and_call_original
      allow(Switchman).to receive(:region).and_return("us-east-1")
      allow(Shard.current).to receive(:database_server).and_return(db)
      expect(InstStatsd::Statsd).not_to receive(:distributed_increment)
      described_class.ignore do
        User.count
      end
    end
  end
end
