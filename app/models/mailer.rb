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

  def message(m)
    headers({
      # notifications have context, bounce replies don't.
      'Auto-Submitted' => m.context ? 'auto-generated' : 'auto-replied'
      })
    recipients m.to
    bcc m.bcc if m.bcc
    cc m.cc if m.cc
    from ("#{m.from_name || HostUrl.outgoing_email_default_name} <" + HostUrl.outgoing_email_address + ">")
    reply_to ReplyToAddress.new(m).address
    subject m.subject
    if m.html_body
      content_type 'multipart/alternative'

      part :content_type => 'text/plain; charset=utf-8', :body => m.body
      part :content_type => 'text/html; charset=utf-8',  :body => m.html_body
    else
      body m.body
    end
  end
end
