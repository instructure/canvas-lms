# frozen_string_literal: true

# Copyright (C) 2025 - present Instructure, Inc.
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

TranslationResponse = Struct.new(:translation, :source_language, keyword_init: true)

describe Translation::CedarTranslator do
  let(:translator) { described_class.new }
  let(:user) { User.create!(name: "Test User") }

  describe "#available?" do
    context "when CedarClient is defined and enabled" do
      before { stub_const("CedarClient", double("CedarClient", enabled?: true)) }

      it "returns true" do
        expect(translator.available?).to be true
      end
    end

    context "when CedarClient is defined but not enabled" do
      before { stub_const("CedarClient", double("CedarClient", enabled?: false)) }

      it "returns false" do
        expect(translator.available?).to be false
      end
    end
  end

  describe "#translate_text" do
    let(:text) { "Hello, world!" }
    let(:tgt_lang) { "es" }
    let(:options) { { root_account_uuid: "1234567890", feature_slug: "discussion", current_user: user } }

    context "when available" do
      before do
        stub_const("CedarClient", double("CedarClient", enabled?: true))
        allow(CedarClient).to receive(:translate_text).and_return(
          TranslationResponse.new(
            translation: "Hola, mundo!",
            source_language: "en"
          )
        )
      end

      it "calls CedarClient.translate_text with correct parameters" do
        expect(CedarClient).to receive(:translate_text).with(
          content: text,
          target_language: tgt_lang,
          feature_slug: "discussion",
          root_account_uuid: "1234567890",
          current_user: user
        )
        translator.translate_text(text:, tgt_lang:, options:)
      end

      it "returns the translated text" do
        expect(translator.translate_text(text:, tgt_lang:, options:)).to eq("Hola, mundo!")
      end

      it "collects translation stats" do
        allow(translator).to receive(:collect_translation_stats)
        translator.translate_text(text:, tgt_lang:, options:)
        expect(translator).to have_received(:collect_translation_stats).with(
          src_lang: "en",
          tgt_lang:,
          type: "discussion"
        )
      end
    end

    context "when not available" do
      before { allow(translator).to receive(:available?).and_return(false) }

      it "returns nil" do
        expect(translator.translate_text(text:, tgt_lang:, options:)).to be_nil
      end
    end

    context "when tgt_lang is nil" do
      before { allow(translator).to receive(:available?).and_return(true) }

      it "returns nil" do
        expect(translator.translate_text(text:, tgt_lang: nil, options:)).to be_nil
      end
    end
  end

  describe "#translate_html" do
    let(:html_string) { "<p>Hello, world!</p>" }
    let(:tgt_lang) { "es" }
    let(:options) { { root_account_uuid: "939393", feature_slug: "discussion", current_user: user } }

    context "when available" do
      before do
        stub_const("CedarClient", double("CedarClient", enabled?: true))
        allow(CedarClient).to receive(:translate_html).and_return(
          TranslationResponse.new(
            translation: "<p>Hola, mundo!</p>",
            source_language: "en"
          )
        )
      end

      it "calls CedarClient.translate_html with correct parameters" do
        expect(CedarClient).to receive(:translate_html).with(
          content: html_string,
          target_language: tgt_lang,
          feature_slug: "discussion",
          root_account_uuid: "939393",
          current_user: user
        )
        translator.translate_html(html_string:, tgt_lang:, options:)
      end

      it "returns the translated html" do
        expect(translator.translate_html(html_string:, tgt_lang:, options:)).to eq("<p>Hola, mundo!</p>")
      end

      it "collects translation stats" do
        allow(translator).to receive(:collect_translation_stats)
        translator.translate_html(html_string:, tgt_lang:, options:)
        expect(translator).to have_received(:collect_translation_stats).with(
          src_lang: "en",
          tgt_lang:,
          type: "discussion"
        )
      end
    end

    context "when not available" do
      before { allow(translator).to receive(:available?).and_return(false) }

      it "returns nil" do
        expect(translator.translate_html(html_string:, tgt_lang:, options:)).to be_nil
      end
    end
  end

  describe ".languages" do
    subject { described_class.languages }

    let(:language_abbrs) do
      %w[ca de en es fr nl pt-BR ru sv zh-Hans]
    end

    it "returns the proper list" do
      expect(subject.pluck(:id)).to match_array(language_abbrs)
    end

    it "returns the list of languages in name asc" do
      expect(subject.pluck(:name).sort).to eq(subject.pluck(:name))
    end
  end
end
