# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module Inbox
  class InboxService
    def initialize(user_id:, root_account_id:)
      @user_id = user_id
      @root_account_id = root_account_id
    end

    def user_settings
      inbox_settings_repo.inbox_settings || default_inbox_settings
    end

    def update_user_settings(use_signature:, signature:, use_out_of_office:, out_of_office_first_date:, out_of_office_last_date:, out_of_office_subject:, out_of_office_message:)
      inbox_settings_repo.save_inbox_settings(use_signature:, signature:, use_out_of_office:, out_of_office_first_date:, out_of_office_last_date:, out_of_office_subject:, out_of_office_message:)
    end

    private

    def inbox_settings_repo
      @inbox_settings_repo ||= Inbox::Repositories::InboxSettingsRepository.new(user_id: @user_id, root_account_id: @root_account_id)
    end

    def default_inbox_settings
      Inbox::Entities::InboxSettings.new(user_id: @user_id)
    end
  end
end
