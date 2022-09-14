# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

module DataFixup::Lti::RemoveUse13FromToolSettings
  def self.run
    # limit by developer_key_id first since that has an index and *should* produce the same results
    ContextExternalTool.where.not(developer_key_id: nil).where("settings LIKE ?", "%use_1_3%").find_each do |tool|
      # account for both Hash and HashWithIndifferentAccess
      tool.settings.delete :use_1_3
      tool.settings.delete "use_1_3"

      tool.save!
    end
  end
end
