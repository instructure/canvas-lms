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

  def tabs_available_json(context, user, session, includes = [], precalculated_permissions: nil)
    json = context_tabs(context, user, session: session, precalculated_permissions: precalculated_permissions).map { |tab|
      tab_json(tab.with_indifferent_access, context, user, session) }
    json.sort!{|x,y| x['position'] <=> y['position']}
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
    hash[:type] = (tab[:external] && 'external') || 'internal'
    if tab[:external] && tab[:args] && tab[:args].length > 1
      launch_type = context.is_a?(Account) ? 'account_navigation' : 'course_navigation'
      hash[:url] = sessionless_launch_url(context, id: tab[:args][1], launch_type: launch_type)
    end
    api_json(hash, user, session)
  end

  def html_url(tab, context, full_url=false)
    if full_url
      method = tab[:href].to_s.sub(/_path$/, '_url').to_sym
      opts = {:host => HostUrl.context_host(context, request.try(:host_with_port))}
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
    if hash[:type] == 'external' && hash[:hidden]
      'none'
    elsif hash[:id] =='settings' || hash[:unused] || hash[:hidden]
      'admins'
    else
      tab[:visibility] || 'public'
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
      precalculated_permissions: precalculated_permissions,
      root_account: root_account,
      session: session
    }

    tabs = context.tabs_available(user, opts).select do |tab|
      if (tab[:id] == context.class::TAB_COLLABORATIONS rescue false)
        tab[:href] && tab[:label] && !new_collaborations_enabled && ::Collaboration.any_collaborations_configured?(context)
      elsif (tab[:id] == context.class::TAB_COLLABORATIONS_NEW rescue false)
        tab[:href] && tab[:label] && new_collaborations_enabled
      elsif (tab[:id] == context.class::TAB_CONFERENCES rescue false)
        tab[:href] && tab[:label] && feature_enabled?(:web_conferences)
      else
        tab[:href] && tab[:label]
      end
    end
    tabs.each_with_index do |tab, i|
      tab[:position] = i + 1
    end
    tabs
  end

end
