# Initialize outgoing email configuration. See config/outgoing_mail.yml.example.

# This doesn't get required if we're not using smtp, and there's some
# references to SMTP exception classes in the code.
require 'net/smtp'

config = {
  :domain => "unknowndomain.example.com",
  :delivery_method => :smtp,
}.merge((Setting.from_config("outgoing_mail") || {}).symbolize_keys)

[:authentication, :delivery_method].each do |key|
  config[key] = config[key].to_sym if config.has_key?(key)
end

Rails.configuration.to_prepare do
  HostUrl.outgoing_email_address = config[:outgoing_address]
  HostUrl.outgoing_email_domain = config[:domain]
  HostUrl.outgoing_email_default_name = config[:default_name]

  IncomingMail::ReplyToAddress.address_pool = config[:reply_to_addresses] ||
    Array(HostUrl.outgoing_email_address)
  IncomingMailProcessor::MailboxAccount.default_outgoing_email = HostUrl.outgoing_email_address
end

# delivery_method can be :smtp, :sendmail or :test
ActionMailer::Base.delivery_method = config[:delivery_method]
ActionMailer::Base.perform_deliveries = config[:perform_deliveries] if config.has_key?(:perform_deliveries)

case config[:delivery_method]
when :smtp
  ActionMailer::Base.smtp_settings.merge!(config)
when :sendmail
  ActionMailer::Base.sendmail_settings.merge!(config)
end
