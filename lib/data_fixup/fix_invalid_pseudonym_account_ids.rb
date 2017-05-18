#
# Copyright (C) 2015 - present Instructure, Inc.
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

module DataFixup::FixInvalidPseudonymAccountIds
  def self.run
    Pseudonym.where("NOT EXISTS (?)", Account.where("account_id=accounts.id AND root_account_id IS NULL")).
      preload(:account, :user).find_each do |p|
      if p.workflow_state == 'deleted'
        destroy_pseudonym(p)
      elsif Pseudonym.where(account_id: p.root_account_id, sis_user_id: p.sis_user_id).
        order(:workflow_state).where("sis_user_id IS NOT NULL").first

        destroy_pseudonym(p)
      elsif (p2 = Pseudonym.by_unique_id(p.unique_id).active.
        where(account_id: p.root_account_id).order(:workflow_state).first)

        UserMerge.from(p.user).into(p2.user)
        destroy_pseudonym(p)
      else
        p.account_id = p.root_account_id
        p.save!
      end
    end
  end

  def self.destroy_pseudonym(p)
    p.session_persistence_tokens.scope.delete_all
    p.destroy_permanently!
  end

end
