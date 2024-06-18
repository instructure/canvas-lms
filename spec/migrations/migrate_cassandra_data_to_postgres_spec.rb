# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../cassandra_spec_helper"
require_relative "../../db/migrate/20240604155656_migrate_cassandra_data_to_postgres"

describe MigrateCassandraDataToPostgres do
  subject(:migration) { described_class }

  include_examples "cassandra page views"

  it "works" do
    allow(migration).to receive(:paging_limit).and_return(2)

    expect(PageView.count).to be 0

    user = User.create!

    5.times do
      migration.cassandra.execute("UPDATE page_views SET user_id=? WHERE request_id=?", user.id, SecureRandom.uuid)
    end

    # 3 times for each page, and 1 time for the no data page
    expect(migration.cassandra).to receive(:execute).exactly(4).times.and_call_original

    migration.up

    expect(PageView.count).to be 5
  end
end
