# frozen_string_literal: true

# Copyright (C) 2024 - present Instructure, Inc.
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

# to add smart search to a model:
#  1. `include SmartSearchable`
#  2. `use_smart_search` and supply the title and body columns
#     as well as the scopes used for indexing (->(course) {...})
#     and searching (->(course, user), {...})
#  3. create the embeddings model and table (with fk/index)

# model requirements:
#  1. Course association
#  2. uses Workflow
#  3. SoftDeletable

module SmartSearchable
  def self.included(klass)
    klass.class_eval do
      extend ClassMethods
    end
  end

  module ClassMethods
    def use_smart_search(title_column:, body_column:, index_scope:, search_scope:)
      class_eval do
        include HtmlTextHelper
        has_many :embeddings, class_name: embedding_class_name, inverse_of: table_name.singularize.to_sym
        cattr_accessor :search_title_column, :search_body_column
        after_save :generate_embeddings, if: :should_generate_embeddings?
        after_save :delete_embeddings, if: -> { deleted? && saved_change_to_workflow_state? }
      end
      self.search_title_column = title_column.to_s
      self.search_body_column = body_column.to_s
      SmartSearch.register_class(self, index_scope, search_scope)
    end

    def embedding_class_name
      "#{class_name}Embedding"
    end

    def embedding_class
      @embedding_class ||= embedding_class_name.constantize
    end

    def embedding_foreign_key
      @embedding_fk ||= :"#{table_name.singularize}_id"
    end
  end

  def should_generate_embeddings?
    return false if deleted?
    return false unless SmartSearch.smart_search_available?(context)

    saved_changes.key?(self.class.search_title_column) || saved_changes.key?(self.class.search_body_column) ||
      (saved_change_to_workflow_state? && workflow_state_before_last_save == "deleted")
  end

  def generate_embeddings
    delete_embeddings
    chunk_content do |chunk|
      embedding = SmartSearch.generate_embedding(chunk)
      embeddings.create!(embedding:)
    end
  end
  handle_asynchronously :generate_embeddings, priority: Delayed::LOW_PRIORITY

  def chunk_content(max_character_length = 4000)
    title = attributes[self.class.search_title_column]
    content = body_text
    if content.length > max_character_length
      # Chunk
      # Hard split on character length, back up to the nearest word boundary
      remaining_text = content
      while remaining_text
        # Find the last space before the max length
        last_space = remaining_text.rindex(/\b/, max_character_length)
        if last_space.nil? || last_space < max_character_length / 2
          # No space found, or no space found in a reasonable distance, so just split at max length
          last_space = max_character_length
        end
        # include the title in each chunk
        yield title + "\n" + remaining_text[0..last_space]
        remaining_text = remaining_text[(last_space + 1)..]
      end
    else
      # No need for chunking
      yield title + "\n" + content
    end
  end

  def body_text
    html_to_text(attributes[self.class.search_body_column])
  end

  def delete_embeddings
    return unless ActiveRecord::Base.connection.table_exists?(self.class.embedding_class.table_name)

    # TODO: delete via the association once pgvector is available everywhere
    # (without :dependent, that would try to nullify the fk in violation of the constraint
    #  but with :dependent, instances without pgvector would try to access the nonexistent table when a page is deleted)
    shard.activate do
      self.class.embedding_class.where(self.class.embedding_foreign_key => self).delete_all
    end
  end
end
