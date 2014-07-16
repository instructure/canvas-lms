#
# Copyright (C) 2011 Instructure, Inc.
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

class Mailer < ActionMailer::Base

  attr_reader :email

  if CANVAS_RAILS2
    # yielded to the block given to #mail as called from #message in order to
    # perform the appropriate rails2-style ActionMailer actions on @target.
    class Formatter
      def initialize(target)
        @target = target
        @parts = []
      end

      # e.g. the "render text: ..." in format.html{ render text: ... }
      def render(params)
        params[:text]
      end

      # e.g. format.text{ render text: ... }
      def text(&block)
        @parts << {
          content_type: 'text/plain; charset=utf-8',
          body: instance_eval(&block)
        }
      end

      # e.g. format.html{ render text: ... }
      def html(&block)
        @parts << {
          content_type: 'text/html; charset=utf-8',
          body: instance_eval(&block)
        }
      end

      def commit
        if @parts.size > 1
          @target.content_type 'multipart/alternative'
          @parts.each{ |part| @target.part part }
        elsif @parts.size == 1
          part = @parts.first
          @target.content_type part[:content_type]
          @target.body part[:body]
        end
      end
    end

    # now define #mail -- as called from #message -- to perform the appropriate
    # rails2-style ActionMailer actions
    def mail(params)
      recipients params[:to]
      bcc params[:bcc] if params[:bcc]
      cc params[:cc] if params[:cc]
      from params[:from]
      reply_to params[:reply_to]
      subject params[:subject]
      formatter = Formatter.new(self)
      yield formatter
      formatter.commit
      self
    end

    # finally, define a proxy so that the rails3-style
    # Mailer.message(m).deliver syntax works to invoke deliver_message(m) as
    # expected by the rails2-implementation of ActionMailer
    class Proxy
      def initialize(message)
        @message = message
      end

      def deliver
        Mailer.deliver_create_message(@message)
      end
    end

    def self.create_message(m)
      Proxy.new(m)
    end
  end

  # define in rails3-style
  def create_message(m)
    # notifications have context, bounce replies don't.
    headers('Auto-Submitted' => m.context ? 'auto-generated' : 'auto-replied')

    params = {
      from: from_mailbox(m),
      reply_to: reply_to_mailbox(m),
      to: m.to,
      subject: m.subject
    }

    params[:cc] = m.cc if m.cc
    params[:bcc] = m.bcc if m.bcc

    mail(params) do |format|
      format.text{ render text: m.body }
      format.html{ render text: m.html_body } if m.html_body
    end
  end

  private
  def from_mailbox(message)
    "#{message.from_name || HostUrl.outgoing_email_default_name} <" + HostUrl.outgoing_email_address + ">"
  end

  def reply_to_mailbox(message)
    address = IncomingMail::ReplyToAddress.new(message).address
    return address unless message.reply_to_name.present?
    "#{message.reply_to_name} <#{address}>"
  end
end
