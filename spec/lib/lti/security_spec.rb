# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require "simple_oauth"

describe Lti::Security do
  describe ".signed_post_params" do
    let(:params) { { custom_a: 1, custom_b: 2 } }
    let(:consumer_key) { "test" }
    let(:launch_url) { "https://test.example/launch" }
    let(:consumer_secret) { "shh" }

    context "disable_lti_post_only" do
      it "generates a correct signature" do
        signed_params = Lti::Security.signed_post_params(params, launch_url, consumer_key, consumer_secret, true)
        nonce = signed_params["oauth_nonce"]
        timestamp = signed_params["oauth_timestamp"]

        header = SimpleOAuth::Header.new(
          :post,
          launch_url,
          params,
          consumer_key:,
          consumer_secret:,
          nonce:,
          timestamp:
        )
        expect(header.valid?(signature: signed_params["oauth_signature"])).to be true
      end

      it "doesn't copy query params" do
        signed_params = Lti::Security.signed_post_params(params, launch_url, consumer_key, consumer_secret, true)
        expect(signed_params).not_to have_key("test")
      end

      it "logs the oauth base string" do
        allow(Lti::Logging).to receive(:lti_1_launch_generated)

        url = "http://test.example:3000/launch"
        signed_params = Lti::Security.signed_post_params(params, url, consumer_key, consumer_secret, true)

        expect(Lti::Logging).to have_received(:lti_1_launch_generated).with(%W[
          POST&http%3A%2F%2Ftest.example%3A3000%2Flaunch&custom_a%3D1%26custom_b%3D2%26
          oauth_consumer_key%3Dtest%26
          oauth_nonce%3D#{signed_params["oauth_nonce"]}%26
          oauth_signature_method%3DHMAC-SHA1%26
          oauth_timestamp%3D#{signed_params["oauth_timestamp"]}%26
          oauth_version%3D1.0
        ].join)
      end

      it "converts newlines to CRLFs in the base string" do
        expect(Lti::Logging).to receive(:lti_1_launch_generated) do |line|
          expect(line).to match(/abc%250D%250Axyz/i)
        end
        Lti::Security.signed_post_params(
          params.merge(custom_b: "abc\nxyz"),
          "http://example.com/",
          consumer_key,
          consumer_secret,
          true
        )
      end
    end

    context "#decoded_lti_assignment_id" do
      it "returns nil if secure params are invalid" do
        expect(Lti::Security.decoded_lti_assignment_id("banana")).to be_nil
      end

      it "returns the lti assignment id if secure params are valid" do
        assignment_id = 12
        body = { lti_assignment_id: assignment_id }
        secure_params = Canvas::Security.create_jwt(body).to_s
        expect(Lti::Security.decoded_lti_assignment_id(secure_params)).to eq assignment_id
      end
    end

    context "#decoded_lti_assignment_description" do
      it "returns nil if secure params are invalid" do
        expect(Lti::Security.decoded_lti_assignment_description("banana")).to be_nil
      end

      it "returns the lti assignment description if secure params are valid" do
        assignment_id = 12
        body = { lti_assignment_description: assignment_id }
        secure_params = Canvas::Security.create_jwt(body).to_s
        expect(Lti::Security.decoded_lti_assignment_description(secure_params)).to eq assignment_id
      end
    end

    context ".check_and_store_nonce" do
      it "rejects a used nonce" do
        enable_cache do
          cache_key = "abcdefghijklmnopqrstuvwxyz"
          timestamp = 1.minute.ago
          expiration = 5.minutes
          params = [cache_key, timestamp, expiration]
          expect(Lti::Security.check_and_store_nonce(*params)).to be true
          expect(Lti::Security.check_and_store_nonce(*params)).to be false
        end
      end

      it "rejects a nonce if the timestamp exceeds the expiration" do
        cache_key = "abcdefghijklmnopqrstuvwxyz"
        expiration = 5.minutes
        timestamp = (expiration + 1.minute).ago.to_i
        expect(Lti::Security.check_and_store_nonce(cache_key, timestamp, expiration)).to be false
      end

      it "rejects a nonce more than 1 minute in the future" do
        cache_key = "abcdefghijklmnopqrstuvwxyz"
        expiration = 5.minutes
        timestamp = 61.seconds.from_now
        expect(Lti::Security.check_and_store_nonce(cache_key, timestamp, expiration)).to be false
      end

      it "accepts a nonce less than 1 minute in the future" do
        cache_key = "abcdefghijklmnopqrstuvwxyz"
        expiration = 5.minutes
        timestamp = 59.seconds.from_now
        expect(Lti::Security.check_and_store_nonce(cache_key, timestamp, expiration)).to be true
      end
    end

    it "generates a correct signature" do
      signed_params = Lti::Security.signed_post_params(params, launch_url, consumer_key, consumer_secret)

      nonce = signed_params["oauth_nonce"]
      timestamp = signed_params["oauth_timestamp"]

      header = SimpleOAuth::Header.new(
        :post,
        launch_url,
        params,
        consumer_key:,
        consumer_secret:,
        nonce:,
        timestamp:
      )
      expect(header.valid?(signature: signed_params["oauth_signature"])).to be true
    end

    it "handles whitespace in URLs" do
      url_with_whitespace = "http://www.test.com "
      signed_params = Lti::Security.signed_post_params(params, url_with_whitespace, consumer_key, consumer_secret)

      nonce = signed_params["oauth_nonce"]
      timestamp = signed_params["oauth_timestamp"]

      header = SimpleOAuth::Header.new(
        :post,
        url_with_whitespace.strip,
        params,
        consumer_key:,
        consumer_secret:,
        nonce:,
        timestamp:
      )
      expect(header.valid?(signature: signed_params["oauth_signature"])).to be true
    end

    it "generates the signature for urls with query params in an incorrect way that we are aware of and saddened by" do
      # in this set of conditions the old code moves the query params to the body, uses the url minus the query params
      # for the base string, and then launches to the full url..... :-(
      url = launch_url + "?test=foo"
      params_copy = params.dup
      signed_params = Lti::Security.signed_post_params(params_copy, url, consumer_key, consumer_secret)

      nonce = signed_params["oauth_nonce"]
      timestamp = signed_params["oauth_timestamp"]

      header = SimpleOAuth::Header.new(
        :post,
        launch_url, # Note that we are using a different url to generate a signature than before :-(
        params.merge(test: "foo"),
        consumer_key:,
        consumer_secret:,
        nonce:,
        timestamp:
      )
      expect(header.valid?(signature: signed_params["oauth_signature"])).to be true
    end

    it "generates the signature correctly for a non standard port" do
      url = "http://test.example:3000/launch"

      signed_params = Lti::Security.signed_post_params(params, url, consumer_key, consumer_secret)
      nonce = signed_params["oauth_nonce"]
      timestamp = signed_params["oauth_timestamp"]

      header = SimpleOAuth::Header.new(
        :post,
        url,
        params,
        consumer_key:,
        consumer_secret:,
        nonce:,
        timestamp:
      )
      expect(header.valid?(signature: signed_params["oauth_signature"])).to be true
    end

    it "logs the oauth base string" do
      allow(Lti::Logging).to receive(:lti_1_launch_generated)

      url = "http://test.example:3000/launch"
      signed_params = Lti::Security.signed_post_params(params, url, consumer_key, consumer_secret)
      nonce = signed_params["oauth_nonce"]
      timestamp = signed_params["oauth_timestamp"]

      expect(Lti::Logging).to have_received(:lti_1_launch_generated).with(%W[
        POST&http%3A%2F%2Ftest.example%3A3000%2Flaunch&custom_a%3D1%26custom_b%3D2%26
        oauth_consumer_key%3Dtest%26oauth_consumer_key%3Dtest%26
        oauth_nonce%3D#{nonce}%26oauth_nonce%3D#{nonce}%26
        oauth_signature_method%3DHMAC-SHA1%26oauth_signature_method%3DHMAC-SHA1%26
        oauth_timestamp%3D#{timestamp}%26oauth_timestamp%3D#{timestamp}%26
        oauth_version%3D1.0%26oauth_version%3D1.0
      ].join)
    end

    it "converts newlines to CRLFs in the base string" do
      expect(Lti::Logging).to receive(:lti_1_launch_generated) do |line|
        expect(line).to match(/abc%250D%250Axyz/i)
      end
      Lti::Security.signed_post_params(
        params.merge(custom_b: "abc\nxyz"),
        "http://example.com/",
        consumer_key,
        consumer_secret
      )
    end
  end
end
