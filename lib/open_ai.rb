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

module OpenAi
  class << self
    def api_key
      Rails.application.credentials.dig(:smart_search, :openai_api_token)
    end

    def smart_search_available?(context)
      api_key.present? && context&.feature_enabled?(:smart_search)
    end

    def generate_embedding(input)
      url = "https://api.openai.com/v1/embeddings"
      headers = {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }

      data = {
        input:,
        model: "text-embedding-ada-002"
      }

      response = JSON.parse(Net::HTTP.post(URI(url), data.to_json, headers).body)
      raise response["error"]["message"] if response["error"]

      response["data"].pluck("embedding")[0]
    end

    def generate_completion(prompt)
      url = "https://api.openai.com/v1/completions"

      headers = {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json"
      }
      data = {
        model: "text-davinci-003",
        prompt:,
        max_tokens: 1500,
        temperature: 0.7
      }
      # TODO: error handling
      response = Net::HTTP.post(URI(url), data.to_json, headers)
      JSON.parse(response.body)["choices"][0]["text"].strip
    end

    def with_pgvector(&)
      vector_schema = ActiveRecord::Base.connection.extension("vector").schema
      ActiveRecord::Base.connection.add_schema_to_search_path(vector_schema, &)
    end

    def index_account(root_account)
      # by default, index all courses updated in the last year
      date_cutoff = Setting.get("smart_search_index_days_ago", "365").to_i.days.ago
      root_account.all_courses.active.where(updated_at: date_cutoff..).find_each do |course|
        delay(priority: Delayed::LOW_PRIORITY,
              singleton: "smart_search_index_course:#{course.global_id}",
              n_strand: "smart_search_index_course").index_course(course)
      end
    end

    def index_course(course)
      # index non-deleted pages (that have not already been indexed)
      course.wiki_pages.not_deleted
            .where.missing(:wiki_page_embeddings)
            .find_each do |page|
        page.generate_embeddings(synchronous: true)
      end
    end
  end
end
