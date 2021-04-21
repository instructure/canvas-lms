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

require "html_text_helper"
require "mail"
require "utf8_cleaner"
require "inst_statsd"

module IncomingMailProcessor
  require "incoming_mail_processor/pop3_mailbox"
  require "incoming_mail_processor/configurable_timeout"
  require "incoming_mail_processor/deprecated_settings"
  require "incoming_mail_processor/directory_mailbox"
  require "incoming_mail_processor/imap_mailbox"
  require "incoming_mail_processor/sqs_mailbox"
  require "incoming_mail_processor/incoming_message_processor"
  require "incoming_mail_processor/mailbox_account"
  require "incoming_mail_processor/settings"
  require "incoming_mail_processor/instrumentation"
end
