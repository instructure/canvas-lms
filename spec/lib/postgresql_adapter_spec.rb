# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe ActiveRecord::ConnectionAdapters::PostgreSQLAdapter do
  it "aborts a query when interrupted" do
    aborted = false
    thread = Thread.new do
      User.connection.transaction(requires_new: true) do
        User.connection.execute("SELECT pg_sleep(30)")
      rescue IRB::Abort
        aborted = true
        raise ActiveRecord::Rollback
      end
      # make sure we can immediately execute our next query
      User.connection.execute("SELECT 1")
    end

    start = Time.now.utc
    # make sure it starts the query
    sleep 0.5
    thread.raise(IRB::Abort)
    thread.join

    expect(Time.now.utc - start).to be < 1.0
    expect(aborted).to be true
  end

  it "differentiates between unique and non-unique indexes" do
    indexes = User.connection.indexes(User.table_name)
    expect(indexes.select(&:unique)).to_not eq([])
    expect(indexes.reject(&:unique)).to_not eq([])
  end

  it "can handle an array of hosts, falling back to a successful connection" do
    db_config = ActiveRecord::Base.connection_pool.db_config
    config = db_config.configuration_hash.dup
    # host might be nil on purpose so can't use Array(), but it might also be an array,
    # so we need to flatten
    config[:host] = (["nonexistent"] + [config[:host]]).flatten
    db_config = ActiveRecord::DatabaseConfigurations::HashConfig.new(db_config.env_name, db_config.name, config)
    conn = if $canvas_rails == "7.2"
             db_config.new_connection
           else
             ActiveRecord::Base.public_send(db_config.adapter_method, db_config.configuration_hash)
           end
    conn.execute("SELECT 1")
  ensure
    conn&.disconnect!
  end
end
