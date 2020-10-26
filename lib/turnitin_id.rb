# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module TurnitinID
  def generate_turnitin_id!
    # the reason we don't just use the global_id all the time is so that the
    # turnitin_id is preserved when shard splits/etc. occur
    turnitin_id || update_attribute(:turnitin_id, global_id)
  end

  def turnitin_asset_string
    generate_turnitin_id!
    "#{self.class.reflection_type_name}_#{turnitin_id}"
  end
end
