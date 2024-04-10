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

module SmartSearch
  class << self
    def api_key
      Rails.application.credentials.dig(:smart_search, :openai_api_token)
    end

    def smart_search_available?(context)
      context&.feature_enabled?(:smart_search) && api_key.present?
    end

    def register_class(klass, index_scope_proc, search_scope_proc)
      @search_info ||= []
      @search_info << [klass, index_scope_proc, search_scope_proc]
    end

    def index_scopes(course)
      @search_info.each do |_, proc, _|
        yield proc.call(course)
      end
    end

    def search_scopes(course, user)
      @search_info.each do |klass, _, proc|
        yield klass, proc.call(course, user)
      end
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

    def perform_search(context, user, query, type_filter = [])
      embedding = SmartSearch.generate_embedding(query)
      collections = []
      ActiveRecord::Base.with_pgvector do
        SmartSearch.search_scopes(context, user) do |klass, item_scope|
          item_scope = apply_filter(klass, item_scope, type_filter)
          next unless item_scope

          item_scope = item_scope.select(
            ActiveRecord::Base.send(:sanitize_sql, ["#{klass.table_name}.*, MIN(embedding <=> ?) AS distance", embedding.to_s])
          )
                                 .joins(:embeddings)
                                 .group("#{klass.table_name}.id")
                                 .reorder("distance ASC")
          collections << [klass.name,
                          BookmarkedCollection.wrap(
                            BookmarkedCollection::SimpleBookmarker.new(klass, { distance: { type: :float, null: false } }, :id),
                            item_scope
                          )]
        end
      end
      BookmarkedCollection.merge(*collections)
    end

    def apply_filter(klass, scope, filter)
      return scope if filter.empty?

      if klass == DiscussionTopic
        if filter.include?("discussion_topics") && filter.include?("announcements")
          scope
        elsif filter.include?("discussion_topics")
          scope.where(type: nil)
        elsif filter.include?("announcements")
          scope.where(type: "Announcement")
        end
      elsif filter.include?(Context.api_type_name(klass))
        scope
      end
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

    def index_account(root_account)
      # by default, index all courses updated in the last year
      date_cutoff = Setting.get("smart_search_index_days_ago", "365").to_i.days.ago
      root_account.all_courses.active.where(updated_at: date_cutoff..).find_each do |course|
        delay(priority: Delayed::LOW_PRIORITY,
              singleton: "smart_search_index_course:#{course.global_id}",
              n_strand: "smart_search_index_course").index_course(course)
      end
      nil
    end

    def index_course(course)
      index_scopes(course) do |scope|
        scope.where.missing(:embeddings)
             .find_each(strategy: :pluck_ids) do |item|
          item.generate_embeddings(synchronous: true)
        end
      end
      nil
    end
  end
end
