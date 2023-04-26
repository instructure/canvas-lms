# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

describe EventStream::Backend::Cassandra do
  let(:database) do
    database = double("database")

    def database.batch
      yield
    end

    def database.update_record(*); end

    def database.insert_record(*args)
      @inserted ||= []
      @inserted << args
    end

    # rubocop:disable Style/TrivialAccessors
    def database.inserted
      @inserted
    end
    # rubocop:enable Style/TrivialAccessors

    def database.update(*); end

    def database.available?
      true
    end

    def database.keyspace
      "test_db"
    end

    def database.fingerprint
      "fingerprint"
    end

    database
  end

  let(:stream) do
    db = database
    s = EventStream::Stream.new do
      backend_strategy :cassandra
      table "test_table"
      database db
    end
    s.raise_on_error = true
    s
  end

  let(:event_record) do
    OpenStruct.new(field: "value", created_at: Time.zone.now, id: "big-uuid")
  end

  describe "executing operations" do
    let(:backend) { EventStream::Backend::Cassandra.new(stream) }

    it "proxies calls through provided cassandra db" do
      backend.execute(:insert, event_record)
      expect(database.inserted.size).to eq(1)
      expect(database.inserted.first[1]["id"]).to eq("big-uuid")
    end

    it "pulls db fingerprint" do
      expect(backend.database_fingerprint).to eq("fingerprint")
    end

    it "uses keyspace for name" do
      expect(backend.database_name).to eq("test_db")
    end
  end
end
