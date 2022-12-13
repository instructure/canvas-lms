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
#

describe "security" do
  it "verify_hmac_sha1" do
    msg = "sign me"
    hmac = CanvasSecurity.hmac_sha1(msg)

    expect(CanvasSecurity.verify_hmac_sha1(hmac, msg)).to be_truthy
    expect(CanvasSecurity.verify_hmac_sha1(hmac, msg + "haha")).not_to be_truthy
  end

  describe "#url_key_encrypt_data" do
    it "does not include url unsafe keys" do
      data1 = 'abcde12345!@#$%^&*()~`/\\|+=-_🙂Ю'
      data2 = "https://www.google.com/maps"

      encrypted_data1 = CanvasSecurity.url_key_encrypt_data(data1)
      encrypted_data2 = CanvasSecurity.url_key_encrypt_data(data2)
      expect(URI::DEFAULT_PARSER.escape(encrypted_data1)).to eq encrypted_data1
      expect(URI::DEFAULT_PARSER.escape(encrypted_data2)).to eq encrypted_data2
    end

    it "decrypts to the same data you sent in" do
      data1 = 'abcde12345!@#$%^&*()~`/\\|+=-_🙂Ю'
      data2 = "https://www.google.com/maps"

      encrypted_data1 = CanvasSecurity.url_key_encrypt_data(data1)
      encrypted_data2 = CanvasSecurity.url_key_encrypt_data(data2)
      expect(data1).to eq 'abcde12345!@#$%^&*()~`/\\|+=-_🙂Ю'
      expect(data2).to eq "https://www.google.com/maps"
      expect(encrypted_data1).to_not eq data1
      expect(encrypted_data2).to_not eq data2
      expect(encrypted_data1).to match(/[\w-]+~[\w-]+~[\w-]+/)
      expect(encrypted_data2).to match(/[\w-]+~[\w-]+~[\w-]+/)
      expect(CanvasSecurity.url_key_decrypt_data(encrypted_data1)).to eq data1
      expect(CanvasSecurity.url_key_decrypt_data(encrypted_data2)).to eq data2
    end
  end

  describe "#url_key_decrypt_data" do
    it "is able to decrypt" do
      allow(CanvasSecurity).to receive(:encryption_key).and_return("facdd3a131ddd8988b14f6e4e01039c93cfa0160")
      encrypted_data1 = "ywOHQZAfnsU351MRazIS2TZ5BM8IgbiuOYxrvecBcELXLdMvvW4CeAQ~qbbJvWGrYf9GwNBB~J1hDYUhq85eHr53KgtLIpg"
      encrypted_data2 = "NmJk7iV0hTz2ztUb50yuX3tCAcNbMKKQELiIMuu4SyLV~aGt-Ed5h1HRsF8n0~Id488slCbupK0V9n-6DpMg"
      expect(CanvasSecurity.url_key_decrypt_data(encrypted_data1)).to eq 'abcde12345!@#$%^&*()~`/\\|+=-_🙂Ю'
      expect(CanvasSecurity.url_key_decrypt_data(encrypted_data2)).to eq "https://www.google.com/maps"
    end
  end
end
