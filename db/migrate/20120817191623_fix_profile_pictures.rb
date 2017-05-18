#
# Copyright (C) 2012 - present Instructure, Inc.
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

class FixProfilePictures < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # we don't support twitter or linked in profile pictures anymore, because
    # they are too small
    User.where(:avatar_image_source => ['twitter', 'linkedin']).
        update_all(
          :avatar_image_source => 'no_pic',
          :avatar_image_url => nil,
          :avatar_image_updated_at => Time.now.utc
        )

    DataFixup::RegenerateUserThumbnails.send_later_if_production(:run)
  end

  def self.down
  end
end
