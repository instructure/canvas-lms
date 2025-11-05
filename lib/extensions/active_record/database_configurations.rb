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
    module DatabaseConfigurations
      module DatabaseConfig
        def ==(other)
          other.is_a?(::ActiveRecord::DatabaseConfigurations::DatabaseConfig) &&
            env_name == other.env_name &&
            name == other.name
        end
      end

      module HashConfig
        def ==(other)
          super &&
            other.is_a?(::ActiveRecord::DatabaseConfigurations::HashConfig) &&
            configuration_hash == other.configuration_hash
        end
      end

      def ==(other)
        configurations == other.configurations
      end
    end
  end
end
