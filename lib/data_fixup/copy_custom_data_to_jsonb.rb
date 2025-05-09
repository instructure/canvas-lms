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

module DataFixup::CopyCustomDataToJsonb
  def self.run
    # Skip if data is empty or data_json has already been modified before this fixup runs
    CustomData.where.not(data: [nil, {}]).where(data_json: {}).find_each(strategy: :id) do |custom_data|
      custom_data.update_column(:data_json, custom_data["data"])
    end
  end
end
