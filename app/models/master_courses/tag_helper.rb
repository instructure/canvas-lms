# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module MasterCourses::TagHelper
  # may as well just reuse the code
  def self.included(klass)
    klass.cattr_accessor :content_tag_association
  end

  def content_tags
    send(content_tag_association)
  end

  def load_tags!(objects = nil)
    return if @content_tag_index && !objects # if we already loaded everything don't worry

    @content_tag_index ||= {}
    tag_scope = content_tags

    if objects
      return unless objects.any?

      objects_to_load = objects.map { |o| (o.is_a?(Assignment) && o.submittable_object) || o }
      tag_scope = tag_scope.where(content: objects_to_load)
    end
    tag_scope.to_a.group_by(&:content_type).each do |content_type, typed_tags|
      index_type = (content_type == "Assignment") ? "AbstractAssignment" : content_type
      @content_tag_index[index_type] = typed_tags.index_by(&:content_id).merge(@content_tag_index[index_type] || {})
    end
    true
  end

  def content_tag_for(content, defaults = {})
    return unless MasterCourses::ALLOWED_CONTENT_TYPES.include?(content.class.base_class.name)

    if content.is_a?(Assignment) && (submittable = content.submittable_object)
      content = submittable # use one child tag
    end
    return unless content&.persisted?

    if @content_tag_index
      tag = (@content_tag_index[content.class.base_class.name] || {})[content.id]
      unless tag
        tag = create_content_tag_for!(content, defaults)
        @content_tag_index[content.class.base_class.name] ||= {}
        @content_tag_index[content.class.base_class.name][content.id] = tag
      end
      tag
    else
      content_tags.where(content:).first || create_content_tag_for!(content, defaults)
    end
  end

  def create_content_tag_for!(content, defaults = {})
    return if content.is_a?(Assignment) && Assignment::SUBMITTABLE_TYPES.include?(content.submission_types)

    self.class.unique_constraint_retry do |retry_count|
      tag = nil
      tag = content_tags.where(content:).first if retry_count > 0
      tag ||= content_tags.create!(defaults.merge(content:))
      tag
    end
  end

  def cached_content_tag_for(content)
    raise "must call `load_tags!` first" unless @content_tag_index

    if content.is_a?(Assignment) && (submittable = content.submittable_object)
      content = submittable # use one child tag
    end
    @content_tag_index.dig(content.class.base_class.name, content.id)
  end
end
