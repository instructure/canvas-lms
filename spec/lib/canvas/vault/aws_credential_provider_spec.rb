# frozen_string_literal: true

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

describe Canvas::Vault::AwsCredentialProvider do
  it "is a very slim wrapper around vault" do
    cred_path = "sts/testaccount/sts/some-vault-assumable-role"
    allow(Canvas::Vault).to receive(:read).with(cred_path).and_return({
                                                                        access_key: "AZ12345",
                                                                        secret_key: "super-sekret-asjdfblkadfbvlasdf",
                                                                        security_token: "asdfasdfasdfasdfasdfasdf"
                                                                      })
    creds = Canvas::Vault::AwsCredentialProvider.new(cred_path).credentials
    expect(creds.class).to eq(Aws::Credentials)
    expect(creds.access_key_id).to eq("AZ12345")
  end

  it "will actually throw an error on failure" do
    cred_path = "sts/testaccount/sts/some-vault-assumable-role"
    allow(Canvas::Vault).to receive(:read).with(cred_path).and_return(nil)
    expect do
      Canvas::Vault::AwsCredentialProvider.new(cred_path).credentials
    end.to raise_error(Canvas::Vault::VaultConfigError)
  end
end
