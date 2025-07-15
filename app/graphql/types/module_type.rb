# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

class ModuleItemsVisibleLoader < GraphQL::Batch::Loader
  def initialize(user)
    super()
    @user = user
  end

  def perform(context_modules)
    GuardRail.activate(:secondary) do
      ActiveRecord::Associations.preload(context_modules, content_tags: { content: :context })

      # Collect all quizzes across all modules to batch the preload_can_unpublish call
      all_quizzes = []
      context_modules.each do |context_module|
        content_tags = context_module.content_tags_visible_to(@user)
        content_items = content_tags.filter_map(&:content)
        quizzes = content_items.select { |item| item.is_a?(Quizzes::Quiz) }
        all_quizzes.concat(quizzes)
      end

      # Batch preload can_unpublish for all quizzes at once
      unless all_quizzes.empty?
        assmnt_ids_with_subs = Assignment.assignment_ids_with_submissions(all_quizzes.filter_map(&:assignment_id))
        Quizzes::Quiz.preload_can_unpublish(all_quizzes, assmnt_ids_with_subs)
      end

      context_modules.each do |context_module|
        content_tags = context_module.content_tags_visible_to(@user)
        fulfill(context_module, content_tags)
      end
    end
  end
end

class ModuleProgressionLoader < GraphQL::Batch::Loader
  def initialize(user, session, context)
    super()
    @user = user
    @session = session
    @context = context
  end

  def perform(context_modules)
    GuardRail.activate(:secondary) do
      if is_student?
        # Batch create progressions for enrolled modules to avoid N+1
        enrolled_modules = get_enrolled_modules(context_modules)
        batch_create_progressions(enrolled_modules)

        # Evaluate modules with pre-created progressions
        context_modules.each { |m| m.evaluate_for(@user) }
      end

      progressions = ContextModuleProgression.where(
        context_module_id: context_modules.map(&:id),
        user_id: @user&.id
      ).index_by(&:context_module_id)
      context_modules.each do |context_module|
        progression = progressions[context_module.id]
        fulfill(context_module, progression)
      end
    end
  end

  private

  def get_enrolled_modules(context_modules)
    return ContextModule.none unless @user && @context

    module_ids = context_modules.map(&:id)

    ContextModule.where(id: module_ids)
                 .where(
                   Enrollment.where("enrollments.course_id = context_modules.context_id")
                            .where(user_id: @user.id)
                            .arel.exists
                 )
  end

  def batch_create_progressions(enrolled_modules_relation)
    return unless @user
    return if enrolled_modules_relation.respond_to?(:empty?) && enrolled_modules_relation.empty?

    # Batch create progressions for all enrolled modules with proper shard activation
    enrolled_modules_relation.find_each do |context_module|
      context_module.shard.activate do
        GuardRail.activate(:primary) do
          ContextModuleProgression.create_and_ignore_on_duplicate(
            user: @user,
            context_module:
          )
        end
      end
    end
  end

  def is_student?
    @context.grants_right?(@user, @session, :participate_as_student)
  end
end

module Types
  class ModuleType < ApplicationObjectType
    graphql_name "Module"

    implements GraphQL::Types::Relay::Node
    implements Interfaces::TimestampInterface
    implements Interfaces::LegacyIDInterface

    class ModulePrerequisiteType < ApplicationObjectType
      field :id, ID, null: false
      field :name, String, null: false
      field :type, String, null: false
    end

    class ModuleCompletionRequirementType < ApplicationObjectType
      field :id, ID, null: false
      field :min_percentage, Float, null: true
      field :min_score, Float, null: true
      field :type, String, null: false
    end

    alias_method :context_module, :object

    global_id_field :id

    field :name, String, null: true

    field :unlock_at, DateTimeType, null: true

    field :position, Integer, null: true

    field :prerequisites, [ModulePrerequisiteType], null: true
    delegate :prerequisites, to: :context_module

    field :require_sequential_progress, Boolean, null: true

    field :completion_requirements, [ModuleCompletionRequirementType], null: true
    def completion_requirements
      ModuleItemsVisibleLoader.for(current_user).load(context_module).then do |_|
        context_module.completion_requirements_visible_to(current_user, is_teacher: false)
      end
    end

    field :requirement_count, Integer, null: true
    delegate :requirement_count, to: :context_module

    field :published, Boolean, null: true, method: :published?

    field :module_items, [Types::ModuleItemType], null: true
    def module_items
      ModuleItemsVisibleLoader.for(current_user).load(context_module)
    end

    field :module_items_connection, Types::ModuleItemType.connection_type, null: true do
      argument :filter, Types::ModuleItemFilterInputType, required: false
    end

    def module_items_connection(filter: {})
      ModuleItemsVisibleLoader.for(current_user).load(context_module).then do |content_tags|
        # Apply filtering if provided
        filtered_tags = apply_module_item_filters(content_tags, filter)
        # Return the array directly - GraphQL will handle connection structure
        filtered_tags
      end
    end

    field :module_items_total_count, Integer, null: false
    def module_items_total_count
      ModuleItemsVisibleLoader.for(current_user).load(context_module).then(&:size)
    end

    field :submission_statistics, Types::ModuleStatisticsType, null: true
    def submission_statistics
      if current_user
        Loaders::ModuleStatisticsLoader.for(current_user:).load(context_module)
      else
        {}
      end
    end

    field :estimated_duration, GraphQL::Types::ISO8601Duration, null: true
    def estimated_duration
      module_items.then do |content_tags|
        return nil if content_tags.all?(&:estimated_duration).nil?

        content_tags.sum { |item| item.estimated_duration&.duration || 0 }.iso8601
      end
    end

    field :progression, Types::ModuleProgressionType, null: true, description: "The current user's progression through the module"
    def progression
      ModuleProgressionLoader.for(current_user, session, context_module.context).load(context_module)
    end

    field :has_active_overrides, Boolean, null: false

    def has_active_overrides
      Loaders::ModuleActiveOverridesLoader.for.load(object)
    end

    private

    def apply_module_item_filters(content_tags, filter)
      return content_tags if filter.blank?

      filtered_tags = content_tags.dup

      if filter[:search_term].present?
        search_term = filter[:search_term].downcase
        filtered_tags = filtered_tags.select do |tag|
          tag.title&.downcase&.include?(search_term) ||
            tag.content&.title&.downcase&.include?(search_term)
        end
      end

      if filter[:published].present?
        filtered_tags = filtered_tags.select do |tag|
          # Check both the tag and its content's published status
          tag_published = tag.published?
          content_published = tag.content&.published? if tag.content.respond_to?(:published?)
          # If content has a published? method, use that; otherwise use tag's status
          actual_published = content_published.nil? ? tag_published : content_published
          actual_published == filter[:published]
        end
      end

      if filter[:content_type].present?
        filtered_tags = filtered_tags.select do |tag|
          tag.content_type == filter[:content_type]
        end
      end

      filtered_tags
    end
  end
end
