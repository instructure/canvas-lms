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

module DataFixup
  module ConvertHighContrastSettingToFeatureFlag
    def self.run
      User.where("preferences LIKE '%high_contrast%'").where("workflow_state<>'deleted'").find_each do |user|
        if user.preferences[:enabled_theme] == 'high_contrast'
          user.enable_feature!(:high_contrast)
        end
      end
    end
  end
end
