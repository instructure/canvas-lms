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

module Api::V1::Tab
  include Api::V1::Json
  include Api::V1::ExternalTools::UrlHelpers
  include NewQuizzesFeaturesHelper

  def self.tab_is?(tab, context, const_name)
    context.class.const_defined?(const_name) && tab[:id] == context.class.const_get(const_name)
  end

  def tabs_available_json(context, user, session, _includes = [], precalculated_permissions: nil)
    json = context_tabs(context, user, session:, precalculated_permissions:).map do |tab|
      tab_json(tab.with_indifferent_access, context, user, session)
    end
    json.sort_by! { |a| a["position"] }
  end

  def tab_json(tab, context, user, session)
    hash = {}
    hash[:id] = tab[:css_class]
    hash[:html_url] = html_url(tab, context)
    hash[:full_url] = html_url(tab, context, true)
    hash[:position] = tab[:position]
    hash[:hidden] = true if tab[:hidden]
    hash[:unused] = true if tab[:hidden_unused]
    hash[:visibility] = visibility(tab, hash)
    hash[:label] = tab[:label]
    hash[:type] = (tab[:external] && "external") || "internal"
    if tab[:external] && tab[:args] && tab[:args].length > 1
      launch_type = context.is_a?(Account) ? "account_navigation" : "course_navigation"
      hash[:url] = sessionless_launch_url(context, id: tab[:args][1], launch_type:)
    end
    api_json(hash, user, session)
  end

  def html_url(tab, context, full_url = false)
    if full_url
      method = tab[:href].to_s.sub(/_path$/, "_url").to_sym
      opts = { host: HostUrl.context_host(context, request.try(:host_with_port)) }
    else
      method = tab[:href]
      opts = {}
    end

    if tab[:args]
      if tab[:args].is_a?(Hash)
        # LTI 2 tools have args as a hash rather than an array (see MessageHandler#lti_apps_tabs)
        send(method, opts.merge(tab[:args].symbolize_keys))
      elsif tab[:args].last.is_a?(Hash) || tab[:args].last.is_a?(ActionController::Parameters)
        # If last argument is a hash (of options), we can't add on another options hash;
        # we need to merge it into the existing options.
        # can't do tab[:args].last.merge(opts), that may convert :host to 'host'
        send(method, *tab[:args][0..-2], opts.merge(tab[:args].last))
      else
        send(method, *tab[:args], opts)
      end
    elsif tab[:no_args]
      send(method, opts)
    else
      send(method, context, opts)
    end
  end

  def visibility(tab, hash)
    if hash[:type] == "external" && hash[:hidden]
      "none"
    elsif hash[:id] == "settings" || hash[:unused] || hash[:hidden]
      "admins"
    else
      tab[:visibility] || "public"
    end
  end

  def context_tabs(context, user, precalculated_permissions: nil, session: nil)
    new_collaborations_enabled = context.feature_enabled?(:new_collaborations)

    if context.is_a?(User)
      root_account = @domain_root_account
      context = context.profile
    end

    opts = {
      include_external: true,
      api: true,
      precalculated_permissions:,
      root_account:,
      session:,
      course_subject_tabs: params["include"]&.include?("course_subject_tabs")
    }

    tabs = context.tabs_available(user, **opts).select do |tab|
      if !tab[:href] || !tab[:label]
        false
      elsif Api::V1::Tab.tab_is?(tab, context, :TAB_COLLABORATIONS)
        !new_collaborations_enabled && ::Collaboration.any_collaborations_configured?(context)
      elsif Api::V1::Tab.tab_is?(tab, context, :TAB_COLLABORATIONS_NEW)
        new_collaborations_enabled
      elsif Api::V1::Tab.tab_is?(tab, context, :TAB_CONFERENCES)
        feature_enabled?(:web_conferences)
      elsif Lti::ExternalToolTab.tool_for_tab(tab)&.quiz_lti?
        new_quizzes_navigation_placements_enabled?(context)
      else
        true
      end
    end
    tabs.each_with_index do |tab, i|
      tab[:position] = i + 1
    end
    tabs
  end
end
