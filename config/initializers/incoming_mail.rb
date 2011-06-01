# Initialize incoming email configuration. See config/incoming_mail.yml.example.

config = Setting.from_config("incoming_mail") || {}

Rails.configuration.to_prepare do
  config.each do |key, value|
    value = value.symbolize_keys if value.respond_to? :symbolize_keys
    Mailman.config.send(key + '=', value)
  end
  # yes, this is lame, but setting this to real nil makes mailman assume '.',
  # which then reloads the rails configuration (and gets an error because we
  # try to remove a method that's already there
  Mailman.config.rails_root = 'nil'
  Mailman.config.logger = Rails.logger
end
