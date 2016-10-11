#
# Copyright (C) 2011 Instructure, Inc.
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

module Factories
  def pseudonym_model(opts={})
    user_model unless @user
    @pseudonym = factory_with_protected_attributes(Pseudonym, valid_pseudonym_attributes.merge(opts))
  end

  # Re-generate these because I need a Unique ID
  def valid_pseudonym_attributes
    {
      :unique_id => "#{SecureRandom.uuid}@example.com",
      :password => "password",
      :password_confirmation => "password",
      :persistence_token => "pt_#{SecureRandom.uuid}",
      :perishable_token => "value for perishable_token",
      :login_count => 1,
      :failed_login_count => 0,
      :last_request_at => Time.now,
      :last_login_at => Time.now,
      :current_login_at => Time.now,
      :last_login_ip => "value for last_login_ip",
      :current_login_ip => "value for current_login_ip",
      :user => @user
    }
  end

  def pseudonym(user, opts={})
    @spec_pseudonym_count ||= 0
    username = opts[:username] || (@spec_pseudonym_count > 0 ? "nobody+#{@spec_pseudonym_count}@example.com" : "nobody@example.com")
    opts[:username] ||= username
    @spec_pseudonym_count += 1 if username =~ /nobody(\+\d+)?@example.com/
    password = opts[:password] || "asdfasdf"
    password = nil if password == :autogenerate
    account = (opts[:account] ? opts[:account].root_account : Account.default)
    @pseudonym = account.pseudonyms.build(:user => user, :unique_id => username, :password => password, :password_confirmation => password)
    @pseudonym.save_without_session_maintenance
    @pseudonym.communication_channel = communication_channel(user, opts)
    @pseudonym
  end

  def managed_pseudonym(user, opts={})
    other_account = opts[:account] || account_with_saml
    if other_account.canvas_authentication?
      config = other_account.authentication_providers.build
      config.auth_type = "saml"
      config.log_in_url = opts[:saml_log_in_url] if opts[:saml_log_in_url]
      config.save!
    end
    opts[:account] = other_account
    pseudonym(user, opts)
    @pseudonym.sis_user_id = opts[:sis_user_id] || "U001"
    @pseudonym.save!
    @pseudonym
  end
end
