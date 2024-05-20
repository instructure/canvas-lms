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
  EMBEDDING_VERSION = 1

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
      @search_info.map do |_, proc, _|
        proc.call(course)
      end
    end

    def search_scopes(course, user)
      @search_info.map do |klass, _, proc|
        [klass, proc.call(course, user)]
      end
    end

    def generate_embedding(input, version: EMBEDDING_VERSION)
      case EMBEDDING_VERSION
      when 1
        generate_embedding_v1(input)
      else
        raise ArgumentError, "Unsupported embedding version #{version}"
      end
    end

    def generate_embedding_v1(input)
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
      version = context.search_embedding_version || EMBEDDING_VERSION
      embedding = SmartSearch.generate_embedding(query, version:)
      collections = []
      ActiveRecord::Base.with_pgvector do
        SmartSearch.search_scopes(context, user).each do |klass, item_scope|
          item_scope = apply_filter(klass, item_scope, type_filter)
          next unless item_scope

          item_scope = item_scope.select(
            ActiveRecord::Base.send(:sanitize_sql, ["#{klass.table_name}.*, MIN(embedding <=> ?) AS distance", embedding.to_s])
          )
                                 .joins(:embeddings)
                                 .where(klass.embedding_class.table_name => { version: })
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

    # returns [ready, progress]
    # progress may be < 100 while ready if upgrading embeddings
    def check_course(course)
      return -1 unless smart_search_available?(course)

      if course.search_embedding_version == EMBEDDING_VERSION
        [true, 100]
      else
        # queue the index job (the singleton will ensure it's only queued once)
        delay(singleton: "smart_search_index_course_#{course.global_id}").index_course(course)

        [course.search_embedding_version.present?, indexing_progress(course)]
      end
    end

    def index_course(course)
      return if course.search_embedding_version == EMBEDDING_VERSION

      # TODO: investigate pipelining this after we switch to Bedrock
      index_scopes(course).each do |scope|
        scope.left_joins(:embeddings)
             .group("#{scope.table_name}.id")
             .having("COALESCE(MAX(#{scope.embedding_class.table_name}.version), 0) < ?", EMBEDDING_VERSION)
             .find_each(strategy: :pluck_ids) do |item|
          item.generate_embeddings(synchronous: true)
        end
      end

      course.update!(search_embedding_version: EMBEDDING_VERSION)

      # TODO: implement this when we add a second embeddings version
      # delay_if_production(priority: Delayed::LOW_PRIORITY).delete_old_embeddings(course)
    end

    def delete_old_embeddings(course)
      index_scopes(course).each do |scope|
        scope.embedding_class
             .where(scope.embedding_foreign_key => scope.except(:order).select(:id))
             .where(version: ...EMBEDDING_VERSION)
             .in_batches
             .delete_all
      end
      nil
    end

    def indexing_progress(course)
      return 100 if course.search_embedding_version == EMBEDDING_VERSION

      total = 0
      indexed = 0
      index_scopes(course).each do |scope|
        n, i = scope.except(:order).left_joins(:embeddings).pick(Arel.sql(<<~SQL.squish))
          COUNT(DISTINCT #{scope.table_name}.id),
          COUNT(DISTINCT CASE WHEN #{scope.embedding_class.table_name}.version = #{EMBEDDING_VERSION} THEN #{scope.table_name}.id END)
        SQL
        total += n
        indexed += i
      end

      (indexed * 100.0 / total).to_i
    end
  end
end
