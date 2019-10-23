#
# Copyright (C) 2019 - present Instructure, Inc.
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

class Loaders::AssetStringLoader < GraphQL::Batch::Loader
  def perform(asset_strings)
    objects = ActiveRecord::Base.find_all_by_asset_string(asset_strings)
    objects.each do |object|
      fulfill(object.asset_string, object)
    end

    asset_strings.each do |asset_string|
      fulfill(asset_string, nil) unless fulfilled?(asset_string)
    end
  end
end