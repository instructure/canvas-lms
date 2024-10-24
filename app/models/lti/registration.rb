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

class Lti::Registration < ActiveRecord::Base
  DEFAULT_PRIVACY_LEVEL = "anonymous"
  CANVAS_EXTENSION_LABEL = "canvas.instructure.com"

  extend RootAccountResolver
  include Canvas::SoftDeletable

  attr_accessor :skip_lti_sync, :account_binding
  attr_writer :account_binding_loaded

  belongs_to :account, inverse_of: :lti_registrations, optional: false
  belongs_to :created_by, class_name: "User", inverse_of: :created_lti_registrations, optional: true
  belongs_to :updated_by, class_name: "User", inverse_of: :updated_lti_registrations, optional: true

  # If this tool has been installed via dynamic registration, it will have an ims_registration.
  has_one :ims_registration, class_name: "Lti::IMS::Registration", inverse_of: :lti_registration, foreign_key: :lti_registration_id

  has_one :developer_key, inverse_of: :lti_registration, foreign_key: :lti_registration_id

  # If this tool has been installed via "paste JSON" or other manual install methods, it will have a manual_configuration.
  has_one :manual_configuration, class_name: "Lti::ToolConfiguration", inverse_of: :lti_registration, foreign_key: :lti_registration_id

  has_many :lti_registration_account_bindings, class_name: "Lti::RegistrationAccountBinding", inverse_of: :registration
  has_many :lti_overlays, class_name: "Lti::Overlay", inverse_of: :registration

  after_update :update_developer_key

  validates :name, :admin_nickname, :vendor, length: { maximum: 255 }
  validates :name, presence: true

  scope :active, -> { where(workflow_state: "active") }

  resolves_root_account through: :account

  before_destroy :destroy_associations

  # Searches for an applicable binding for this Registration and Account in
  # the given root account, its parent root account (for federated consortia), and Site Admin.
  # Searches on the current shard, not the Registration's shard.
  #
  # @return [Lti::RegistrationAccountBinding | nil]
  def account_binding_for(account)
    return nil unless account
    return account_binding if @account_binding_loaded

    # If subaccount support/bindings are needed in the future, reference
    # DeveloperKey#account_binding_for and DeveloperKeyAccountBinding#find_in_account_priority
    # for the correct priority searching logic.
    unless account.root_account?
      account = account.root_account
    end

    account_binding = Lti::RegistrationAccountBinding.find_in_site_admin(self)
    return account_binding if account_binding

    unless account.primary_settings_root_account?
      account_binding = account_binding_for_federated_parent(account)
      return account_binding if account_binding
    end

    Lti::RegistrationAccountBinding.find_by(registration: self, account:)
  end

  def new_external_tool(context, existing_tool: nil)
    # disabled tools should stay disabled while getting updated
    # deleted tools are never updated during a dev key update so can be safely ignored
    tool_is_disabled = existing_tool&.workflow_state == ContextExternalTool::DISABLED_STATE

    tool = existing_tool || ContextExternalTool.new(context:)
    Importers::ContextExternalToolImporter.import_from_migration(
      importable_configuration,
      context,
      nil,
      tool,
      false
    )
    tool.developer_key = developer_key
    tool.workflow_state = (tool_is_disabled && ContextExternalTool::DISABLED_STATE) || privacy_level
    tool
  end

  def self.preload_account_bindings(registrations, account)
    return nil unless account

    # If subaccount support/bindings are needed in the future, reference
    # DeveloperKey#account_binding_for and DeveloperKeyAccountBinding#find_in_account_priority
    # for the correct priority searching logic.
    unless account.root_account?
      account = account.root_account
    end

    account_bindings = Lti::RegistrationAccountBinding.where(account:, registration: registrations) +
                       Lti::RegistrationAccountBinding.find_all_in_site_admin(registrations)

    associate_bindings(registrations, account_bindings)
  end

  def self.associate_bindings(registrations, account_bindings)
    registrations_by_id = registrations.index_by(&:global_id)

    registrations.each { |registration| registration.account_binding_loaded = true }

    account_bindings.each do |acct_binding|
      global_registration_id = Shard.global_id_for(acct_binding.registration_id, Shard.current)
      registration = registrations_by_id[global_registration_id]
      registration&.account_binding = acct_binding
    end
  end
  private_class_method :associate_bindings

  # Returns true if this Registration is from a different account than the given account.
  #
  # This will not properly account for a possible future scenario where the account is
  # for a _sub_ account underneath the registration's root account.
  def inherited_for?(account)
    account != self.account
  end

  # TODO: this will eventually need to account for 1.1 registrations
  def icon_url
    ims_registration&.logo_uri || manual_configuration&.settings&.dig("extensions", 0, "settings", "icon_url")
  end

  # TODO: this will eventually need to account for 1.1 registrations
  def configuration
    # hack; remove the need to look for developer_key.tool_configuration and ensure that is
    # always available as manual_configuration. This would need to happen in an after_save
    # callback on the developer key.
    ims_registration&.internal_lti_configuration || manual_configuration&.internal_configuration || developer_key&.tool_configuration&.internal_configuration || {}
  end

  def importable_configuration
    ims_registration&.importable_configuration || manual_configuration&.importable_configuration || developer_key&.tool_configuration&.importable_configuration || {}
  end

  def privacy_level
    ims_registration&.privacy_level || manual_configuration&.privacy_level || developer_key&.tool_configuration&.privacy_level || DEFAULT_PRIVACY_LEVEL
  end

  # TODO: this will eventually need to account for 1.1 registrations
  def lti_version
    Lti::V1P3
  end

  def dynamic_registration?
    lti_version == Lti::V1P3 && ims_registration.present?
  end

  def undestroy(active_state: "active")
    ims_registration&.undestroy
    developer_key&.update!(workflow_state: active_state)
    lti_registration_account_bindings.each(&:undestroy)
    manual_configuration&.undestroy
    super
  end

  private

  # For unknown reasons, adding dependent: :destroy to the ims_registration or developer_key
  # causes the destroy callbacks to fail, leaving the registration undeleted. Foreign key maybe?
  # The ims_registration and developer_key delete just fine, so we'll just handle it manually.
  # Additionally, dependent: :destroy removes the bindings from the association which we do not want.
  def destroy_associations
    ims_registration&.destroy
    developer_key&.destroy
    lti_registration_account_bindings.each(&:destroy)
    manual_configuration&.destroy
  end

  def update_developer_key
    return if skip_lti_sync

    developer_key&.update!(name: admin_nickname,
                           workflow_state:,
                           skip_lti_sync: true)
  end

  # Overridden in MRA, where federated consortia are supported
  def account_binding_for_federated_parent(_account)
    nil
  end
end
