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
  module Repositories
    class InboxSettingsRepository
      class InboxSettingsRecord < ActiveRecord::Base
        self.table_name = "inbox_settings"
      end

      class << self
        def get_inbox_settings(user_id:, root_account_id:)
          settings = InboxSettingsRecord.find_by(user_id:, root_account_id:)
          as_entity settings unless settings.nil?
        end

        def save_inbox_settings(
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
          settings = InboxSettingsRecord.find_by(user_id:, root_account_id:) ||
                     InboxSettingsRecord.new(user_id:, root_account_id:)
          settings.use_signature = use_signature
          settings.signature = signature
          settings.use_out_of_office = use_out_of_office
          settings.out_of_office_first_date = out_of_office_first_date
          settings.out_of_office_last_date = out_of_office_last_date
          settings.out_of_office_subject = out_of_office_subject
          settings.out_of_office_message = out_of_office_message
          settings.save!

          as_entity settings
        end

        def get_users_out_of_office(user_ids:, root_account_id:, date:)
          user_ids = user_ids.map(&:to_s)
          InboxSettingsRecord.where(
            "user_id IN (:user_ids) AND root_account_id = :root_account_id AND use_out_of_office = TRUE AND out_of_office_first_date <= :date AND out_of_office_last_date >= :date",
            root_account_id:,
            date:,
            user_ids:
          )
        end

        def create_inbox_settings_ooo_hash(user_id:, root_account_id:)
          settings = InboxSettingsRecord.find_by(user_id:, root_account_id:)

          return nil unless settings

          # Grab specific settings to include in hash snapshot
          ooo_first_date = settings.out_of_office_first_date.present? ? settings.out_of_office_first_date.strftime("%FT%T%:z") : ""
          ooo_last_date = settings.out_of_office_last_date.present? ? settings.out_of_office_last_date.strftime("%FT%T%:z") : ""
          ooo_subject = settings.out_of_office_subject || ""
          ooo_message = settings.out_of_office_message || ""

          hash_str = user_id.to_s + ooo_first_date + ooo_last_date + ooo_subject + ooo_message

          Digest::SHA1.hexdigest(hash_str)
        end

        private

        def as_entity(settings)
          Entities::InboxSettings.new(id: settings.id,
                                      user_id: settings.user_id,
                                      root_account_id: settings.root_account_id,
                                      use_signature: settings.use_signature,
                                      signature: settings.signature,
                                      use_out_of_office: settings.use_out_of_office,
                                      out_of_office_first_date: settings.out_of_office_first_date,
                                      out_of_office_last_date: settings.out_of_office_last_date,
                                      out_of_office_subject: settings.out_of_office_subject,
                                      out_of_office_message: settings.out_of_office_message,
                                      created_at: settings.created_at,
                                      updated_at: settings.updated_at)
        end
      end
    end
  end
end
