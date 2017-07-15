#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AssignmentConfigurationToolLookup < ActiveRecord::Base
  belongs_to :tool, polymorphic: true
  belongs_to :assignment
  after_create :create_subscription

  # Do not add before_destroy or after_destroy, these records are "delete_all"ed

  def destroy_subscription
    return unless tool.instance_of? Lti::MessageHandler
    tool_proxy = tool.resource_handler.tool_proxy
    Lti::AssignmentSubscriptionsHelper.new(tool_proxy).destroy_subscription(subscription_id)
  end

  private

  def create_subscription
    return unless tool.instance_of? Lti::MessageHandler
    tool_proxy = tool.resource_handler.tool_proxy
    subscription_helper = Lti::AssignmentSubscriptionsHelper.new(tool_proxy, assignment)
    self.update_attributes(subscription_id: subscription_helper.create_subscription)
  end
end
