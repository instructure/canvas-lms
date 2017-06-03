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

module DataFixup::AddLtiMessageHandlerIdToLtiResourcePlacements
  def self.run
    scope = Lti::ResourceHandler.where("EXISTS (SELECT 1 FROM #{Lti::ResourcePlacement.quoted_table_name} WHERE resource_handler_id=lti_resource_handlers.id AND message_handler_id IS NULL)")
    while scope.exists?
      scope.find_each do |resource_handler|
        message_handler_id = resource_handler.message_handlers.
            where(message_type: 'basic-lti-launch-request').
            pluck(:id).first
        Lti::ResourcePlacement.
            where(resource_handler_id: resource_handler, message_handler_id: nil).
            update_all(message_handler_id: message_handler_id)
      end
    end
  end
end