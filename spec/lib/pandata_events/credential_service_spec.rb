# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe PandataEvents::CredentialService do
  let(:credentials) do
    {
      canvas_key: "CANVAS",
      canvas_secret: "secret",
      other_key: "OTHER",
      other_secret: "other_secret",
    }.with_indifferent_access
  end

  before do
    allow(PandataEvents).to receive(:credentials).and_return(credentials)
  end

  describe ".new" do
    subject { described_class.new(app_key:, prefix:, valid_prefixes:) }

    let(:app_key) { nil }
    let(:prefix) { nil }
    let(:valid_prefixes) { nil }

    context "when app_key and prefix aren't provided" do
      it "errors" do
        expect { subject }.to raise_error(PandataEvents::Errors::InvalidAppKey)
      end
    end

    context "when app_key and prefix are both provided" do
      let(:app_key) { "CANVAS" }
      let(:prefix) { :canvas }

      it "errors" do
        expect { subject }.to raise_error(PandataEvents::Errors::InvalidAppKey)
      end
    end

    context "when app_key isn't found in configs" do
      let(:app_key) { "not_a_real_key" }

      it "errors" do
        expect { subject }.to raise_error(PandataEvents::Errors::InvalidAppKey)
      end
    end

    context "with app_key and valid_prefixes" do
      let(:app_key) { "OTHER" }
      let(:valid_prefixes) { ["canvas"] }

      it "errors if the app_key isn't found in a valid prefix" do
        expect { subject }.to raise_error(PandataEvents::Errors::InvalidAppKey)
      end
    end

    context "with prefix and valid_prefixes" do
      let(:prefix) { :other }
      let(:valid_prefixes) { ["canvas"] }

      it "errors if prefix isn't found" do
        expect { subject }.to raise_error(PandataEvents::Errors::InvalidAppKey)
      end
    end

    context "when properly configured with app_key" do
      let(:app_key) { "CANVAS" }

      it "returns a new instance" do
        expect { subject }.not_to raise_error
      end

      context "when alg is provided in configs" do
        let(:alg) { "HS256" }
        let(:credentials) do
          super().merge(canvas_secret_alg: alg)
        end

        it "sets alg from configs" do
          expect(subject.alg).to eq(alg)
        end
      end

      it "defaults alg to ES512" do
        expect(subject.alg).to eq(:ES512)
      end

      it "sets secret from configs" do
        expect(subject.secret).to eq(credentials[:canvas_secret])
      end
    end

    context "when properly configured with prefix" do
      let(:prefix) { :canvas }

      it "returns a new instance" do
        expect { subject }.not_to raise_error
      end
    end
  end

  describe "#token" do
    subject { service.token(body, expires_at:) }

    let(:service) { described_class.new(app_key: "CANVAS") }
    let(:expires_at) { nil }
    let(:body) { { "foo" => "bar" } }
    let(:decoded_body) { CanvasSecurity.decode_jwt(subject, [credentials[:canvas_secret]]) }

    context "with HS256 secret" do
      let(:credentials) do
        super().merge(canvas_secret_alg: :HS256)
      end

      it "returns a valid token" do
        expect(subject).to be_a(String)
        expect(decoded_body).to eq(body)
      end

      it "does not expire" do
        expect(decoded_body["exp"]).to be_nil
      end

      context "with expires_at" do
        let(:expires_at) { 1.day.from_now }

        it "includes exp in token" do
          expect(decoded_body["exp"]).to eq(expires_at.to_i)
        end
      end
    end

    context "with ES512 secret" do
      let(:private_key) do
        <<~PEM
          -----BEGIN EC PRIVATE KEY-----
          MIHcAgEBBEIA/p2E4ALblSwyqEsvgXpXa3VotiOhMH/Vgpto5es0ACKrsKhiwZ9g
          6uzFkrLH/Nye7S9/GxFNPIy3qlCvWZ+4CKugBwYFK4EEACOhgYkDgYYABAEaN87f
          1jWaaWt/tfe/shbpCXHca2pspoR2mJ1WxpT2ygnkzKiEIfcBdQrG7+odWrPb5wzS
          kYGRffWzFG+dQ4296wDYbEQDC1yCrEQuf2UROlATU+07lD6ZU5VO5mPrC32QexnT
          Vnl6+XNK+BUaHlabe1BxBVdNsV4b0iApXNwQNkad8g==
          -----END EC PRIVATE KEY-----
        PEM
      end
      let(:public_key) do
        <<~PEM
          -----BEGIN PUBLIC KEY-----
          MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQBGjfO39Y1mmlrf7X3v7IW6Qlx3Gtq
          bKaEdpidVsaU9soJ5MyohCH3AXUKxu/qHVqz2+cM0pGBkX31sxRvnUONvesA2GxE
          AwtcgqxELn9lETpQE1PtO5Q+mVOVTuZj6wt9kHsZ01Z5evlzSvgVGh5Wm3tQcQVX
          TbFeG9IgKVzcEDZGnfI=
          -----END PUBLIC KEY-----
        PEM
      end
      let(:credentials) do
        super().merge(canvas_secret: Base64.encode64(private_key))
      end

      it "returns a valid token" do
        jwt = subject
        expect(jwt).to be_a(String)
        decoded_body = CanvasSecurity.decode_jwt(jwt, [OpenSSL::PKey::EC.new(public_key)])
        expect(decoded_body).to eq(body)
      end
    end
  end

  describe "#auth_token" do
    subject { service.auth_token(sub, expires_at:) }

    let(:service) { described_class.new(app_key: "CANVAS") }
    let(:expires_at) { nil }
    let(:sub) { nil }
    let(:decoded_body) { CanvasSecurity.decode_jwt(subject, [credentials[:canvas_secret]]) }
    let(:credentials) do
      super().merge(canvas_secret_alg: :HS256)
    end

    it "includes app_key in token" do
      expect(decoded_body["iss"]).to eq("CANVAS")
    end

    it "does not include sub" do
      expect(decoded_body["sub"]).to be_nil
    end

    context "when sub is provided" do
      let(:sub) { "123" }

      it "includes sub in token" do
        expect(decoded_body["sub"]).to eq(sub)
      end
    end

    context "caching" do
      specs_require_cache(:redis_cache_store)

      let(:cache_key) { "pandata_events:auth_token:CANVAS:#{sub}:1" }

      before do
        allow(Canvas.redis).to receive(:setex).and_call_original
      end

      context "when cache is false" do
        subject { service.auth_token(sub, expires_at:, cache: false) }

        before do
          allow(Canvas.redis).to receive(:get).and_call_original
        end

        it "does not cache the token" do
          subject
          expect(Canvas.redis).not_to have_received(:setex)
          expect(Canvas.redis).not_to have_received(:get)
        end
      end

      it "returns cached token if present" do
        service.auth_token(sub, expires_at:)
        service.auth_token(sub, expires_at:)
        expect(Canvas.redis).to have_received(:setex).once

        Canvas.redis.del(cache_key)
        service.auth_token(sub, expires_at:)
        expect(Canvas.redis).to have_received(:setex).twice
      end

      it "caches the token for roughly 1 day" do
        service.auth_token(sub, expires_at:)
        expect(Canvas.redis.ttl(cache_key)).to be_within(10.minutes).of(1.day)
      end

      context "with expires_at" do
        let(:expires_at) { 1.hour.from_now }

        it "caches the token until roughly expires_at" do
          service.auth_token(sub, expires_at:)
          expect(Canvas.redis.ttl(cache_key)).to be_within(10.minutes).of(1.hour)
        end
      end
    end
  end
end
