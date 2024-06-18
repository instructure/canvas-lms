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
require "aws-sdk-bedrockruntime"

module SmartSearch
  EMBEDDING_VERSION = 2
  CHUNK_MAX_LENGTH = 1500

  class << self
    def api_key
      Rails.application.credentials.dig(:smart_search, :openai_api_token)
    end

    def bedrock_client
      return @bedrock_client if instance_variable_defined?(:@bedrock_client)

      # for local dev, assume that we are using creds from inseng (us-west-2)
      settings = YAML.safe_load(DynamicSettings.find(tree: :private)["bedrock.yml"] || "{}")
      config = {
        region: settings["bedrock_region"] || "us-west-2"
      }
      # Will load creds from vault (prod) or rails credential store (local / oss).
      # Credentials stored in rails credential store in the `bedrock_creds` key
      # with `aws_access_key_id` and `aws_secret_access_key` keys
      config[:credentials] = Canvas::AwsCredentialProvider.new("bedrock_creds", settings["vault_credential_path"])
      @bedrock_client = if config[:credentials].set?
                          Aws::BedrockRuntime::Client.new(config)
                        end
    end

    def smart_search_available?(context)
      context&.feature_enabled?(:smart_search) && bedrock_client.present?
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

    def generate_embedding(input, query: false, version: EMBEDDING_VERSION)
      case version
      when 1
        generate_embedding_v1(input)
      when 2
        generate_embedding_v2(input, query)
      else
        raise ArgumentError, "Unsupported embedding version #{version}"
      end
    end

    def generate_embedding_v1(input)
      # NOTE: openai does not differentiate between query and document embeddings
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

    def generate_embedding_v2(input, query)
      resp = bedrock_client.invoke_model({
                                           content_type: "application/json",
                                           accept: "application/json",
                                           model_id: "cohere.embed-multilingual-v3",
                                           body: {
                                             texts: [input],
                                             input_type: query ? "search_query" : "search_document"
                                           }.to_json,
                                         })
      json = JSON.parse(resp.body.string)
      json["embeddings"][0]
    end

    def perform_search(context, user, query, type_filter = [])
      version = context.search_embedding_version || EMBEDDING_VERSION
      embedding = SmartSearch.generate_embedding(query, version:, query: true)
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

    def result_relevance(object)
      version = object.context.try(:search_embeddings_version) || EMBEDDING_VERSION
      case version
      when 1
        (100.0 * (1.0 - object.distance)).round
      when 2
        # this function stretches out the useful range of distances;
        # otherwise everything would be 40-60% relevant using the old formula
        (100.0 * ((2.0 / (1.0 + Math.exp(-18.0 * ((1.0 - object.distance)**3)))) - 1.0)).round
      end
    end

    def up_to_date?(course)
      smart_search_available?(course) && course.search_embedding_version == SmartSearch::EMBEDDING_VERSION
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

      # TODO: investigate pipelining this
      index_scopes(course).each do |scope|
        scope.left_joins(:embeddings)
             .group("#{scope.table_name}.id")
             .having("COALESCE(MAX(#{scope.embedding_class.table_name}.version), 0) < ?", EMBEDDING_VERSION)
             .find_each(strategy: :pluck_ids) do |item|
          item.generate_embeddings(synchronous: true)
        end
      end

      course.update!(search_embedding_version: EMBEDDING_VERSION)
      delay_if_production(priority: Delayed::LOW_PRIORITY).delete_old_embeddings(course)
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

    def copy_embeddings(content_migration)
      return unless content_migration.for_course_copy? &&
                    content_migration.source_course&.search_embedding_version == EMBEDDING_VERSION &&
                    SmartSearch.smart_search_available?(content_migration.context)

      content_migration.imported_asset_id_map&.each do |class_name, id_mapping|
        klass = class_name.constantize
        next unless klass.respond_to?(:embedding_class)

        fk = klass.embedding_foreign_key # i.e. :wiki_page_id

        content_migration.context.shard.activate do
          klass.embedding_class
               .where(:version => EMBEDDING_VERSION, fk => id_mapping.values)
               .in_batches
               .delete_all
        end

        content_migration.source_course.shard.activate do
          klass.embedding_class.where(:version => EMBEDDING_VERSION, fk => id_mapping.keys)
               .find_in_batches(batch_size: 50) do |src_embeddings|
            dest_embeddings = src_embeddings.map do |src_embedding|
              {
                :embedding => src_embedding.embedding,
                fk => id_mapping[src_embedding[fk]],
                :version => EMBEDDING_VERSION,
                :root_account_id => content_migration.context.root_account_id,
                :created_at => Time.now.utc,
                :updated_at => Time.now.utc
              }
            end

            content_migration.context.shard.activate do
              klass.embedding_class.insert_all(dest_embeddings)
            end
          end
        end
      end
    end
  end
end
