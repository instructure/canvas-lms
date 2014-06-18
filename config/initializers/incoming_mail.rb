# Initialize incoming email configuration. See config/incoming_mail.yml.example.

config = ConfigFile.load("incoming_mail") || {}

Rails.configuration.to_prepare do
  IncomingMailProcessor::IncomingMessageProcessor.configure(config)
  IncomingMailProcessor::IncomingMessageProcessor.logger = Rails.logger
end
