# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

module SIS
  module Models
    class User
      attr_accessor :user_id,
                    :login_id,
                    :status,
                    :first_name,
                    :last_name,
                    :email,
                    :password,
                    :ssha_password,
                    :integration_id,
                    :row,
                    :short_name,
                    :full_name,
                    :sortable_name,
                    :lineno,
                    :csv,
                    :pronouns,
                    :declared_user_type,
                    :canvas_password_notification,
                    :home_account,
                    :authentication_provider_id,
                    :sis_batch_id,
                    :existing_user_id,
                    :existing_integration_id,
                    :existing_canvas_user_id,
                    :root_account_id

      def initialize(user_id:,
                     login_id:,
                     status:,
                     first_name: nil,
                     last_name: nil,
                     email: nil,
                     password: nil,
                     ssha_password: nil,
                     pronouns: nil,
                     declared_user_type: nil,
                     canvas_password_notification: nil,
                     integration_id: nil,
                     short_name: nil,
                     full_name: nil,
                     sortable_name: nil,
                     authentication_provider_id: nil,
                     home_account: nil,
                     sis_batch_id: nil,
                     lineno: nil,
                     csv: nil,
                     existing_user_id: nil,
                     existing_integration_id: nil,
                     existing_canvas_user_id: nil,
                     root_account_id: nil,
                     row: nil)
        self.user_id = user_id
        self.login_id = login_id
        self.status = status
        self.first_name = first_name
        self.last_name = last_name
        self.email = email
        self.pronouns = pronouns
        self.declared_user_type = declared_user_type
        self.password = password
        self.ssha_password = ssha_password
        self.integration_id = integration_id
        self.short_name = short_name
        self.full_name = full_name
        self.sortable_name = sortable_name
        self.authentication_provider_id = authentication_provider_id
        self.canvas_password_notification = Canvas::Plugin.value_to_boolean(canvas_password_notification)
        self.home_account = Canvas::Plugin.value_to_boolean(home_account)
        self.lineno = lineno
        self.csv = csv
        self.sis_batch_id = sis_batch_id
        self.existing_user_id = existing_user_id
        self.existing_integration_id = existing_integration_id
        self.existing_canvas_user_id = existing_canvas_user_id
        self.root_account_id = root_account_id
        self.row = row
      end

      def login_hash
        hash = {}
        hash["sis_user_id"] = existing_user_id if existing_user_id.present?
        hash["integration_id"] = existing_integration_id if existing_integration_id.present?
        hash["user_id"] = existing_canvas_user_id.to_i if existing_canvas_user_id.present?
        hash
      end

      def login_row_info
        [existing_user_id:, existing_integration_id:,
         existing_canvas_user_id:, root_account_id:,
         user_id:, login_id:, status:, email:,
         integration_id:,
         authentication_provider_id:].to_s
      end

      def row_info
        [user_id:, login_id:, status:,
         first_name:, last_name:, email:,
         integration_id:, short_name:,
         full_name:, sortable_name:,
         canvas_password_notification:,
         authentication_provider_id:,
         declared_user_type:, home_account:].to_s
      end
    end
  end
end
