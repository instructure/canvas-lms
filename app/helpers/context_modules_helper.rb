# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module ContextModulesHelper
  include CyoeHelper
  include ApplicationHelper

  def cache_if_module(context_module, viewable, can_add, can_edit, can_delete, is_student, can_view_unpublished, user, context, &)
    if context_module && !module_performance_improvement_is_enabled?(context, user)
      visible_assignments = user ? user.learning_object_visibilities(context) : []
      cache_key_items = ["context_module_render_22_",
                         context_module.cache_key,
                         viewable,
                         can_add,
                         can_edit,
                         can_delete,
                         is_student,
                         can_view_unpublished,
                         @module_ids_with_overrides&.include?(context_module.id),
                         true,
                         Time.zone,
                         Digest::SHA256.hexdigest([visible_assignments, @section_visibility].join("/"))]
      cache_key = cache_key_items.join("/")
      cache_key = add_menu_tools_to_cache_key(cache_key)
      cache_key = add_mastery_paths_to_cache_key(cache_key, context, user)
      cache(cache_key, {}, &)
    else
      yield
    end
  end

  def cache_if_no_module_perf_enabled(cache_key, context, user, &)
    if module_performance_improvement_is_enabled?(context, user)
      # No caching
      yield
    else
      cache(cache_key, {}, &)
    end
  end

  def module_performance_improvement_is_enabled?(context, current_user)
    return false unless context
    return false unless current_user

    feature_flag = context.account.feature_enabled?(:modules_perf)
    return false unless feature_flag

    tags_count = GuardRail.activate(:secondary) { context.module_items_visible_to(current_user).count }
    module_perf_threshold = Setting.get("module_perf_threshold", 100).to_i
    feature_flag && (tags_count > module_perf_threshold) # && request.path.include?("/modules")
  end

  def add_menu_tools_to_cache_key(cache_key)
    tool_key = @menu_tools ? @menu_tools.values.flatten.map(&:cache_key).join("/") : ""
    cache_key += Digest::SHA256.hexdigest(tool_key) if tool_key.present?
    # should leave it alone if there are no tools
    cache_key
  end

  def add_mastery_paths_to_cache_key(cache_key, context, user)
    if user && cyoe_enabled?(context)
      if context.user_is_student?(user)
        rules = cyoe_rules(context, user, @session)
        cache_key += "/mastery:" + Digest::SHA256.hexdigest(rules.to_s)
        cache_key += "/mastery_actions:" + Digest::SHA256.hexdigest(assignment_set_action_ids(rules, user).to_s)
      else
        rules = ConditionalRelease::Service.active_rules(context, user, @session)
        cache_key += "/mastery:" + Digest::SHA256.hexdigest(rules.to_s)
      end
    end
    cache_key
  end

  def preload_can_unpublish(context, modules)
    items = modules.map(&:content_tags).flatten.map(&:content)
    asmnts = items.select { |item| item.is_a?(Assignment) }
    topics = items.select { |item| item.is_a?(DiscussionTopic) }
    quizzes = items.select { |item| item.is_a?(Quizzes::Quiz) }
    wiki_pages = items.select { |item| item.is_a?(WikiPage) }

    assmnt_ids_with_subs = Assignment.assignment_ids_with_submissions(context.assignments.pluck(:id))
    Assignment.preload_can_unpublish(asmnts, assmnt_ids_with_subs)
    DiscussionTopic.preload_can_unpublish(context, topics, assmnt_ids_with_subs)
    Quizzes::Quiz.preload_can_unpublish(quizzes, assmnt_ids_with_subs)
    WikiPage.preload_can_unpublish(context, wiki_pages)
  end

  def module_item_publishable_id(item)
    if item.nil?
      ""
    elsif item.content_type == "WikiPage"
      item.content.url
    else
      (item.content.respond_to?(:published?) ? item.content.id : item.id)
    end
  end

  def module_item_publishable?(item)
    return true if item.nil? || !item.content || !item.content.respond_to?(:can_publish?)

    item.content.can_publish?
  end

  def module_item_publish_at(item)
    (item&.content.respond_to?(:publish_at) && item.content.publish_at&.iso8601) || nil
  end

  def prerequisite_list(prerequisites)
    prerequisites.pluck(:name).join(", ")
  end

  def module_item_unpublishable?(item)
    return true if item.nil? || !item.content || !item.content.respond_to?(:can_unpublish?)

    item.content.can_unpublish?
  end

  def preload_modules_content(modules)
    modules.each_slice(1000) do |slice|
      ActiveRecord::Associations.preload(slice, content_tags: { content: %i[context external_tool_tag current_lookup wiki] })
      assignmentable_content = slice.map(&:content_tags).flatten.select(&:can_have_assignment?)
      ActiveRecord::Associations.preload(assignmentable_content, content: { assignment: :context }) unless assignmentable_content.empty?
    end
    preload_can_unpublish(@context, modules) if @can_view
  end

  def load_content_tags(context_module, current_user)
    items = context_module.content_tags_visible_to(current_user)
    items.reject do |item|
      item.content.respond_to?(:hide_on_modules_view?) && item.content.hide_on_modules_view?
    end
  end

  def process_module_data(mod, current_user = nil, session = nil, student: false)
    items = load_content_tags(mod, current_user)
    process_module_items_data(items, mod, current_user, session, student:)
  end

  def process_module_items_data(items, mod, current_user = nil, session = nil, student: false)
    module_data = {
      published_status: mod.published? ? "published" : "unpublished",
      items:
    }

    if cyoe_enabled?(@context)
      rules = cyoe_rules(@context, current_user, session) || []
    end

    items_data = {}
    module_data[:items].each do |item|
      # pre-calculated module item view data can be added here
      item_data = {
        published_status: item.published? ? "published" : "unpublished",
      }

      if cyoe_enabled?(@context)
        path_opts = { conditional_release_rules: rules, is_student: student }
        item_data[:mastery_paths] = conditional_release_rule_for_module_item(item, path_opts)
        if student && item_data[:mastery_paths].present?
          item_data[:show_cyoe_placeholder] = show_cyoe_placeholder(item_data[:mastery_paths])
          item_data[:choose_url] = context_url(@context, :context_url) + "/modules/items/" + item.id.to_s + "/choose"
        end
      end

      items_data[item.id] = item_data
    end

    module_data[:items_data] = items_data

    if @is_child_course && !student &&
       @context.account.feature_enabled?(:modules_page_hide_blueprint_lock_icon_for_children)
      module_data[:items_restrictions] =
        MasterCourses::MasterContentTag.fetch_module_item_restrictions_for_child(module_data[:items].map(&:id))
      module_data[:items_restrictions].transform_values!(&:any?)
    end
    module_data
  end

  def module_item_translated_content_type(item, student: false)
    return "" unless item
    if item.content_type_class == "lti-quiz"
      return student ? I18n.t("Quiz") : I18n.t("New Quiz")
    end

    Context.translated_content_type(item.content_type)
  end
end
