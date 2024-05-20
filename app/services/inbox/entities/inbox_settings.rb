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
  module Entities
    class InboxSettings
      attr_reader :id,
                  :user_id,
                  :root_account_id,
                  :use_signature,
                  :signature,
                  :use_out_of_office,
                  :out_of_office_first_date,
                  :out_of_office_last_date,
                  :out_of_office_subject,
                  :out_of_office_message,
                  :created_at,
                  :updated_at

      def initialize(id:,
                     user_id:,
                     root_account_id:,
                     use_signature: false,
                     signature: nil,
                     use_out_of_office: false,
                     out_of_office_first_date: nil,
                     out_of_office_last_date: nil,
                     out_of_office_subject: nil,
                     out_of_office_message: nil,
                     created_at: nil,
                     updated_at: nil)
        @id = validate_not_nil(id, "id")
        @user_id = validate_not_nil(user_id, "user_id")
        @root_account_id = validate_not_nil(root_account_id, "root_account_id")
        @use_signature = use_signature
        @signature = signature
        @use_out_of_office = use_out_of_office
        @out_of_office_first_date = out_of_office_first_date
        @out_of_office_last_date = out_of_office_last_date
        @out_of_office_subject = out_of_office_subject
        @out_of_office_message = out_of_office_message
        @created_at = created_at
        @updated_at = updated_at
      end

      private

      # TODO: should be a shared util function
      def validate_not_nil(arg, arg_name)
        raise ArgumentError, "#{arg_name} cannot be nil" if arg.nil?

        arg
      end
    end
  end
end
