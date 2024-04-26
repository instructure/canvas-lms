# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Canvas
  class AwsCredentialProvider
    def initialize(credential_name, vault_path = nil)
      @credential_name = credential_name
      unless vault_path.nil?
        @vault_provider = Canvas::Vault::AwsCredentialProvider.new(vault_path)
      end
    end

    def set?
      return @vault_provider.credentials.set? unless @vault_provider.nil?

      cred_hash = Rails.application.credentials.send(@credential_name)
      return false if cred_hash.nil?

      cred_hash.key?(:aws_access_key_id) && cred_hash.key?(:aws_secret_access_key)
    end

    def credentials
      return @vault_provider.credentials unless @vault_provider.nil?

      cred_hash = Rails.application.credentials.send(@credential_name)
      ::Aws::Credentials.new(cred_hash[:aws_access_key_id], cred_hash[:aws_secret_access_key], cred_hash[:aws_security_token])
    end
  end
end
