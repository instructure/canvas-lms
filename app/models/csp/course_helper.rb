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
module Csp::CourseHelper
  def self.included(course_class)
    course_class.add_setting :csp_disabled, boolean: true, default: false
  end

  def csp_enabled?
    account.csp_enabled? && csp_inherited?
  end

  def csp_inherited?
    csp_locked? || !csp_disabled?
  end

  delegate :csp_locked?, to: :account

  def inherit_csp!
    self.csp_disabled = false
    save!
  end

  def disable_csp!
    self.csp_disabled = true
    save!
  end

  def csp_whitelisted_domains(request = nil, include_files:, include_tools:)
    domains = account.csp_whitelisted_domains(request, include_files:, include_tools:)
    domains += cached_tool_domains if include_tools
    domains.uniq.sort
  end

  def tool_domain_cache_key
    ["course_tool_domains", global_id].cache_key
  end

  def cached_tool_domains
    # invalidate when the course is touched
    Rails.cache.fetch(tool_domain_cache_key) do
      context_external_tools.active.map do |tool|
        Csp::Domain.domains_for_tool(tool)
      end.flatten.compact.uniq
    end
  end

  def clear_tool_domain_cache
    Rails.cache.delete(tool_domain_cache_key)
  end
end
