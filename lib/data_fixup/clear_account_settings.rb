# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module DataFixup
  module ClearAccountSettings
    def self.run(settings, include_subaccounts: false)
      settings.each do |setting|
        account_scope = include_subaccounts ? Account.all : Account.root_accounts
        account_scope.active.non_shadow.where("settings LIKE ?", "%#{setting}%").find_each do |account|
          account.settings.delete(setting.to_sym)
          account.save!
        end
      end
    end
  end
end
