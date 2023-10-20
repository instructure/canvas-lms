# frozen_string_literal: true

# Copyright (C) 2017 - present Instructure, Inc.
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

describe Attachments::S3Storage do
  describe "#sign_policy" do
    # example values from http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
    let(:attachment) { attachment_model }
    let(:access_key_id) { "AKIAIOSFODNN7EXAMPLE" }
    let(:secret_access_key) { "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" }
    let(:datetime) { "20151229T000000Z" }
    let(:string_to_sign) { <<~BASE64.delete("\n") }
      eyAiZXhwaXJhdGlvbiI6ICIyMDE1LTEyLTMwVDEyOjAwOjAwLjAwMFoiLA0KICAiY29uZ
      Gl0aW9ucyI6IFsNCiAgICB7ImJ1Y2tldCI6ICJzaWd2NGV4YW1wbGVidWNrZXQifSwNCi
      AgICBbInN0YXJ0cy13aXRoIiwgIiRrZXkiLCAidXNlci91c2VyMS8iXSwNCiAgICB7ImF
      jbCI6ICJwdWJsaWMtcmVhZCJ9LA0KICAgIHsic3VjY2Vzc19hY3Rpb25fcmVkaXJlY3Qi
      OiAiaHR0cDovL3NpZ3Y0ZXhhbXBsZWJ1Y2tldC5zMy5hbWF6b25hd3MuY29tL3N1Y2Nlc
      3NmdWxfdXBsb2FkLmh0bWwifSwNCiAgICBbInN0YXJ0cy13aXRoIiwgIiRDb250ZW50LV
      R5cGUiLCAiaW1hZ2UvIl0sDQogICAgeyJ4LWFtei1tZXRhLXV1aWQiOiAiMTQzNjUxMjM
      2NTEyNzQifSwNCiAgICB7IngtYW16LXNlcnZlci1zaWRlLWVuY3J5cHRpb24iOiAiQUVT
      MjU2In0sDQogICAgWyJzdGFydHMtd2l0aCIsICIkeC1hbXotbWV0YS10YWciLCAiIl0sD
      QoNCiAgICB7IngtYW16LWNyZWRlbnRpYWwiOiAiQUtJQUlPU0ZPRE5ON0VYQU1QTEUvMj
      AxNTEyMjkvdXMtZWFzdC0xL3MzL2F3czRfcmVxdWVzdCJ9LA0KICAgIHsieC1hbXotYWx
      nb3JpdGhtIjogIkFXUzQtSE1BQy1TSEEyNTYifSwNCiAgICB7IngtYW16LWRhdGUiOiAi
      MjAxNTEyMjlUMDAwMDAwWiIgfQ0KICBdDQp9
    BASE64
    let(:signature) { "8afdbf4008c03f22c2cd3cdb72e4afbb1f6a588f3255ac628749a66d7f09699e" }
    let(:bucket) do
      config = double("config", {
                        secret_access_key:,
                        region: "us-east-1",
                        credentials: double(credentials: double(access_key_id:, secret_access_key:)),
                      })
      client = double("client", config:)
      double("bucket", client:)
    end

    it "follows the v4 signing example from AWS" do
      expect(attachment).to receive(:bucket).and_return(bucket)
      store = Attachments::S3Storage.new(attachment)
      _sig_key, sig_val = store.sign_policy(string_to_sign, datetime)
      expect(sig_val).to eq signature
    end
  end
end
