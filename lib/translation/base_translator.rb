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

module Translation
  class BaseTranslator
    def translate_text(text:, tgt_lang:, options: {})
      raise NotImplementedError, "Subclasses must implement the translate_text method"
    end

    def translate_html(html_string:, tgt_lang:, options: {})
      raise NotImplementedError, "Subclasses must implement the translate_html method"
    end

    protected

    # Shared methods for translation services

    def check_same_language(source, target)
      if source == target
        InstStatsd::Statsd.distributed_increment("translation.errors", tags: ["error:same_language"])
        raise Translation::SameLanguageTranslationError
      end
    end

    def collect_translation_stats(src_lang:, tgt_lang:, type:)
      tags = %W[type:#{type} source_language:#{src_lang} dest_language:#{tgt_lang}]
      InstStatsd::Statsd.distributed_increment("translation.invocations", tags:)
    end

    def create_client_config(yaml_name)
      Rails.logger.info("Creating translation client")
      settings = YAML.safe_load(DynamicSettings.find(tree: :private)[yaml_name] || "{}")
      config = {
        region: settings["translation_region"] || "us-west-2",
      }

      @endpoint = settings["endpoint_name"]
      config[:credentials] = Canvas::AwsCredentialProvider.new("translation", settings["vault_credential_path"])
      config
    end
  end
end
