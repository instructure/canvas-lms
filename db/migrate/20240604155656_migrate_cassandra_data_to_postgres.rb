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

class MigrateCassandraDataToPostgres < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  include Canvas::Cassandra::Migration

  def self.cassandra_cluster
    "page_views"
  end

  def self.paging_limit
    1000
  end

  def self.up
    return unless PageView.cassandra?

    consistency = CanvasCassandra::DatabaseBuilder.read_consistency_setting(:page_views)

    last_id = nil
    loop do
      args = []
      query = +"SELECT * FROM page_views %CONSISTENCY%"
      if last_id
        query << " WHERE token(request_id) > token(?)"
        args << last_id
      end
      query << " LIMIT #{paging_limit}"
      last_id = nil
      cassandra.execute(query, *args, consistency:).fetch do |row|
        pv = PageView.from_attributes(row.to_hash, true)
        last_id = pv.request_id
        pv.save!
      rescue ActiveRecord::RecordNotUnique
        # ignore duplicates from a possibly interrupted migration
      end
      break if last_id.nil?
    end

    Setting.set("enable_page_views", "db")
  end
end
