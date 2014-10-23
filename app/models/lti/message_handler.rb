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
  class MessageHandler< ActiveRecord::Base
    attr_accessible :message_type, :launch_path, :capabilities, :parameters, :resource_handler, :links
    attr_readonly :created_at

    belongs_to :resource_handler, class_name: "Lti::ResourceHandler", :foreign_key => :resource_handler_id
    has_many :links, :class_name => 'Lti::LtiLink'

    serialize :capabilities
    serialize :parameters

    validates_presence_of :message_type, :resource_handler, :launch_path

    scope :by_message_types, lambda { |*message_types| where('lti_message_handlers.message_type IN (?)', message_types) }

    scope :for_context, lambda { |context|
      tool_proxies = ToolProxy.find_active_proxies_for_context(context)
      joins(:resource_handler).where('lti_resource_handlers.tool_proxy_id' => tool_proxies)
    }

  end
end