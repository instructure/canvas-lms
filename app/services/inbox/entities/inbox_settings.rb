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
      attr_reader :user_id, :use_signature, :signature, :use_out_of_office, :out_of_office_first_date, :out_of_office_last_date, :out_of_office_subject, :out_of_office_message

      def initialize(user_id:, use_signature: false, signature: nil, use_out_of_office: false, out_of_office_first_date: nil, out_of_office_last_date: nil, out_of_office_subject: nil, out_of_office_message: nil)
        @user_id = validate_not_nil(user_id, "user_id")
        @use_signature = use_signature
        @signature = signature
        @use_out_of_office = use_out_of_office
        @out_of_office_first_date = out_of_office_first_date
        @out_of_office_last_date = out_of_office_last_date
        @out_of_office_subject = out_of_office_subject
        @out_of_office_message = out_of_office_message
      end

      def self.as_json(inbox_settings:)
        {
          userId: inbox_settings.user_id,
          useSignature: inbox_settings.use_signature,
          signature: inbox_settings.signature,
          useOutOfOffice: inbox_settings.use_out_of_office,
          outOfOfficeFirstDate: inbox_settings.out_of_office_first_date,
          outOfOfficeLastDate: inbox_settings.out_of_office_last_date,
          outOfOfficeSubject: inbox_settings.out_of_office_subject,
          outOfOfficeMessage: inbox_settings.out_of_office_message
        }
      end

      def self.from_json(json:)
        InboxSettings.new(user_id: json["userId"],
                          use_signature: json["useSignature"],
                          signature: json["signature"],
                          use_out_of_office: json["useOutOfOffice"],
                          out_of_office_first_date: json["outOfOfficeFirstDate"],
                          out_of_office_last_date: json["outOfOfficeLastDate"],
                          out_of_office_subject: json["outOfOfficeSubject"],
                          out_of_office_message: json["outOfOfficeMessage"])
      end

      private

      # TODO: should be a shared util function
      def validate_not_nil(arg, arg_name)
        if arg.nil?
          raise ArgumentError, "#{arg_name} cannot be nil"
        end

        arg
      end
    end
  end
end
