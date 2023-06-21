# frozen_string_literal: true

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
    Lti::ToolProxy.active.joins(:product_family)
                  .where("raw_data like '%#{Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2}%'")
                  .group(:product_code, :vendor_code)
                  .select("array_agg(lti_tool_proxies.id) as tool_ids").each do |tools|
      endpoints = Lti::ToolProxy.where(id: tools.tool_ids).map(&:event_endpoint).uniq.compact
      endpoints.each do |endpoint|
        tools_with_endpoint = Lti::ToolProxy.where(id: tools.tool_ids)
                                            .where("raw_data like '%vnd.Canvas.SubmissionEvent%'")
                                            .where("raw_data like #{Lti::ToolProxy.connection.quote("%endpoint: #{endpoint}%")}")
        subscription_id = Lti::ToolProxy.where.not(subscription_id: nil).find_by(id: tools_with_endpoint)&.subscription_id
        subscription_id ||= Lti::PlagiarismSubscriptionsHelper.new(tools_with_endpoint.take).create_subscription
        Lti::ToolProxy.active.where(id: tools_with_endpoint, subscription_id: nil).update_all(subscription_id:)
      rescue
        next
      end
    end
  end

  def self.delete_subscriptions
    Lti::ToolProxy
      .where("raw_data like '%#{Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2}%'")
      .where.not(subscription_id: nil).active.find_each do |tool|
      Lti::PlagiarismSubscriptionsHelper.new(tool).destroy_subscription(tool.subscription_id)
      tool.update_columns(subscription_id: nil)
    end
  end

  def self.recreate_subscriptions
    Lti::ToolProxy.where("raw_data like '%#{Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2}%'")
                  .where.not(subscription_id: nil)
                  .group(:subscription_id)
                  .select("array_agg(lti_tool_proxies.id) as ids").each do |tools|
      example_tool = Lti::ToolProxy.find(tools.ids.min)
      old_subscription_id = example_tool.subscription_id
      Lti::ToolProxy.where(id: tools.ids).find_each do |tool|
        tool.update(subscription_id: Lti::PlagiarismSubscriptionsHelper.new(tool).create_subscription)
      end
      Lti::PlagiarismSubscriptionsHelper.new(example_tool).destroy_subscription(old_subscription_id)
    end
  end
end
