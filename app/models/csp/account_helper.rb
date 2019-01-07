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
module Csp::AccountHelper
  def self.included(account_class)
    account_class.has_many :csp_domains, :class_name => "Csp::Domain"

    # the setting (and id of the account to search) that will be passed down to sub-accounts e.g. ([true, 2])
    account_class.add_setting :csp_inherited_data, :inheritable => true
  end

  def load_csp_data
    unless @csp_loaded
      csp_data = self.settings.dig(:csp_inherited_data, :value) || self.csp_inherited_data&.dig(:value) || [false, nil]
      @csp_enabled, @csp_account_id = csp_data
      @csp_loaded = true
    end
  end

  def csp_enabled?
    load_csp_data
    @csp_enabled
  end

  def csp_account_id
    load_csp_data
    @csp_account_id
  end

  def csp_inherited?
    csp_account_id != self.global_id
  end

  def csp_directly_enabled?
    csp_enabled? && !csp_inherited?
  end

  def enable_csp!
    set_csp_setting!([true, self.global_id])
  end

  def disable_csp!
    set_csp_setting!([false, self.global_id])
  end

  def set_csp_setting!(value)
    self.settings[:csp_inherited_data] = {:value => value}
    self.save!
  end

  def inherit_csp!
    self.settings.delete(:csp_inherited_data)
    self.save!
  end

  def add_domain!(domain)
    domain.downcase!
    Csp::Domain.unique_constraint_retry do |retry_count|
      if retry_count > 0 && (record = self.csp_domains.where(:domain => domain).take)
        record.undestroy if record.deleted?
      else
        record = self.csp_domains.create(:domain => domain)
        record.valid? && record
      end
    end
  end

  def remove_domain!(domain)
    self.csp_domains.active.where(:domain => domain.downcase).take&.destroy!
  end


  def csp_whitelisted_domains
    reutrn [] unless csp_enabled?
    # first, get the whitelist from the enabled csp account
    # then get the list of domains extracted from external tools
    (::Csp::Domain.get_cached_domains_for_account(self.csp_account_id) +
      self.cached_tool_domains).uniq.sort
  end

  ACCOUNT_TOOL_CACHE_KEY_PREFIX = "account_tool_domains".freeze
  def cached_tool_domains
    @cached_tool_domains ||= Rails.cache.fetch([ACCOUNT_TOOL_CACHE_KEY_PREFIX, self.global_id].cache_key) do
      get_account_tool_domains
    end
  end

  def csp_tools_grouped_by_domain
    csp_tool_scope.to_a.group_by{|tool| (tool.domain || (Addressable::URI.parse(tool.url).normalize.host rescue nil))&.downcase }.except(nil)
  end

  def get_account_tool_domains
    Csp::Domain.domains_for_tools(csp_tool_scope)
  end

  def csp_tool_scope
    ContextExternalTool.where(:context_type => "Account", :context_id => account_chain_ids).active
  end

  def clear_tool_domain_cache
    Account.send_later_if_production(:invalidate_inherited_caches, self, [ACCOUNT_TOOL_CACHE_KEY_PREFIX])
  end
end
