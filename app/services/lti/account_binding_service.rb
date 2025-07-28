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

# This class is responsible for managing DeveloperKeyAccountBinding and Lti::RegistrationAccountBindings
# and ensuring they stay in sync. This class can handle both LTI Developer Keys and non-LTI Developer Keys.
class Lti::AccountBindingService < ApplicationService
  attr_reader :account, :workflow_state, :registration, :user, :overwrite_created_by

  def initialize(account:, user:, registration:, workflow_state: :off, overwrite_created_by: false)
    raise ArgumentError, "registration must be provided" if registration.nil?
    raise ArgumentError, "account must be provided" if account.nil?

    super()

    @account = account
    @registration = registration
    @workflow_state = workflow_state
    @user = user
    @overwrite_created_by = overwrite_created_by
  end

  def call
    Lti::Registration.transaction do
      reg_binding = bind_to_registration
      key_binding = bind_to_developer_key(reg_binding)
      { lti_registration_account_binding: reg_binding, developer_key_account_binding: key_binding }
    end
  end

  private

  def bind_to_registration
    reg_binding = Lti::RegistrationAccountBinding.find_or_initialize_by(registration:, account:)

    if reg_binding.new_record? || overwrite_created_by
      reg_binding.created_by = user
    end

    reg_binding.updated_by = user
    reg_binding.workflow_state = workflow_state

    reg_binding.save!
    reg_binding
  end

  def bind_to_developer_key(reg_binding)
    key_binding = DeveloperKeyAccountBinding.find_or_initialize_by(developer_key:, account:)

    key_binding.skip_dev_key_association_cache do
      key_binding.workflow_state = workflow_state
      key_binding.lti_registration_account_binding = reg_binding
      key_binding.save!
    end

    key_binding
  end

  def developer_key
    @developer_key ||= registration.developer_key
  end
end
