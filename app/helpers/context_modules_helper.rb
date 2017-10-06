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
  include Api::V1::ContextModule
  include CyoeHelper

  TRANSLATED_COMMENT_TYPE = {
    'Announcement': I18n.t('Announcement'),
    'Assignment': I18n.t('Assignment'),
    'Attachment': I18n.t('Attachment'),
    'ContextExternalTool': I18n.t('External Tool'),
    'ContextModuleSubHeader': I18n.t('Context Module Sub Header'),
    'DiscussionTopic': I18n.t('Discussion Topic'),
    'ExternalUrl': I18n.t('External Url'),
    'Quiz': I18n.t('Quiz'),
    'Quizzes::Quiz': I18n.t('Quiz'),
    'WikiPage': I18n.t('Wiki Page')
  }.freeze

  def cache_if_module(context_module, editable, is_student, can_view_unpublished, user, context, &block)
    if context_module
      visible_assignments = user ? user.assignment_and_quiz_visibilities(context) : []
      cache_key_items = ['context_module_render_20_', context_module.cache_key, editable, is_student, can_view_unpublished, true, Time.zone, Digest::MD5.hexdigest(visible_assignments.to_s)]
      cache_key = cache_key_items.join('/')
      cache_key = add_menu_tools_to_cache_key(cache_key)
      cache_key = add_mastery_paths_to_cache_key(cache_key, context, context_module, user)
      cache(cache_key, {}, &block)
    else
      yield
    end
  end

  def add_menu_tools_to_cache_key(cache_key)
    tool_key = @menu_tools && @menu_tools.values.flatten.map(&:cache_key).join("/")
    cache_key += Digest::MD5.hexdigest(tool_key) if tool_key.present?
    # should leave it alone if there are no tools
    cache_key
  end

  def add_mastery_paths_to_cache_key(cache_key, context, module_or_modules, user)
    if user && cyoe_enabled?(context)
      if context.user_is_student?(user)
        items = Rails.cache.fetch("visible_content_tags_for/#{cache_key}") do
          Array.wrap(module_or_modules).map{ |m| m.content_tags_visible_to(user, :is_teacher => false) }.flatten
        end
        rules = cyoe_rules(context, user, items, @session)
      else
        rules = ConditionalRelease::Service.active_rules(context, user, @session)
      end
      cache_key += '/mastery:' + Digest::MD5.hexdigest(rules.to_s)
    end
    cache_key
  end

  def preload_can_unpublish(context, modules)
    items = modules.map(&:content_tags).flatten.map(&:content)
    asmnts = items.select{|item| item.is_a?(Assignment)}
    topics = items.select{|item| item.is_a?(DiscussionTopic)}
    quizzes = items.select{|item| item.is_a?(Quizzes::Quiz)}
    wiki_pages = items.select{|item| item.is_a?(WikiPage)}

    assmnt_ids_with_subs = Assignment.assignment_ids_with_submissions(context.assignments.pluck(:id))
    Assignment.preload_can_unpublish(asmnts, assmnt_ids_with_subs)
    DiscussionTopic.preload_can_unpublish(context, topics, assmnt_ids_with_subs)
    Quizzes::Quiz.preload_can_unpublish(quizzes, assmnt_ids_with_subs)
    WikiPage.preload_can_unpublish(context, wiki_pages)
  end

  def module_item_publishable_id(item)
    if item.nil?
      ''
    elsif (item.content_type == 'WikiPage')
      item.content.url
    else
      (item.content && item.content.respond_to?(:published?) ? item.content.id : item.id)
    end
  end

  def module_item_publishable?(item)
    true
  end

  def prerequisite_list(prerequisites)
    prerequisites.map {|p| p[:name]}.join(', ')
  end

  def module_item_unpublishable?(item)
    return true if item.nil? || !item.content || !item.content.respond_to?(:can_unpublish?)
    item.content.can_unpublish?
  end

  def preload_modules_content(modules, can_edit)
    ActiveRecord::Associations::Preloader.new.preload(modules, :content_tags => :content)
    preload_can_unpublish(@context, modules) if can_edit
  end

  def process_module_data(mod, is_student = false, current_user = nil, session = nil)
    # pre-calculated module view data can be added here
    module_data = {
      published_status: mod.published? ? 'published' : 'unpublished',
      items: mod.content_tags_visible_to(@current_user)
    }

    if cyoe_enabled?(@context)
      rules = cyoe_rules(@context, current_user, module_data[:items], session) || []
    end

    items_data = {}
    module_data[:items].each do |item|
      # pre-calculated module item view data can be added here
      item_data = {
        published_status: item.published? ? 'published' : 'unpublished',
      }

      if cyoe_enabled?(@context)
        path_opts = { conditional_release_rules: rules, is_student: is_student }
        item_data[:mastery_paths] = conditional_release_rule_for_module_item(item, path_opts)
        if is_student && item_data[:mastery_paths].present?
          item_data[:show_cyoe_placeholder] = show_cyoe_placeholder(item_data[:mastery_paths])
          item_data[:choose_url] = context_url(@context, :context_url) + '/modules/items/' + item.id.to_s + '/choose'
        end
      end

      items_data[item.id] = item_data
    end

    module_data[:items_data] = items_data
    return module_data
  end

  def module_item_translated_content_type(item)
    return '' unless item
    TRANSLATED_COMMENT_TYPE[item.content_type.to_sym] || I18n.t('Unknown Content Type')
  end
end
