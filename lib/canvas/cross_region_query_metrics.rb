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

module Canvas
  class CrossRegionQueryMetrics < ActiveSupport::LogSubscriber
    class << self
      @ignored = false

      def ignore
        prior = @ignored
        @ignored = true
        yield
      ensure
        @ignored = prior
      end

      def ignored?
        @ignored
      end
    end

    def sql(event)
      return if defined?(Rails::Console) # don't count queries from the console
      return if self.class.ignored?

      payload = event.payload

      shard = payload[:shard]
      return unless shard
      # don't count queries to the default shard
      return if shard[:id] == ::Shard.default.id

      db = DatabaseServer.find(shard[:database_server_id])
      return if db.in_current_region?

      InstStatsd::Statsd.distributed_increment("cross_region_queries", tags: {
                                                 source_region: Switchman.region,
                                                 target_region: db.region,
                                                 cluster: shard[:database_server_id]
                                               })
    end
  end
end
