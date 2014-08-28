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
  class ToolProxy < ActiveRecord::Base

    attr_accessible :shared_secret, :guid, :product_version, :lti_version, :product_family, :workflow_state, :raw_data, :context

    has_many :bindings, class_name: 'Lti::ToolProxyBinding'
    has_many :resources, class_name: 'Lti::ResourceHandler'
    validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']
    belongs_to :context, :polymorphic => true

    belongs_to :product_family, class_name: 'Lti::ProductFamily'
    has_one :tool_setting, :class_name => 'Lti::ToolSetting', as: :settable

    serialize :raw_data

    validates_presence_of :shared_secret, :guid, :product_version, :lti_version, :product_family_id, :workflow_state, :raw_data, :context
    validates_uniqueness_of :guid
    validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']

  end
end