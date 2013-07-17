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

  MODULE_JSON_ATTRS = %w(id position name unlock_at)

  MODULE_ITEM_JSON_ATTRS = %w(id position title indent)

  # optionally pass progression to include 'state', 'completed_at'
  def module_json(context_module, current_user, session, progression = nil)
    hash = api_json(context_module, current_user, session, :only => MODULE_JSON_ATTRS)
    hash['require_sequential_progress'] = !!context_module.require_sequential_progress
    hash['prerequisite_module_ids'] = context_module.prerequisites.reject{|p| p[:type] != 'context_module'}.map{|p| p[:id]}
    if progression
      hash['state'] = progression.workflow_state
      hash['completed_at'] = progression.completed_at
    end
    hash['published'] = context_module.active? if context_module.grants_right?(current_user, :update)
    hash
  end

  # optionally pass context_module to avoid redundant queries when rendering multiple items
  # optionally pass progression to include completion status
  def module_item_json(content_tag, current_user, session, context_module = nil, progression = nil)
    context_module ||= content_tag.context_module

    hash = api_json(content_tag, current_user, session, :only => MODULE_ITEM_JSON_ATTRS)
    hash['type'] = Api::API_DATA_TYPE[content_tag.content_type] || content_tag.content_type

    # add canvas web url
    unless content_tag.content_type == 'ContextModuleSubHeader'
      hash['html_url'] = case content_tag.content_type
        when 'ExternalUrl'
          # API prefers to redirect to the external page, rather than host in an iframe
          api_v1_course_context_module_item_redirect_url(:id => content_tag.id)
        else
          # otherwise we'll link to the same thing the web UI does
          course_context_modules_item_redirect_url(:id => content_tag.id)
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
      when 'Assignment', 'WikiPage', 'DiscussionTopic', 'Quiz'
        api_url = polymorphic_url([:api_v1, context_module.context, content_tag.content])
      # no context
      when 'Attachment'
        api_url = polymorphic_url([:api_v1, content_tag.content])
      when 'ContextExternalTool'
        api_url = sessionless_launch_url(context_module.context, :url => content_tag.url)
    end
    hash['url'] = api_url if api_url

    # add external_url, if applicable
    hash['external_url'] = content_tag.url if ['ExternalUrl', 'ContextExternalTool'].include?(content_tag.content_type)

    # add new_tab, if applicable
    hash['new_tab'] = content_tag.new_tab if content_tag.content_type == 'ContextExternalTool'

    # add completion requirements
    if criterion = context_module.completion_requirements && context_module.completion_requirements.detect { |r| r[:id] == content_tag.id }
      ch = { 'type' => criterion[:type] }
      ch['min_score'] = criterion[:min_score] if criterion[:type] == 'min_score'
      ch['completed'] = !!progression.requirements_met.detect{|r|r[:type] == criterion[:type] && r[:id] == content_tag.id} if progression && progression.requirements_met.present?
      hash['completion_requirement'] = ch
    end

    hash['published'] = content_tag.active? if context_module.grants_right?(current_user, :update)

    hash
  end
end
