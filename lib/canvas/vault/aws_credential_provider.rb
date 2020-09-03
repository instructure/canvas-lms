#
# Copyright (C) 2020 - present Instructure, Inc.
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
module Canvas::Vault
  class AwsCredentialProvider
    include ::Aws::CredentialProvider

    def initialize(credential_path)
      @_path = credential_path
    end

    # it looks like we're not caching anything or renewing anything here
    # which might seem concerning, but internally the vault read
    # takes care of caching the result and trying to refresh it after half the lease
    # period has passed.  It's safe to read every time, mostly it's just fetching
    # out of the local redis cache.
    def credentials
      cred_hash = ::Canvas::Vault.read(@_path)
      ::Aws::Credentials.new(cred_hash[:access_key], cred_hash[:secret_key], cred_hash[:security_token])
    end
  end
end