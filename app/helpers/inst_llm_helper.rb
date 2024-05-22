# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "inst_llm"

module InstLLMHelper
  def self.client(model_id)
    @clients ||= {}
    # For local dev, assume that we are using creds from inseng (us-west-2)
    # Will load creds from vault (prod) or rails credential store (local / oss).
    # Credentials stored in rails credential store in the `bedrock_creds` key
    # with `aws_access_key_id` and `aws_secret_access_key` keys
    settings = YAML.safe_load(DynamicSettings.find(tree: :private)["bedrock.yml"] || "{}")
    credentials = Canvas::AwsCredentialProvider.new("bedrock_creds", settings["vault_credential_path"]).credentials

    @clients[model_id] ||= InstLLM::Client.new(
      model_id,
      region: settings["bedrock_region"] || "us-west-2",
      access_key_id: credentials.access_key_id,
      secret_access_key: credentials.secret_access_key,
      session_token: credentials.session_token
    )
  end
end
