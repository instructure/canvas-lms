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
#

NO_SRC_LANG = {
  endpoint_name: "translation-endpoint",
  body: { inputs: { src_lang: "es", tgt_lang: "en", text: "¿Dónde está el baño?" } }.to_json,
  content_type: "application/json",
  accept: "application/json"
}.freeze

USER_LOCALE_SET = {
  endpoint_name: "translation-endpoint",
  body: { inputs: { src_lang: "es", tgt_lang: "sv", text: "¿Dónde está el baño?" } }.to_json,
  content_type: "application/json",
  accept: "application/json"
}.freeze

class MockResponse
  def read
    { translated_text: "translated" }.to_json
  end
end

class MockCredentials
  def set?
    true
  end
end

require "aws-sdk-sagemakerruntime"

describe "Translation" do
  before do
    # Mock DynamicSettings to return our endpoint.
    allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
    allow(DynamicSettings).to receive(:find).with(tree: :private).and_return({ "sagemaker.yml" => { "endpoint_name" => "translation-endpoint" }.to_yaml })

    # Mock statsd to allow it to receive what we expect
    allow(InstStatsd::Statsd).to receive(:increment)

    # Mock the runtime and the credential provider
    @runtime_mock = instance_double("Aws::SageMakerRuntime::Client")
    allow(Canvas::AwsCredentialProvider).to receive(:new).and_return(MockCredentials.new)
    allow(Aws::SageMakerRuntime::Client).to receive(:new).and_return(@runtime_mock)

    # Mock the response that the runtime returns.
    @mock_response = instance_double("Response")
    allow(@mock_response).to receive(:body).and_return(MockResponse.new)
    allow(@runtime_mock).to receive(:invoke_endpoint).and_return(@mock_response)

    # Mock user
    @user = user_factory(active_all: true)
  end

  describe ":create" do
    it "detects src_lang if not present" do
      Translation.create(tgt_lang: "en", text: "¿Dónde está el baño?")
      expect(@runtime_mock).to have_received(:invoke_endpoint).with(NO_SRC_LANG)
    end

    it "trims locale for src_lang" do
      expect(CLD).to receive(:detect_language).and_return({ code: "es-ES" })
      Translation.create(tgt_lang: "en", text: "¿Dónde está el baño?")
      expect(@runtime_mock).to have_received(:invoke_endpoint).with(NO_SRC_LANG)
    end

    it "requires user or tgt lang set" do
      expect(Translation.create(text: "hello, world")).to be_nil
    end

    it "uses trimmed user locale if tgt_lang not set" do
      @user.locale = "sv-x-k12"
      Translation.create(user: @user, src_lang: "es", text: "¿Dónde está el baño?")
      expect(@runtime_mock).to have_received(:invoke_endpoint).with(USER_LOCALE_SET)
    end

    it "increments the translation metric" do
      Translation.create(tgt_lang: "en", text: "¿Dónde está el baño?")
      expect(InstStatsd::Statsd).to have_received(:increment).with("translation.create.es.en")
    end
  end

  describe ":translated_languages" do
    it "does not translate controls if locale is english" do
      @user.locale = "en"
      allow(Translation).to receive(:create)
      Translation.translated_languages(@user)
      expect(Translation).not_to have_received(:create)
    end

    it "does not translate if no locale" do
      allow(Translation).to receive(:create)
      Translation.translated_languages(@user)
      expect(Translation).not_to have_received(:create)
    end

    it "translates if non-english locale is set" do
      @user.locale = "es"
      allow(Translation).to receive(:create)
      Translation.translated_languages(@user)
      expect(Translation).to have_received(:create).exactly(Translation.languages.length).times
    end

    it "uses the cache if key is present" do
      # Arrange
      @user.locale = "es"
      allow(Canvas.redis).to receive(:get).with(["translated_languages", @user.locale].cache_key).and_return({ language: "languages" }.to_json)

      # Act
      resp = Translation.translated_languages(@user)

      # Assert
      expect(resp).to eq({ "language" => "languages" })
    end

    it "caches the translation results" do
      # Arrange
      allow(Canvas.redis).to receive(:set)
      @user.locale = "es"

      # Act
      Translation.translated_languages(@user)

      # Assert
      expect(Canvas.redis).to have_received(:set).exactly(1)
    end
  end

  describe ":language_matches_user_locale?" do
    it "does match" do
      @user.locale = "es"
      expect(Translation.language_matches_user_locale?(@user, "¿Dónde está el baño?")).to be_truthy
    end

    it "does not match" do
      @user.locale = "en"
      expect(Translation.language_matches_user_locale?(@user, "¿Dónde está el baño?")).to be_falsey
    end
  end
end
