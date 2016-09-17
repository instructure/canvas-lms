#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::ContextModule
  include Api::V1::Json
  include Api::V1::User
  include Api::V1::ExternalTools::UrlHelpers
  include Api::V1::Locked
  include Api::V1::Assignment

  MODULE_JSON_ATTRS = %w(id position name unlock_at)

  MODULE_ITEM_JSON_ATTRS = %w(id position title indent)

  # optionally pass progression to include 'state', 'completed_at'
  def module_json(context_module, current_user, session, progression = nil, includes = [], opts = {})
    hash = api_json(context_module, current_user, session, :only => MODULE_JSON_ATTRS)
    hash['require_sequential_progress'] = !!context_module.require_sequential_progress?
    hash['publish_final_grade'] = context_module.publish_final_grade?
    hash['prerequisite_module_ids'] = context_module.prerequisites.reject{|p| p[:type] != 'context_module'}.map{|p| p[:id]}
    if progression
      hash['state'] = progression.workflow_state
      hash['completed_at'] = progression.completed_at
    end
    has_update_rights = context_module.grants_right?(current_user, :update)
    hash['published'] = context_module.active? if has_update_rights
    tags = context_module.content_tags_visible_to(@current_user,
      opts.slice(
        :assignment_visibilities,
        :discussion_visibilities,
        :page_visibilities,
        :quiz_visibilities,
        :observed_student_ids
      )
    )
    count = tags.count
    hash['items_count'] = count
    hash['items_url'] = polymorphic_url([:api_v1, context_module.context, context_module, :items])
    if includes.include?('items') && count <= Setting.get('api_max_per_page', '50').to_i
      if opts[:search_term].present? && !context_module.matches_attribute?(:name, opts[:search_term])
        tags = ContentTag.search_by_attribute(tags, :title, opts[:search_term])
        return nil if tags.count == 0
      end
      item_includes = includes & ['content_details']
      hash['items'] = tags.map do |tag|
        module_item_json(tag, current_user, session, context_module, progression, item_includes, :has_update_rights => has_update_rights)
      end
    end
    hash
  end

  # optionally pass context_module to avoid redundant queries when rendering multiple items
  # optionally pass progression to include completion status
  def module_item_json(content_tag, current_user, session, context_module = nil, progression = nil, includes = [], opts = {})
    context_module ||= content_tag.context_module

    hash = api_json(content_tag, current_user, session, :only => MODULE_ITEM_JSON_ATTRS)
    hash['type'] = Api::API_DATA_TYPE[content_tag.content_type] || content_tag.content_type

    hash['module_id'] = content_tag.context_module_id

    # add canvas web url
    unless content_tag.content_type == 'ContextModuleSubHeader'
      hash['html_url'] = case content_tag.content_type
        when 'ExternalUrl'
          if value_to_boolean(request.params[:frame_external_urls])
            # canvas UI wants external links hosted in iframe
            course_context_modules_item_redirect_url(:id => content_tag.id, :course_id => context_module.context.id)
          else
            # API prefers to redirect to the external page, rather than host in an iframe
            api_v1_course_context_module_item_redirect_url(:id => content_tag.id, :course_id => context_module.context.id)
          end
        else
          # otherwise we'll link to the same thing the web UI does
          course_context_modules_item_redirect_url(:id => content_tag.id, :course_id => context_module.context.id)
      end
    end

    # add content_id, if applicable
    # (note that wiki page ids are not exposed by the api)
    unless %w(WikiPage ContextModuleSubHeader ExternalUrl).include? content_tag.content_type
      hash['content_id'] = content_tag.content_id
    end

    if content_tag.content_type == 'WikiPage'
      hash['page_url'] = content_tag.content.url
    end

    # add data-api-endpoint link, if applicable
    api_url = nil
    case content_tag.content_type
      # course context
      when *Quizzes::Quiz.class_names
        api_url = api_v1_course_quiz_url(context_module.context, content_tag.content)
      when 'Assignment', 'WikiPage', 'DiscussionTopic'
        api_url = polymorphic_url([:api_v1, context_module.context, content_tag.content])
      # no context
      when 'Attachment'
        api_url = polymorphic_url([:api_v1, context_module.context, content_tag.content])
      when 'ContextExternalTool'
        if content_tag.content && content_tag.content.tool_id
          api_url = sessionless_launch_url(context_module.context, :id => content_tag.content.id, :url => (content_tag.url || content_tag.content.url))
        elsif content_tag.content
          api_url = sessionless_launch_url(context_module.context, :url => (content_tag.url || content_tag.content.url))
        else
          api_url = sessionless_launch_url(context_module.context, :url => content_tag.url)
        end
    end
    hash['url'] = api_url if api_url

    if ['ExternalUrl', 'ContextExternalTool'].include?(content_tag.content_type)
      # add external_url, if applicable
      hash['external_url'] = content_tag.url
      # add new_tab, if applicable
      hash['new_tab'] = content_tag.new_tab
    end

    # add completion requirements
    if criterion = context_module.completion_requirements && context_module.completion_requirements.detect { |r| r[:id] == content_tag.id }
      ch = { 'type' => criterion[:type] }
      ch['min_score'] = criterion[:min_score] if criterion[:type] == 'min_score'
      ch['completed'] = !!(progression.requirements_met.present? && progression.requirements_met.detect{|r|r[:type] == criterion[:type] && r[:id] == content_tag.id}) if progression
      hash['completion_requirement'] = ch
    end

    has_update_rights = if opts.has_key? :has_update_rights
                          opts[:has_update_rights]
                        else
                          context_module.grants_right?(current_user, :update)
                        end
    hash['published'] = content_tag.active? if has_update_rights

    hash['content_details'] = content_details(content_tag, current_user) if includes.include?('content_details')

    hash['mastery_paths'] = conditional_release(content_tag, opts) if includes.include?('mastery_paths')

    hash
  end

  def content_details(content_tag, current_user, opts = {})
    details = {}
    item = content_tag.content

    item = item.assignment if item.is_a?(DiscussionTopic) && item.assignment
    item = item.overridden_for(current_user) if item.respond_to?(:overridden_for)

    attrs = [:usage_rights, :thumbnail_url, :locked, :hidden, :lock_explanation, :display_name, :due_at, :unlock_at, :lock_at, :points_possible]
    attrs.delete(:thumbnail_url) if opts[:for_admin]

    attrs.each do |attr|
      if item.respond_to?(attr) && val = item.try(attr)
        details[attr] = val
      end
    end

    unless opts[:for_admin]
      item_type = case content_tag.content_type
                  when 'Quiz', 'Quizzes::Quiz'
                    'quiz'
                  when 'Assignment'
                    'assignment'
                  when 'DiscussionTopic'
                    'topic'
                  when 'Attachment'
                    'file'
                  when 'WikiPage'
                    'page'
                  else
                    ''
                end
      lock_item = item && item.respond_to?(:locked_for?) ? item : content_tag
      locked_json(details, lock_item, current_user, item_type)
    end

    details
  end

  def conditional_release(content_tag, opts = {})
    rules = opts[:conditional_release_rules]
    assignment_id = content_tag.content.try(:assignment_id) || content_tag.content_id
    conditional_release_assignment_set(rules, assignment_id) if rules.present? && assignment_id.present?
  end

  def conditional_release_assignment_set(rules, id)
    result = rules.find { |rule| rule[:trigger_assignment].to_s == id.to_s }
    return unless result.present?
    result.slice(:locked, :assignment_sets)
  end
end
