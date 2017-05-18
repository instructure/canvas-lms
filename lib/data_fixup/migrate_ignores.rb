#
# Copyright (C) 2013 - present Instructure, Inc.
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

module DataFixup::MigrateIgnores
  def self.run
    User.where("preferences LIKE '%ignore%'").find_each do |user|
      user.preferences[:ignore].each do |purpose, assets|
        assets.each do |asset, details|
          begin
            ignore = Ignore.new
            ignore.asset_type, ignore.asset_id = ActiveRecord::Base.parse_asset_string(asset)
            ignore.purpose = purpose.to_s
            ignore.permanent = details[:permanent]
            ignore.created_at = Time.parse(details[:set])
            ignore.user = user
            ignore.save!
          rescue ActiveRecord::RecordNotUnique
          end
        end
      end
    end
  end
end