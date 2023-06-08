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

module DataFixup::ChangeImmersiveReaderAllowedOnToOn
  def self.run
    # Site Admin has the flag as STATE_DEFAULT_OFF, but just in case, ignore it here.
    root_accounts_scope = if Shard.current.default?
                            Account.root_accounts.active.where.not(id: Account.site_admin&.id)
                          else
                            Account.root_accounts.active
                          end

    allowed_on_flags = FeatureFlag.where(
      context_id: root_accounts_scope,
      context_type: "Account",
      feature: :immersive_reader_wiki_pages,
      state: Feature::STATE_DEFAULT_ON
    )

    allowed_on_flags.update_all(state: Feature::STATE_ON, updated_at: Time.zone.now)
  end
end
