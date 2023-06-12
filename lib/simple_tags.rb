# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

module SimpleTags
  module ReaderInstanceMethods
    def tags
      @tag_array ||= read_attribute(:tags)&.split(",") || []
    end

    def serialized_tags(tags = self.tags)
      SimpleTags.normalize_tags(tags).join(",")
    end

    def self.included(klass)
      klass.extend ClassMethods
    end
  end

  module ClassMethods
    def tagged(*tags)
      options = tags.last.is_a?(Hash) ? tags.pop : {}
      options[:mode] ||= :or
      conditions = handle_tags(tags, options) +
                   tags.map do |tag|
                     wildcard(ConversationParticipant.quoted_table_name + ".tags", tag, delimiter: ",")
                   end
      if conditions.empty?
        none
      else
        where(conditions.join((options[:mode] == :or) ? " OR " : " AND "))
      end
    end

    def tagged_scope_handler(pattern, &block)
      @tagged_scope_handlers ||= []
      @tagged_scope_handlers << [pattern, block]
    end

    protected

    def handle_tags(tags, options)
      return [] unless @tagged_scope_handlers

      @tagged_scope_handlers.inject([]) do |result, (pattern, handler)|
        handler_tags = []
        tags.delete_if do |tag|
          handler_tags << tag and true if tag&.match?(pattern)
        end
        result.concat handler_tags.present? ? [handler.call(handler_tags, options)].flatten : []
      end
    end
  end

  module WriterInstanceMethods
    def self.included(klass)
      klass.before_save :serialize_tags
    end

    def tags=(new_tags)
      tags_will_change! unless tags == new_tags
      @tag_array = new_tags || []
    end

    def reload(*args)
      remove_instance_variable :@tag_array if @tag_array
      super
    end

    protected

    def serialize_tags
      if @tag_array
        write_attribute(:tags, serialized_tags)
        remove_instance_variable :@tag_array
      end
    end
  end

  def self.normalize_tags(tags)
    tags.each_with_object([]) do |tag, ary|
      case tag
      when /\A((course|group)_\d+).*/
        ary << $1
      when /\Asection_(\d+).*/
        section = CourseSection.where(id: $1).first
        ary << section.course.asset_string if section
        # TODO: allow user-defined tags, e.g. #foo
      end
    end.uniq
  end

  def self.included(klass)
    klass.include ReaderInstanceMethods
    klass.include WriterInstanceMethods
  end
end
