#
# Copyright (C) 2017 - present Instructure, Inc.
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

module SIS
  module Models
    class DataChange
      attr_accessor :old_id, :new_id, :old_integration_id, :new_integration_id, :type

      def initialize(old_id: nil, new_id: nil, old_integration_id: nil, new_integration_id: nil, type: nil)
        self.old_id = old_id
        self.new_id = new_id
        self.old_integration_id = old_integration_id
        self.new_integration_id = new_integration_id
        self.type = type
      end

      def to_a
        [old_id, new_id, old_integration_id, new_integration_id, type]
      end
    end
  end
end


