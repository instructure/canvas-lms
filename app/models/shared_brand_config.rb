# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

class SharedBrandConfig < ActiveRecord::Base
  belongs_to :brand_config, foreign_key: "brand_config_md5"
  belongs_to :account

  validates :brand_config, presence: true

  set_policy do
    given { |user, session| self.account.grants_right?(user, session, :manage_account_settings) }
    can :create and can :update and can :delete
  end
end
