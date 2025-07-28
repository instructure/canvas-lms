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

TranslationResponse = Struct.new(:translation, :source_language, keyword_init: true)

describe Translation do
  let(:translation_flags) { { translation: true, ai_translation_improvements: true, cedar_translation: true } }

  before do
    # We're gonna focus on CedarClient, since other clients are deprecated
    allow(CedarClient).to receive(:enabled?).and_return(true)
  end

  # rubocop:disable Layout/MultilineArrayLineBreaks
  describe "#languages" do
    context "when improvements feature is enabled" do
      subject { described_class.languages({ translation: true, ai_translation_improvements: true, cedar_translation: false }) }

      let(:language_abbrs) do
        %w[
          af sq am ar hy az bn bs bg ca zh-TW zh hr cs da fa-AF nl en et
          fa tl fi fr-CA fr ka de el gu ht ha he hi hu is id
          ga it ja kn kk ko lv lt mk ms ml mt mr mn no ps pl pt pt-PT pa
          ro ru sr si sk sl so es es-MX sw sv ta te th tr uk ur uz vi cy
        ]
      end

      it "returns the proper list" do
        expect(subject.pluck(:id)).to match_array(language_abbrs)
      end

      it "returns the list of languages in name asc" do
        expect(subject.pluck(:name).sort).to eq(subject.pluck(:name))
      end
    end

    context "when improvements feature is disabled" do
      subject { described_class.languages({ translation: true, ai_translation_improvements: false, cedar_translation: false }) }

      let(:language_abbrs) do
        %w[
          af sq am ar hy az bn bs bg ca zh hr cs da nl en et
          fa tl fi fr ka de el gu ht ha he hi hu is id
          ga it ja kn kk ko lv lt mk ms ml mr mn no ps pl pt pa
          ro ru sr si sk sl so es sw sv ta th tr uk ur uz vi cy
          ast ba be br ceb ff fy gd gl ig ilo jv km lb lg ln lo
          mg my ne ns oc or sd ss su tn wo xh yi yo zu
        ]
      end

      it "returns the proper list" do
        expect(subject.pluck(:id)).to match_array(language_abbrs)
      end

      it "returns the list of languages in name asc" do
        expect(subject.pluck(:name).sort).to eq(subject.pluck(:name))
      end
    end

    context "when language characters using unicode chars" do
      subject { described_class.languages({ translation: true, ai_translation_improvements: true, cedar_translation: false }) }

      let(:improvements_feature_enabled) { true }

      it "returns the proper list sorted by unicode characters" do
        I18n.with_locale(:hu) do
          result_names = subject.pluck(:name)
          expect(result_names.find_index("Örmény") < result_names.find_index("Román")).to be true
        end
      end
    end
  end
  # rubocop:enable Layout/MultilineArrayLineBreaks

  describe "available?" do
    it "returns true if feature flag is enabled and translation client is present" do
      expect(described_class.available?(translation_flags)).to be true
    end

    it "returns false if feature flag is disabled" do
      expect(described_class.available?({ translation: false })).to be false
    end

    it "returns false if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.available?(translation_flags)).to be false
    end
  end

  describe "current_translation_provider_type" do
    it "returns nil if translation flags are not enabled" do
      flags = { translation: false, ai_translation_improvements: false, cedar_translation: false }
      expect(described_class.current_translation_provider_type(flags)).to be_nil
    end

    it "returns sagemaker as default translation provider" do
      flags = { translation: true, ai_translation_improvements: false, cedar_translation: false }
      expect(described_class.current_translation_provider_type(flags)).to eq(Translation::TranslationType::SAGEMAKER)
    end

    it "returns aws translate as improved translation provider" do
      flags = { translation: true, ai_translation_improvements: true, cedar_translation: false }
      expect(described_class.current_translation_provider_type(flags)).to eq(Translation::TranslationType::AWS_TRANSLATE)
    end

    it "returns cedar if cedar is on" do
      flags = { translation: true, ai_translation_improvements: false, cedar_translation: true }
      expect(described_class.current_translation_provider_type(flags)).to eq(Translation::TranslationType::CEDAR)
    end
  end

  describe "translate_text" do
    let(:text) { "Hello, world!" }
    let(:result) { "Hola, mundo!" }

    before do
      stub_const("CedarClient", Class.new do
        def self.enabled?
          true
        end

        def self.translate_text(*)
          TranslationResponse.new(
            translation: "Hola, mundo!",
            source_language: "en"
          )
        end
      end)
    end

    it "returns nil if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.translate_text(text:, tgt_lang: "es", flags: translation_flags)).to be_nil
    end

    it "returns nil if tgt_lang is nil" do
      expect(described_class.translate_text(text:, tgt_lang: nil, flags: translation_flags)).to be_nil
    end

    it "translates text when tgt_lang is provided" do
      expect(described_class.translate_text(text:, tgt_lang: "es", flags: translation_flags, options: { feature_slug: "inbox" })).to eq(result)
    end

    context "when target language is identical to detected source language" do
      it "raises SameLanguageTranslationError" do
        expect { described_class.translate_text(text: "Hello world", tgt_lang: "en", flags: translation_flags) }.to raise_error(Translation::SameLanguageTranslationError)
      end
    end
  end

  describe "translate_html" do
    let(:html) { "<p>Hello, world!</p>" }
    let(:result) { "<p>Hola, mundo!</p>" }

    before do
      stub_const("CedarClient", Class.new do
        def self.enabled?
          true
        end

        def self.translate_html(*)
          TranslationResponse.new(
            translation: "<p>Hola, mundo!</p>",
            source_language: "en"
          )
        end
      end)
    end

    it "returns nil if translation client is not present" do
      allow(described_class).to receive(:translation_client).and_return(nil)
      expect(described_class.translate_html(html_string: html, tgt_lang: "es", flags: translation_flags)).to be_nil
    end

    it "returns nil if tgt_lang is nil" do
      expect(described_class.translate_html(html_string: html, tgt_lang: nil, flags: translation_flags)).to be_nil
    end

    it "translates text when tgt_lang is provided" do
      expect(described_class.translate_html(html_string: html, tgt_lang: "es", flags: translation_flags, options: { feature_slug: "discussion" })).to eq("<p>Hola, mundo!</p>")
    end
  end
end
