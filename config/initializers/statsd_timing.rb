ActiveSupport::Notifications.subscribe(/process_action.action_controller/) do |*args|
  CanvasStatsd::RequestStat.new(*args).report
end
