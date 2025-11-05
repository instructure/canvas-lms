# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Extensions
  module ActiveRecord
    module ConnectionHandling
      def with_connection(...)
        attempt ||= 0
        super
      rescue ::ActiveRecord::DatabaseConnectionError
        raise unless attempt == 0

        attempt += 1
        check_database_configuration_change ? retry : raise
      end

      def check_database_configuration_change # rubocop:disable Naming/PredicateMethod
        # Switchman::DatabaseServer.create modifies ActiveRecord::Base.configurations directly,
        # but is only allowed to do so in test environments.
        # We don't want to accidentally kill all connections in test
        return false if Rails.env.test?

        db_configs = ::ActiveRecord::DatabaseConfigurations.new(Rails.application.config.database_configuration)

        if db_configs == ::ActiveRecord::Base.configurations
          # no change; do NOT discard current connections
          false
        else
          ::Rails.logger.info("Database configuration changed; reconnecting...")
          ::ActiveRecord::Base.configurations = db_configs
          # reset a whole bunch of connection info in both AR and Switchman
          Switchman::DatabaseServer.instance_variable_get(:@database_servers).clear
          ::ActiveRecord::Base.connection_handler.each_connection_pool(&:disconnect)
          ::ActiveRecord::Base.connection_handler.send(:connection_name_to_pool_manager).clear
          ::ActiveRecord::Base.establish_connection
          DatabaseServer.all
          true
        end
      end
      module_function :check_database_configuration_change

      Canvas::Reloader.on_reload do
        check_database_configuration_change
      end
    end
  end
end
