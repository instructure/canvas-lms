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


