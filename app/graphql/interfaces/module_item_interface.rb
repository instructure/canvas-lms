# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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
module Interfaces::ModuleItemInterface
  include Interfaces::BaseInterface

  description "An item that can be in context modules"

  field :modules, [Types::ModuleType], null: true
  def modules
    Loaders::IDLoader.for(ContentTag).load_many(@object.context_module_tag_ids).then do |cts|
      Loaders::AssociationLoader.for(ContentTag, :context_module).load_many(cts).then do |modules|
        modules.sort_by(&:position)
      end
    end
  end

  field :can_duplicate, Boolean, null: true
  def can_duplicate
    if object.respond_to?(:can_duplicate?)
      if object.is_a?(Assignment)
        # Use loader to batch load external_tool_tag associations
        Loaders::AssignmentExternalToolTagLoader.for.load(object.id).then do |external_tool_tag|
          # Set the association target to prevent re-querying
          if external_tool_tag
            object.association(:external_tool_tag).target = external_tool_tag
          else
            object.association(:external_tool_tag).loaded!
          end
          object.can_duplicate?
        end
      else
        object.can_duplicate?
      end
    else
      object.is_a?(DiscussionTopic) || object.is_a?(WikiPage)
    end
  end

  field :can_manage_assign_to, Boolean, null: true
  def can_manage_assign_to
    is_differentiable_type = ["Assignment", "Quizzes::Quiz", "WikiPage"].include?(object.class.name) || (object.is_a?(DiscussionTopic) && (object.graded? || (!object.graded? && object.group_category_id.blank?)))
    object.grants_right?(current_user, :manage_assign_to) && is_differentiable_type
  end

  field :is_locked_by_master_course, Boolean, null: false
  def is_locked_by_master_course
    # First check if we're in a course context
    course = @object.context if @object.respond_to?(:context)
    return false unless course.is_a?(Course)

    # Check if this is a master course or child course
    is_master_course = MasterCourses::MasterTemplate.is_master_course?(course)
    is_child_course = MasterCourses::ChildSubscription.is_child_course?(course)
    return false unless is_master_course || is_child_course

    # For master courses, find the master content tag directly
    if is_master_course
      master_template = MasterCourses::MasterTemplate.full_template_for(course)
      return false unless master_template

      # Find the content tag for this item
      master_tag = master_template.content_tag_for(@object)
      return false unless master_tag

      return master_tag.restrictions.present? && master_tag.restrictions.values.any?
    end

    # For child courses, we need to find the child subscription and then the master content tag
    if is_child_course
      # Check if this item has a migration_id (which links it to the master course item)
      return false unless @object.respond_to?(:migration_id) && @object.migration_id.present?

      # Find the child subscription
      child_subscription = MasterCourses::ChildSubscription.find_by(child_course_id: course.id)
      return false unless child_subscription

      # Get the master template and find the master content tag through the migration_id
      master_template = child_subscription.master_template
      master_tag = master_template.master_content_tags.find_by(migration_id: @object.migration_id)
      return false unless master_tag

      return master_tag.restrictions.present? && master_tag.restrictions.values.any?
    end

    false
  end

  field :title, String, null: true
  delegate :title, to: :@object

  field :type, String, null: true
  def type
    @object.class.name
  end

  field :points_possible, Float, null: true
  def points_possible
    @object.try(:points_possible)
  end

  field :published, Boolean, null: true do
    description "Whether the module item is published"
  end
  def published
    object.published?
  end

  field :can_unpublish, Boolean, null: true do
    description "Whether the module item can be unpublished"
  end
  def can_unpublish
    if object.is_a?(WikiPage)
      Loaders::WikiPageLoaders::CanUnpublishLoader.for(object.context).load(object.id)
    elsif object.is_a?(DiscussionTopic)
      Loaders::DiscussionTopicLoaders::CanUnpublishLoader.for(object.context).load(object.id)
    elsif object.respond_to?(:can_unpublish?)
      if object.is_a?(Assignment)
        # Use loader to batch load submission existence check
        Loaders::AssignmentHasSubmissionsLoader.for.load(object.id).then do |has_submissions|
          # Set cache for both methods that check submission existence
          object.instance_variable_set(:@has_student_submissions, has_submissions)
          object.instance_variable_set(:@has_submitted_submissions, has_submissions)
          object.can_unpublish?
        end
      else
        object.can_unpublish?
      end
    else
      true
    end
  end

  field :graded, Boolean, null: true

  def graded
    if @object.respond_to?(:graded?)
      @object.graded?
    else
      false
    end
  end
end
