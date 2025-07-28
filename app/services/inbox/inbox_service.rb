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
    class << self
      def inbox_settings_for_user(user_id:, root_account_id:)
        Inbox::Repositories::InboxSettingsRepository.get_inbox_settings(user_id:, root_account_id:) ||
          create_default_inbox_settings_for_user(user_id:, root_account_id:)
      end

      def update_inbox_settings_for_user(
        user_id:,
        root_account_id:,
        use_signature:,
        signature:,
        use_out_of_office:,
        out_of_office_first_date:,
        out_of_office_last_date:,
        out_of_office_subject:,
        out_of_office_message:
      )
        Inbox::Repositories::InboxSettingsRepository.save_inbox_settings(
          user_id:,
          root_account_id:,
          use_signature:,
          signature:,
          use_out_of_office:,
          out_of_office_first_date:,
          out_of_office_last_date:,
          out_of_office_subject:,
          out_of_office_message:
        )
      end

      def inbox_settings_ooo_hash(user_id:, root_account_id:)
        Inbox::Repositories::InboxSettingsRepository.create_inbox_settings_ooo_hash(user_id:, root_account_id:)
      end

      def users_out_of_office(user_ids:, root_account_id:, date:)
        Inbox::Repositories::InboxSettingsRepository.get_users_out_of_office(user_ids:, root_account_id:, date:)
      end

      private

      def create_default_inbox_settings_for_user(user_id:, root_account_id:)
        temp_id = SecureRandom.uuid
        default_settings = Inbox::Entities::InboxSettings.new(id: temp_id, user_id:, root_account_id:)
        update_inbox_settings_for_user(
          user_id:,
          root_account_id:,
          use_signature: default_settings.use_signature,
          signature: default_settings.signature,
          use_out_of_office: default_settings.use_out_of_office,
          out_of_office_first_date: default_settings.out_of_office_first_date,
          out_of_office_last_date: default_settings.out_of_office_last_date,
          out_of_office_subject: default_settings.out_of_office_subject,
          out_of_office_message: default_settings.out_of_office_subject
        )
      end
    end
  end
end
