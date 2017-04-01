class AssignmentConfigurationToolLookup < ActiveRecord::Base
  belongs_to :tool, polymorphic: true
  belongs_to :assignment
  after_create :create_subscription

  # Do not add before_destroy or after_destroy, these records are "delete_all"ed

  private

  def create_subscription
    return unless tool.instance_of? Lti::MessageHandler
    tool_proxy = tool.resource_handler.tool_proxy
    subscription_helper = Lti::AssignmentSubscriptionsHelper.new(assignment, tool_proxy)
    self.update_attributes(subscription_id: subscription_helper.create_subscription)
  end
end


