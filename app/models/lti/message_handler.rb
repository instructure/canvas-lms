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

    attr_accessible :message_type, :launch_path, :capabilities, :parameters, :resource

    belongs_to :resource, class_name: "Lti::ResourceHandler", :foreign_key => :resource_handler_id

    serialize :capabilities
    serialize :parameters

    validates_presence_of :message_type, :resource, :launch_path

  end
end