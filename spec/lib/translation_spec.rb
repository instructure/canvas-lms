# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require "aws-sdk-translate"

class MockResponse
  def content
    "<p>Hola, mundo!</p>"
  end
end

describe Translation do
  let(:translation_client) { double("Translation") }

  before do
    allow(described_class).to receive(:translation_client).and_return(translation_client)
    allow(Account.site_admin).to receive(:feature_enabled?).with(:ai_translation_improvements).and_return(true)
  end

  describe "available?" do
    let(:context) { double("Context", feature_enabled?: true) }

    it "returns true if feature flag is enabled and translation client is present" do
      expect(described_class.available?(context, :some_flag)).to be true
    end

    it "returns false if feature flag is disabled" do
      allow(context).to receive(:feature_enabled?).with(:some_flag).and_return(false)
      expect(described_class.available?(context, :some_flag)).to be false
    end

    it "returns false if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.available?(context, :some_flag)).to be false
    end
  end

  describe "translate_text" do
    let(:text) { "Hello, world!" }
    let(:result) { double("Result", translated_text: "Hola, mundo!") }

    it "returns nil if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.translate_text(text: text, src_lang: "en", tgt_lang: "es")).to be_nil
    end

    it "returns nil if tgt_lang is nil" do
      expect(described_class.translate_text(text: text, src_lang: "en", tgt_lang: nil)).to be_nil
    end

    it "determines source language from text if nil" do
      hungarian_text = "Hello, világ!"
      allow(translation_client).to receive(:translate_text).and_return(result)
      expect(described_class.translate_text(text: hungarian_text, src_lang: nil, tgt_lang: "es")).to eq("Hola, mundo!")
      expect(translation_client).to have_received(:translate_text).with(
        text: hungarian_text,
        source_language_code: "hu",
        target_language_code: "es"
      )
    end

    it "translates text when src_lang and tgt_lang are provided" do
      allow(translation_client).to receive(:translate_text).and_return(result)
      expect(described_class.translate_text(text: text, src_lang: "en", tgt_lang: "es")).to eq("Hola, mundo!")
    end
  end

  describe "translate_html" do
    let(:html) { "<p>Hello, world!</p>" }
    let(:result) { double("Result", translated_document: MockResponse.new) }

    before do
      allow(described_class).to receive(:translation_client).and_return(translation_client)
    end

    it "returns nil if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.translate_html(html_string: html, src_lang: "en", tgt_lang: "es")).to be_nil
    end

    it "returns nil if tgt_lang is nil" do
      expect(described_class.translate_html(html_string: html, src_lang: "en", tgt_lang: nil)).to be_nil
    end

    it "determines source language from text if nil" do
      hungarian_html = "Hello, világ!"
      allow(translation_client).to receive(:translate_document).and_return(result)
      expect(described_class.translate_html(html_string: hungarian_html, src_lang: nil, tgt_lang: "es")).to eq("<p>Hola, mundo!</p>")
      expect(translation_client).to have_received(:translate_document).with(
        document: {
          content: hungarian_html,
          content_type: "text/html",
        },
        source_language_code: "hu",
        target_language_code: "es"
      )
    end

    it "translates text when src_lang and tgt_lang are provided" do
      allow(translation_client).to receive(:translate_document).and_return(result)
      expect(described_class.translate_html(html_string: html, src_lang: "en", tgt_lang: "es")).to eq("<p>Hola, mundo!</p>")
    end
  end
end
