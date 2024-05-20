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

class Lti::RegistrationAccountBinding < ActiveRecord::Base
  extend RootAccountResolver

  include Workflow
  workflow do
    state :off
    state :on
    state :allow
    state :deleted
  end

  belongs_to :account, inverse_of: :lti_registration_account_bindings, optional: false
  belongs_to :registration, class_name: "Lti::Registration", inverse_of: :lti_registration_account_bindings, optional: false
  belongs_to :root_account, class_name: "Account"
  belongs_to :created_by, class_name: "User", inverse_of: :created_lti_registration_account_bindings
  belongs_to :updated_by, class_name: "User", inverse_of: :updated_lti_registration_account_bindings
  belongs_to :developer_key_account_binding, inverse_of: :lti_registration_account_binding

  resolves_root_account through: :account

  # -- BEGIN SoftDeleteable --
  # adapting SoftDeleteable, but with no "active" state
  scope :active, -> { where.not(workflow_state: :deleted) }

  alias_method :destroy_permanently!, :destroy
  def destroy
    return true if deleted?

    self.workflow_state = :deleted
    run_callbacks(:destroy) { save! }
  end

  def undestroy(active_state: "off")
    self.workflow_state = active_state
    save!
    true
  end
  # -- END SoftDeleteable --

  # The skip_lime_sync attribute should be set when this this model is being updated
  # by the developer_key_account_binding's after_save method. If it is set, this model
  # should skip its own update_developer_key_account_binding method. This is to prevent
  # a loop between the two models' after_saves.
  attr_accessor :skip_lime_sync

  after_save :update_developer_key_account_binding

  private

  def update_developer_key_account_binding
    if skip_lime_sync
      self.skip_lime_sync = false
      return
    end

    if developer_key_account_binding
      developer_key_account_binding.update!(workflow_state:, skip_lime_sync: true)
    elsif registration.developer_key
      DeveloperKeyAccountBinding.create!(
        account:,
        workflow_state:,
        developer_key: registration.developer_key,
        lti_registration_account_binding: self,
        skip_lime_sync: true
      )
    end
  end
end
