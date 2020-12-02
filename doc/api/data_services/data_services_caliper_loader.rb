# frozen_string_literal: true

#
# Copyright (C) 2020 Instructure, Inc.
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
class DataServicesCaliperLoader
  JSON_BASE_PATH = 'doc/api/data_services/json/caliper'

  def self.data
    @@data ||= begin
      DataServicesEventsLoader.new(JSON_BASE_PATH).data
    end
  end

  def self.extensions
    @@extensions ||= begin
      {
        'extensions' => JSON.parse(File.read("#{JSON_BASE_PATH}/extensions.json")),
        'actor_extensions' => JSON.parse(File.read("#{JSON_BASE_PATH}/actor_extensions.json"))
      }
    end
  end
end
