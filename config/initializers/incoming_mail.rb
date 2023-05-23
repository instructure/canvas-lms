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

# Initialize incoming email configuration. See config/incoming_mail.yml.example.

config = ConfigFile.load("incoming_mail").deep_dup || {}

Rails.configuration.to_prepare do
  if config.key?("sqs")
    config["sqs"]["credentials"] = Canvas::AwsCredentialProvider.new("incoming_mail_creds", config["sqs"]["vault_credential_path"])
  end

  IncomingMailProcessor::IncomingMessageProcessor.configure(config)
  IncomingMailProcessor::IncomingMessageProcessor.logger = Rails.logger
end
