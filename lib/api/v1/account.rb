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

  def account_json(account, user, session, includes)
    api_json(account, user, session, :only => %w(id name parent_account_id root_account_id)).tap do |hash|
      hash['sis_account_id'] = account.sis_source_id if !account.root_account? && account.root_account.grants_rights?(user, :read_sis, :manage_sis).values.any?
      @@extensions.each do |extension|
        hash = extension.extend_account_json(hash, account, user, session, includes)
      end
    end
  end
end

