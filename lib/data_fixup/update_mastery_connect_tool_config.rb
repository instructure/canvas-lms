#
# Copyright (C) 2020 - present Instructure, Inc.
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

module DataFixup::UpdateMasteryConnectToolConfig
  def self.run
    ContextExternalTool.active.where(domain: 'app.masteryconnect.com').find_each do |cet|
      next if cet.settings['submission_type_selection']
      cet.settings['submission_type_selection'] = {
        "text" => "Link Assessment",
        "url" => "https://app.masteryconnect.com/lti/v1.1/launch/classrooms",
        "message_type" => "ContentItemSelectionRequest",
        "selection_width" => 720,
        "selection_height" => 700
      }
      cet.save!
    end
  end
end
