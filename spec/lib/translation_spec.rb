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

TranslationResponse = Struct.new(:translation, :source_language, keyword_init: true)

describe Translation do
  let(:user) { User.create!(name: "Test User") }

  describe "#available?" do
    context "when CedarClient is defined and enabled" do
      before { stub_const("CedarClient", class_double(CedarClient, enabled?: true)) }

      it "returns true" do
        expect(Translation.available?).to be true
      end
    end

    context "when CedarClient is defined but not enabled" do
      before { stub_const("CedarClient", class_double(CedarClient, enabled?: false)) }

      it "returns false" do
        expect(Translation.available?).to be false
      end
    end
  end

  describe "#translate_text" do
    let(:text) { "Hello, world!" }
    let(:tgt_lang) { "es" }
    let(:options) { { root_account_uuid: "1234567890", feature_slug: "discussion", current_user: user } }

    context "when available" do
      before do
        stub_const("CedarClient", class_double(CedarClient, enabled?: true))
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
        Translation.translate_text(text:, tgt_lang:, options:)
      end

      it "returns the translated text" do
        expect(Translation.translate_text(text:, tgt_lang:, options:)).to eq("Hola, mundo!")
      end

      it "collects translation stats" do
        allow(Translation).to receive(:collect_translation_stats)
        Translation.translate_text(text:, tgt_lang:, options:)
        expect(Translation).to have_received(:collect_translation_stats).with(
          src_lang: "en",
          tgt_lang:,
          type: "discussion"
        )
      end

      it "raises TextTooLongError if text is too long" do
        long_text = "a" * 5001
        allow(CedarClient).to receive(:translate_text).and_raise(InstructureMiscPlugin::Extensions::CedarClient::ContentTooLongError)
        expect { Translation.translate_text(text: long_text, tgt_lang:, options:) }.to raise_error(Translation::TextTooLongError)
      end

      it "raises UnsupportedLanguageError if language is not supported" do
        allow(CedarClient).to receive(:translate_text).and_raise(InstructureMiscPlugin::Extensions::CedarClient::UnsupportedLanguageError)
        expect { Translation.translate_text(text: "Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn", tgt_lang: "??", options:) }.to raise_error(Translation::UnsupportedLanguageError)
      end

      it "raises ValidationError if required parameter is missing or empty" do
        allow(CedarClient).to receive(:translate_text).and_raise(InstructureMiscPlugin::Extensions::CedarClient::ValidationError)
        expect { Translation.translate_text(text: "", tgt_lang:, options:) }.to raise_error(Translation::ValidationError)
      end
    end

    context "when not available" do
      before { allow(Translation).to receive(:available?).and_return(false) }

      it "returns nil" do
        expect(Translation.translate_text(text:, tgt_lang:, options:)).to be_nil
      end
    end

    context "when tgt_lang is nil" do
      before { allow(Translation).to receive(:available?).and_return(true) }

      it "returns nil" do
        expect(Translation.translate_text(text:, tgt_lang: nil, options:)).to be_nil
      end
    end
  end

  describe "#translate_html" do
    let(:html_string) { "<p>Hello, world!</p>" }
    let(:tgt_lang) { "es" }
    let(:options) { { root_account_uuid: "939393", feature_slug: "discussion", current_user: user } }

    context "when available" do
      before do
        stub_const("CedarClient", class_double(CedarClient, enabled?: true))
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
        Translation.translate_html(html_string:, tgt_lang:, options:)
      end

      it "returns the translated html" do
        expect(Translation.translate_html(html_string:, tgt_lang:, options:)).to eq("<p>Hola, mundo!</p>")
      end

      it "collects translation stats" do
        allow(Translation).to receive(:collect_translation_stats)
        Translation.translate_html(html_string:, tgt_lang:, options:)
        expect(Translation).to have_received(:collect_translation_stats).with(
          src_lang: "en",
          tgt_lang:,
          type: "discussion"
        )
      end

      it "raises TextTooLongError if html_string is too long" do
        long_html = "<p>" + ("a" * 5000) + "</p>"
        allow(CedarClient).to receive(:translate_html).and_raise(InstructureMiscPlugin::Extensions::CedarClient::ContentTooLongError, "Content too long")
        expect { Translation.translate_html(html_string: long_html, tgt_lang:, options:) }.to raise_error(Translation::TextTooLongError)
      end

      it "raises UnsupportedLanguageError if language is not supported" do
        allow(CedarClient).to receive(:translate_html).and_raise(InstructureMiscPlugin::Extensions::CedarClient::UnsupportedLanguageError)
        expect { Translation.translate_html(html_string: "<p>Ph'nglui mglw'nafh Cthulhu R'lyeh wgah'nagl fhtagn</p>", tgt_lang: "??", options:) }.to raise_error(Translation::UnsupportedLanguageError)
      end

      it "raises ValidationError if required parameter is missing or empty" do
        allow(CedarClient).to receive(:translate_html).and_raise(InstructureMiscPlugin::Extensions::CedarClient::ValidationError)
        expect { Translation.translate_html(html_string: "", tgt_lang:, options:) }.to raise_error(Translation::ValidationError)
      end
    end

    context "when not available" do
      before { allow(Translation).to receive(:available?).and_return(false) }

      it "returns nil" do
        expect(Translation.translate_html(html_string:, tgt_lang:, options:)).to be_nil
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
