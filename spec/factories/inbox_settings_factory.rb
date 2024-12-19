# frozen_string_literal: true

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

module Factories
  def inbox_settings_factory(opts = {})
    Inbox::Repositories::InboxSettingsRepository.save_inbox_settings(
      user_id: opts[:user_id] || @user&.id,
      root_account_id: opts[:root_account_id] || Account.default.id,
      use_signature: opts[:use_signature] || true,
      signature: opts[:signature] || "Signature",
      use_out_of_office: opts[:use_out_of_office] || true,
      out_of_office_first_date: opts[:out_of_office_first_date] || Time.zone.now,
      out_of_office_last_date: opts[:out_of_office_last_date] || 1.week.from_now,
      out_of_office_subject: opts[:out_of_office_subject] || "Out of office",
      out_of_office_message: opts[:out_of_office_message] || "I'm out of office for a week"
    )
  end
end
