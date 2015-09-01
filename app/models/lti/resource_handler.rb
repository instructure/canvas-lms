#
# Copyright (C) 2014 Instructure, Inc.
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

module Lti
  class ResourceHandler < ActiveRecord::Base

    attr_accessible :resource_type_code, :name, :description, :icon_info, :tool_proxy
    attr_readonly :created_at

    belongs_to :tool_proxy, class_name: 'Lti::ToolProxy'
    has_many :message_handlers, class_name: 'Lti::MessageHandler', :foreign_key => :resource_handler_id, dependent: :destroy
    has_many :placements, class_name: 'Lti::ResourcePlacement', through: :message_handlers

    serialize :icon_info

    validates_presence_of :resource_type_code, :name, :tool_proxy

  end
end