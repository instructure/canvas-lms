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
#

class Mutations::UpdateMyInboxSettings < Mutations::BaseMutation
  # rubocop:disable GraphQL/ExtractInputType
  argument :out_of_office_first_date, String, required: false
  argument :out_of_office_last_date, String, required: false
  argument :out_of_office_message, String, required: false
  argument :out_of_office_subject, String, required: false
  argument :signature, String, required: false
  argument :use_out_of_office, Boolean, required: true
  argument :use_signature, Boolean, required: true
  # rubocop:enable GraphQL/ExtractInputType

  field :my_inbox_settings, Types::InboxSettingsType, null: true

  def self.my_inbox_settings_log_entry(_entry, context)
    context[:current_user]
  end

  def resolve(input:) # rubocop:disable GraphQL/UnusedArgument
    check_feature_enabled

    updated_inbox_settings = Inbox::InboxService.update_inbox_settings_for_user(user_id: context[:current_user]&.id&.to_s,
                                                                                root_account_id: context[:domain_root_account]&.id,
                                                                                use_signature: input[:use_signature],
                                                                                signature: input[:signature],
                                                                                use_out_of_office: input[:use_out_of_office],
                                                                                out_of_office_first_date: input[:out_of_office_first_date],
                                                                                out_of_office_last_date: input[:out_of_office_last_date],
                                                                                out_of_office_subject: input[:out_of_office_subject],
                                                                                out_of_office_message: input[:out_of_office_message])

    if updated_inbox_settings
      { my_inbox_settings: updated_inbox_settings }
    else
      errors_for(updated_inbox_settings)
    end
  end

  private

  def check_feature_enabled
    raise GraphQL::ExecutionError, I18n.t("inbox settings feature is disabled") unless Account.site_admin.feature_enabled?(:inbox_settings)
  end
end
