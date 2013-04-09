# Initialize incoming email configuration. See config/incoming_mail.yml.example.

config = Setting.from_config("incoming_mail") || {}

Rails.configuration.to_prepare do
  IncomingMail::IncomingMessageProcessor.configure(config)
end
