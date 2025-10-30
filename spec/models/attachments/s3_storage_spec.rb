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
  let(:attachment) { attachment_model }

  describe "#sign_policy" do
    # example values from http://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-post-example.html
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

  describe "#open" do
    before { s3_storage! }

    context "when the attachment exists" do
      it "returns a tempfile" do
        result = attachment.open
        expect(result).to be_a(Tempfile)
      end

      it "downloads the file to the tempfile" do
        expect_any_instance_of(Aws::S3::Object).to receive(:get).once
        attachment.open
      end

      it "validates the hash if integrity_check is true" do
        expect(attachment).to receive(:validate_hash)
        attachment.open(integrity_check: true)
      end
    end

    context "when the S3 object is missing" do
      let(:s3_error) { Aws::S3::Errors::NoSuchKey.new(double("ctx"), "no such key") }

      before do
        attachment.update!(file_state: "available")
        allow_any_instance_of(Aws::S3::Object).to receive(:get).and_raise(s3_error)
        allow(Canvas::Errors).to receive(:capture_exception)
      end

      it "returns nil" do
        expect(attachment.open).to be_nil
      end

      it "sets in-memory file_state to broken" do
        attachment.open
        expect(attachment.file_state).to eq "broken"
      end

      it "persists file_state to broken" do
        attachment.open
        expect(attachment.reload.file_state).to eq "broken"
      end

      it "captures the exception" do
        attachment.open
        expect(Canvas::Errors).to have_received(:capture_exception).with(:attachment, s3_error, :warn)
      end

      it "does not perform integrity check even if requested" do
        expect(attachment).not_to receive(:validate_hash)
        attachment.open(integrity_check: true)
      end

      it "does not yield chunks when block given" do
        yielded = false
        attachment.open { |_chunk| yielded = true }
        expect(yielded).to be false
      end
    end

    context "when file_state is already broken" do
      before do
        attachment.update!(file_state: "broken")
      end

      it "returns nil immediately without calling S3 get" do
        expect_any_instance_of(Aws::S3::Object).not_to receive(:get)
        expect(attachment.open).to be_nil
      end
    end
  end
end
