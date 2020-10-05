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

class UserAccountAssociation < ActiveRecord::Base
  extend RootAccountResolver

  belongs_to :user
  belongs_to :account

  after_commit :update_user_root_account_ids

  validates_presence_of :user_id, :account_id

  resolves_root_account through: :account

  scope :for_root_accounts, -> { where('root_account_id = account_id') }
  scope :for_user_id, lambda { |user_id| where('user_id =?', user_id) }

  def for_root_account?
    account_id == root_account_id
  end

  private

  def update_user_root_account_ids
    return unless for_root_account?

    # In some Canvas environments we may not want to populate
    # root_account_ids due to the high number of root account associations
    # per user. This Setting allows us to control if root_account_ids syncing
    # occurs.
    return unless Setting.get('sync_root_account_ids_on_user_records', 'true') == 'true'
    user.update_root_account_ids_later
  end

end
