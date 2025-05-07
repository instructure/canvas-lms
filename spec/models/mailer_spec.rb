# frozen_string_literal: true

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

describe Mailer do
  describe "create_message" do
    it "passes through to address" do
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail.to).to eq ["someemail@example.com"]
    end

    it "has defaults for critical fields" do
      message = message_model
      mail = Mailer.create_message(message)
      expect(mail.header["From"].to_s).to eq "#{HostUrl.outgoing_email_default_name} <#{HostUrl.outgoing_email_address}>"
      expect(mail.header["Reply-To"].to_s).to eq IncomingMail::ReplyToAddress.new(message).address
    end

    it "allows overrides for critical fields" do
      message = message_model
      message.from_name = "Handy Randy"
      message.reply_to_name = "Stan Theman"
      mail = Mailer.create_message(message)
      expect(mail.header["Reply-To"].to_s).to eq "Stan Theman <#{IncomingMail::ReplyToAddress.new(message).address}>"
      expect(mail.header["From"].to_s).to eq "Handy Randy <#{HostUrl.outgoing_email_address}>"
    end

    it "omits reply_to for sms" do
      message = message_model(path_type: "sms")
      message.from_name = "Handy Randy"
      message.reply_to_name = "Stan Theman"
      mail = Mailer.create_message(message)
      expect(mail.header["Reply-To"]).to be_nil
      expect(mail.header["From"].to_s).to eq "Handy Randy <#{HostUrl.outgoing_email_address}>"
    end

    it "truncates the message body if it exceeds the maximum text length" do
      message = message_model
      message.body = "a" * 300.kilobytes
      message.html_body = "a" * 300.kilobytes
      mail = Mailer.create_message(message)
      expect(mail.message.html_part.body.raw_source).to eq "message preview unavailable"
    end
  end

  describe "deliver_now" do
    it "calls deliver_now if notification_service is not configured" do
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail).to receive(:deliver_now)
      expect(Services::NotificationService).not_to receive(:process)
      Mailer.deliver(mail)
    end

    it "sends stat to stat service" do
      allow(InstStatsd::Statsd).to receive(:distributed_increment)
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail).to receive(:deliver_now)
      Mailer.deliver(mail)
      expect(InstStatsd::Statsd).to have_received(:distributed_increment).with(
        "message.deliver",
        { tags: { path_type: "mailer_emails", notification_name: "mailer_delivery" } }
      )
    end

    it "calls the notification service if configured" do
      Account.site_admin.enable_feature!(:notification_service)
      message = message_model(to: "someemail@example.com")
      mail = Mailer.create_message(message)
      expect(mail).not_to receive(:deliver_now)
      expect(Services::NotificationService).to receive(:process)
      Mailer.deliver(mail)
    end

    it "truncate display name if it exceeds the maximum email display name length" do
      message = message_model
      # Latin should have a 1 for 1 byte ratio
      message.from_name = "Maior pars mortalium, Pauline, de naturae malignitate conqueritur, quod in exiguum aeui gignimur, quod haec tam uelociter, tam rapide dati nobis temporis spatia decurrant, adeo ut exceptis admodum paucis ceteros in ipso uitae apparatu uita destituat. Nec huic publico, ut opinantur, malo turba tantum et imprudens uulgus ingemuit; clarorum quoque uirorum hic affectus querellas euocauit. "
      mail = Mailer.create_message(message)
      expect(mail.header["From"].to_s.bytesize).to be <= Mailer::MAX_EMAIL_DISPLAY_NAME_BYTE

      # non latin chars should have a 4 for 1 byte ratio
      message.from_name = "𓄿𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅀𓅁𓅂𓅃𓅄𓅅𓅆𓅇𓅈𓅉𓅊𓅋𓅌𓅍𓅎𓅏𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅠𓅡𓅢𓅣𓅤𓅥𓅦𓅧𓅨𓅩𓅪𓅫𓅬𓅭𓅮𓅯𓅰𓅱𓄿𓅲𓅳𓅴𓅵𓅶𓆐𓅷𓅸𓅹𓅺𓅻𓅼𓆀𓆁𓆂𓅽𓅾𓅿𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓄿𓄿𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅀𓅁𓅂𓅃𓅄𓅅𓅆𓅇𓅈𓅉𓅊𓅋𓅌𓅍𓅎𓅏𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅠𓅡𓅢𓅣𓅤𓅥𓅦𓅧𓅨𓅩𓅪𓅫𓅬𓅭𓅮𓅯𓅰𓅱𓄿𓅲𓅳𓅴𓅵𓅶𓆐𓅷𓅸𓅹𓅺𓅻𓅼𓆀𓆁𓆂𓅽𓅾𓅿𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓄿𓄿𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅀𓅁𓅂𓅃𓅄𓅅𓅆𓅇𓅈𓅉𓅊𓅋𓅌𓅍𓅎𓅏𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅠𓅡𓅢𓅣𓅤𓅥𓅦𓅧𓅨𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅩𓅪𓅫𓅬𓅭𓅮𓅯𓅰𓅱𓄿𓅲𓅳𓅴𓅵𓅶𓆐𓅷𓅸𓅹𓅺𓅻𓅼𓆀𓆁𓆂𓅽𓅾𓅿𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓃠𓄿"
      mail = Mailer.create_message(message)
      expect(mail.header["From"].to_s.bytesize).to be <= Mailer::MAX_EMAIL_DISPLAY_NAME_BYTE
    end
  end
end
