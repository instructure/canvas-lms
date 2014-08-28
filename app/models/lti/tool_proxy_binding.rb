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
  class ToolProxyBinding < ActiveRecord::Base

    attr_accessible :context, :tool_proxy

    belongs_to :tool_proxy, class_name: 'Lti::ToolProxy'
    validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']
    belongs_to :context, :polymorphic => true
    has_one :tool_setting, :class_name => 'Lti::ToolSetting', as: :settable

    validates_presence_of :tool_proxy, :context

    after_save :touch_context

  end
end