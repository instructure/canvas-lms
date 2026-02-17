# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

require "spec_helper"

describe CanvasKaltura::ClientV3::CaptionAssetMethods do
  subject(:kaltura_client) do
    CanvasKaltura::ClientV3.new.tap { it.ks = ks }
  end

  let(:ks) { "fakekalturasession" }

  before do
    allow(CanvasKaltura::ClientV3).to receive_messages(config: {})
    WebMock.enable!
  end

  describe "#caption_assets" do
    let(:entry_id) { "m-123" }
    let(:response_body) { <<~XML }
      <?xml version="1.0" encoding="UTF-8"?>
      <xml>
        <result>
          <item>
            <objectType>KalturaCaptionAsset</objectType>
            <id>c-abc</id>
            <format>1</format>
            <languageCode>en</languageCode>
            <status>2</status>
          </item>
          <item>
            <objectType>KalturaCaptionAsset</objectType>
            <id>c-def</id>
            <format>1</format>
            <languageCode>es</languageCode>
            <status>2</status>
          </item>
        </result>
      </xml>
    XML

    before do
      stub_request(:get, "https://www.kaltura.com/api_v3/")
        .with(
          query: hash_including(
            service: "captionAsset",
            action: "list",
            filter: { entryIdEqual: entry_id }
          )
        )
        .to_return(body: response_body)
    end

    it "calls getRequest with proper parameters" do
      expect(kaltura_client).to receive(:getRequest).with(
        :captionAsset,
        :list,
        ks:,
        "filter[entryIdEqual]": entry_id
      ).and_call_original

      kaltura_client.caption_assets(entry_id)
    end

    it "returns array of caption assets" do
      expect(kaltura_client.caption_assets(entry_id))
        .to contain_exactly(
          hash_including(
            id: "c-abc",
            languageCode: "en",
            status: "2",
            objectType: "KalturaCaptionAsset"
          ),
          hash_including(
            id: "c-def",
            languageCode: "es",
            status: "2",
            objectType: "KalturaCaptionAsset"
          )
        )
    end

    context "when no captions exist" do
      let(:response_body) { <<~XML }
        <?xml version="1.0" encoding="UTF-8"?>
        <xml>
          <result></result>
        </xml>
      XML

      it "returns empty array when no captions exist" do
        expect(kaltura_client.caption_assets(entry_id)).to be_empty
      end
    end

    it "returns nil when getRequest fails" do
      allow(kaltura_client).to receive(:getRequest).and_return(nil)
      expect(kaltura_client.caption_assets(entry_id)).to be_nil
    end
  end

  describe "create_caption_asset" do
    let(:entry_id) { "m-123" }
    let(:language_code) { "en" }
    let(:response_body) { <<~XML }
      <?xml version="1.0" encoding="UTF-8"?>
      <xml>
        <result>
          <objectType>KalturaCaptionAsset</objectType>
          <id>c-123</id>
          <format>1</format>
          <languageCode>en</languageCode>
          <status>0</status>
          <entryId>test_entry_123</entryId>
        </result>
      </xml>
    XML

    before do
      stub_request(:get, "https://www.kaltura.com/api_v3/")
        .with(query: hash_including(
          service: "captionAsset",
          action: "add",
          entryId: entry_id,
          captionAsset: { languageCode: language_code }
        ))
        .to_return(body: response_body)
    end

    it "calls getRequest with proper parameters" do
      expect(kaltura_client).to receive(:getRequest).with(
        :captionAsset,
        :add,
        ks:,
        entryId: entry_id,
        "captionAsset[languageCode]": language_code
      ).and_call_original

      kaltura_client.create_caption_asset(entry_id, language_code)
    end

    it "returns created caption asset hash" do
      expect(kaltura_client.create_caption_asset(entry_id, language_code))
        .to match(
          hash_including(
            id: "c-123",
            languageCode: "en",
            status: "0",
            objectType: "KalturaCaptionAsset"
          )
        )
    end

    it "returns nil when getRequest fails" do
      allow(kaltura_client).to receive(:getRequest).and_return(nil)
      expect(kaltura_client.create_caption_asset(entry_id, language_code)).to be_nil
    end
  end

  describe "caption_asset" do
    let(:caption_id) { "c-123" }
    let(:response_body) { <<~XML }
      <?xml version="1.0" encoding="UTF-8"?>
      <xml>
        <result>
          <objectType>KalturaCaptionAsset</objectType>
          <id>c-123</id>
          <format>1</format>
          <languageCode>en</languageCode>
          <status>2</status>
        </result>
      </xml>
    XML

    before do
      stub_request(:get, "https://www.kaltura.com/api_v3/")
        .with(query: hash_including(
          service: "captionAsset",
          action: "get",
          captionAssetId: caption_id
        ))
        .to_return(body: response_body)
    end

    it "calls getRequest with proper parameters" do
      expect(kaltura_client).to receive(:getRequest).with(
        :captionAsset,
        :get,
        ks:,
        captionAssetId: caption_id
      ).and_call_original

      kaltura_client.caption_asset(caption_id)
    end

    it "returns caption asset hash" do
      expect(kaltura_client.caption_asset(caption_id))
        .to match(
          hash_including(
            id: "c-123",
            languageCode: "en",
            status: "2",
            objectType: "KalturaCaptionAsset"
          )
        )
    end

    it "returns nil when getRequest fails" do
      allow(kaltura_client).to receive(:getRequest).and_return(nil)
      expect(kaltura_client.caption_asset(caption_id)).to be_nil
    end
  end

  describe "caption_asset_url" do
    let(:caption_id) { "c-123" }
    let(:response_body) { <<~XML }
      <?xml version="1.0" encoding="UTF-8"?>
      <xml>
        <result>
          https://www.kaltura.com/captions/c-123.srt
        </result>
      </xml>
    XML

    before do
      stub_request(:get, "https://www.kaltura.com/api_v3/")
        .with(query: hash_including(
          service: "captionAsset",
          action: "getUrl"
        ))
        .to_return(body: response_body)
    end

    it "calls getRequest with proper parameters" do
      expect(kaltura_client).to receive(:getRequest).with(
        :captionAsset,
        :getUrl,
        ks:,
        captionAssetId: caption_id
      ).and_call_original

      kaltura_client.caption_asset_url(caption_id)
    end

    it "returns caption URL string" do
      expect(kaltura_client.caption_asset_url(caption_id)).to eq "https://www.kaltura.com/captions/c-123.srt"
    end

    it "returns nil when getRequest fails" do
      allow(kaltura_client).to receive(:getRequest).and_return(nil)
      expect(kaltura_client.caption_asset_url(caption_id)).to be_nil
    end
  end

  describe "caption_asset_contents" do
    let(:caption_id) { "c-123" }
    let(:srt_content) { <<~SRT.strip }
      1
      00:00:00,000 --> 00:00:02,000
      Hello world

      2
      00:00:02,000 --> 00:00:05,000
      This is a test caption
    SRT
    let(:response_body) { <<~XML }
      <?xml version="1.0" encoding="UTF-8"?>
      <xml>
        <result>
          #{CGI.escapeHTML(srt_content)}
        </result>
      </xml>
    XML

    before do
      stub_request(:get, "https://www.kaltura.com/api_v3/")
        .with(query: hash_including(
          service: "captionAsset",
          action: "serve",
          captionAssetId: caption_id
        ))
        .to_return(body: response_body)
    end

    it "calls getRequest with proper parameters" do
      expect(kaltura_client).to receive(:getRequest).with(
        :captionAsset,
        :serve,
        ks:,
        captionAssetId: caption_id
      ).and_call_original

      kaltura_client.caption_asset_contents(caption_id)
    end

    it "returns caption SRT content string" do
      expect(kaltura_client.caption_asset_contents(caption_id)).to eql(srt_content)
    end

    it "returns nil when service unavailable" do
      allow(kaltura_client).to receive(:getRequest).and_return(nil)
      expect(kaltura_client.caption_asset_contents(caption_id)).to be_nil
    end
  end
end
