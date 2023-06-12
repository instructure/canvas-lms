# frozen_string_literal: true

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

module K5Common
  def toggle_k5_setting(account, enable = true)
    account.settings[:enable_as_k5_account] = { value: enable, locked: enable }
    account.root_account.settings[:k5_accounts] = enable ? [account.id] : []
    account.root_account.save!
    account.save!
  end

  def toggle_classic_font_setting(account, enable = true)
    account.settings[:use_classic_font_in_k5] = { value: enable, locked: enable }
    account.root_account.settings[:k5_classic_font_accounts] = enable ? [account.id] : []
    account.root_account.save!
    account.save!
  end
end
