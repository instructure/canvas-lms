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

module Api::V1::Account
  include Api::V1::Json

  @@extensions = []

  # In order to register a module/class as an extension,
  # it must have a class method called 'extend_account_json',
  # which should act similarly to the account_json method, but include a parameter 'hash'
  # which will have the current account json (to which the method is expected to change and return)
  def self.register_extension(extension)
    if result = extension.respond_to?(:extend_account_json)
      @@extensions << extension
    end
    result
  end

  def self.deregister_extension(extension)
    @@extensions.delete(extension)
  end

  def account_json(account, user, session, includes, read_only=false)
    attributes = %w(id name parent_account_id root_account_id workflow_state uuid)
    if read_only
      return api_json(account, user, session, :only => attributes).tap do |hash|
        hash['default_time_zone'] = account.default_time_zone.tzinfo.name
      end
    end

    methods = %w(default_storage_quota_mb default_user_storage_quota_mb default_group_storage_quota_mb)
    api_json(account, user, session, :only => attributes, :methods => methods).tap do |hash|
      hash['default_time_zone'] = account.default_time_zone.tzinfo.name
      hash['sis_account_id'] = account.sis_source_id if !account.root_account? && account.root_account.grants_any_right?(user, :read_sis, :manage_sis)
      hash['sis_import_id'] = account.sis_batch_id if !account.root_account? && account.root_account.grants_right?(user, session, :manage_sis)
      hash['integration_id'] = account.integration_id if !account.root_account? && account.root_account.grants_any_right?(user, :read_sis, :manage_sis)
      hash['lti_guid'] = account.lti_guid if includes.include?('lti_guid')
      if includes.include?('registration_settings')
        hash['registration_settings'] = {:login_handle_name => account.login_handle_name_with_inference}
        if account.root_account?
          hash['terms_required'] = account.terms_required?
          hash['terms_of_use_url'] = terms_of_use_url
          hash['privacy_policy_url'] = privacy_policy_url
        end
      end
      if includes.include?('services') && account.grants_right?(user, session, :manage_account_settings)
        hash['services'] = Hash[Account.services_exposed_to_ui_hash(nil, user, account).keys.map{|k| [k, account.service_enabled?(k)]}]
      end

      @@extensions.each do |extension|
        hash = extension.extend_account_json(hash, account, user, session, includes)
      end
    end
  end

  def accounts_json(accounts, user, session, includes)
    accounts.map{ |account| account_json(account, user, session, includes) }
  end
end
