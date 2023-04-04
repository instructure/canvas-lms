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
#

require "mail"

class Mailer < ActionMailer::Base
  attr_reader :email

  # define in rails3-style
  def create_message(m)
    # notifications have context, bounce replies don't.
    headers("Auto-Submitted" => m.context ? "auto-generated" : "auto-replied")

    params = {
      from: from_mailbox(m),
      to: m.to,
      subject: m.subject
    }

    reply_to = reply_to_mailbox(m)
    params[:reply_to] = reply_to if reply_to

    mail(params) do |format|
      [:body, :html_body].each do |attr|
        if m.send(attr)
          body = (m.send(attr).bytesize > Message.maximum_text_length) ? Message.unavailable_message : m.send(attr)
          (attr == :body) ? format.text { render plain: body } : format.html { render plain: body }
        end
      end
    end
  end

  # if you can't go through Message.deliver, this is a fallback that respects
  # the notification service.
  def self.deliver(mail_obj)
    InstStatsd::Statsd.increment("message.deliver",
                                 short_stat: "message.deliver",
                                 tags: { path_type: "mailer_emails", notification_name: "mailer_delivery" })
    if Account.site_admin.feature_enabled?(:notification_service)
      Services::NotificationService.process(
        "direct:#{SecureRandom.hex(10)}",
        mail_obj.to_s,
        "email",
        mail_obj.to.first
      )
    else
      mail_obj.deliver_now
    end
  end

  private

  def quoted_address(display_name, address)
    addr = Mail::Address.new(address)
    addr.display_name = display_name
    addr.format
  end

  def from_mailbox(message)
    quoted_address(message.from_name || HostUrl.outgoing_email_default_name, HostUrl.outgoing_email_address)
  end

  def reply_to_mailbox(message)
    address = IncomingMail::ReplyToAddress.new(message).address
    return address unless message.reply_to_name.present?
    return nil unless address.present?

    quoted_address(message.reply_to_name, address)
  end
end
