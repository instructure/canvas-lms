# frozen_string_literal: true

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

require "aws-sdk-sagemakerruntime"

module Translation
  class << self
    include Aws::SageMakerRuntime

    def sagemaker_client
      settings = YAML.safe_load(DynamicSettings.find(tree: :private)["translation.yml"] || "{}")
      config = {
        region: settings["translation_region"] || "us-west-2"
      }

      config[:credentials] = Canvas::AwsCredentialProvider.new("translation", settings["vault_credential_path"])
      if config[:credentials].set?
        Aws::SageMakerRuntime::Client.new(config)
      end
    end

    ##
    # Can we provide API translations?
    #
    def available?(context, feature_flag)
      context&.feature_enabled?(feature_flag) && sagemaker_client.present?
    end

    ##

    ##
    # Create a translation given the src -> target mapping
    #
    def create(src_lang:, tgt_lang:, text:)
      return unless sagemaker_client.present?

      # TODO: Error handling of invoke endpoint.
      response = sagemaker_client.invoke_endpoint(
        endpoint_name: "translation-endpoint", # TODO: Configuration value.
        body: { inputs: { src_lang:, tgt_lang:, text: } }.to_json,
        content_type: "application/json",
        accept: "application/json"
      )

      JSON.parse(response.body.read)
    end

    def languages
      # TODO: Use the i18n gem to pull locale names from supported locales.
      # TODO: Add locale names to each language in that native language.
      [
        { id: "en", name: "English" },
        { id: "ga", name: "Irish" },
        { id: "ja", name: "Japanese" },
        { id: "de", name: "German" },
        { id: "hu", name: "Hungarian" },
        { id: "es", name: "Spanish" },
        { id: "zh", name: "Chinese" }
      ]
    end
  end
end
