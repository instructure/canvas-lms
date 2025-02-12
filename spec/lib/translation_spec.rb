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
    let(:result) { double("Result", translated_text: "Hola, mundo!", source_language_code: "en", target_language_code: "es") }

    it "returns nil if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.translate_text(text: text, tgt_lang: "es")).to be_nil
    end

    it "returns nil if tgt_lang is nil" do
      expect(described_class.translate_text(text: text, tgt_lang: nil)).to be_nil
    end

    it "translates text when src_lang and tgt_lang are provided" do
      allow(translation_client).to receive(:translate_text).and_return(result)
      expect(described_class.translate_text(text: text, tgt_lang: "es")).to eq("Hola, mundo!")
    end

    context "when target language is identical to detected source language" do
      let(:result) { double("Result", translated_text: "Hola, mundo!", source_language_code: "es", target_language_code: "es") }

      it "raises SameLanguageTranslationError" do
        allow(translation_client).to receive(:translate_text).and_return(result)
        expect { described_class.translate_text(text: text, tgt_lang: "es") }.to raise_error(Translation::SameLanguageTranslationError)
      end
    end
  end

  describe "translate_html" do
    let(:html) { "<p>Hello, world!</p>" }
    let(:result) { double("Result", translated_document: MockResponse.new, source_language_code: "en", target_language_code: "es") }

    before do
      allow(described_class).to receive(:translation_client).and_return(translation_client)
    end

    it "returns nil if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.translate_html(html_string: html, tgt_lang: "es")).to be_nil
    end

    it "returns nil if tgt_lang is nil" do
      expect(described_class.translate_html(html_string: html, tgt_lang: nil)).to be_nil
    end

    it "translates text when src_lang and tgt_lang are provided" do
      allow(translation_client).to receive(:translate_document).and_return(result)
      expect(described_class.translate_html(html_string: html, tgt_lang: "es")).to eq("<p>Hola, mundo!</p>")
    end

    context "when target language is identical to detected source language" do
      let(:result) { double("Result", translated_document: MockResponse.new, source_language_code: "es", target_language_code: "es") }

      it "raises SameLanguageTranslationError" do
        allow(translation_client).to receive(:translate_document).and_return(result)
        expect { described_class.translate_html(html_string: html, tgt_lang: "es") }.to raise_error(Translation::SameLanguageTranslationError)
      end
    end
  end
end
