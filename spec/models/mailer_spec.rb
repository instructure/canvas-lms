#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe Mailer do

  describe 'create_message' do
    it 'passes through to address' do
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail.to).to eq ["someemail@example.com"]
    end

    it 'has defaults for critical fields' do
      message = message_model()
      mail = Mailer.create_message(message)
      expect(mail.header['From'].to_s).to eq "#{HostUrl.outgoing_email_default_name} <#{HostUrl.outgoing_email_address}>"
      expect(mail.header['Reply-To'].to_s).to eq IncomingMail::ReplyToAddress.new(message).address
    end

    it 'allows overrides for critical fields' do
      message = message_model()
      message.from_name = "Handy Randy"
      message.reply_to_name = "Stan Theman"
      mail = Mailer.create_message(message)
      expect(mail.header['Reply-To'].to_s).to eq "Stan Theman <#{IncomingMail::ReplyToAddress.new(message).address}>"
      expect(mail.header['From'].to_s).to eq "Handy Randy <#{HostUrl.outgoing_email_address}>"
    end

    it 'omits reply_to for sms' do
      message = message_model(path_type: 'sms')
      message.from_name = "Handy Randy"
      message.reply_to_name = "Stan Theman"
      mail = Mailer.create_message(message)
      expect(mail.header['Reply-To']).to be_nil
      expect(mail.header['From'].to_s).to eq "Handy Randy <#{HostUrl.outgoing_email_address}>"
    end
  end

  describe 'deliver_now' do
    it 'calls deliver_now if notification_service is not configured' do
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail).to receive(:deliver_now)
      expect(Services::NotificationService).not_to receive(:process)
      Mailer.deliver(mail)
    end

    it 'sends stat to stat service' do
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail).to receive(:deliver_now)
      expect(InstStatsd::Statsd).to receive(:increment).with("message.deliver",
                                                             { short_stat: "message.deliver",
                                                               tags: { path_type: "mailer_emails", notification_name: 'mailer_delivery' } })
      Mailer.deliver(mail)
    end

    it 'calls the notification service if configured' do
      Account.site_admin.enable_feature!(:notification_service)
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail).not_to receive(:deliver_now)
      expect(Services::NotificationService).to receive(:process)
      Mailer.deliver(mail)
    end
  end
end
