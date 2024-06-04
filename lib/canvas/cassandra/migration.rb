# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Canvas
  module Cassandra
    module Migration
      module ClassMethods
        def cassandra
          # Our current cassandra.yml in production set a timeout of 15 seconds. We've seen some migrations appear to
          # fail but actually succeded in a way that seems like timeout issues. For a migration we'll just override the
          # statement timeout to be 3 minutes. (It should hopefully never take 3 minutes.)
          @cassandra ||= CanvasCassandra::DatabaseBuilder.from_config(cassandra_cluster,
                                                                      override_options: { "timeout" => 180 })
        end

        def runnable?
          raise "cassandra_cluster is required to be defined" unless respond_to?(:cassandra_cluster) && cassandra_cluster.present?

          Switchman::Shard.current == Switchman::Shard.birth && CanvasCassandra::DatabaseBuilder.configured?(cassandra_cluster)
        end
      end

      def self.included(migration)
        migration.tag :cassandra
        migration.singleton_class.include(ClassMethods)
      end
    end
  end
end
