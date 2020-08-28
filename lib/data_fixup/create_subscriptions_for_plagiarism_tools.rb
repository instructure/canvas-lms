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

module DataFixup::CreateSubscriptionsForPlagiarismTools
  def self.create_subscriptions
    Lti::ToolProxy.active.joins(:product_family).
      where("raw_data like '%#{Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2}%'").
      group(:product_code, :vendor_code).
      select("array_agg(lti_tool_proxies.id) as tool_ids").each do |tools|
        subscription_id = Lti::ToolProxy.where(id: tools.tool_ids).where.not(subscription_id: nil).take&.subscription_id
        subscription_id ||= Lti::PlagiarismSubscriptionsHelper.new(Lti::ToolProxy.find_by(id: tools.tool_ids)).create_subscription
        Lti::ToolProxy.active.where(id: tools.tool_ids, subscription_id: nil).update_all(subscription_id: subscription_id)
    end
  end

  def self.delete_subscriptions
    Lti::ToolProxy.
      where("raw_data like '%#{Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2}%'").
      where.not(subscription_id: nil).active.find_each do |tool|
        Lti::PlagiarismSubscriptionsHelper.new(tool).destroy_subscription(tool.subscription_id)
        tool.update_columns(subscription_id: nil)
    end
  end
end
