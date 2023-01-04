# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# Initialize outgoing email configuration. See config/outgoing_mail.yml.example.

# This doesn't get required if we're not using smtp, and there's some
# references to SMTP exception classes in the code.

config = {
  domain: "unknowndomain.example.com",
  delivery_method: :smtp,
}.merge((ConfigFile.load("outgoing_mail").dup || {}).symbolize_keys)

[:authentication, :delivery_method].each do |key|
  config[key] = config[key].to_sym if config.key?(key)
end

Rails.configuration.to_prepare do
  HostUrl.outgoing_email_address = config[:outgoing_address]
  HostUrl.outgoing_email_domain = config[:domain]
  HostUrl.outgoing_email_default_name = config[:default_name]

  IncomingMail::ReplyToAddress.address_pool = config[:reply_to_addresses] ||
                                              Array(HostUrl.outgoing_email_address)
  IncomingMailProcessor::MailboxAccount.default_outgoing_email = HostUrl.outgoing_email_address
  IncomingMailProcessor::MailboxAccount.reply_to_enabled = config[:reply_to_disabled].blank?
end

# delivery_method can be :smtp, :sendmail, :letter_opener, or :test
ActionMailer::Base.delivery_method = config[:delivery_method]

ActionMailer::Base.perform_deliveries = config[:perform_deliveries] if config.key?(:perform_deliveries)

case config[:delivery_method]
when :smtp
  ActionMailer::Base.smtp_settings.merge!(config)
when :sendmail
  ActionMailer::Base.sendmail_settings.merge!(config)
end
