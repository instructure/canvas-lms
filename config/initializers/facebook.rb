Facebook::Connection.config = Proc.new do
  res = Canvas::Plugin.find(:facebook).try(:settings)
  res && res['app_id'] ? res : nil
end

Facebook::Connection.logger = Rails.logger