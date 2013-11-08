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
      end

      # e.g. the "render text: ..." in format.html{ render text: ... }
      def render(params)
        params[:text]
      end

      # e.g. format.html{ render text: ... }
      def html
        body = yield self
        @hasHTML = true
        @target.content_type 'multipart/alternative'
        @target.part content_type: 'text/html; charset=utf-8', body: body
      end

      # e.g. format.text{ render text: ... }
      def text
        body = yield self
        if @hasHTML
          @target.part content_type: 'text/plain; charset=utf-8', body: body
        else
          @target.body body
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
      yield Formatter.new(self)
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
        Mailer.deliver_message(@message)
      end
    end

    def self.message(m)
      Proxy.new(m)
    end
  end

  # define in rails3-style
  def message(m)
    # notifications have context, bounce replies don't.
    headers('Auto-Submitted' => m.context ? 'auto-generated' : 'auto-replied')

    params = {
      from: "#{m.from_name || HostUrl.outgoing_email_default_name} <" + HostUrl.outgoing_email_address + ">",
      reply_to: ReplyToAddress.new(m).address,
      to: m.to,
      subject: m.subject
    }

    params[:cc] = m.cc if m.cc
    params[:bcc] = m.bcc if m.bcc

    mail(params) do |format|
      format.html{ render text: m.html_body } if m.html_body
      format.text{ render text: m.body }
    end
  end
end
