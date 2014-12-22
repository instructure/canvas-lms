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

    has_many :bindings, class_name: 'Lti::ToolProxyBinding', dependent: :destroy
    has_many :resources, class_name: 'Lti::ResourceHandler', dependent: :destroy
    has_many :tool_settings, class_name: 'Lti::ToolSetting', dependent: :destroy
    validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course', 'Account']
    belongs_to :context, :polymorphic => true

    belongs_to :product_family, class_name: 'Lti::ProductFamily'

    serialize :raw_data

    validates_presence_of :shared_secret, :guid, :product_version, :lti_version, :product_family_id, :workflow_state, :raw_data, :context
    validates_uniqueness_of :guid
    validates_inclusion_of :workflow_state, in: ['active', 'deleted', 'disabled']

    def self.find_active_proxies_for_context(context)
      account_ids = context.account_chain.map { |a| a.id }

      account_sql_string = account_ids.each_with_index.map { |x, i| "('Account',#{x},#{i})" }.unshift("('#{context.class.name}',#{context.id},#{0})").join(',')

      subquery = ToolProxyBinding.select('DISTINCT ON (lti_tool_proxies.id) lti_tool_proxy_bindings.*').joins(:tool_proxy).where('lti_tool_proxies.workflow_state = ?', 'active').
        joins("INNER JOIN ( VALUES #{account_sql_string}) as x(context_type, context_id, ordering) ON lti_tool_proxy_bindings.context_type = x.context_type AND lti_tool_proxy_bindings.context_id = x.context_id").
        where('(lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id = ?) OR (lti_tool_proxy_bindings.context_type = ? AND lti_tool_proxy_bindings.context_id IN (?))', context.class.name, context.id, 'Account', account_ids).
        order('lti_tool_proxies.id, x.ordering').to_sql
      ToolProxy.joins("JOIN (#{subquery}) bindings on lti_tool_proxies.id = bindings.tool_proxy_id").where('bindings.enabled = true')
    end

  end
end