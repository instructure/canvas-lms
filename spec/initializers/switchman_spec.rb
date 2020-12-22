# frozen_string_literal: true

# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe Switchman::Shard do
  describe "in_region" do
    it "should not include shards referencing non-extant database servers" do
      # this one isn't actually in the config
      allow(Shard).to receive(:non_existent_database_servers).and_return(["jobs4"])

      dbs = []
      dbs << DatabaseServer.new("jobs1", { region: 'us-east-1' })
      dbs << DatabaseServer.new("jobs2", { region: 'us-east-1' })
      dbs << DatabaseServer.new("jobs3", { region: 'eu-west-1' })
      dbs << DatabaseServer.new("jobs4", { region: 'us-east-1' })
      allow(DatabaseServer).to receive(:all).and_return(dbs)

      s1 = Shard.create!(database_server_id: "jobs1")
      s2 = Shard.create!(database_server_id: "jobs2")
      s3 = Shard.create!(database_server_id: "jobs3")
      s4 = Shard.create!(database_server_id: "jobs4")

      expect(Shard.in_region('us-east-1')).to eq([s1, s2])
      expect(Shard.in_region('eu-west-1')).to eq([s3])
    end
  end
end