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
module Csp::AccountHelper
  def self.included(account_class)
    account_class.has_many :csp_domains, class_name: "Csp::Domain"

    # the setting (and id of the account to search) that will be passed down to sub-accounts e.g. ([true, 2])
    account_class.add_setting :csp_inherited_data, inheritable: true

    account_class.after_save :unload_csp_data
  end

  def unload_csp_data
    @csp_loaded = false
  end

  def load_csp_data
    unless @csp_loaded
      csp_data = csp_inherited_data
      @csp_enabled, @csp_account_id = csp_data&.dig(:value) || [false, nil]
      @csp_locked = !!csp_data&.dig(:locked)
      @csp_loaded = true
    end
  end

  def csp_enabled?
    load_csp_data
    @csp_enabled
  end

  def csp_account_id
    load_csp_data
    @csp_account_id || global_id
  end

  def csp_inherited?
    load_csp_data
    @csp_account_id != global_id
  end

  def csp_locked?
    load_csp_data
    @csp_locked
  end

  def csp_directly_enabled?
    csp_enabled? && !csp_inherited?
  end

  def enable_csp!
    set_csp_setting!([true, global_id])
  end

  def disable_csp!
    set_csp_setting!([false, global_id])
  end

  def lock_csp!
    set_csp_locked!(true)
  end

  def unlock_csp!
    set_csp_locked!(false)
  end

  def set_csp_locked!(value)
    csp_settings = settings[:csp_inherited_data].dup
    raise "csp not explicitly set" unless csp_settings

    csp_settings[:locked] = !!value
    settings[:csp_inherited_data] = csp_settings
    save!
  end

  def set_csp_setting!(value)
    csp_settings = settings[:csp_inherited_data].dup || {}
    csp_settings[:value] = value
    settings[:csp_inherited_data] = csp_settings
    save!
  end

  def inherit_csp!
    settings.delete(:csp_inherited_data)
    save!
  end

  def add_domain!(domain)
    domain = domain.downcase
    Csp::Domain.unique_constraint_retry do |retry_count|
      if retry_count > 0 && (record = csp_domains.find_by(domain:))
        record.undestroy if record.deleted?
        record
      else
        record = csp_domains.create(domain:)
        record.valid? && record
      end
    end
  end

  def remove_domain!(domain)
    csp_domains.active.find_by(domain: domain.downcase)&.destroy!
  end

  def csp_whitelisted_domains(request = nil, include_files:, include_tools:)
    # first, get the allowed domain list from the enabled csp account
    # then get the list of domains extracted from external tools
    domains = ::Csp::Domain.get_cached_domains_for_account(csp_account_id)
    # directly include `canvas.instructure.com` or its variants so that LTI 1.3 launches
    # still work. This is still needed for now until all LTI 1.3 tools have been
    # transitioned to using `sso.canvaslms.com`, or until we decide to begin enforcing this.
    domains << HostUrl.context_host(Account.default, request&.host_with_port) if include_tools
    domains += Setting.get("csp.global_whitelist", "").split(",").map(&:strip)
    domains += cached_tool_domains if include_tools
    domains += csp_files_domains(request) if include_files
    domains += csp_dynamic_registration_domain(request)
    domains.compact.uniq.sort
  end

  ACCOUNT_TOOL_CACHE_KEY_PREFIX = "account_tool_domains"

  def account_tool_cache_key(global_id, internal_service_only)
    key = [ACCOUNT_TOOL_CACHE_KEY_PREFIX, global_id]
    key << "internal_service_only" if internal_service_only
    key.cache_key
  end

  def cached_tool_domains(internal_service_only: false)
    @cached_tool_domains ||= {}
    @cached_tool_domains[internal_service_only] ||= Rails.cache.fetch(
      account_tool_cache_key(global_id, internal_service_only)
    ) do
      get_account_tool_domains(internal_service_only:)
    end
  end

  def csp_tools_grouped_by_domain(internal_service_only: false)
    csp_tool_scope = ContextExternalTool.where(context_type: "Account", context_id: account_chain_ids).active

    if internal_service_only
      unique_dev_keys = csp_tool_scope.distinct.pluck(:developer_key_id)
      internal_service_dev_keys = DeveloperKey.where(id: unique_dev_keys, internal_service: true).pluck(:id)
      csp_tool_scope = csp_tool_scope.where(developer_key_id: internal_service_dev_keys)
    end

    csp_tool_scope.each_with_object({}) do |tool, hash|
      Csp::Domain.domains_for_tool(tool).each do |domain|
        hash[domain] ||= []
        hash[domain] << tool
      end
    end
  end

  def get_account_tool_domains(internal_service_only:)
    csp_tools_grouped_by_domain(internal_service_only:).keys.uniq
  end

  def clear_tool_domain_cache
    Rails.cache.delete(account_tool_cache_key(global_id, false))
    Rails.cache.delete(account_tool_cache_key(global_id, true))
    Account.delay_if_production.invalidate_inherited_caches(self, [ACCOUNT_TOOL_CACHE_KEY_PREFIX])
  end

  def csp_files_domains(request)
    files_host = HostUrl.file_host(root_account, request.host_with_port)
    config = DynamicSettings.find(tree: :private, cluster: root_account.shard.database_server.id)
    if config["attachment_specific_file_domain", failsafe: false] == "true"
      separator = config["attachment_specific_file_domain_separator"] || "."
      files_host = if separator == "."
                     "*.#{files_host}"
                   else
                     "*.#{files_host[files_host.index(".") + 1..]}"
                   end
    end
    canvadocs_host = Canvadocs.enabled?.presence && URI.parse(Canvadocs.config["base_url"]).host
    inst_fs_host = InstFS.enabled?.presence && URI.parse(InstFS.app_host).host
    # allow for custom CDN domain for inst-fs, sub-domain naming scheme not enforced
    inst_fs_cdn_host = "*.#{inst_fs_host}" if inst_fs_host

    csp_files_domains = [files_host, canvadocs_host, inst_fs_host]
    csp_files_domains << inst_fs_cdn_host if inst_fs_cdn_host

    csp_files_domains.compact
  end

  def csp_logging_config
    @config ||= Rails.application.credentials.csp_logging || {}
  end

  private

  def csp_dynamic_registration_domain(request)
    return [] unless request.respond_to?(:env)
    return [] unless request.env&.[]("dynamic_reg_url_csp")

    [URI.parse(request.env["dynamic_reg_url_csp"]).host]
  end
end
